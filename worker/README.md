# dotfiles-redirect

5-line Cloudflare Worker that redirects `dotfiles.creatoraris.com` to
`raw.githubusercontent.com/.../bootstrap.ps1`, so the install command can be
the short form:

```powershell
irm dotfiles.creatoraris.com | iex
```

## Deploy

```bash
CLOUDFLARE_API_TOKEN=... npx wrangler deploy
```

The API token must come from a CF allow-listed IP (current laptop IP is
blocked; deploy from gcp-tokyo or any other whitelisted machine).
