#!/usr/bin/env bash
#
# Shared Python Environment Setup Functions
# Used by: macapply, macupdate, macrun, and other scripts
#
# Usage:
#   source "$(dirname "$0")/lib/python-env.sh"
#   setup_python_env
#

# Default virtualenv name
VENV_NAME="${VENV_NAME:-mac-dev-playbook-venv}"

# Color codes (define if not already set)
RED="${RED:-\033[0;31m}"
GREEN="${GREEN:-\033[0;32m}"
YELLOW="${YELLOW:-\033[1;33m}"
BLUE="${BLUE:-\033[0;34m}"
NC="${NC:-\033[0m}"

# Log functions (if not already defined as functions)
if ! declare -f log &> /dev/null; then
    log() { echo -e "${BLUE}[$(basename "$0")]${NC} $*"; }
fi

if ! declare -f log_warn &> /dev/null; then
    log_warn() { echo -e "${YELLOW}[$(basename "$0")]${NC} $*"; }
fi

if ! declare -f log_error &> /dev/null; then
    log_error() { echo -e "${RED}[$(basename "$0")]${NC} $*"; }
fi

if ! declare -f log_success &> /dev/null; then
    log_success() { echo -e "${GREEN}[$(basename "$0")]${NC} $*"; }
fi

# Setup Python environment (pyenv + virtualenv)
# Returns: 0 on success, 1 on error
setup_python_env() {
    local venv_name="${1:-$VENV_NAME}"

    # Check if we're already in a pyenv virtualenv
    if [[ -n "${PYENV_VERSION:-}" ]]; then
        log "Already in pyenv virtualenv: ${PYENV_VERSION}"
        return 0
    fi

    log_warn "Not in a pyenv virtualenv"
    log "Activating ${venv_name}..."

    # Check if pyenv is installed
    if ! command -v pyenv &> /dev/null; then
        log_error "pyenv not found. Please install pyenv first:"
        log_error "  brew install pyenv"
        log_error "Or run 'macupdate' to set up the environment."
        return 1
    fi

    # Initialize pyenv
    eval "$(pyenv init -)"

    # Check if virtualenv plugin is available
    if ! pyenv commands | grep -q virtualenv; then
        log_error "pyenv-virtualenv plugin not found. Please install it:"
        log_error "  brew install pyenv-virtualenv"
        return 1
    fi

    # Check if virtualenv exists
    if pyenv versions | grep -q "${venv_name}"; then
        pyenv activate "${venv_name}"
        log_success "Activated virtualenv: ${venv_name}"
        return 0
    else
        log_error "Virtualenv '${venv_name}' not found."
        log_error "Please run 'macupdate' first to create the environment."
        log_error ""
        log_error "Or create it manually:"
        log_error "  pyenv virtualenv 3.11 ${venv_name}"
        log_error "  pyenv activate ${venv_name}"
        log_error "  pip install -r requirements.txt"
        return 1
    fi
}

# Get the Python version from .python-version file
get_required_python_version() {
    local repo_root="${1:-.}"
    local python_version_file="${repo_root}/.python-version"

    if [[ -f "${python_version_file}" ]]; then
        cat "${python_version_file}"
    else
        echo "3.11"  # Default fallback
    fi
}

# Check if required Python version is installed
check_python_version() {
    local required_version="${1}"

    if ! command -v pyenv &> /dev/null; then
        return 1
    fi

    if pyenv versions | grep -q "${required_version}"; then
        return 0
    else
        return 1
    fi
}

# Install required Python version if not present
install_python_version() {
    local required_version="${1}"

    log "Installing Python ${required_version}..."

    if ! command -v pyenv &> /dev/null; then
        log_error "pyenv not installed"
        return 1
    fi

    pyenv install "${required_version}"
}

# Create virtualenv if it doesn't exist
create_virtualenv() {
    local venv_name="${1:-$VENV_NAME}"
    local python_version="${2}"

    if pyenv versions | grep -q "${venv_name}"; then
        log "Virtualenv '${venv_name}' already exists"
        return 0
    fi

    log "Creating virtualenv '${venv_name}' with Python ${python_version}..."

    if ! command -v pyenv &> /dev/null; then
        log_error "pyenv not installed"
        return 1
    fi

    pyenv virtualenv "${python_version}" "${venv_name}"
}

# Full setup: Install Python, create venv, install requirements
full_python_setup() {
    local repo_root="${1:-.}"
    local venv_name="${2:-$VENV_NAME}"

    # Get required Python version
    local python_version
    python_version=$(get_required_python_version "${repo_root}")

    log "Required Python version: ${python_version}"

    # Check and install Python if needed
    if ! check_python_version "${python_version}"; then
        install_python_version "${python_version}" || return 1
    fi

    # Create virtualenv if needed
    create_virtualenv "${venv_name}" "${python_version}" || return 1

    # Activate virtualenv
    setup_python_env "${venv_name}" || return 1

    # Install requirements if file exists
    local requirements_file="${repo_root}/requirements.txt"
    if [[ -f "${requirements_file}" ]]; then
        log "Installing requirements from ${requirements_file}..."
        pip install -r "${requirements_file}"
    fi

    log_success "Python environment setup complete"
    return 0
}
