"""Claude Code state widget for ccstatusline (custom-command).

Reads the statusline JSON on stdin, looks up this session's state file
written by cc_state_hook.py, and prints "<state> <elapsed>" for the bottom
statusline. Prints nothing when idle or when no state file exists.

User interrupts (Esc / tool rejection) fire no hook, so the state file
would stay stuck on the last tool/model state forever. The transcript does
record them as a user text row starting with "[Request interrupted by user",
so any interrupt marker newer than the state file forces idle. A hard
elapsed cap catches everything else (killed sessions, missed events).
"""

import json
import os
import sys
import time
from datetime import datetime

STATE_DIR = os.path.join(os.environ.get("LOCALAPPDATA", ""), "cc-state")
DETAIL_MAX = 32
TAIL_BYTES = 16_384
STALE_CAP_S = 15 * 60


def fmt_elapsed(seconds: int) -> str:
    if seconds < 60:
        return f"{seconds}s"
    return f"{seconds // 60}m{seconds % 60:02d}s"


def last_interrupt_ts(transcript: str) -> float | None:
    """Epoch of the newest '[Request interrupted by user...' row, if any."""
    try:
        with open(transcript, "rb") as f:
            f.seek(0, os.SEEK_END)
            f.seek(max(0, f.tell() - TAIL_BYTES))
            tail = f.read().decode("utf-8", errors="ignore")
    except OSError:
        return None
    newest = None
    for line in tail.splitlines():
        if "[Request interrupted by user" not in line:
            continue
        try:
            o = json.loads(line)
        except json.JSONDecodeError:
            continue
        if o.get("type") != "user":
            continue
        content = (o.get("message") or {}).get("content")
        if not isinstance(content, list):
            continue
        hit = any(
            isinstance(c, dict)
            and c.get("type") == "text"
            and str(c.get("text", "")).startswith("[Request interrupted by user")
            for c in content
        )
        if hit:
            try:
                ts = datetime.fromisoformat((o.get("timestamp") or "").replace("Z", "+00:00")).timestamp()
            except ValueError:
                continue
            if newest is None or ts > newest:
                newest = ts
    return newest


def main() -> None:
    try:
        payload = json.load(sys.stdin)
        session_id = payload.get("session_id")
        if not session_id:
            return
        path = os.path.join(STATE_DIR, f"{session_id}.txt")
        with open(path, encoding="utf-8") as f:
            ts_raw, state, detail, _cwd = f.readline().rstrip("\n").split("\t", 3)
        state_ts = int(ts_raw)
        elapsed = max(0, int(time.time()) - state_ts)
        if state == "idle" or elapsed > STALE_CAP_S:
            return

        transcript = payload.get("transcript_path")
        if transcript and state in ("model", "tool"):
            interrupted = last_interrupt_ts(transcript)
            if interrupted is not None and interrupted >= state_ts:
                return

        if state == "tool":
            label = detail[:DETAIL_MAX] or "tool"
        elif state == "model":
            label = "generating"
        elif state == "waiting":
            label = "awaiting input"
        elif state == "compact":
            label = "compacting"
        else:
            return
        print(f"{label} {fmt_elapsed(elapsed)}")
    except Exception:
        return


if __name__ == "__main__":
    main()
