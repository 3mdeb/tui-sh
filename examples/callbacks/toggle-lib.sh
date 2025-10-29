#!/bin/bash
# Toggle Library - Shared functions for toggle callbacks

# Update a state variable in the demo-state.sh file
# Usage: update_state_file
# Reads all current exported variables and writes them to state file
update_state_file() {
    local script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    local state_file="${script_dir}/../demo-state.sh"
    local temp_file="${state_file}.tmp"

    # Write updated state back to file
    cat > "$temp_file" <<EOF
# Demo state file - sourced by demo.sh and updated by callbacks
# This file is generated and should not be edited manually

# DPP Credentials display state
export DPP_EMAIL_DISPLAY="$DPP_EMAIL_DISPLAY"
export DPP_PASSWORD_DISPLAY="$DPP_PASSWORD_DISPLAY"
export DISPLAY_CRED_LABEL="$DISPLAY_CRED_LABEL"

# SSH Status state
export SSH_ACTIVE="$SSH_ACTIVE"
export SSH_STATUS="$SSH_STATUS"
export SSH_IP="$SSH_IP"
export SSH_LABEL="$SSH_LABEL"

# Logs sending state
export SEND_LOGS_LABEL="$SEND_LOGS_LABEL"
export SEND_LOGS_STATUS="$SEND_LOGS_STATUS"
EOF

    mv "$temp_file" "$state_file"
}

# Load current state from demo-state.sh
# Usage: load_state_file
load_state_file() {
    local script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    local state_file="${script_dir}/../demo-state.sh"
    source "$state_file"
}
