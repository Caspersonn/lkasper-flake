# Change: Add AWS MFA Bitwarden/Vaultwarden Auto-fill

## Why

Currently, the `aws-mfa` command requires manual entry of MFA codes, which is repetitive and interrupts workflow. Since MFA codes are already stored in Bitwarden/Vaultwarden (accessible via `rbw`), automating this process will streamline AWS authentication and reduce context switching.

## What Changes

- Create a new script `aws-mfa-auto.sh` in `home/desktop-environments/hyprland/scripts/` that:
  - Unlocks the Bitwarden vault using `rbw unlock` (prompts for password)
  - Retrieves the current TOTP code from the "AWS Console login TechNative" item using `rbw code`
  - Automatically provides the code to the `aws-mfa` command
- The script will be integrated into the Hyprland desktop environment configuration
- The script will handle error cases (vault unlock failure, item not found, rbw not available)

## Impact

- **Affected specs**: New capability `aws-automation`
- **Affected code**: 
  - New file: `home/desktop-environments/hyprland/scripts/aws-mfa-auto.sh`
  - Potentially: `home/desktop-environments/hyprland/default.nix` (to make script available)
- **Dependencies**: Requires `rbw` package (already installed via `modules/packages/pkgs-technative.nix:34`)
- **User impact**: Users can run the automated script instead of manually entering MFA codes
