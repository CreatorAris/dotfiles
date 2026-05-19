# pwsh profile — loaded by $PROFILE stub via dot-source.
# All UI tweaks live here so syncing dotfiles syncs the shell experience.

# -------------------------------------------------------------------
# Aliases / shortcuts
# -------------------------------------------------------------------
# `cc` = Claude Code with permission prompts disabled.
# `cx` = Codex with approval prompts + sandbox disabled.
# pwsh aliases don't take args, so these have to be functions.
function cc { claude --dangerously-skip-permissions @args }
function cx { codex  --dangerously-bypass-approvals-and-sandbox @args }

# -------------------------------------------------------------------
# Terminal-Icons — file-type icons in `Get-ChildItem` output
# -------------------------------------------------------------------
Import-Module Terminal-Icons -ErrorAction SilentlyContinue

# -------------------------------------------------------------------
# Starship prompt
# -------------------------------------------------------------------
if (Get-Command starship -ErrorAction SilentlyContinue) {
    $env:STARSHIP_CONFIG = "$env:USERPROFILE\dotfiles\starship\starship.toml"
    Invoke-Expression (&starship init powershell)
}

# -------------------------------------------------------------------
# PSReadLine — Tokyo Night Storm palette + smarter input UX
# -------------------------------------------------------------------
if ((Get-Module -ListAvailable -Name PSReadLine) -and -not [Console]::IsOutputRedirected) {
    Set-PSReadLineOption -Colors @{
        Command          = '#7aa2f7'  # blue
        Parameter        = '#7dcfff'  # cyan
        Operator         = '#bb9af7'  # purple
        Variable         = '#e0af68'  # yellow
        String           = '#9ece6a'  # green
        Number           = '#ff9e64'  # orange
        Type             = '#bb9af7'  # purple
        Comment          = '#565f89'  # dim
        Keyword          = '#bb9af7'  # purple
        Member           = '#7dcfff'  # cyan
        Default          = '#c0caf5'  # fg
        Emphasis         = '#ff9e64'  # orange
        Error            = '#f7768e'  # red
        InlinePrediction = '#414868'  # very dim — ghost text from history
        ListPrediction   = '#7aa2f7'
        Selection        = "`e[48;2;52;59;88m"   # bg highlight
    }
    Set-PSReadLineOption -PredictionSource HistoryAndPlugin -PredictionViewStyle ListView
    Set-PSReadLineOption -EditMode Emacs
    Set-PSReadLineOption -BellStyle None
    Set-PSReadLineKeyHandler -Key Tab -Function MenuComplete
    Set-PSReadLineKeyHandler -Key Ctrl+d -Function DeleteCharOrExit
}
