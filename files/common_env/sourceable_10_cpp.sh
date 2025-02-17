_SYSTEM_UNAME="$(uname -s)"
case "${_SYSTEM_UNAME}" in
    Linux*)     machine=Linux;;
    Darwin*)    machine=Mac; USER_BIN_PATH="${HOME}/bin";;
    CYGWIN*)    machine=Cygwin;;
    MINGW*)     machine=MinGw;;
    *)          machine="UNKNOWN_${_SYSTEM_UNAME}"
esac
unset _SYSTEM_UNAME

# we're using zsh. based on the machine variable, we need to check that the user
# has a USER_BIN_PATH set. if not, we default to ~/bin and we print out a
# warning. then, we want code that checks to see if the machine is Mac, check to
# see if brew is installed and check to see if clang-tidy and
# clang-apply-replacements and clang-format are in the $(brew --prefix llvm)/bin
# directory. if they are, then add symlinks if they don't exist to
# ${USER_BIN_PATH} so that they're on the path. for each environment, like
# CYGWIN, Linux, Microsoft, based on system uname, we want to set the those
# links in those paths.

# • Checks for USER_BIN_PATH (defaulting it to ~/bin with a warning if it’s not set)

# • For a Mac system, verifies that brew is installed, then attempts to find clang-tidy, clang-apply-replacements, and clang-format in the LLVM directory (as installed via brew). If any of these exist and aren’t already linked in USER_BIN_PATH, it creates a symlink there.

# • For other systems (Linux, Cygwin, MinGw, or unknown), it attempts a similar procedure by locating the tool on the system (via command -v) and linking it into USER_BIN_PATH if found.


# Check if USER_BIN_PATH is set; if not, default to ~/bin and warn the user.
if [[ -z "${USER_BIN_PATH}" ]]; then
    export USER_BIN_PATH="${HOME}/bin"
    echo "WARNING: USER_BIN_PATH not set. Defaulting to ${USER_BIN_PATH}"
fi

# Ensure that the USER_BIN_PATH directory exists.
[[ -d "${USER_BIN_PATH}" ]] || mkdir -p "${USER_BIN_PATH}"

# Define the list of tools we care about.
tools=(clang-tidy clang-apply-replacements clang-format)

if [[ "$machine" == "Mac" ]]; then
    # Check if brew is installed.
    if command -v brew >/dev/null 2>&1; then
        # Try to get the llvm prefix path
        LLVM_PREFIX=$(brew --prefix llvm 2>/dev/null)
        if [[ -n "${LLVM_PREFIX}" && -d "${LLVM_PREFIX}/bin" ]]; then
            for tool in ${tools[@]}; do
                tool_path="${LLVM_PREFIX}/bin/${tool}"
                if [[ -x "${tool_path}" ]]; then
                    # Create symlink only when one does not already exist.
                    if [[ ! -e "${USER_BIN_PATH}/${tool}" ]]; then
                        ln -s "${tool_path}" "${USER_BIN_PATH}/${tool}"
                        echo "Linked ${tool} from ${tool_path} to ${USER_BIN_PATH}"
                    else
                        echo "${tool} already exists in ${USER_BIN_PATH}"
                    fi
                else
                    echo "WARNING: ${tool} not found in ${LLVM_PREFIX}/bin"
                fi
            done
        else
            echo "WARNING: Unable to locate the LLVM installation via brew."
        fi
    else
        echo "WARNING: brew is not installed on this Mac system."
    fi

elif [[ "$machine" == "Linux" ]]; then
    echo "Linux environment detected. Attempting to link clang tools from your PATH if available."
    for tool in ${tools[@]}; do
        # Try finding the tool in the current PATH.
        if command -v ${tool} >/dev/null 2>&1; then
            tool_path=$(command -v ${tool})
            if [[ ! -e "${USER_BIN_PATH}/${tool}" ]]; then
                ln -s "${tool_path}" "${USER_BIN_PATH}/${tool}"
                echo "Linked ${tool} from ${tool_path} to ${USER_BIN_PATH}"
            else
                echo "${tool} already exists in ${USER_BIN_PATH}"
            fi
        else
            echo "WARNING: ${tool} not found in your PATH on Linux."
        fi
    done

elif [[ "$machine" == "Cygwin" || "$machine" == "MinGw" || "$machine" == UNKNOWN* ]]; then
    echo "Non-Mac/Linux environment detected (${machine}). Attempting to link available clang tools."
    for tool in ${tools[@]}; do
        # Try locating the tool via command -v.
        if command -v ${tool} >/dev/null 2>&1; then
            tool_path=$(command -v ${tool})
            if [[ ! -e "${USER_BIN_PATH}/${tool}" ]]; then
                ln -s "${tool_path}" "${USER_BIN_PATH}/${tool}"
                echo "Linked ${tool} from ${tool_path} to ${USER_BIN_PATH}"
            else
                echo "${tool} already exists in ${USER_BIN_PATH}"
            fi
        else
            echo "WARNING: ${tool} not found in your environment (${machine})."
        fi
    done

else
    echo "WARNING: Unrecognized machine type (${machine}). No tool symlinks were created."
fi
