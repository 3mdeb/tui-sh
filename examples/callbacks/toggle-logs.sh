#!/bin/bash
# Toggle log sending status

# Get script directory and source toggle library
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/toggle-lib.sh"

# Load current state
load_state_file

# Toggle logs state
if [[ "$SEND_LOGS_STATUS" == "enabled" ]]; then
    # Currently enabled, disable it
    SEND_LOGS_LABEL="enable sending DTS logs"
    SEND_LOGS_STATUS="disabled"
    echo "Log sending disabled"
else
    # Currently disabled, enable it
    SEND_LOGS_LABEL="disable sending DTS logs"
    SEND_LOGS_STATUS="enabled"
    echo "Log sending enabled"
fi

# Save updated state
update_state_file

sleep 1
exit 0
