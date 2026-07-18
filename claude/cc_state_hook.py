"""Claude Code lifecycle hook -> per-session state file.

Registered for UserPromptSubmit / PreToolUse / PostToolUse / Notification /
Stop / PreCompact / SessionEnd in ~/.claude/settings.json. Writes the current
state to %LOCALAPPDATA%/cc-state/<session>.txt so the wezterm status bar can
show what CC is doing and for how long.

Must stay silent: UserPromptSubmit stdout would be injected into the prompt,
and a non-zero exit from PreToolUse would block the tool call.
"""

import json
import os
import sys
import time

STATE_DIR = os.path.join(os.environ.get("LOCALAPPDATA", ""), "cc-state")


def detail_for_tool(name: str, tool_input: dict) -> str:
    for key in ("description", "command", "file_path", "pattern", "skill", "prompt"):
        val = tool_input.get(key)
        if isinstance(val, str) and val.strip():
            return f"{name}:{val.strip()}"
    return name


def main() -> None:
    try:
        o = json.load(sys.stdin)
    except Exception:
        return
    event = o.get("hook_event_name") or ""
    session_id = o.get("session_id") or "unknown"
    cwd = o.get("cwd") or ""
    path = os.path.join(STATE_DIR, f"{session_id}.txt")

    detail = ""
    if event in ("UserPromptSubmit", "PostToolUse"):
        state = "model"
    elif event == "PreToolUse":
        state = "tool"
        detail = detail_for_tool(o.get("tool_name") or "?", o.get("tool_input") or {})
    elif event == "Notification":
        state = "waiting"
        detail = o.get("message") or ""
    elif event == "Stop":
        state = "idle"
    elif event == "PreCompact":
        state = "compact"
    elif event == "SessionEnd":
        try:
            os.remove(path)
        except OSError:
            pass
        return
    else:
        return

    detail = detail.replace("\t", " ").replace("\n", " ")[:80]
    try:
        os.makedirs(STATE_DIR, exist_ok=True)
        with open(path, "w", encoding="utf-8") as f:
            f.write(f"{int(time.time())}\t{state}\t{detail}\t{cwd}\n")
    except OSError:
        pass


if __name__ == "__main__":
    main()
