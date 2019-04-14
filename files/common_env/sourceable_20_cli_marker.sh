# if marker is setup
if [[ -s "$HOME/.local/share/marker/marker.sh" ]]; then
    export MARKER_KEY_MARK="^[^k" # default is \C-k
    export MARKER_KEY_GET="^[^@" # default is \C-@
    export MARKER_KEY_NEXT_PLACEHOLDER="^[^t" # default is \C-t
fi
