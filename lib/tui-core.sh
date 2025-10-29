#!/bin/bash
# TUI Core Library - Main menu system and rendering engine
# Requires: tui-util.sh, yq (YAML processor), jq (JSON processor)

# Get the directory where this script is located
TUI_CORE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source utility library
if [[ -f "${TUI_CORE_DIR}/tui-util.sh" ]]; then
    source "${TUI_CORE_DIR}/tui-util.sh"
else
    echo "Error: tui-util.sh not found in ${TUI_CORE_DIR}" >&2
    return 1 2>/dev/null || exit 1
fi

# ============================================================================
# Core State Variables
# ============================================================================

# Global variables
TUI_RUNNING=true

# Header variables
TUI_HEADER_TITLE=""
TUI_HEADER_SUBTITLE=""
TUI_HEADER_LINK=""

# Section arrays (using | as delimiter)
declare -a TUI_SECTIONS_DATA=() # condition|label
declare -a TUI_ENTRIES_DATA=()  # section_idx|condition|label|value

# Menu and footer arrays
declare -a TUI_MENU_DATA=()   # key|condition|label|callback
declare -a TUI_FOOTER_DATA=() # key|condition|label|callback

# Callback arrays for pre/post render hooks
declare -A TUI_PRE_RENDER_CALLBACKS=()
declare -A TUI_POST_RENDER_CALLBACKS=()
TUI_PRE_RENDER_CALLBACKS_ORDER=()
TUI_POST_RENDER_CALLBACKS_ORDER=()

# ============================================================================
# Configuration Loading
# ============================================================================

# Load YAML configuration and parse into bash variables
# Usage: tui_load_config "config.yaml"
tui_load_config() {
    local config_file="$1"

    if [[ ! -f "$config_file" ]]; then
        echo "Error: Config file not found: $config_file" >&2
        return 1
    fi

    if ! command -v yq &>/dev/null; then
        echo "Error: yq is required but not installed" >&2
        echo "Install with: pip install yq  or  brew install yq" >&2
        return 1
    fi

    if ! command -v jq &>/dev/null; then
        echo "Error: jq is required but not installed" >&2
        return 1
    fi

    # Convert YAML to JSON once
    local json_config
    json_config=$(yq eval -o=json "$config_file")

    # Parse header
    TUI_HEADER_TITLE=$(echo "$json_config" | jq -r '.header.title // ""')
    TUI_HEADER_SUBTITLE=$(echo "$json_config" | jq -r '.header.subtitle // ""')
    TUI_HEADER_LINK=$(echo "$json_config" | jq -r '.header.link // ""')

    # Clear arrays
    TUI_SECTIONS_DATA=()
    TUI_ENTRIES_DATA=()
    TUI_MENU_DATA=()
    TUI_FOOTER_DATA=()

    # Parse sections
    local section_idx=0
    while IFS='|' read -r condition label; do
        if [[ -z "$label" && -z "$condition" ]]; then
            continue
        fi
        TUI_SECTIONS_DATA+=("$condition|$label")

        # Parse entries for this section
        while IFS='|' read -r entry_cond entry_label entry_value; do
            if [[ -z "$entry_label" && -z "$entry_value" ]]; then
                continue
            fi
            TUI_ENTRIES_DATA+=("$section_idx|$entry_cond|$entry_label|$entry_value")
        done < <(echo "$json_config" | jq -r ".sections[$section_idx].entries[]? | \"\(.condition // \"\")|\" + (.label | gsub(\"\\\\|\"; \"\\\\|\" )) + \"|\" + (.value | gsub(\"\\\\|\"; \"\\\\|\"))")

        ((section_idx++))
    done < <(echo "$json_config" | jq -r '.sections[]? | "\(.condition // "")|" + (.label | gsub("\\|"; "\\|"))')

    # Parse menu items
    while IFS='|' read -r key condition label callback; do
        if [[ -z "$key" ]]; then
            continue
        fi
        TUI_MENU_DATA+=("$key|$condition|$label|$callback")
    done < <(echo "$json_config" | jq -r '.menu[]? | .key + "|" + (.condition // "") + "|" + (.label | gsub("\\|"; "\\|")) + "|" + .callback')

    # Parse footer items
    while IFS='|' read -r key condition label callback; do
        if [[ -z "$key" ]]; then
            continue
        fi
        TUI_FOOTER_DATA+=("$key|$condition|$label|$callback")
    done < <(echo "$json_config" | jq -r '.footer[]? | .key + "|" + (.condition // "") + "|" + (.label | gsub("\\|"; "\\|")) + "|" + .callback')
}

# ============================================================================
# Rendering Functions
# ============================================================================

