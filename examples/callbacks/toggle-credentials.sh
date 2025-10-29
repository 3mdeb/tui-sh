#!/bin/bash
# Toggle credentials display

# Get script directory and source toggle library
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/toggle-lib.sh"

# Load current state
load_state_file

# Toggle credentials state
if [[ "$DPP_EMAIL_DISPLAY" == "***hidden***" ]]; then
    # Currently hidden, show them
    DPP_EMAIL_DISPLAY="user@dasharo.com"
    DPP_PASSWORD_DISPLAY="MySecretPassword123"
    DISPLAY_CRED_LABEL="hide DPP credentials"
    echo "DPP credentials visible"
else
    # Currently visible, hide them
    DPP_EMAIL_DISPLAY="***hidden***"
    DPP_PASSWORD_DISPLAY="***hidden***"
    DISPLAY_CRED_LABEL="display DPP credentials"
    echo "DPP credentials hidden"
fi

# Save updated state
update_state_file

sleep 1
exit 0
