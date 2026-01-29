# Implementation Tasks

## 1. Script Development

- [x] 1.1 Create `home/desktop-environments/hyprland/scripts/aws-mfa-auto.sh`
- [x] 1.2 Implement vault unlock logic with `rbw unlock`
- [x] 1.3 Implement TOTP code retrieval using `rbw code "AWS Console login TechNative"`
- [x] 1.4 Implement automatic code passing to `aws-mfa`
- [x] 1.5 Add error handling for vault unlock failure
- [x] 1.6 Add error handling for missing Bitwarden item
- [x] 1.7 Add error handling for missing `rbw` command
- [x] 1.8 Set executable permissions on the script

## 2. Integration

- [x] 2.1 Verify script is accessible from Hyprland environment
- [x] 2.2 Test script execution with locked vault
- [x] 2.3 Test script execution with unlocked vault
- [x] 2.4 Test error scenarios (wrong password, missing item, missing rbw)

## 3. Documentation

- [x] 3.1 Add usage instructions in script comments
- [x] 3.2 Document the Bitwarden item name requirement ("AWS Console login TechNative")

## 4. Validation

- [x] 4.1 Run `openspec validate add-aws-mfa-bitwarden-autofill --strict`
- [x] 4.2 Test end-to-end AWS MFA authentication flow