# Render header section
# Usage: tui_render_header
tui_render_header() {
    if [[ -n "$TUI_HEADER_TITLE" ]]; then
        local title
        title=$(tui_expand_vars "$TUI_HEADER_TITLE")
        echo -e "${TUI_NORMAL}$title${TUI_NORMAL}"
    fi

    if [[ -n "$TUI_HEADER_SUBTITLE" ]]; then
        local subtitle
        subtitle=$(tui_expand_vars "$TUI_HEADER_SUBTITLE")
        echo -e "${TUI_NORMAL}$subtitle${TUI_NORMAL}"
    fi

    if [[ -n "$TUI_HEADER_LINK" ]]; then
        local link
        link=$(tui_expand_vars "$TUI_HEADER_LINK")
        echo -e "${TUI_NORMAL}Report issues at: $link${TUI_NORMAL}"
    fi
}

# Render all information sections
# Usage: tui_render_info_sections
tui_render_info_sections() {
    local section_idx=0
    local section_data
    for section_data in "${TUI_SECTIONS_DATA[@]}"; do
        local condition label
        IFS='|' read -r condition label <<<"$section_data"

        # Check if section should be displayed
        if ! tui_check_condition "$condition"; then
            ((section_idx++))
            continue
        fi

        label=$(tui_expand_vars "$label")
        tui_print_section_header "$label"

        # Render entries for this section
        local entry_data
        for entry_data in "${TUI_ENTRIES_DATA[@]}"; do
            local entry_section_idx entry_condition entry_label entry_value
            IFS='|' read -r entry_section_idx entry_condition entry_label entry_value <<<"$entry_data"

            # Only render entries for this section
            if [[ "$entry_section_idx" != "$section_idx" ]]; then
                continue
            fi

            if ! tui_check_condition "$entry_condition"; then
                continue
            fi

            entry_label=$(tui_expand_vars "$entry_label")
            entry_value=$(tui_expand_vars "$entry_value")
            tui_print_section_entry "$entry_label" "$entry_value"
        done

        ((section_idx++))
    done
}

