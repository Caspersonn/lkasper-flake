# AWS Automation Specification

## ADDED Requirements

### Requirement: AWS MFA Auto-fill from Bitwarden

The system SHALL provide automated MFA code retrieval from Bitwarden/Vaultwarden for AWS authentication.

#### Scenario: Successful MFA auto-fill

- **WHEN** the user runs the AWS MFA auto-fill script
- **THEN** the script unlocks the Bitwarden vault via `rbw unlock`
- **AND** retrieves the TOTP code from the "AWS Console login TechNative" item
- **AND** automatically provides the code to `aws-mfa`

#### Scenario: Vault unlock required

- **WHEN** the Bitwarden vault is locked
- **THEN** the script prompts for the vault password via `rbw unlock`
- **AND** proceeds with MFA code retrieval after successful unlock

#### Scenario: Already unlocked vault

- **WHEN** the Bitwarden vault is already unlocked
- **THEN** the script skips the unlock prompt
- **AND** directly retrieves the TOTP code

### Requirement: Error Handling

The system SHALL handle error conditions gracefully when automating AWS MFA.

#### Scenario: Vault unlock failure

- **WHEN** `rbw unlock` fails (wrong password or other error)
- **THEN** the script displays an error message
- **AND** exits with a non-zero status code
- **AND** does not attempt to retrieve the MFA code

#### Scenario: Item not found

- **WHEN** the "AWS Console login TechNative" item does not exist in Bitwarden
- **THEN** the script displays an error message indicating the item is missing
- **AND** exits with a non-zero status code

#### Scenario: rbw not available

- **WHEN** the `rbw` command is not found in PATH
- **THEN** the script displays an error message
- **AND** exits with a non-zero status code

### Requirement: Script Integration

The system SHALL integrate the AWS MFA auto-fill script into the Hyprland desktop environment.

#### Scenario: Script available in Hyprland

- **WHEN** the Hyprland desktop environment is active
- **THEN** the `aws-mfa-auto.sh` script is available in the user's PATH or in the scripts directory
- **AND** has executable permissions

#### Scenario: Script location

- **WHEN** the system is built
- **THEN** the script is located at `home/desktop-environments/hyprland/scripts/aws-mfa-auto.sh`
