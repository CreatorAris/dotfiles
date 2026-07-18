"""Token-speed widget for Claude Code statusline (ccstatusline custom-command).

Reads the CC statusline JSON on stdin, tails the session transcript JSONL,
groups assistant rows by requestId into API calls, and estimates each call's
generation speed as output_tokens / (call_end - previous_event). The speed of
the most recent call is printed for the statusline, and also dropped into
%LOCALAPPDATA%/cc-tokspeed/<session>.txt for the wezterm tab bar to pick up.

Transcript row format is internal to Claude Code and may change between
releases; on any parse failure this prints nothing and exits 0.
"""

import json
import os
import sys
import time
from datetime import datetime, timezone

TAIL_BYTES = 262_144
MIN_OUT_TOKENS = 16  # ignore tiny calls: rate is all TTFT noise
MIN_DURATION_S = 0.3
STATE_DIR = os.path.join(os.environ.get("LOCALAPPDATA", ""), "cc-tokspeed")
STATE_TTL_S = 24 * 3600


def parse_ts(s: str) -> float | None:
    try:
        return datetime.fromisoformat(s.replace("Z", "+00:00")).timestamp()
    except (ValueError, AttributeError):
        return None


def tail_lines(path: str) -> list[str]:
    with open(path, "rb") as f:
        f.seek(0, os.SEEK_END)
        size = f.tell()
        f.seek(max(0, size - TAIL_BYTES))
        data = f.read()
    text = data.decode("utf-8", errors="ignore")
    lines = text.splitlines()
    if size > TAIL_BYTES and lines:
        lines = lines[1:]  # first line is likely truncated
    return lines


def call_rates(lines: list[str]) -> list[float]:
    """Ordered per-call tok/s, oldest first."""
    calls: dict[str, dict] = {}  # reqId -> {anchor, last, out}
    order: list[str] = []
    prev_ts: float | None = None
    for line in lines:
        try:
            o = json.loads(line)
        except json.JSONDecodeError:
            continue
        ts = parse_ts(o.get("timestamp") or "")
        if ts is None or o.get("isSidechain"):
            continue
        if o.get("type") == "assistant":
            msg = o.get("message") or {}
            req = o.get("requestId") or msg.get("id")
            out = (msg.get("usage") or {}).get("output_tokens")
            if req and isinstance(out, int):
                c = calls.get(req)
                if c is None:
                    calls[req] = {"anchor": prev_ts, "last": ts, "out": out}
                    order.append(req)
                else:
                    c["last"] = max(c["last"], ts)
                    c["out"] = max(c["out"], out)
        prev_ts = ts

    rates = []
    for req in order:
        c = calls[req]
        if c["anchor"] is None or c["out"] < MIN_OUT_TOKENS:
            continue
        dur = c["last"] - c["anchor"]
        if dur >= MIN_DURATION_S:
            rates.append(c["out"] / dur)
    return rates


def write_state(session_id: str, cwd: str, rate: float) -> None:
    try:
        os.makedirs(STATE_DIR, exist_ok=True)
        now = time.time()
        path = os.path.join(STATE_DIR, f"{session_id}.txt")
        with open(path, "w", encoding="utf-8") as f:
            f.write(f"{int(now)}\t{rate:.0f}\t{cwd}\n")
        for name in os.listdir(STATE_DIR):
            p = os.path.join(STATE_DIR, name)
            if now - os.path.getmtime(p) > STATE_TTL_S:
                os.remove(p)
    except OSError:
        pass


def main() -> None:
    try:
        payload = json.load(sys.stdin)
        transcript = payload.get("transcript_path")
        if not transcript or not os.path.isfile(transcript):
            return
        rates = call_rates(tail_lines(transcript))
        if not rates:
            return
        rate = rates[-1]
        session_id = payload.get("session_id") or "unknown"
        cwd = (payload.get("workspace") or {}).get("current_dir") or ""
        write_state(session_id, cwd, rate)
        print(f"{rate:.0f} tok/s")
    except Exception:
        return


if __name__ == "__main__":
    main()
