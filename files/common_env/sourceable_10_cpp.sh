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


# CLANG_CONFIG_FILE_SYSTEM_DIR: /opt/homebrew/etc/clang
# CLANG_CONFIG_FILE_USER_DIR:   ~/.config/clang

# LLD is now provided in a separate formula:
#   brew install lld

# Using `clang`, `clang++`, etc., requires a CLT installation at `/Library/Developer/CommandLineTools`.
# If you don't want to install the CLT, you can write appropriate configuration files pointing to your
# SDK at ~/.config/clang.

# To use the bundled libunwind please use the following LDFLAGS:
#   LDFLAGS="-L/opt/homebrew/opt/llvm/lib/unwind -lunwind"

# To use the bundled libc++ please use the following LDFLAGS:
#   LDFLAGS="-L/opt/homebrew/opt/llvm/lib/c++ -L/opt/homebrew/opt/llvm/lib/unwind -lunwind"

# NOTE: You probably want to use the libunwind and libc++ provided by macOS unless you know what you're doing.

# llvm is keg-only, which means it was not symlinked into /opt/homebrew,
# because macOS already provides this software and installing another version in
# parallel can cause all kinds of trouble.

# If you need to have llvm first in your PATH, run:
#   echo 'export PATH="/opt/homebrew/opt/llvm/bin:$PATH"' >> ~/.zshrc

# For compilers to find llvm you may need to set:
#   export LDFLAGS="-L/opt/homebrew/opt/llvm/lib"
#   export CPPFLAGS="-I/opt/homebrew/opt/llvm/include"


# CLANG_CONFIG_FILE_SYSTEM_DIR: /opt/homebrew/etc/clang
# CLANG_CONFIG_FILE_USER_DIR:   ~/.config/clang

# LLD is now provided in a separate formula:
#   brew install lld

# Using `clang`, `clang++`, etc., requires a CLT installation at `/Library/Developer/CommandLineTools`.
# If you don't want to install the CLT, you can write appropriate configuration files pointing to your
# SDK at ~/.config/clang.

# To use the bundled libunwind please use the following LDFLAGS:
#   LDFLAGS="-L/opt/homebrew/opt/llvm/lib/unwind -lunwind"

# To use the bundled libc++ please use the following LDFLAGS:
#   LDFLAGS="-L/opt/homebrew/opt/llvm/lib/c++ -L/opt/homebrew/opt/llvm/lib/unwind -lunwind"

# NOTE: You probably want to use the libunwind and libc++ provided by macOS unless you know what you're doing.

# llvm is keg-only, which means it was not symlinked into /opt/homebrew,
# because macOS already provides this software and installing another version in
# parallel can cause all kinds of trouble.

# If you need to have llvm first in your PATH, run:
#   echo 'export PATH="/opt/homebrew/opt/llvm/bin:$PATH"' >> ~/.zshrc

# For compilers to find llvm you may need to set:
#   export LDFLAGS="-L/opt/homebrew/opt/llvm/lib"
#   export CPPFLAGS="-I/opt/homebrew/opt/llvm/include"


VERBOSE_LOG=0

verbose() {
    if [[ "${VERBOSE_LOG}" == "1" ]]; then
        echo "$@"
    fi
}

# Function to print warning messages in orange
warning() {
    # Orange (bold yellow) color: \033[1;33m, reset: \033[0m
    # Use escape sequences only if output is a terminal
    if [ -t 1 ]; then
        echo -e "\033[1;33mWARNING:\033[0m $@"
    else
        echo "WARNING: $@"
    fi
}

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
                        verbose "Linked ${tool} from ${tool_path} to ${USER_BIN_PATH}"
                    else
                        verbose "${tool} already exists in ${USER_BIN_PATH}"
                    fi
                else
                    warning "${tool} not found in ${LLVM_PREFIX}/bin"
                fi
            done
        else
            warning "Unable to locate the LLVM installation via brew."
        fi
    else
        warning "brew is not installed on this Mac system."
    fi

elif [[ "$machine" == "Linux" ]]; then
    verbose "Linux environment detected. Attempting to link clang tools from your PATH if available."
    for tool in ${tools[@]}; do
        # Try finding the tool in the current PATH.
        if command -v ${tool} >/dev/null 2>&1; then
            tool_path=$(command -v ${tool})
            if [[ ! -e "${USER_BIN_PATH}/${tool}" ]]; then
                ln -s "${tool_path}" "${USER_BIN_PATH}/${tool}"
                verbose "Linked ${tool} from ${tool_path} to ${USER_BIN_PATH}"
            else
                verbose "${tool} already exists in ${USER_BIN_PATH}"
            fi
        else
            warning "${tool} not found in your PATH on Linux."
        fi
    done

elif [[ "$machine" == "Cygwin" || "$machine" == "MinGw" || "$machine" == UNKNOWN* ]]; then
    verbose "Non-Mac/Linux environment detected (${machine}). Attempting to link available clang tools."
    for tool in ${tools[@]}; do
        # Try locating the tool via command -v.
        if command -v ${tool} >/dev/null 2>&1; then
            tool_path=$(command -v ${tool})
            if [[ ! -e "${USER_BIN_PATH}/${tool}" ]]; then
                ln -s "${tool_path}" "${USER_BIN_PATH}/${tool}"
                verbose "Linked ${tool} from ${tool_path} to ${USER_BIN_PATH}"
            else
                verbose "${tool} already exists in ${USER_BIN_PATH}"
            fi
        else
            warning "${tool} not found in your environment (${machine})."
        fi
    done

else
    warning "Unrecognized machine type (${machine}). No tool symlinks were created."
fi
