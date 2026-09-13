export HOMEBREW_GITHUB_API_TOKEN=$(security find-generic-password -s 'HOMEBREW_GITHUB_API_TOKEN' -w)

# GITHUB_TOKEN comes from Keychain, not from a literal op:// reference.
#
# History: this used to be `export GITHUB_TOKEN="op://Private/<id>/token"`.
# gh reads GITHUB_TOKEN in preference to its own keyring credentials, so an
# unresolved reference did not merely fail to help -- it shadowed working auth.
# `gh auth status` reported "The token in GITHUB_TOKEN is invalid" until the
# variable was unset.
#
# Resolving through `op` at shell start is not an option either: op is signed
# out by default, so it would block on a sign-in prompt in every new terminal.
# Keychain needs no sign-in and costs ~20ms, same as the line above.
#
# Only exported when non-empty. If the Keychain item is missing, GITHUB_TOKEN
# stays unset and gh falls back to its keyring, which is the working path.
_github_token=$(security find-generic-password -s 'GITHUB_TOKEN' -w 2>/dev/null)
if [ -n "$_github_token" ]; then
    export GITHUB_TOKEN="$_github_token"
fi
unset _github_token

# One-time per machine, after `op signin`: copy the token out of 1Password into
# Keychain so the block above finds it. New shells pick it up from then on.
#
# `security` takes the secret as an argument, so it is briefly visible to `ps`
# on this machine. If you would rather not, run this instead and paste at the
# prompt, which reads from the terminal without echoing:
#
#     security add-generic-password -U -a "$USER" -s GITHUB_TOKEN -w
#
sync_github_token_to_keychain() {
    if ! command -v op > /dev/null 2>&1; then
        echo "sync_github_token_to_keychain: 1Password CLI (op) not found" >&2
        return 1
    fi

    local _token
    if ! _token=$(op read "op://Private/gz6cwnpibov6b2nbrsbx2lhso4/token"); then
        echo "sync_github_token_to_keychain: op read failed; run 'op signin' first" >&2
        return 1
    fi

    if [ -z "$_token" ]; then
        echo "sync_github_token_to_keychain: op returned an empty value" >&2
        return 1
    fi

    security add-generic-password -U -a "$USER" -s GITHUB_TOKEN -w "$_token" || return 1
    _token=

    echo "GITHUB_TOKEN stored in Keychain. Open a new shell to pick it up."
}
