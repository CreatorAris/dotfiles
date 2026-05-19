# dotfiles

Personal terminal & shell config, synced across machines.

## Layout

```
dotfiles/
├── wezterm/
│   └── wezterm.lua    # WezTerm config (Tokyo Night Storm, Maple Mono NF CN)
└── install.ps1        # Drop bootstrap stubs into %USERPROFILE%
```

`install.ps1` writes one-line stub files in `$env:USERPROFILE` that `dofile()` the
real config in this repo. No symlinks, so no admin / Developer Mode required.

## New machine setup (Windows)

```powershell
# 1. Install WezTerm + Maple Mono NF CN
winget install --id wez.wezterm -e
# Font: https://github.com/subframe7536/maple-font/releases  (MapleMono-NF-CN.zip)
# Drop the .ttf files into %LOCALAPPDATA%\Microsoft\Windows\Fonts and register
# under HKCU:\Software\Microsoft\Windows NT\CurrentVersion\Fonts.

# 2. Clone this repo to $env:USERPROFILE\dotfiles
git clone git@github.com:CreatorAris/dotfiles.git $env:USERPROFILE\dotfiles

# 3. Install bootstrap stubs
cd $env:USERPROFILE\dotfiles
pwsh -File install.ps1
```

## Updating config

Edit files inside `~/dotfiles/`, commit, push. WezTerm hot-reloads on save.
