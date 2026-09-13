# Customize to your needs...
# Make sure the standard system directories are on the list zsh searches for
# programs. Appended, not prepended: prepending put /usr/bin ahead of Homebrew,
# ~/.local/bin and friends. .zshrc has `typeset -aU path`, so directories that
# are already present keep their position.
path+=(
    /usr/local/{bin,sbin}
    /usr/{bin,sbin}
    /{bin,sbin}
)

# Left over from prezto and deliberately dropped under chezmoi, where .zshrc
# owns these:
# - SHELL=/opt/homebrew/bin/zsh: the login shell sets SHELL, and a hardcoded
#   path breaks anything that execs $SHELL when that zsh is not installed.
# - sourcing ~/.p10k.zsh: .zshrc already does, right after the instant prompt.
# - HISTFILE=~/.zhistory and an empty HISTSIZE (workaround for
#   https://github.com/sorin-ionescu/prezto/issues/1744): .zshrc uses
#   ~/.zsh_history, and an empty HISTSIZE would have switched history off.
