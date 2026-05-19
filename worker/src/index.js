// Redirects dotfiles.creatoraris.com -> raw bootstrap.ps1 on GitHub.
// Lets the install command be `irm dotfiles.creatoraris.com | iex`.

const TARGET = 'https://raw.githubusercontent.com/CreatorAris/dotfiles/main/bootstrap.ps1';

export default {
  async fetch() {
    return Response.redirect(TARGET, 302);
  },
};