# Render main menu options
# Usage: tui_render_menu
tui_render_menu() {
    if [[ ${#TUI_MENU_DATA[@]} -eq 0 ]]; then
        return 0
    fi

    tui_print_border
    local menu_item
    for menu_item in "${TUI_MENU_DATA[@]}"; do
        local key condition label callback
        IFS='|' read -r key condition label callback <<<"$menu_item"

        if ! tui_check_condition "$condition"; then
            continue
        fi

        label=$(tui_expand_vars "$label")
        tui_print_menu_option "$key" "$label"
    done
    tui_print_border
}

# Render footer actions with auto-wrap
# Usage: tui_render_footer
tui_render_footer() {
    if [[ ${#TUI_FOOTER_DATA[@]} -eq 0 ]]; then
        return 0
    fi

    local footer_parts=()
    local footer_item

    # Build footer parts
    for footer_item in "${TUI_FOOTER_DATA[@]}"; do
        local key condition label callback
        IFS='|' read -r key condition label callback <<<"$footer_item"

        if ! tui_check_condition "$condition"; then
            continue
        fi

        label=$(tui_expand_vars "$label")
        footer_parts+=("${TUI_RED}$key${TUI_NORMAL} to $label")
    done

    if [[ ${#footer_parts[@]} -gt 0 ]]; then
        # Auto-wrap footer to multiple lines if needed
        local current_line=""
        local current_length=0
        local max_width=$((TUI_MAX_WIDTH - 2)) # Leave 2 chars margin

        for part in "${footer_parts[@]}"; do
            # Calculate visible length (strip ANSI codes)
            local visible_part
            visible_part=$(echo -e "$part" | sed 's/\x1b\[[0-9;]*m//g')
            local part_length=${#visible_part}

            # Add separator length if not first item on line
            local separator_length=0
            if [[ -n "$current_line" ]]; then
                separator_length=2 # "  " = 2 spaces
            fi

            # Check if adding this part would exceed max width
            if [[ -n "$current_line" ]] && ((current_length + separator_length + part_length > max_width)); then
                # Print current line and start new line
                echo -e "$current_line"
                current_line="$part"
                current_length=$part_length
            else
                # Add to current line
                if [[ -n "$current_line" ]]; then
                    current_line+="  $part"
                    current_length=$((current_length + separator_length + part_length))
                else
                    current_line="$part"
                    current_length=$part_length
                fi
            fi
        done

        # Print remaining line
        if [[ -n "$current_line" ]]; then
            echo -e "$current_line"
        fi
    fi
}

# Render complete menu
# Usage: tui_render
tui_render() {
    tui_clear_screen
    tui_render_header
    tui_render_info_sections
    tui_render_menu
    tui_render_footer
    echo ""
    echo -n -e "${TUI_YELLOW}Enter an option:${TUI_NORMAL}"
}

# ============================================================================
# Callback Execution
# ============================================================================

# Execute a callback (script or shell command) without waiting
# Usage: tui_execute_callback_without_waiting "command"
tui_execute_callback_without_waiting() {
    local callback="$1"

    # Clear screen before executing callback
    tui_clear_screen

    # Check if callback looks like a file path (contains /)
    if [[ "$callback" == *"/"* ]]; then
        # Looks like a file path - check if it exists
        if [[ ! -f "$callback" ]]; then
            echo "Error: Callback script not found: $callback" >&2
            return 1
        fi
        # It's a file - check if executable
        if [[ ! -x "$callback" ]]; then
            echo "Error: Callback script is not executable: $callback" >&2
            return 1
        fi
        # Execute the script
        "$callback"
    else
        # Not a file path - treat as shell command
        eval "$callback"
    fi
}

# Execute a callback (script or command) and wait for user input
# Usage: tui_execute_callback "script_path" or tui_execute_callback "command"
tui_execute_callback() {
    tui_execute_callback_without_waiting "$@"
    local exit_code=$?

    tui_read_enter_to_continue
    return $exit_code
}

# ============================================================================
# Menu Navigation
# ============================================================================

# Find menu item by key and return its callback
# Usage: callback=$(tui_find_menu_callback "1")
tui_find_menu_callback() {
    local key="$1"

    for menu_item in "${TUI_MENU_DATA[@]}"; do
        IFS='|' read -r menu_key condition label callback <<<"$menu_item"

        if [[ "$menu_key" == "$key" ]]; then
            if tui_check_condition "$condition"; then
                # Expand environment variables in callback path
                callback=$(tui_expand_vars "$callback")
                echo "$callback"
                return 0
            fi
        fi
    done

    return 1
}

# Find footer item by key and return its callback
# Usage: callback=$(tui_find_footer_callback "Q")
tui_find_footer_callback() {
    local key="$1"

    for footer_item in "${TUI_FOOTER_DATA[@]}"; do
        IFS='|' read -r footer_key condition label callback <<<"$footer_item"

        if [[ "$footer_key" == "$key" ]]; then
            if tui_check_condition "$condition"; then
                # Expand environment variables in callback path
                callback=$(tui_expand_vars "$callback")
                echo "$callback"
                return 0
            fi
        fi
    done

    return 1
}

# Handle user input
# Usage: tui_handle_input
tui_handle_input() {
    local key
    key=$(tui_read_key)

    # Convert to uppercase for case-insensitive matching
    key=$(echo "$key" | tr '[:lower:]' '[:upper:]')

    # Hidden option: Q to quit (useful for testing)
    if [[ "$key" == "Q" ]]; then
        tui_stop
        return 0
    fi

    # Try to find callback in menu items
    local callback
    if callback=$(tui_find_menu_callback "$key"); then
        tui_execute_callback "$callback"
        return 0
    fi

    # Try to find callback in footer items
    if callback=$(tui_find_footer_callback "$key"); then
        tui_execute_callback_without_waiting "$callback"
        return 0
    fi

    # No matching option found
    return 0
}

# ============================================================================
# Main Loop and Control
# ============================================================================

# Stop the TUI loop
# Usage: tui_stop
tui_stop() {
    TUI_RUNNING=false
}

# Register callbacks called before each render
# Usage: tui_register_pre_render_callback callback_func arg1 arg2
tui_register_pre_render_callback() {
    local callback="$1"
    shift
    TUI_PRE_RENDER_CALLBACKS["${callback}"]="$*"
    TUI_PRE_RENDER_CALLBACKS_ORDER+=("${callback}")
}

# Register callbacks called after each render
# Usage: tui_register_post_render_callback callback_func arg1 arg2
tui_register_post_render_callback() {
    local callback="$1"
    shift
    TUI_POST_RENDER_CALLBACKS["${callback}"]="$*"
    TUI_POST_RENDER_CALLBACKS_ORDER+=("${callback}")
}

# Main TUI loop
# Usage: tui_run "config.yaml"
tui_run() {
    local config_file="$1"

    if ! tui_load_config "$config_file"; then
        return 1
    fi

    tui_hide_cursor
    TUI_RUNNING=true

    while $TUI_RUNNING; do
        # Call pre-render callbacks
        for callback in "${TUI_PRE_RENDER_CALLBACKS_ORDER[@]}"; do
            eval "${callback}" "${TUI_PRE_RENDER_CALLBACKS["${callback}"]}"
        done

        # Render the menu
        tui_render

        # Call post-render callbacks
        for callback in "${TUI_POST_RENDER_CALLBACKS_ORDER[@]}"; do
            eval "${callback}" "${TUI_POST_RENDER_CALLBACKS["${callback}"]}"
        done

        # Handle user input
        tui_handle_input
    done

    tui_show_cursor
    tui_clear_screen
}
