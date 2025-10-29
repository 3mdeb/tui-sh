# TUI-SH - Text User Interface Library for Bash

A lightweight bash library for creating text-based user interfaces with YAML
configuration, ANSI colors, and immediate keypress handling.

## Features

- **YAML-based configuration** - Define menus in YAML
- **Two-library architecture** - Use utilities standalone or full menu system
- **Immediate keypress response** - No Enter key needed
- **Dynamic content** - Environment variables and command substitution
- **Conditional display** - Show/hide elements based on conditions
- **Auto-wrapping text** - Handles long labels and values gracefully
- **Serial port compatible** - Works over SSH and serial consoles

## Requirements

- Bash 4.0+
- `yq` for YAML parsing (menu system only)

## Quick Start

### 1. Create YAML Configuration

`my-app.yaml`:
```yaml
header:
  title: " My Application "

sections:
  - label: "SYSTEM INFO"
    entries:
      - label: "User"
        value: "${USER}"

menu:
  - key: "1"
    label: "Run backup"
    callback: "echo 'Running backup...' && sleep 1"

footer:
  - key: "Q"
    label: "quit"
    callback: "exit 0"
```

### 2. Create Application Script

`my-app.sh`:
```bash
#!/bin/bash
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/lib/tui-core.sh"
tui_run "${SCRIPT_DIR}/my-app.yaml"
```

### 3. Run

```bash
chmod +x my-app.sh
./my-app.sh
```

## Library Architecture

### `lib/tui-util.sh` - Standalone Utilities

Lightweight functions for scripts and callbacks. **No dependencies.**

```bash
#!/bin/bash
source "lib/tui-util.sh"

tui_print_success "Operation completed!"
name=$(tui_read_prompt "Enter your name")
if tui_read_confirm "Continue?"; then
    tui_print_section_entry "Name" "$name"
fi
```

**Use for:**
- Callback scripts with user interaction
- Colored output and formatted display
- Input prompts and confirmations

### `lib/tui-core.sh` - Full Menu System

Complete YAML-driven menu system. **Requires yq.**

```bash
#!/bin/bash
source "lib/tui-core.sh"
tui_run "config.yaml"
```

**Use for:**
- Full TUI applications
- Multi-section information displays
- Dynamic menu navigation

## YAML Configuration

### Header
```yaml
header:
  title: "App Title ${VERSION}"
  subtitle: "Optional subtitle"
  link: "https://github.com/user/repo"
```

### Sections
```yaml
sections:
  - label: "SECTION NAME"
    condition: "${SHOW_SECTION}"     # Optional
    entries:
      - label: "Field"
        value: "${VALUE}"
        condition: "${SHOW_FIELD}"   # Optional
```

### Menu
```yaml
menu:
  - key: "1"
    label: "Menu option"
    callback: "path/to/script.sh"
    condition: "${SHOW_OPTION}"      # Optional
```

### Footer
```yaml
footer:
  - key: "Q"
    label: "quit"
    callback: "exit 0"
```

## Dynamic Content

Use bash variable syntax in YAML:

```yaml
# Environment variables
value: "${MY_VAR}"
value: "${MY_VAR:-default}"

# Command substitution
value: "$(hostname)"
```

## Conditional Display

**Environment variables:**
```yaml
condition: "${IS_ADMIN}"  # Shows if non-empty and not "false" or "0"
```

```bash
export IS_ADMIN="true"    # Show
export IS_ADMIN=""        # Hide
export IS_ADMIN="false"   # Hide
```

**Shell commands:**
```yaml
condition: "systemctl is-active sshd"     # Show if SSH running
condition: "test ${UID} -eq 0"            # Show if root
condition: "! test -f /tmp/lock"          # Show if file doesn't exist
condition: "command -v docker"            # Show if docker installed
```

Commands are executed and exit code determines visibility (0 = show, non-zero =
hide).

## Callbacks

**Inline commands:**
```yaml
callback: "echo 'Hello!' && sleep 1"
callback: "systemctl restart nginx"
callback: "bash"  # Launch shell
```

**Script paths:**
```yaml
callback: "callbacks/backup.sh"
callback: "${SCRIPT_DIR}/update.sh"
```

Scripts are executed with `eval`, so use `bash script.sh` for non-executable
files.

## Utility Functions

### Colored Output
```bash
tui_print_success "Done!"
tui_print_warning "Be careful"
tui_print_error "Failed!"

tui_print_line_red "Error text"
tui_print_line_green "Success text"
tui_print_line_yellow "Warning text"
```

### User Input
```bash
# Text input
name=$(tui_read_prompt "Enter name")

# Password (silent or masked)
pwd=$(tui_read_password "Password")
pwd=$(tui_read_password "Password" "*")

# Confirmation
if tui_read_confirm "Continue?"; then
    echo "Yes"
fi

# Choice menu
choice=$(tui_ask_for_choice "Select:" "a:Apple" "b:Banana")
choice=$(tui_ask_for_choice_numbered "Select:" "Apple" "Banana")
```

### Layout & Formatting
```bash
tui_print_border
tui_print_section_header "SECTION TITLE"
tui_print_section_entry "Label" "Value"  # Auto-wraps long values
tui_print_menu_option "1" "Menu item"    # Auto-wraps long labels
```

### Terminal Control
```bash
tui_clear_screen
tui_hide_cursor
tui_show_cursor
```

## Utility Example

```bash
#!/bin/bash
source "lib/tui-util.sh"

tui_clear_screen
tui_print_section_header "CONFIGURATION"

hostname=$(tui_read_prompt "Hostname")
env=$(tui_ask_for_choice "Environment:" "d:Dev" "p:Prod")

if tui_ask_for_confirmation "Apply changes?"; then
    tui_print_success "Applied!"
    tui_print_section_entry "Hostname" "$hostname"
    tui_print_section_entry "Environment" "$env"
else
    tui_print_warning "Cancelled"
fi
```

## Pre-render Callbacks

Update state before each menu render:

```bash
#!/bin/bash
source "lib/tui-core.sh"

# Reload state before each render
reload_state() {
    source "state.sh"
}

tui_register_pre_render_callback reload_state
tui_run "config.yaml"
```

Useful for toggle scripts that update state files.

## Example

See `examples/demo.sh` for a complete working example:

```bash
cd examples
./demo.sh
```

Features demonstrated:
- Multiple sections with dynamic content
- Conditional display
- Toggle callbacks (SSH, credentials)
- Text wrapping for long entries
- Interactive input in callbacks

## Testing

```bash
# Install bats
sudo apt-get install bats  # Ubuntu/Debian
brew install bats-core     # macOS

# Run tests
bats tests/
```
