#!/bin/bash
# Example callback demonstrating tui-util.sh usage
# This script uses only the utility functions without the full TUI menu system

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source only the utility library (lightweight, no menu system)
source "${SCRIPT_DIR}/../../lib/tui-util.sh"

# Clear screen and show header
tui_clear_screen

tui_print_border
tui_print_line_blue "Interactive Utility Demo"
tui_print_border
echo ""

# Example 1: Status messages
tui_print_section_header "STATUS MESSAGES"
tui_print_success "Operation completed successfully!"
tui_print_warning "This is a warning message"
tui_print_error "This is an error message"
echo ""

# Example 2: Colored output
tui_print_section_header "COLORED OUTPUT"
tui_print_line_red "Red text"
tui_print_line_yellow "Yellow text"
tui_print_line_green "Green text"
tui_print_line_blue "Blue (cyan) text"
echo ""

# Example 3: Section entries
tui_print_section_header "SYSTEM INFORMATION"
tui_print_section_entry "Hostname" "$(hostname)"
tui_print_section_entry "User" "$USER"
tui_print_section_entry "Shell" "$SHELL"
tui_print_section_entry "Home" "$HOME"
echo ""

# Example 4: User input
tui_print_section_header "USER INPUT"

# Read a name
name=$(tui_read_prompt "Enter your name")
tui_print_line_green "Hello, $name!"
echo ""

# Confirm an action
if tui_read_confirm "Do you want to continue?"; then
    tui_print_success "User confirmed!"
else
    tui_print_warning "User declined"
fi
echo ""

# Example 5: Border generation
tui_print_section_header "CUSTOM BORDERS"
echo "Default border:"
tui_print_border
echo ""
echo "Custom border with = character:"
border=$(tui_generate_border 40 "=")
echo "$border"
echo ""

# Example 6: Condition checking
tui_print_section_header "CONDITION CHECKING"

# Check environment variable
export TEST_VAR="enabled"
if tui_check_condition "\$TEST_VAR"; then
    tui_print_line_green "✓ TEST_VAR is set and enabled"
else
    tui_print_line_red "✗ TEST_VAR is not set or disabled"
fi

# Check command
if tui_check_condition "test -d /tmp"; then
    tui_print_line_green "✓ /tmp directory exists"
else
    tui_print_line_red "✗ /tmp directory does not exist"
fi

# Check if running as root
if tui_check_condition "test \${UID} -eq 0"; then
    tui_print_line_yellow "Running as root"
else
    tui_print_line_green "Running as regular user"
fi
echo ""

tui_print_border
tui_print_line_blue "Demo completed!"
tui_print_border
echo ""

exit 0
