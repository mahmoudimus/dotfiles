# dotfiles (stow-migration)

Stow-managed dotfiles. This branch replaces the old Ansible + Mackup setup
on `master`/`pre-ansible` with plain [GNU Stow](https://www.gnu.org/software/stow/)
packages — no playbooks, no Dropbox-synced secrets, just symlinks.

## Bootstrap a new machine

```bash
curl -fsSL https://raw.githubusercontent.com/mahmoudimus/dotfiles/stow-migration/bootstrap | sh -s mac
```

Or, if you've already cloned it:

```bash
git clone -b stow-migration git@github.com:mahmoudimus/dotfiles.git ~/.dotfiles
~/.dotfiles/bootstrap mac
```

`bootstrap` installs Homebrew (if missing), installs `git`/`stow`, clones/updates
this repo into `~/.dotfiles`, then hands off to `install`, which stows each
package with `stow -R`. Pass `mac` or `server` to pick the package set for
that machine (see `MAC_PACKAGES`/`SERVER_PACKAGES` in `install`).

## Packages

| Package | Contents |
|---|---|
| `main`  | git/ssh/shell env config, `~/.config/*` (starship, ghostty, k9s, bat, atuin, …), `~/bin` scripts |
| `zsh`   | `.zshrc`, `.zprofile`, `.zsh/*.zsh` fragments, zinit-managed plugins |
| `bash`  | bash equivalents, for `server` hosts without zsh |
| `node`  | nodenv + pnpm setup |
| `python`| pyenv setup |
| `rust`  | rustup setup |
| `tmux`  | tmux config + Catppuccin theme loader |
| `screen`| GNU screen config |
| `ai`    | `~/.claude` — agents and skills for Claude Code |

## Requirements

- [Homebrew](https://brew.sh) (bootstrap installs it)
- [GNU Stow](https://www.gnu.org/software/stow/) (bootstrap installs it)
- An SSH key registered with GitHub — `zinit`, `nodenv`, `pyenv`, and the
  tmux Catppuccin theme all self-install on first shell load via
  `git clone git@github.com:...`, which needs a working key
  (`.ssh/config` already points `IdentityAgent` at the 1Password SSH agent)
- `brew bundle --file=Brewfile` installs the rest of the toolchain; `bin/update`
  runs it plus the various `update-*` helpers

## Notes

- Adding a new dotfile: drop it in the right package (matching its path
  under `$HOME`) and re-run `stow -R <package>`.
- Adding a new package: create the directory, add it to `MAC_PACKAGES`
  and/or `SERVER_PACKAGES` in `install`.
- `stow` refuses to touch a package if any of its target paths already
  exist as real (non-symlink) files — back up and remove the conflicting
  file first, then re-run `stow -R`.
