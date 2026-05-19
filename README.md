# dotfiles

Personal terminal & shell config, synced across machines.

## Layout

```
dotfiles/
├── wezterm/
│   └── wezterm.lua    # WezTerm config (Tokyo Night Storm, Maple Mono NF CN)
└── install.ps1        # Symlink targets into %USERPROFILE%
```

## New machine setup (Windows)

```powershell
# 1. Install WezTerm + font
winget install --id wez.wezterm -e
# Download Maple Mono NF CN from https://github.com/subframe7536/maple-font/releases

# 2. Clone this repo
git clone git@github.com:CreatorAris/dotfiles.git $env:USERPROFILE\dotfiles

# 3. Run install (requires admin shell for symlinks, OR enable Windows Dev Mode)
cd $env:USERPROFILE\dotfiles
pwsh -File install.ps1
```

## Updating config

Edit files inside `~/dotfiles/`, commit, push. WezTerm hot-reloads on save.
