"""Read-only Nephele metrics for WezTerm; network work stays outside Lua."""

import argparse
from concurrent.futures import ThreadPoolExecutor, as_completed
import json
import logging
import os
from pathlib import Path
import re
import time
import urllib.request


CACHE = Path.home() / ".cache" / "wezterm" / "nephele-status.json"
PROJECT = Path(r"E:\Nephele Workshop")
USER_AGENT = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 Chrome/131.0.0.0 Safari/537.36"
INTERVALS = {"presence": 10, "api": 30, "rollout": 60, "telemetry": 60}
FAILURE_EVENTS = (
    "client_error",
    "recorder_start_failed",
    "recorder_rollover_failed",
    "recorder_stop_failed",
    "lazy_window_load_failed",
    "image_download_failed",
    "payment_failed",
)
TELEMETRY_FIELDS = (
    "failure_users_24h",
    "failure_reports_24h",
    "dirty_shutdown_reports_24h",
    "updated_24h",
    "updated_1h",
    "failure_users_1h",
    "failure_reports_1h",
    "failure_users_today",
    "failure_reports_today",
)
FAILURE_CATEGORIES = (*FAILURE_EVENTS, "local_tool_used", "app_crash")
BREAKDOWN_FIELDS = tuple(f"{event}_{suffix}" for event in FAILURE_CATEGORIES for suffix in ("users", "reports"))


def read_env(path: Path) -> dict:
    if not path.is_file():
        return {}
    values = {}
    for line in path.read_text(encoding="utf-8-sig").splitlines():
        if "=" in line and not line.lstrip().startswith("#"):
            key, value = line.split("=", 1)
            values[key.strip()] = value.strip().strip("\"'")
    return values


def request_json(url: str, headers: dict, body: dict | None = None) -> dict:
    request = urllib.request.Request(
        url,
        data=json.dumps(body).encode("utf-8") if body is not None else None,
        headers={"User-Agent": USER_AGENT, "Content-Type": "application/json", **headers},
    )
    with urllib.request.urlopen(request, timeout=15) as response:
        data = json.loads(response.read().decode("utf-8"))
    if not isinstance(data, dict):
        raise ValueError("Expected JSON object")
    return data


def api_summary(data: dict) -> dict:
    # Reuse the monitor's current + four previous minute buckets. Admin,
    # health checks, scanners and synthetic checks aren't product requests.
    windows = data["window5"]
    if not isinstance(windows, dict):
        raise ValueError("Missing API window")
    rows = [v for k, v in windows.items() if re.match(r"^[A-Z]+ /(?:v1|auth)/", k)]
    return {
        "errors_5m": sum(int(v["err"]) for v in rows),
        "requests_5m": sum(int(v["total"]) for v in rows),
        "server_at": data["now"] / 1000,
        "endpoints": sorted(
            (
                {"endpoint": k, "errors": int(v["err"]), "requests": int(v["total"])}
                for k, v in windows.items()
                if re.match(r"^[A-Z]+ /(?:v1|auth)/", k) and int(v["total"]) > 0
            ),
            key=lambda row: (-row["errors"], -row["requests"], row["endpoint"]),
        )[:5],
    }


def rollout_summary(data: dict) -> dict:
    config = data["update_config"] or {}
    percent = int(config.get("rollout_percent", 100))
    if not 0 <= percent <= 100:
        raise ValueError("Invalid rollout percent")
    return {
        "percent": percent,
        "paused": config.get("paused") is True,
        "force_after_version": config.get("force_after_version"),
    }


def _failure_predicate() -> str:
    event_names = ",".join(f"'{event}'" for event in FAILURE_EVENTS)
    return (
        f"(event IN ({event_names}) "
        "AND NOT (event='recorder_start_failed' "
        "AND coalesce(toString(properties.origin),'') IN ('source_reset','doc_switch')) "
        "AND NOT (event='recorder_rollover_failed' "
        "AND coalesce(toString(properties.error),'')='window_gone') "
        "AND NOT (event='recorder_stop_failed' AND coalesce(toString(properties.idle),'')='true') "
        "OR event='local_tool_used' AND properties.status='fail' "
        "OR event='app_crash' AND properties.exception_type!='DirtyShutdown' "
        "AND toString(properties.filtered)!='true')"
    )


def telemetry_query(version: str) -> str:
    if not re.fullmatch(r"[0-9]+\.[0-9]+\.[0-9]+[A-Za-z0-9.+-]*", version):
        raise ValueError("Invalid release version")
    success = (
        "event='update_boot_after_update' AND properties.result='success' "
        f"AND properties.actual_version='{version}' "
        "AND properties.expected_version=properties.actual_version "
        "AND notEmpty(toString(properties.from_version)) "
        "AND properties.from_version!='unknown' "
        "AND properties.from_version!=properties.actual_version"
    )
    event_names = ",".join(f"'{event}'" for event in FAILURE_EVENTS)
    failure = _failure_predicate()
    today = "toDate(toTimeZone(timestamp,'Asia/Shanghai'))=toDate(toTimeZone(now(),'Asia/Shanghai'))"
    breakdown = ",\n".join(
        f"count(DISTINCT if({failure} AND event='{event}',person_id,NULL)) {event}_users, "
        f"countIf({failure} AND event='{event}') {event}_reports"
        for event in FAILURE_CATEGORIES
    )
    return f"""SELECT
      count(DISTINCT if({failure},person_id,NULL)) failure_users_24h,
      countIf({failure}) failure_reports_24h,
      countIf(event='app_crash' AND properties.exception_type='DirtyShutdown'
        AND toString(properties.filtered)!='true'
        AND (empty(toString(properties.prev_version))
             OR properties.prev_version=properties.app_version)) dirty_shutdown_reports_24h,
      count(DISTINCT if({success},person_id,NULL)) updated_24h,
      count(DISTINCT if(timestamp>now()-INTERVAL 1 HOUR
        AND {success},person_id,NULL)) updated_1h,
      count(DISTINCT if(timestamp>now()-INTERVAL 1 HOUR AND {failure},person_id,NULL)) failure_users_1h,
      countIf(timestamp>now()-INTERVAL 1 HOUR AND {failure}) failure_reports_1h,
      count(DISTINCT if({today} AND {failure},person_id,NULL)) failure_users_today,
      countIf({today} AND {failure}) failure_reports_today,
      {breakdown}
    FROM events WHERE timestamp>now()-INTERVAL 24 HOUR
      AND event IN ({event_names},'local_tool_used','app_crash','update_boot_after_update')
      AND (properties.x_client_type='nephele-desktop' OR properties.$lib='posthog-python')
      AND toString(person.properties.is_dev)!='true'
      AND toString(properties.is_dev)!='true'
      AND distinct_id NOT LIKE 'cron:%' AND distinct_id NOT LIKE 'installer:%'
      AND distinct_id NOT IN ('6a843113-2d23-4193-9293-54e5f2012bb9')"""


