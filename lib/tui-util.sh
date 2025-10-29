#!/bin/bash
# TUI Utility Library - Standalone utilities for user interaction
# Can be used independently in scripts without the full TUI menu system

# ANSI color codes (matching DTS color scheme)
TUI_NORMAL='\033[0m'
TUI_RED='\033[0;31m'
TUI_GREEN='\033[0;32m'
TUI_YELLOW='\033[0;33m'
TUI_BLUE='\033[0;36m' # Cyan, used for borders (matches DTS BLUE)

# Terminal width configuration
TUI_MAX_WIDTH=60 # Maximum width for borders and footer wrapping

# ============================================================================
# Terminal Control Functions
# ============================================================================

# Clear the terminal screen
# Usage: tui_clear_screen
tui_clear_screen() {
    printf '\033[2J\033[H'
}

# Hide terminal cursor
# Usage: tui_hide_cursor
tui_hide_cursor() {
    printf '\033[?25l'
}

# Show terminal cursor
# Usage: tui_show_cursor
tui_show_cursor() {
    printf '\033[?25h'
}

# Clear current line
# Usage: tui_clear_line
tui_clear_line() {
    printf '\r\033[K'
}

# Trap to ensure cursor is shown on exit
trap 'tui_show_cursor' EXIT INT TERM

# ============================================================================
# Utility Functions
# ============================================================================

# Calculate visible text length (stripping ANSI codes)
# Usage: tui_visible_length "text with ANSI codes"
tui_visible_length() {
    local text="$1"
    # Remove ANSI escape sequences and count characters
    echo -n "$text" | sed 's/\x1b\[[0-9;]*m//g' | wc -c
}

# Generate a border string of specified length with character
# Usage: tui_generate_border 80 "*"
tui_generate_border() {
    local length="$1"
    local char="${2:-*}"
    printf "%${length}s" | tr ' ' "$char"
}

# Expand environment variables in a string
# Usage: tui_expand_vars "string with $VAR"
tui_expand_vars() {
    local string="$1"
    # Use eval to expand variables, but safely quote the result
    eval "printf '%s' \"$string\""
}

# Check if a condition evaluates to true
# Conditions can be:
#  - Environment variables: ${VAR} or ${VAR:-default}
#  - Shell commands: systemctl is-active sshd.service
# Usage: tui_check_condition "condition"
tui_check_condition() {
    local condition="$1"
    [[ -z "$condition" ]] && return 0 # No condition means always show

    # First, try to expand as environment variable
    local result
    result=$(eval echo "$condition" 2>/dev/null || echo "")

    # If result is non-empty after variable expansion, check its value
    if [[ -n "$result" && "$result" != "$condition" ]]; then
        # Variable was expanded - check if result is truthy
        [[ "$result" != "false" && "$result" != "0" ]]
        return $?
    fi

    # Not a variable expansion - treat as shell command
    # Execute command and check exit code (suppress all output)
    eval "$condition" &>/dev/null
    return $?
}

# ============================================================================
# Color Echo Functions (DTS-compatible)
# ============================================================================

# Print text in normal color
# Usage: tui_echo_normal "text"
tui_echo_normal() {
    echo -e "${TUI_NORMAL}$1${TUI_NORMAL}"
}

# Print text in red
# Usage: tui_echo_red "text"
tui_echo_red() {
    echo -e "${TUI_RED}$1${TUI_NORMAL}"
}

# Print text in yellow
# Usage: tui_echo_yellow "text"
tui_echo_yellow() {
    echo -e "${TUI_YELLOW}$1${TUI_NORMAL}"
}

# Print text in green
# Usage: tui_echo_green "text"
tui_echo_green() {
    echo -e "${TUI_GREEN}$1${TUI_NORMAL}"
}

# Print text in blue (cyan)
# Usage: tui_echo_blue "text"
tui_echo_blue() {
    echo -e "${TUI_BLUE}$1${TUI_NORMAL}"
}

# ============================================================================
# Status Message Functions
# ============================================================================

# Print a warning message in yellow
# Usage: tui_print_warning "message"
tui_print_warning() {
    tui_echo_yellow "Warning: $1"
}

