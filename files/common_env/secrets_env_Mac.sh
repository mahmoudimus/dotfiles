export HOMEBREW_GITHUB_API_TOKEN=$(security find-generic-password -s 'HOMEBREW_GITHUB_API_TOKEN' -w)

# GITHUB_TOKEN is deliberately NOT exported here.
#
# It used to be assigned the literal string "op://Private/<id>/token". gh reads
# GITHUB_TOKEN in preference to its own keyring credentials, so an unresolved
# reference does not merely fail to help -- it shadows working auth. With it
# set, `gh auth status` reports "The token in GITHUB_TOKEN is invalid"; with it
# unset, the same command logs in fine from the keyring.
#
# Resolving it eagerly is not an option either: `op` is signed out by default,
# so `op read` at shell start would block on a sign-in or biometric prompt on
# every new terminal. Call the function below when a tool actually needs the
# token, the same way export_llm_keys works in env_Mac.sh.
#
#     export_github_token && terraform apply
#
# If you would rather have it always set, put the token in Keychain and use the
# same pattern as HOMEBREW_GITHUB_API_TOKEN above; that costs ~20ms and needs
# no sign-in.
export_github_token() {
    if ! command -v op > /dev/null 2>&1; then
        echo "export_github_token: 1Password CLI (op) not found" >&2
        return 1
    fi

    local _token
    if ! _token=$(op read "op://Private/gz6cwnpibov6b2nbrsbx2lhso4/token"); then
        echo "export_github_token: op read failed; run 'op signin' first" >&2
        return 1
    fi

    export GITHUB_TOKEN="$_token"
}
