# Customize to your needs...
# Set the list of directories that Zsh searches for programs.
path=(
    $HOME/.gitextras
    $HOME/bin
    $HOME/.local/bin
    /usr/local/{bin,sbin}
    /usr/{bin,sbin}
    /{bin,sbin}
    "$path[@]"
)
SHELL=/opt/homebrew/bin/zsh

# # Customize to your needs for ZSH *BEFORE* the zshrc is loaded
# # Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# # Initialization code that may require console input (password prompts, [y/n]
# # confirmations, etc.) must go above this block; everything else may go below.
# if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
#     source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
# fi

# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

# autoload -Uz promptinit
# promptinit
# prompt mahmoudimus
# prompt powerlevel10k

# Workaround for: https://github.com/sorin-ionescu/prezto/issues/1744
#
export HISTFILE="${ZDOTDIR:-$HOME}/.zhistory" # The path to the history file.
export HISTSIZE=
export HISTFILESIZE=
