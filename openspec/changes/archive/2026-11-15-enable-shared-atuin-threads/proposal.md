# Proposal

## Why

OpenCode and Claude Code conversations should be available across a user's devices through the self-hosted Atuin server on kaito. Shared Home Manager configuration currently selects that server and enables shell-history auto-sync, but does not provision authentication or enable Threads capture.

## What Changes

- Enable Threads capture, a managed per-user daemon, and encrypted record synchronization in `shared-atuin`.
- Provision each user's Atuin session token and encryption key through agenix, reused across that user's devices without interactive login on each device.
- Automatically import existing supported agent conversations with a repeatable, non-destructive import step.
- Keep the sync service hosted on kaito at `https://atuin.inspiravita.com` and verify server/client compatibility.
- Apply the behavior to all configured users through the shared module, keeping accounts and encryption keys separate between users.
- Preserve existing shell-history preferences and disabled Atuin AI assistant behavior; Threads does not require enabling that assistant.

## Capabilities

### New Capabilities

- `shared-atuin-threads`: Declarative, per-user encrypted synchronization of Claude Code and OpenCode conversations across devices using kaito.

### Modified Capabilities

None.

## Impact

- Home Manager: `modules/users/shared/atuin.nix`, existing `shared-age`, and Casper/Antonia imports of the shared module. No Home Manager migration is required.
- NixOS: `modules/services/tools/atuin.nix` and kaito's existing import; other hosts importing the same server module must retain working service configuration.
- Secrets: per-user encrypted session/key files and recipient declarations in `secrets/secrets.nix`; no plaintext credentials in the repository or Nix store.
- Hosts: client behavior applies across gaming-casper, personal-casper, technative-casper, server-casper, kaito, and any other Home Manager profile importing `shared-atuin`, on x86_64-linux and aarch64-linux.
- Dependencies: the locked unstable Atuin version and Home Manager daemon support must be verified against the Threads settings used. Updates, if required, must remain narrowly scoped.
- Existing conversations and tool calls become encrypted sync data; source transcripts and local databases must remain intact.
- Implementation follows the existing import-based dendritic modules, without a new feature enable option. Comments in code are not needed.
