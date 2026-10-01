"""No-op placeholder. The observability experiment was reverted (dotfiles
678e84f); this stub only exists so any still-running CC session that loaded
the old hook config doesn't block tool calls on a missing script. Safe to
delete once all CC sessions from 2026-07-18 have been restarted.
"""

import sys

sys.stdin.read()