def fetch_telemetry(headers: dict) -> dict:
    manifest = request_json("https://download.arisfusion.com/beta/manifest.json", {})
    version = manifest["version"]
    data = request_json(
        "https://us.posthog.com/api/projects/281191/query/",
        headers,
        {"query": {"kind": "HogQLQuery", "query": telemetry_query(version)}, "refresh": "force_blocking"},
    )
    rows = data["results"]
    fields = TELEMETRY_FIELDS + BREAKDOWN_FIELDS
    if len(rows) != 1 or len(rows[0]) != len(fields) or any(type(v) is not int or v < 0 for v in rows[0]):
        raise ValueError("Invalid telemetry result")
    values = dict(zip(fields, rows[0]))
    breakdown = sorted(
        (
            {"event": event, "users": values[f"{event}_users"], "reports": values[f"{event}_reports"]}
            for event in FAILURE_CATEGORIES
            if values[f"{event}_reports"] > 0
        ),
        key=lambda row: (-row["reports"], row["event"]),
    )
    return {**{key: values[key] for key in TELEMETRY_FIELDS}, "version": version, "failure_types": breakdown}


def read_cache(path: Path) -> dict:
    try:
        value = json.loads(path.read_text(encoding="utf-8"))
        return value if isinstance(value, dict) else {}
    except (OSError, ValueError):
        return {}


def save_cache(path: Path, data: dict) -> None:
    temporary = path.with_suffix(".tmp")
    temporary.write_text(json.dumps(data, ensure_ascii=False), encoding="utf-8")
    os.replace(temporary, path)


def refresh_source(previous: dict, fetch, now: float) -> dict:
    try:
        value = fetch()
        return {"attempted_at": now, "fetched_at": time.time(), "value": value}
    except Exception as error:
        # No response bodies or credentials in the cache or terminal logs.
        return {**previous, "attempted_at": now, "error": type(error).__name__}


def collect(path: Path = CACHE, force: bool = False) -> dict:
    path.parent.mkdir(parents=True, exist_ok=True)
    # Multiple terminal windows and config reloads share one short-lived job.
    import msvcrt

    with path.with_suffix(".lock").open("a+b") as lock:
        if os.fstat(lock.fileno()).st_size == 0:
            lock.write(b"0")
            lock.flush()
        lock.seek(0)
        try:
            msvcrt.locking(lock.fileno(), msvcrt.LK_NBLCK, 1)
        except OSError:
            return read_cache(path)
        try:
            secrets = read_env(Path(r"E:\.secret"))
            admin_key = read_env(PROJECT / "nephele-api" / ".dev.vars").get("DEV_ADMIN_KEY")
            admin_headers = {
                "X-Dev-Key": admin_key or secrets.get("DEV_ADMIN_KEY_LOCAL") or secrets.get("DEV_ADMIN_KEY", "")
            }
            jobs = {
                "presence": lambda: request_json(
                    "https://ws.arisfusion.com/presence/count",
                    {"X-Presence-Secret": secrets["NEPHELE_PRESENCE_SECRET"]},
                ),
                "api": lambda: api_summary(
                    request_json("https://api.arisfusion.com/admin/error-monitor", admin_headers)
                ),
                "rollout": lambda: rollout_summary(
                    request_json("https://api.arisfusion.com/admin/config", admin_headers)
                ),
                "telemetry": lambda: fetch_telemetry(
                    {"Authorization": "Bearer " + secrets["POSTHOG_PERSONAL_API_TOKEN"]}
                ),
            }
            cache = read_cache(path)
            now = time.time()
            with ThreadPoolExecutor(max_workers=4) as pool:
                pending = {
                    pool.submit(refresh_source, cache.get(name, {}), fetch, now): name
                    for name, fetch in jobs.items()
                    if force or now - cache.get(name, {}).get("attempted_at", 0) >= INTERVALS[name]
                }
                for future in as_completed(pending):
                    cache[pending[future]] = future.result()
                    save_cache(path, cache)
            return cache
        finally:
            lock.seek(0)
            msvcrt.locking(lock.fileno(), msvcrt.LK_UNLCK, 1)


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--force", action="store_true")
    parser.add_argument("--cache", type=Path, default=CACHE)
    args = parser.parse_args()
    try:
        collect(args.cache, args.force)
    except Exception as error:
        logging.error("Status collection failed: %s", type(error).__name__)


if __name__ == "__main__":
    main()