# Print an error message in red
# Usage: tui_print_error "message"
tui_print_error() {
    tui_echo_red "Error: $1"
}

# Print a success message in green
# Usage: tui_print_success "message"
tui_print_success() {
    tui_echo_green "$1"
}

# ============================================================================
# Border and Layout Functions
# ============================================================================

# Print a full-width border line
# Usage: tui_print_border
tui_print_border() {
    local border
    border=$(tui_generate_border "$TUI_MAX_WIDTH" "*")
    echo -e "${TUI_BLUE}${border}${TUI_NORMAL}"
}

# Print the "**" prefix used in sections and menu items
# Usage: tui_print_border_prefix
tui_print_border_prefix() {
    echo -n -e "${TUI_BLUE}**${TUI_NORMAL}"
}

# Print a section header with borders
# Usage: tui_print_section_header "SECTION LABEL"
tui_print_section_header() {
    local label="$1"
    tui_print_border
    echo -e "${TUI_BLUE}**${TUI_NORMAL}                $label ${TUI_NORMAL}"
    tui_print_border
}

# Print a section entry (label: value)
# Usage: tui_print_section_entry "Label" "Value"
tui_print_section_entry() {
    local label="$1"
    local value="$2"
    printf "${TUI_BLUE}**${TUI_YELLOW}%15s: ${TUI_NORMAL}%s\n" "$label" "$value"
}

# Print a menu option
# Usage: tui_print_menu_option "1" "Menu label"
tui_print_menu_option() {
    local key="$1"
    local label="$2"
    printf "${TUI_BLUE}**${TUI_YELLOW}     %s)${TUI_BLUE} %s${TUI_NORMAL}\n" "$key" "$label"
}

# Print a footer action
# Usage: tui_print_footer_action "K" "label"
tui_print_footer_action() {
    local key="$1"
    local label="$2"
    echo -n -e "${TUI_RED}$key${TUI_NORMAL} to $label"
}

# ============================================================================
# Input Functions
# ============================================================================

# Read a single keypress without waiting for Enter
# Usage: key=$(tui_read_key)
tui_read_key() {
    local key
    read -n 1 -s key
    echo "$key"
}

# Print prompt and read user input (full line)
# Usage: answer=$(tui_read_prompt "Enter your name")
tui_read_prompt() {
    local prompt="$1"
    local answer
    echo -n "${prompt}: " >&2
    read -r answer
    echo "${answer}"
}

# Wait for user to press any key
# Usage: tui_read_key_to_continue
tui_read_key_to_continue() {
    echo "" >&2
    echo -n "Press any key to continue..." >&2
    tui_read_key
}

# Wait for user to press Enter
# Usage: tui_read_enter_to_continue
tui_read_enter_to_continue() {
    echo "" >&2
    echo -n "Press Enter to continue..." >&2
    read -r &>/dev/null
}

# Read yes/no confirmation
# Usage: if tui_read_confirm "Delete file?"; then ... fi
tui_read_confirm() {
    local prompt="$1"
    local answer
    echo -n "${prompt} (y/n): " >&2
    read -r answer
    [[ "$answer" =~ ^[Yy]$ ]]
}

# ============================================================================
# Export Functions for Use in Other Scripts
# ============================================================================

# Terminal control
export -f tui_clear_screen
export -f tui_hide_cursor
export -f tui_show_cursor
export -f tui_clear_line

# Utility functions
export -f tui_visible_length
export -f tui_generate_border
export -f tui_expand_vars
export -f tui_check_condition

# Color echo functions
export -f tui_echo_normal
export -f tui_echo_red
export -f tui_echo_yellow
export -f tui_echo_green
export -f tui_echo_blue

# Status message functions
export -f tui_print_warning
export -f tui_print_error
export -f tui_print_success

# Border and layout functions
export -f tui_print_border
export -f tui_print_border_prefix
export -f tui_print_section_header
export -f tui_print_section_entry
export -f tui_print_menu_option
export -f tui_print_footer_action

# Input functions
export -f tui_read_key
export -f tui_read_prompt
export -f tui_read_key_to_continue
export -f tui_read_enter_to_continue
export -f tui_read_confirm
