#!/bin/bash
# TUI Utility Library - Standalone utilities for user interaction
# Can be used independently in scripts without the full TUI menu system

# ============================================================================
# Color Variables - Export for Direct Use in Scripts
# ============================================================================
#
# Usage examples:
#   echo -e "${TUI_RED}Error message${TUI_NORMAL}"
#   printf "${TUI_YELLOW}Warning: %s${TUI_NORMAL}\n" "$message"
#   echo -e "Status: ${TUI_GREEN}OK${TUI_NORMAL}"

# ANSI color codes (matching DTS color scheme)
export TUI_NORMAL='\033[0m'
export TUI_RED='\033[0;31m'
export TUI_GREEN='\033[0;32m'
export TUI_YELLOW='\033[0;33m'
export TUI_BLUE='\033[0;36m' # Cyan, used for borders (matches DTS BLUE)

# Terminal width configuration
export TUI_MAX_WIDTH=60 # Maximum width for borders and footer wrapping

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
# String Formatting Functions
# ============================================================================

# Wrap text to multiple lines with specified width
# Usage: tui_format_wrap "long text" 40
# Outputs multiple lines, each max 40 chars, wrapping at word boundaries
tui_format_wrap() {
    local text="$1"
    local width="$2"
    local line=""
    local word

    for word in $text; do
        if [[ -z "$line" ]]; then
            line="$word"
        elif [[ $((${#line} + 1 + ${#word})) -le $width ]]; then
            line="$line $word"
        else
            echo "$line"
            line="$word"
        fi
    done

    # Print remaining line
    [[ -n "$line" ]] && echo "$line"
}

# ============================================================================
# Colored Output Functions
# ============================================================================

# Print colored line with newline
# Usage: tui_print_line_normal "text"
tui_print_line_normal() {
    echo -e "${TUI_NORMAL}$1${TUI_NORMAL}"
}

# Print red line
# Usage: tui_print_line_red "text"
tui_print_line_red() {
    echo -e "${TUI_RED}$1${TUI_NORMAL}"
}

# Print yellow line
# Usage: tui_print_line_yellow "text"
tui_print_line_yellow() {
    echo -e "${TUI_YELLOW}$1${TUI_NORMAL}"
}

# Print green line
# Usage: tui_print_line_green "text"
tui_print_line_green() {
    echo -e "${TUI_GREEN}$1${TUI_NORMAL}"
}

# Print blue (cyan) line
# Usage: tui_print_line_blue "text"
tui_print_line_blue() {
    echo -e "${TUI_BLUE}$1${TUI_NORMAL}"
}

# Print colored text without newline (use with echo -e or printf)
# Usage: tui_print_text_red "text" && echo ""
tui_print_text_red() {
    echo -n -e "${TUI_RED}$1${TUI_NORMAL}"
}

tui_print_text_yellow() {
    echo -n -e "${TUI_YELLOW}$1${TUI_NORMAL}"
}

tui_print_text_green() {
    echo -n -e "${TUI_GREEN}$1${TUI_NORMAL}"
}

tui_print_text_blue() {
    echo -n -e "${TUI_BLUE}$1${TUI_NORMAL}"
}

tui_print_text_normal() {
    echo -n -e "${TUI_NORMAL}$1${TUI_NORMAL}"
}

# ============================================================================
# Status Message Functions
# ============================================================================

# Print a warning message in yellow
# Usage: tui_print_warning "message"
tui_print_warning() {
    tui_print_line_yellow "Warning: $1"
}

# Print an error message in red
# Usage: tui_print_error "message"
tui_print_error() {
    tui_print_line_red "Error: $1"
}

# Print a success message in green
# Usage: tui_print_success "message"
tui_print_success() {
    tui_print_line_green "$1"
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

    # Calculate padding for centered label with right border
    local label_length=${#label}
    local content_width=$((TUI_MAX_WIDTH - 4))  # ** on left, ** on right
    local total_padding=$((content_width - label_length))
    local left_padding=$((total_padding / 2))
    local right_padding=$((total_padding - left_padding))

    printf "${TUI_BLUE}**${TUI_NORMAL}%${left_padding}s%s%${right_padding}s${TUI_BLUE}**${TUI_NORMAL}\n" "" "$label" ""

    tui_print_border
}

# Print a section entry (label: value) with automatic wrapping
# Usage: tui_print_section_entry "Label" "Value"
# Long values automatically wrap across multiple lines with proper indentation
tui_print_section_entry() {
    local label="$1"
    local value="$2"
    local label_width=15
    local max_value_width=$((TUI_MAX_WIDTH - 2 - label_width - 2 - 2))  # ** (left) + label + ": " + ** (right)
    local first_line=true

    # Wrap the value
    while IFS= read -r line; do
        local line_length=${#line}
        local padding=$((max_value_width - line_length))

        if $first_line; then
            # First line with label
            printf "${TUI_BLUE}**${TUI_YELLOW}%${label_width}s: ${TUI_NORMAL}%s%${padding}s${TUI_BLUE}**${TUI_NORMAL}\n" "$label" "$line" ""
            first_line=false
        else
            # Continuation lines with indentation
            printf "${TUI_BLUE}**${TUI_NORMAL}%$((label_width + 2))s%s%${padding}s${TUI_BLUE}**${TUI_NORMAL}\n" "" "$line" ""
        fi
    done < <(tui_format_wrap "$value" "$max_value_width")
}

# Print a menu option with automatic label wrapping
# Usage: tui_print_menu_option "1" "Menu label"
# Long labels automatically wrap across multiple lines with proper indentation
tui_print_menu_option() {
    local key="$1"
    local label="$2"
    # First line: "**     X) " = 2 + 5 + 1 + 2 = 10 chars, then text, then 2 for "**"
    # Continuation: "**          " = 2 + 10 = 12 chars, then text, then 2 for "**"
    local first_line_prefix=10
    local continuation_prefix=12
    local max_label_width=$((TUI_MAX_WIDTH - first_line_prefix - 2))  # For first line
    local continuation_width=$((TUI_MAX_WIDTH - continuation_prefix - 2))  # For continuation
    local first_line=true

    # Wrap the label
    while IFS= read -r line; do
        if $first_line; then
            # First line with key
            local line_length=${#line}
            local padding=$((max_label_width - line_length))
            printf "${TUI_BLUE}**${TUI_YELLOW}     %s)${TUI_BLUE} %s%${padding}s${TUI_BLUE}**${TUI_NORMAL}\n" "$key" "$line" ""
            first_line=false
        else
            # Continuation lines with indentation and blue color
            local line_length=${#line}
            local padding=$((continuation_width - line_length))
            printf "${TUI_BLUE}**%${first_line_prefix}s%s%${padding}s**${TUI_NORMAL}\n" "" "$line" ""
        fi
    done < <(tui_format_wrap "$label" "$max_label_width")
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

# Read password (silent input with optional masking)
# Usage: password=$(tui_read_password "Enter password")
# Usage: password=$(tui_read_password "Enter password" "*")  # Show asterisks
tui_read_password() {
    local prompt="$1"
    local mask_char="${2:-}"  # Optional mask character (empty = silent)
    local password=""
    local char

    echo -n "${prompt}: " >&2

    if [[ -n "$mask_char" ]]; then
        # Masked input - show character for each keypress
        while IFS= read -r -n 1 -s char; do
            # Handle Enter key
            if [[ -z "$char" ]]; then
                echo "" >&2
                break
            fi

            # Handle backspace
            if [[ "$char" == $'\177' ]] || [[ "$char" == $'\b' ]]; then
                if [[ -n "$password" ]]; then
                    password="${password%?}"
                    echo -n $'\b \b' >&2
                fi
            else
                password+="$char"
                echo -n "$mask_char" >&2
            fi
        done
    else
        # Silent input - no visual feedback
        read -r -s password
        echo "" >&2
    fi

    echo "$password"
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

# Ask user to choose from a list with custom keys
# Usage: choice=$(tui_ask_for_choice "Select option:" "a:Apple" "b:Banana" "c:Cherry")
# Returns the selected key (e.g., "a", "b", "c")
tui_ask_for_choice() {
    local prompt="$1"
    shift
    local choices=("$@")

    echo "$prompt" >&2
    echo "" >&2

    # Display choices
    local key label
    for choice in "${choices[@]}"; do
        IFS=':' read -r key label <<< "$choice"
        echo "  $key) $label" >&2
    done
    echo "" >&2

    # Read user selection
    local selected
    while true; do
        echo -n "Enter choice: " >&2
        read -r selected

        # Validate selection
        for choice in "${choices[@]}"; do
            IFS=':' read -r key label <<< "$choice"
            if [[ "$selected" == "$key" ]]; then
                echo "$selected"
                return 0
            fi
        done

        tui_print_line_red "Invalid choice. Please try again." >&2
    done
}

# Ask user to choose from a list with auto-numbered options
# Usage: choice=$(tui_ask_for_choice_numbered "Select fruit:" "Apple" "Banana" "Cherry")
# Returns the index of selected item (1-based: 1, 2, 3, ...)
tui_ask_for_choice_numbered() {
    local prompt="$1"
    shift
    local options=("$@")
    local count=${#options[@]}

    echo "$prompt" >&2
    echo "" >&2

    # Display numbered options
    local i
    for i in "${!options[@]}"; do
        echo "  $((i + 1))) ${options[$i]}" >&2
    done
    echo "" >&2

    # Read user selection
    local selected
    while true; do
        echo -n "Enter choice (1-$count): " >&2
        read -r selected

        # Validate selection
        if [[ "$selected" =~ ^[0-9]+$ ]] && ((selected >= 1 && selected <= count)); then
            echo "$selected"
            return 0
        fi

        tui_print_line_red "Invalid choice. Please enter a number between 1 and $count." >&2
    done
}

# Ask user for confirmation with customizable yes/no prompts
# Usage: if tui_ask_for_confirmation "Proceed with installation?"; then ... fi
# Usage: if tui_ask_for_confirmation "Continue?" "yes" "no"; then ... fi
tui_ask_for_confirmation() {
    local prompt="$1"
    local yes_text="${2:-y}"
    local no_text="${3:-n}"
    local answer

    while true; do
        echo -n "${prompt} (${yes_text}/${no_text}): " >&2
        read -r answer

        # Convert to lowercase for comparison
        answer=$(echo "$answer" | tr '[:upper:]' '[:lower:]')

        if [[ "$answer" == "${yes_text,,}" ]] || [[ "$answer" == "y" ]]; then
            return 0
        elif [[ "$answer" == "${no_text,,}" ]] || [[ "$answer" == "n" ]]; then
            return 1
        else
            tui_print_line_red "Invalid input. Please enter '${yes_text}' or '${no_text}'." >&2
        fi
    done
}
