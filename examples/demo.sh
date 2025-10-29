#!/bin/bash
# Demo script for TUI library - Dasharo Tools Suite example

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
export SCRIPT_DIR  # Export for use in YAML callbacks

# Source the TUI core library
source "$PROJECT_ROOT/lib/tui-core.sh"

# ============================================================================
# Hardware Information
# ============================================================================
export DTS_VERSION="2.7.1"
export SYSTEM_VENDOR="Emulation"
export SYSTEM_MODEL="QEMU x86 q35/ich9"
export BOARD_MODEL="QEMU x86 q35/ich9"
export CPU_VERSION="Intel Core Processor (Skylake)"
export RAM_INFO="Not Specified"

# ============================================================================
# Firmware Information
# ============================================================================
export BIOS_VENDOR="3mdeb Dasharo (coreboot+UEFI)"
export BIOS_VERSION="v0.2.1-rc1"

# ============================================================================
# DPP Credentials (conditional display)
# ============================================================================
export DPP_IS_LOGGED="true"

# ============================================================================
# Menu Options Labels and Conditions
# ============================================================================
export DASHARO_FIRMWARE_LABEL="Update Dasharo Firmware"
export SHOW_DASHARO_FIRMWARE="true"

export SHOW_RESTORE_FIRMWARE=""  # Hidden by default

export DPP_KEYS_LABEL="Edit your DPP keys"

export SHOW_DTS_EXTENSIONS=""  # Hidden by default

export SHOW_TRANSITION="true"

export SHOW_FUSE="true"

# ============================================================================
# Load Dynamic State (updated by toggle callbacks)
# ============================================================================
source "$SCRIPT_DIR/demo-state.sh"

# ============================================================================
# Register Pre-Render Callback to Reload State
# ============================================================================
# This function is called before each render to pick up state changes
reload_demo_state() {
    source "$SCRIPT_DIR/demo-state.sh"
}

# Register callback to reload state before each render
tui_register_pre_render_callback reload_demo_state

# Run the TUI
tui_run "$SCRIPT_DIR/demo.yaml"
