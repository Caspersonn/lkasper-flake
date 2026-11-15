# Shared Atuin Threads Specification

## Purpose

Provide private, declaratively configured synchronization of each user's Claude Code and OpenCode conversations across their devices through Atuin on kaito.

## Requirements

### Requirement: Shared client configuration
The Home Manager feature in `modules/users/shared/atuin.nix` SHALL enable Threads capture and background synchronization for every configured user importing `shared-atuin`, on supported x86_64-linux and aarch64-linux hosts. It MUST preserve the user's existing shell-history settings and keep the Atuin AI assistant disabled.

#### Scenario: Shared module activation
- **WHEN** a configured user's Home Manager profile is activated and the user session starts
- **THEN** Threads capture and its background daemon are enabled without running an interactive Atuin configuration command
- **AND** the existing shell-history preferences remain effective and the Atuin AI assistant remains disabled

### Requirement: Declarative authentication and user isolation
The system MUST provision a distinct Atuin account's session token and encryption key for each configured user through encrypted secrets. A user's credentials SHALL be reused across that user's devices without device-by-device interactive login. Credential contents MUST NOT enter source-controlled plaintext, Nix store outputs, command arguments, or logs, and decrypted files MUST be accessible only to the intended user and privileged administrators.

#### Scenario: Fresh device
- **WHEN** an existing user's profile is deployed on another device with an authorized decryption identity
- **THEN** Atuin authenticates and decrypts that user's synced records without manual login or copying credentials

#### Scenario: Separate users
- **WHEN** Casper and Antonia use their configured profiles
- **THEN** each synchronizes only their own account's conversations using separate encryption keys

#### Scenario: Unavailable credentials
- **WHEN** required credentials are absent or cannot be decrypted
- **THEN** the configuration or service reports an actionable error without exposing secrets or falling back to another user's account
- **AND** existing conversations and history are retained

### Requirement: Kaito-hosted encrypted synchronization
Clients SHALL synchronize encrypted thread records through `https://atuin.inspiravita.com`, served by the NixOS Atuin service on kaito in `modules/services/tools/atuin.nix`. The server MUST support the deployed clients' record synchronization protocol and MUST NOT require plaintext conversation content or client encryption keys.

#### Scenario: Conversation transfer
- **WHEN** a user continues a Claude Code or OpenCode conversation on device A and both devices complete background synchronization
- **THEN** the conversation is discoverable through Atuin Threads on device B under the same user's account
- **AND** `atuin resume` can restore or resume it using the supported installed agent and a suitable local checkout

#### Scenario: Temporary server outage
- **WHEN** kaito is unavailable while a conversation is captured
- **THEN** the local conversation remains available and synchronization recovers after connectivity returns without another interactive login

### Requirement: Existing conversation import
The shared feature SHALL automatically import existing supported Claude Code and OpenCode conversations into Threads. Import MUST be repeatable without duplicate threads and MUST NOT delete or overwrite the source conversations or agent databases.

#### Scenario: Initial import and repetition
- **WHEN** the configured import runs with existing local conversations and later runs again without new data
- **THEN** those conversations are available in Threads with no duplicate copies caused by repetition
- **AND** the original agent transcripts and databases remain intact

#### Scenario: No agent conversations
- **WHEN** a user has no local Claude Code or OpenCode conversations
- **THEN** the import completes without requiring either agent to be installed or preventing background synchronization

### Requirement: Managed background lifecycle
Capture and synchronization SHALL run as the owning user's managed background service without an interactive shell staying open. The service MUST start after required secrets are available and recover after a user-session restart.

#### Scenario: Restart without an open shell
- **WHEN** the user's session restarts after configuration activation
- **THEN** capture and synchronization resume using provisioned credentials without opening a terminal or manually starting Atuin
