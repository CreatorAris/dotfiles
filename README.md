# dotfiles

Personal terminal & shell config, synced across machines.

## One-line install (Windows)

```powershell
irm https://raw.githubusercontent.com/CreatorAris/dotfiles/main/bootstrap.ps1 | iex
```

That single command:

1. `winget install` — WezTerm, Starship, zoxide, fzf, eza
2. `Install-Module` — Terminal-Icons, PSFzf
3. `git clone` the repo to `$env:USERPROFILE\dotfiles`
4. Download + register Maple Mono NF CN (16 faces, user-level — no admin)
5. Drop stub files at `~/.wezterm.lua` and `$PROFILE` that load this repo
6. Add the "Open in WezTerm" Windows right-click menu

Idempotent. Safe to re-run on a partially-set-up machine — skips anything
already installed.

**Prereqs:** PowerShell 7+ (`pwsh`) and `git` on PATH. Most dev machines
already have both. If missing:

```powershell
winget install Microsoft.PowerShell Git.Git
# close & reopen pwsh, then run the irm | iex line above
```

## Layout

```
dotfiles/
├── bootstrap.ps1                       # one-shot installer (above)
├── install.ps1                         # stub-only step, called by bootstrap
├── wezterm/
│   ├── wezterm.lua                     # Tokyo Night Storm + Maple Mono NF CN + bar.wezterm
│   ├── assets/background.png           # current desktop bg (blurred, sigma=5)
│   ├── regen-background.ps1            # swap / re-blur the bg
│   ├── install-context-menu.ps1        # adds "Open in WezTerm" to right-click
│   └── uninstall-context-menu.ps1
├── pwsh/profile.ps1                    # cc/cx/nw + zoxide + PSFzf + eza + Starship + PSReadLine
└── starship/starship.toml              # Tokyo Night Storm prompt
```

## Daily editing

- WezTerm config — edit `wezterm/wezterm.lua`, save, **hot-reloads instantly**
- pwsh profile — edit `pwsh/profile.ps1`, then `. $PROFILE` or open a fresh tab
- Background — `pwsh -File wezterm/regen-background.ps1 -Source <path> -Sigma <N>`

## Uninstall

```powershell
pwsh -File ~/dotfiles/wezterm/uninstall-context-menu.ps1
Remove-Item ~/.wezterm.lua
Remove-Item $PROFILE
# winget uninstall the apps separately if desired
```
