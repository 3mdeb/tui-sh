#!/bin/bash
# Toggle SSH server status

# Get script directory and source toggle library
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/toggle-lib.sh"

# Load current state
load_state_file

# Toggle SSH state
if [[ "$SSH_ACTIVE" == "true" ]]; then
    # Currently enabled, disable it
    SSH_ACTIVE=""
    SSH_STATUS="disabled"
    SSH_LABEL="launch SSH server"
    echo "SSH server disabled"
else
    # Currently disabled, enable it
    SSH_ACTIVE="true"
    SSH_STATUS="enabled"
    SSH_LABEL="stop SSH server"
    SSH_IP="192.168.1.100"
    echo "SSH server enabled on 192.168.1.100"
fi

# Save updated state
update_state_file

sleep 1
exit 0
