#!/usr/bin/env bash

##############################################################################
# AWS MFA Auto-fill Script
#
# Description:
#   Automatically retrieves MFA codes from Bitwarden/Vaultwarden using rbw
#   and provides them to the aws-mfa command for seamless AWS authentication.
#
# Usage:
#   ./aws-mfa-auto.sh
#
# Requirements:
#   - rbw (Unofficial Bitwarden CLI) must be installed and configured
#   - aws-mfa command must be available in PATH
#   - Bitwarden item named "AWS Console login TechNative" must exist with TOTP
#
# Author: OpenCode
# Created: 2026-01-29
##############################################################################

set -euo pipefail

export AWS_PROFILE=technative

# Configuration
BITWARDEN_ITEM="AWS Console login TechNative"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Helper functions
error() {
    echo -e "${RED}Error: $1${NC}" >&2
    exit 1
}

info() {
    echo -e "${GREEN}$1${NC}"
}

warn() {
    echo -e "${YELLOW}$1${NC}"
}

# Check if rbw is available
if ! command -v rbw &> /dev/null; then
    error "rbw command not found. Please ensure rbw (Bitwarden CLI) is installed."
fi

# Check if aws-mfa is available
if ! command -v aws-mfa &> /dev/null; then
    error "aws-mfa command not found. Please ensure aws-mfa is installed."
fi

# Check if vault is unlocked, if not, unlock it
info "Checking Bitwarden vault status..."
if ! rbw unlocked &> /dev/null; then
    info "Vault is locked. Unlocking..."
    if ! rbw unlock; then
        error "Failed to unlock Bitwarden vault. Please check your password."
    fi
    info "Vault unlocked successfully."
else
    info "Vault is already unlocked."
fi

# Retrieve TOTP code from Bitwarden
info "Retrieving MFA code from Bitwarden..."
MFA_CODE=$(rbw code "$BITWARDEN_ITEM" 2>&1)

# Check if code retrieval was successful
if [ $? -ne 0 ]; then
    if echo "$MFA_CODE" | grep -q "entry not found"; then
        error "Bitwarden item '$BITWARDEN_ITEM' not found. Please ensure the item exists with TOTP enabled."
    else
        error "Failed to retrieve MFA code: $MFA_CODE"
    fi
fi

# Validate MFA code format (should be 6 digits)
if ! [[ "$MFA_CODE" =~ ^[0-9]{6}$ ]]; then
    error "Invalid MFA code format received: '$MFA_CODE'. Expected 6 digits."
fi

info "MFA code retrieved: $MFA_CODE"

# Execute aws-mfa with the retrieved code
info "Running aws-mfa with retrieved code..."
echo "$MFA_CODE" | aws-mfa

# Check if aws-mfa succeeded
if [ $? -eq 0 ]; then
    info "AWS MFA authentication completed successfully!"
else
    error "aws-mfa command failed. Please check your AWS configuration."
fi
