#!/bin/bash

# Demo: Modular library structure
# Shows how tui-util.sh can be used independently in callbacks

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export SCRIPT_DIR

# Source the TUI library (uses tui-core.sh internally)
source "${SCRIPT_DIR}/../lib/tui-core.sh"

# Run the TUI
tui_run "${SCRIPT_DIR}/util-demo.yaml"
