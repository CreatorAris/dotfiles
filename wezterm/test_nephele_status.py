import importlib.util
from pathlib import Path
import sqlite3
import tempfile
import unittest
from unittest.mock import patch

spec = importlib.util.spec_from_file_location("status", Path(__file__).with_name("nephele_status.py"))
status = importlib.util.module_from_spec(spec)
spec.loader.exec_module(status)


class StatusTests(unittest.TestCase):
    def test_api_excludes_admin_health_and_scanners(self):
        result = status.api_summary(
            {
                "now": 123000,
                "window5": {
                    "POST /v1/chat/max": {"err": 2, "total": 20},
                    "POST /auth/send-code": {"err": 1, "total": 5},
                    "GET /admin/config": {"err": 3},
                    "GET unmatched": {"err": 9},
                    "GET /health": {"err": 1},
                    "captcha_widget_geetest": {"err": 4},
                },
            }
        )
        self.assertEqual(result["errors_5m"], 3)
        self.assertEqual(result["requests_5m"], 25)
        self.assertEqual(result["server_at"], 123)
        self.assertEqual(
            result["endpoints"],
            [
                {"endpoint": "POST /v1/chat/max", "errors": 2, "requests": 20},
                {"endpoint": "POST /auth/send-code", "errors": 1, "requests": 5},
            ],
        )

    def test_missing_api_window_is_not_zero_errors(self):
        with self.assertRaises(KeyError):
            status.api_summary({"error": "Unavailable"})

    def test_rollout_defaults_only_when_config_is_present(self):
        self.assertEqual(status.rollout_summary({"update_config": None})["percent"], 100)
        with self.assertRaises(KeyError):
            status.rollout_summary({"error": "Unavailable"})
        self.assertTrue(status.rollout_summary({"update_config": {"paused": True, "rollout_percent": 10}})["paused"])

    def test_success_and_failure_cache_states(self):
        previous = {"value": {"online": 63}, "fetched_at": 100}

        def fail():
            raise ValueError("secret response body")

        failed = status.refresh_source(previous, fail, 200)
        self.assertEqual(failed["value"], previous["value"])
        self.assertEqual(failed["fetched_at"], 100)
        self.assertEqual(failed["error"], "ValueError")
        recovered = status.refresh_source(failed, lambda: {"online": 0}, 300)
        self.assertNotIn("error", recovered)
        self.assertEqual(recovered["value"]["online"], 0)

    def test_cjk_io_and_atomic_cache(self):
        with tempfile.TemporaryDirectory(prefix="状态栏测试-") as temporary:
            path = Path(temporary) / "遥测.json"
            status.save_cache(path, {"说明": "更新成功"})
            self.assertEqual(status.read_cache(path), {"说明": "更新成功"})
            path.write_text("broken", encoding="utf-8")
            self.assertEqual(status.read_cache(path), {})
            env = Path(temporary) / "凭证.env"
            env.write_text('# ignored=secret\nKEY="中文"\n', encoding="utf-8")
            self.assertEqual(status.read_env(env), {"KEY": "中文"})

    def test_query_rejects_untrusted_version(self):
        with self.assertRaises(ValueError):
            status.telemetry_query("0.8.1'; DROP TABLE events")

    def _matches_failure(self, event: str, **properties: str | None) -> bool:
        columns = ("origin", "error", "idle", "status", "exception_type", "filtered")
        with sqlite3.connect(":memory:") as database:
            database.create_function("toString", 1, lambda value: value)
            database.execute("CREATE TABLE events (event TEXT, " + ", ".join(f"{name} TEXT" for name in columns) + ")")
            values = (event, *(properties.get(name) for name in columns))
            database.execute("INSERT INTO events VALUES (" + ",".join("?" for _ in values) + ")", values)
            result = database.execute(f"SELECT {status._failure_predicate()} FROM events AS properties").fetchone()
        return bool(result[0])

    def test_start_failure_preserves_manual_and_legacy_events(self) -> None:
        for origin in (None, "", "manual", "auto_prompt", "switch"):
            with self.subTest(origin=origin):
                self.assertTrue(self._matches_failure("recorder_start_failed", origin=origin))
        for origin in ("source_reset", "doc_switch"):
            with self.subTest(origin=origin):
                self.assertFalse(self._matches_failure("recorder_start_failed", origin=origin))

    def test_rollover_failure_counts_only_terminal_errors(self) -> None:
        for error in (None, "", "No Open Document", "finalization_timeout"):
            with self.subTest(error=error):
                self.assertTrue(self._matches_failure("recorder_rollover_failed", origin="source_reset", error=error))
        self.assertFalse(self._matches_failure("recorder_rollover_failed", error="window_gone"))

    def test_rollover_attempts_do_not_inflate_terminal_count(self) -> None:
        attempts = [
            ("recorder_start_failed", {"origin": "source_reset", "error": "No Open Document"}),
            ("recorder_start_failed", {"origin": "source_reset", "error": "No Open Document"}),
        ]
        self.assertEqual(sum(self._matches_failure(event, **props) for event, props in attempts), 0)
        terminal = ("recorder_rollover_failed", {"origin": "source_reset", "error": "No Open Document"})
        self.assertEqual(sum(self._matches_failure(event, **props) for event, props in [*attempts, terminal]), 1)
        failed_stop = ("recorder_stop_failed", {"origin": "source_reset", "idle": "false"})
        self.assertEqual(
            sum(self._matches_failure(event, **props) for event, props in [*attempts, failed_stop, terminal]), 2
        )

    def test_stop_and_other_failure_rules_are_preserved(self) -> None:
        self.assertFalse(self._matches_failure("recorder_stop_failed", idle="true"))
        for idle in (None, "false"):
            with self.subTest(idle=idle):
                self.assertTrue(self._matches_failure("recorder_stop_failed", origin="doc_switch", idle=idle))
        for event in ("client_error", "image_download_failed", "lazy_window_load_failed", "payment_failed"):
            with self.subTest(event=event):
                self.assertTrue(self._matches_failure(event))
        self.assertTrue(self._matches_failure("local_tool_used", status="fail"))
        self.assertFalse(self._matches_failure("local_tool_used", status="success"))
        self.assertTrue(self._matches_failure("app_crash", exception_type="RuntimeError", filtered="false"))
        self.assertFalse(self._matches_failure("app_crash", exception_type="DirtyShutdown", filtered="false"))
        self.assertFalse(self._matches_failure("app_crash", exception_type="RuntimeError", filtered="true"))

    def test_all_failure_windows_and_breakdowns_share_the_predicate(self) -> None:
        query = status.telemetry_query("0.8.1-beta")
        self.assertIn("recorder_rollover_failed", status.FAILURE_EVENTS)
        self.assertEqual(query.count(status._failure_predicate()), 6 + 2 * len(status.FAILURE_CATEGORIES))
        self.assertIn("recorder_rollover_failed_users", query)
        self.assertIn("recorder_rollover_failed_reports", query)

    def test_second_window_does_not_read_a_locked_byte(self):
        import msvcrt

        with tempfile.TemporaryDirectory(prefix="并发状态栏-") as temporary:
            path = Path(temporary) / "缓存.json"
            status.save_cache(path, {"presence": {"value": {"online": 63}}})
            with path.with_suffix(".lock").open("w+b") as lock:
                lock.write(b"0")
                lock.flush()
                lock.seek(0)
                msvcrt.locking(lock.fileno(), msvcrt.LK_NBLCK, 1)
                try:
                    self.assertEqual(status.collect(path)["presence"]["value"]["online"], 63)
                finally:
                    lock.seek(0)
                    msvcrt.locking(lock.fileno(), msvcrt.LK_UNLCK, 1)

    def test_telemetry_validation(self):
        counts = dict(zip(status.TELEMETRY_FIELDS, [8, 53, 20, 43, 2, 1, 2, 8, 46]))
        counts.update(
            recorder_start_failed_users=2,
            recorder_start_failed_reports=41,
            recorder_rollover_failed_users=1,
            recorder_rollover_failed_reports=2,
        )
        fields = status.TELEMETRY_FIELDS + status.BREAKDOWN_FIELDS
        with patch.object(
            status,
            "request_json",
            side_effect=[{"version": "0.8.0-beta.1"}, {"results": [[counts.get(key, 0) for key in fields]]}],
        ):
            result = status.fetch_telemetry({})
        self.assertEqual(result["updated_24h"], 43)
        self.assertEqual(result["updated_1h"], 2)
        self.assertEqual(result["failure_users_24h"], 8)
        self.assertEqual(result["failure_reports_24h"], 53)
        self.assertEqual(result["dirty_shutdown_reports_24h"], 20)
        self.assertEqual(result["failure_reports_today"], 46)
        self.assertEqual(
            result["failure_types"],
            [
                {"event": "recorder_start_failed", "users": 2, "reports": 41},
                {"event": "recorder_rollover_failed", "users": 1, "reports": 2},
            ],
        )
        with patch.object(status, "request_json", side_effect=[{"version": "0.8.0-beta.1"}, {"results": []}]):
            with self.assertRaises(ValueError):
                status.fetch_telemetry({})


if __name__ == "__main__":
    unittest.main()
