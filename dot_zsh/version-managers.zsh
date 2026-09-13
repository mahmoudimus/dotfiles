# Lazy-loaded version managers (pyenv, rbenv, nodenv, jenv) and direnv.
#
# Each `eval "$(foo init -)"` spawns a subprocess on every interactive shell,
# about 0.7s between the four. The only part that has to happen before you run
# one of these tools is putting its shims on PATH, so do that directly and defer
# each manager's own init to its first invocation.
#
# Caveat: init also ran a rehash, which this skips. After installing a gem or
# npm package, run `rbenv rehash` or `nodenv rehash` once.
#
# Everything is guarded, so on a machine without these tools this file only
# costs a few directory checks.

export PYENV_ROOT="${PYENV_ROOT:-$HOME/.pyenv}"
export NODENV_ROOT="${NODENV_ROOT:-$HOME/.nodenv}"

# Same order the eager inits used to leave behind. (N/) drops missing dirs.
path[1,0]=(
  "$HOME/.rbenv/shims"(N/)
  "$NODENV_ROOT/bin"(N/)
  "$NODENV_ROOT/shims"(N/)
  "$HOME/.jenv/shims"(N/)
  "$PYENV_ROOT/shims"(N/)
  "$PYENV_ROOT/bin"(N/)
)

_lazy_version_manager() {
  local mgr=$1
  shift
  unfunction "$mgr"
  eval "$(command "$mgr" init -)"
  "$mgr" "$@"
}
for _mgr in pyenv rbenv nodenv jenv; do
  (( $+commands[$_mgr] )) || continue
  eval "${_mgr}() { _lazy_version_manager ${_mgr} \"\$@\" }"
done
unset _mgr

# direnv installs a precmd hook, so it genuinely has to load eagerly.
if (( $+commands[direnv] )); then
  eval "$(direnv hook zsh)"
fi
