# Design

## Context

See `proposal.md` for motivation. Kaito already imports the NixOS `atuin` module, which provisions PostgreSQL locally and proxies port 8888 through HTTPS at `atuin.inspiravita.com`. The same module is also imported by neko and server-casper; this change does not remove those deployments or move their data.

`shared-atuin` serves Casper and Antonia and selects locked `unstable.atuin` 18.24.5. Release-matched settings enable Threads and managed synchronization while preserving shell-history preferences and the disabled AI assistant.

`shared-age` imports the agenix Home Manager module. Casper's runtime credentials use his SSH identity; Antonia's use explicitly authorized Sakura system decryption. Per-user recipient declarations in `secrets/secrets.nix` do not inherit its broad shared lists. Actual deployment and remaining verification boundaries are recorded below.

## Goals / Non-Goals

**Goals:** Keep client behavior in the existing shared Home Manager module, preserve per-user privacy, and make a provisioned device synchronize without interactive setup.

**Non-Goals:** Sharing conversations between different users, synchronizing repository files or agent provider credentials, installing an Atuin MCP server, enabling the Atuin AI assistant, or replacing other hosts' server deployments. No code comments are needed.

## Decisions

### User-approved closure scope

On 2026-11-15 the user requested removal of tasks 1.2 and 2.2, closure of 3.3, 4.3, and 4.5, and archival. The remaining Sakura runtime decryption/permissions, aarch64 build confirmation, global flake check, fresh Claude capture/latency, provider-backed continuation, full user-session restart, and rollback checks are excluded from closure acceptance, not recorded as successful tests. Earlier references below to open acceptance work document validation boundaries and are superseded by this closure decision. Implemented security controls, per-user credentials, and normative runtime behavior remain unchanged. No code comments are needed.

### Shared import-based feature

Extend `modules/users/shared/atuin.nix` rather than adding Casper-specific configuration or a new feature enable option. Keep its existing dendritic wrapper and preserve shell preferences. Enable the selected release's Threads capture and encrypted record sync settings independently of `ai.enabled = false`. Consolidate the module's repeated `settings` declarations while doing so.

### Credentials per user, shared only across that user's devices

Declare encrypted files named `atuin-<username>-session.age` and `atuin-<username>-key.age`, selected from the Home Manager username. Reference the decrypted key using Atuin's `key_path`. A managed runtime credential initializer reads the decrypted session file and provisions the token into Atuin's metadata database; `session_path` is not supported by the locked release. Never read decrypted contents during Nix evaluation. Import `shared-age` directly if necessary to make this dependency self-contained.

Use user-readable mode 0400 and an explicit user-specific recipient policy covering only that user's authorized decryption identities. Existing broad recipient lists are not evidence that every listed identity is authorized for every user's chats. Missing user secrets or identity access are provisioning blockers, not reasons to borrow Casper's account or disable sync silently.

The user explicitly authorized Casper's existing `user1` SSH key in `secrets/secrets.nix` as the administrative recipient for both users' Atuin secrets, then approved adding the relevant hostkeys for automatic system decryption of Antonia's runtime credentials. Antonia is configured only on sakura, so her session/key files use `[ user1 sakura ]`; Casper's session/key files retain `[ user1 ]`. No broad `users ++ systems` list is used. Antonia's generated registration password is retained separately in `atuin-antonia-password.age` with only `[ user1 ]` for administrative recovery; it is not a runtime login dependency and must not be deployed as a fallback password. This authorizes Casper and the explicitly selected system to decrypt Antonia's runtime credentials; it does not authorize sharing an Atuin account or record-encryption key. Do not copy Casper's private identity into Antonia's home, the repository, or the store.

Use system-level agenix with Sakura's existing host identity to decrypt Antonia's runtime session/key with owner antonia and mode 0400, exposing stable runtime paths to the shared Home Manager module. Keep Casper's user-level agenix decryption using his authorized private identity. Order Antonia's runtime services after availability of the system-provisioned files; missing files must fail clearly, without user-level fallback to Casper's private key. Standalone Home Manager activation on Sakura relies on this NixOS provisioning and must not require per-device Atuin login. Adding another Antonia host requires explicitly authorizing its recipient, not a blanket list.

An initial account/session/key must exist once per user. Reuse valid existing credentials where available; otherwise provision each account once on kaito using a controlled, non-logging process and encrypt the resulting token/key. This enrollment is separate from device setup. No device requires `atuin login`, interactive registration, or manual file copying. Preserve exact credential bytes, including avoiding trailing newlines where required by the selected release.

An alternative automatic password login on every device adds password distribution and repeated authentication logic; token/key provisioning avoids those dependencies.

### One managed daemon per user

Use the locked Home Manager module's `programs.atuin.daemon.enable = true` support. It generates `atuin-daemon.service` running `atuin daemon start`, requires `atuin-daemon.socket`, starts under `default.target`, and restarts on failure. The socket listens at `%t/atuin.sock` with mode 0600. Home Manager sets `daemon.enabled = true` and `daemon.systemd_socket = true`; set `daemon.autostart = false` explicitly to retain one systemd-owned daemon. Set `daemon.sync_frequency = 300` for five-minute background sync.

Order startup after agenix decryption and install under the user session's normal target. Do not require an interactive shell. Offline operation must retain local data and retry sync. Continuous operation after logout is not required; this change does not enable linger globally.

The daemon must require successful runtime credential initialization after decryption, including on daemon restarts. Initialization is local and does not run login or registration commands. It must use Atuin's release-matched metadata schema, preserve unrelated metadata, and write the session entry transactionally through bound parameters. Credential bytes must never appear in SQL command arguments, environment variables, generated store files, or logs. Restrict the metadata database and any journal files to the owning user. Validate credentials before mutation and do not let the daemon start with missing or invalid managed credentials.

An existing profile must not be silently switched to another account or encryption key: compare its existing key with the managed key before allowing token replacement, and fail with an actionable error on a mismatch while retaining all local data. Repeated initialization with unchanged credentials must be harmless. Rotation of the session token with the same encryption key must update the runtime session entry automatically; encryption-key changes require an explicit migration decision rather than replacing the key of existing records. Fresh-profile initialization, restart ordering, token rotation, permissions, and account-mismatch handling require fixture tests before deployment.

### Idempotent import outside activation

Add a managed per-user oneshot import step using the selected release's supported Threads import command. Run after decryption, credential initialization, configuration availability, and daemon startup. Run again on subsequent user-service starts so upstream incremental import discovers new data without maintaining a custom transcript migration marker. Do not put network-dependent work in Home Manager activation. No source transcript is moved or deleted.

### Keep kaito as the sync endpoint

Retain the existing public URL, local database, HTTPS proxy, and kaito import. Verify that the selected server accepts encrypted records and thread record sizes; change only concrete compatibility or proxy limits demonstrated necessary. Threads uses Atuin's encrypted record store, not an additional chat server. No new public listener is needed.

### Versioned compatibility, not moving documentation

Use release-matched source/help to confirm capture, sync, import, and daemon settings for the locked 18.24.5 package and the locked Home Manager module. Verify aarch64 support as well. If a release-specific limitation prevents the required behavior, update only the necessary dependency and update this design in the same implementation turn. Do not enable the AI assistant as a workaround.

### Verified release behavior and approved authentication adaptation

Task 1.1 inspected the locked v18.24.5 source (`crates/atuin-client/src/settings.rs`, `settings/daemon.rs`, `meta.rs`, `crates/atuin-daemon/src/lib.rs`, `sync/engine/worker.rs`, and `crates/atuin-ai/src/commands/session.rs`) and the locked Home Manager `modules/programs/atuin.nix`.

- `threads.capture = true` enables capture independently of `ai.enabled = false`. `threads.capture_tools` defaults to true.
- `auto_sync = true` and `daemon.sync_frequency = 300` enable periodic encrypted record sync. The daemon syncs the record store, projects downloaded thread records locally, and retries transient failures. No additional `sync.records` setting is needed.
- `atuin threads import` runs through the daemon, so the import unit starts after the daemon, not before it. An optional `--harness` filters agents; the unfiltered command scans supported agents and skips unavailable sources. Fixture-level idempotence and preservation are verified under task 2.4.
- The locked package enables the `ai`, `client`, `daemon`, and `sync` build features needed for Threads. Both x86_64-linux and aarch64-linux evaluate to version 18.24.5; aarch64 reports `meta.available = true`. This is package availability, not a completed architecture build.

The proposed `session_path` credential reference is not supported by this release. Session tokens are read from the `session` entry in the runtime metadata SQLite database. The legacy `data_dir/session` file is imported only once, guarded by the `files_migrated` metadata entry, so a symlink alone cannot reliably provision existing profiles or rotate tokens. `key_path` remains supported.

The user approved automatic runtime metadata-token provisioning on the condition that no device login is required. This replaces the planned `session_path` reference without changing the per-user encrypted-secret model. No dependency update is needed. The initializer and local fixture tests are implemented; gaming-casper and Kaito activation are verified below, while Sakura rollout remains incomplete.

The user corrected the public DNS to 83.83.71.166 and supplied kaito's Nebula SSH address, casper@10.123.0.1. HTTPS now returns 200 and Atuin-Version 18.24.5. Kaito's scanned SSH host key matches the existing kaito recipient in secrets/secrets.nix; SSH with that pinned key succeeds. Kaito currently has no Antonia OS account, so it cannot verify her client-side decryption access.

One-time enrollment is complete: the explicitly authorized account antonia was registered using antoniagosker@gmail.com and a generated password passed through stdin in an isolated private runtime directory. The password was encrypted before registration for recovery, followed by the resulting session and key. Exact-byte age round trips with Casper's authorized identity succeeded; the isolated runtime directory was removed. The existing local metadata token authenticates as caspersonn, not casper; it was reused together with its existing key without changing Casper's profile. Both accounts were verified with authenticated GET /api/v0/me, and their encryption keys differ. No token, password, or key was printed or passed as a command argument.

Antonia's session/key ciphertexts were re-encrypted to the approved Casper and Sakura recipients, and exact-byte decryption through Casper's identity still matches the originals. Her recovery password was not changed. Runtime decryption remains unverified under task 1.2: the user confirmed Sakura is powered off and unavailable. The selected Sakura recipient comes from the repository's existing key declaration, not an unverified scan. System-level provisioning is now declared in Antonia's NixOS user module and evaluates to Antonia-owned mode-0400 files at `/run/agenix/atuin-antonia-{session,key}`. Actual host-key decryption still requires Sakura; offline configuration work does not establish runtime availability.

### Implemented runtime initialization and offline checks

`modules/users/shared/atuin/credentials.py` reads private runtime files, validates the token and release-supported key encodings, and rejects an existing local key mismatch before calling Atuin. It follows the release's new-data-directory versus legacy-XDG selection, runs local `atuin info` with captured output to initialize upstream migrations, and transactionally upserts only the session token. A mode-0600 local key anchor is retained for future rotation checks. Existing history or encrypted records without an anchor fail rather than assuming their account. A fresh CLI can create empty databases before connecting to the activation socket: allow only zero history/record rows, known bootstrap metadata, and no different current or legacy session in this case. This narrowly handles the observed first-start race without relaxing existing-data migration safeguards. Python's SQLite connection is closed explicitly and umask 0077 protects new journals; a fixture checks the live DELETE journal is mode 0600 and disappears after commit.

Casper's agenix secrets use stable symlinks at `${XDG_STATE_HOME}/atuin/credentials/{session,key}` pointing to agenix runtime files. This avoids embedding unexpanded `${XDG_RUNTIME_DIR}` text in initializer arguments. Antonia consumes system-level paths without access to Casper's private identity. The managed `ATUIN_CONFIG_DIR` is supplied to the daemon, importer, and Home Manager session so an existing `~/.atuin/config.toml` cannot silently select different credentials in new shells.

Credential initialization runs as the native daemon's `ExecStartPre`, including on restarts. Casper's daemon requires and follows `agenix.service`; Antonia's files are provisioned during NixOS activation before the user session, and the initializer rejects absent files. The daemon wants an import oneshot ordered after it, with PartOf restart propagation and on-failure retries for socket-readiness races. Import fixtures pass against a real isolated Atuin 18.24.5 daemon with network synchronization disabled: Claude Code JSONL and OpenCode SQLite produce two threads, repeated import retains the identical list, source files remain byte-identical, and an empty profile imports successfully. Fourteen initializer/import/lifecycle tests pass. The rootless systemd fixture verifies socket activation without a terminal, secret-ready ordering before initialization, mode-0600 socket permissions, changed daemon PID on restart, and a second successful import propagated through PartOf. Test units use unique runtime names and are removed afterward; production units are not replaced by the fixtures.

An isolated two-device acceptance test used gaming-casper and kaito with Antonia's own managed credentials, Atuin 18.24.5, and the existing public HTTPS server. Synthetic Claude Code and OpenCode thread records were discovered automatically on kaito after 1.73 seconds. The isolated test used a one-second daemon interval; production remains 300 seconds. No explicit sync or device login was used. Test processes and local temporary profiles were removed, while the two harmless synthetic server records were retained. This test establishes encrypted-record exchange, not genuine agent resume or production-interval latency. Seven generated activation/config/unit/helper outputs were checked against all five decrypted credential files in memory; no plaintext match was found. Deployed production-unit logs and process arguments/environment also passed the non-disclosing audit on both activated devices.

### Approved rollout and existing Kaito profile

The user approved continuing through activation. Kaito's built Home Manager generation `/nix/store/56xllqvm98gclgalfn95y8hqv7f86y0y-home-manager-generation` was copied to its Nix store and its activation dry-run succeeded. A content comparison against the active generation found no removed home files; differences concern Atuin/agenix units and generated environment/package paths. The dry-run reports an existing unrelated failed `nextcloud-autosync.service`; it was not modified.

Pre-activation comparison found that Kaito's existing Casper encryption key differed from the enrolled managed Casper key, including after decoding the supported file encodings to their 32-byte values. This required an existing-profile migration, not an encoding adjustment. Initial activation was paused at `/nix/store/xiqyipgl3zx0wl9b094shi3cb96nmf9p-home-manager-generation` until the authorized verified migration described below; closure copying and dry-run alone were not treated as live acceptance.

The user subsequently authorized autonomous continuation, including migration work, except when sudo/root or other actual access is required. Upstream `atuin store rekey` accepts a supplied key only through a positional argument, so a temporary runtime-file-reading maintenance build was tested before migration. Local gaming-casper's decoded key already matched the managed account; its separate unmanaged Vesktop conflict was resolved only after explicit backup approval. Both real profiles now use `/nix/store/6y8lm2qv8fvxn7d4jzr5jy8nar4vgdn7-home-manager-generation` with retained recovery material.

Both `antonia@sakura` and `casper@kaito` Home Manager activation packages and Kaito's NixOS toplevel build successfully without activation. Generated TOML was parsed and checked for both users. Ten existing Casper/Antonia Home Manager profiles evaluate using `--impure`; their current host definitions are x86_64-linux. Pure Casper evaluation is blocked by existing shared AWS configuration reading `/home/casper/.aws/managed_service_accounts.json`; the separate `lucak@technative-casper` output references an undefined `lucak` module. `nix flake check --no-build` is blocked by the existing neko Nextcloud 32.0.15 EOL package restriction. These unrelated settings were not changed or bypassed.

Final setting/unit assertions pass for all ten x86_64 profiles and both users instantiated with aarch64 Home Manager: capture enabled, AI disabled, interval 300, shell autostart disabled, native socket dependency, daemon-wanted importer, and importer restart propagation. No aarch64 build or live Sakura test is claimed.

The current host advertises `aarch64-linux` in Nix's extra platforms and has an enabled `/proc/sys/fs/binfmt_misc/aarch64-linux` interpreter. A build of both isolated aarch64 shared-module Home Manager activation packages has been launched; it is not marked complete until the build result is available. The production observer measured a fresh native OpenCode thread update reaching Kaito 459.99 seconds after gaming-casper's local Threads capture, with both production daemon intervals unchanged at 300 seconds and no explicit sync/login. This measures capture-to-discovery rather than user-message-to-capture latency. Independent upload/download schedules can exceed one five-minute interval; this single observation is not a worst-case delivery guarantee.

### Kaito migration implementation

Kaito's pre-migration record-store tags were exclusively `history`; a read-only check found no metadata or legacy session token, so it was an unauthenticated local profile rather than a confirmed second server account. History continued growing during normal shell use. The temporary release-matched Atuin build reads the destination key from the runtime file named by `ATUIN_REKEY_KEY_FILE`; the environment contains only a file path, never key bytes. Upstream transactional record re-encryption and sidecar invalidation remain unchanged, and production uses the unmodified locked package. Isolated fixture checks preceded the verified private-snapshot/live-transaction migration, with original keys and snapshots retained as described under Operations.

### Local activation acceptance

After explicit user approval to back up the two unmanaged Vesktop files, local gaming-casper activated `/nix/store/6y8lm2qv8fvxn7d4jzr5jy8nar4vgdn7-home-manager-generation` using Home Manager's `HOME_MANAGER_BACKUP_EXT=before-atuin-20261115`. Both original files remain as adjacent backups with verified SHA256 matches. Before activation, consistent SQLite snapshots and private copies of the existing local key/session were saved under `~/.local/state/atuin/before-threads-20261115` with a private directory and files. No root access or device login was required.

The actual daemon and socket are active; the import oneshot completed successfully and initially listed 40 imported/discovered threads without printing their contents. All 82,203 pre-activation history IDs are still present. Runtime managed credentials resolve to Casper-owned mode-0400 files. Restarting the real daemon changes its PID and successfully reruns the importer. All five decrypted credentials were checked in memory against seven active generated outputs, the relevant production journals, and the daemon's arguments/environment; none occurs in those outputs. This establishes local activation, not user-session logout recovery or Sakura decryption. Kaito's subsequent migration/activation and native restore checks are recorded below.

### Additional isolation and request-size acceptance

A fresh isolated Antonia profile authenticates with her own managed credentials and automatically lists only her account's threads: its IDs are disjoint from the active Casper profile. Import succeeds without installed/local agent conversations. An encrypted Casper history row copied read-only into this isolated store cannot be decrypted with Antonia's key. Upstream `atuin store verify` reports failures through its diagnostic but still returns success, so acceptance checks inspect captured failure/success diagnostics and never rely on exit status alone. A new missing-secret fixture confirms an existing metadata database remains byte-identical; all 15 tests pass. Temporary profiles are removed and no production database is modified by the isolation test.

Both synthetic harness threads also transfer through live HTTPS with 2,097,152 additional text bytes each in 2.18 seconds, retaining the one-second test-only sync interval. Production stays at 300 seconds. Kaito's evaluated nginx request-body limit is 10m, and upstream's record-size default is 1 GiB. The tested larger records need no server/proxy changes; larger requests beyond the proxy limit are not claimed to work. Harmless encrypted test records remain on Antonia's account; local/remote test processes and profiles are cleaned.

## Operations

### Verified migration maintenance path

The temporary release-matched maintenance package built successfully as `/nix/store/glbfw79gvcdqkr7m75m1xy59qhwxb3iw-atuin-18.24.5`. Isolated real Atuin fixtures verify missing file-path failure leaves encrypted rows unchanged, target-file re-encryption preserves every record identity/metadata field and plaintext history row, and the unmodified package reports target-key decryption success. The snapshot/commit wrapper also passes a valid migration and an invalid-target failure that restores original key bytes/permissions and leaves active records unchanged.

For Kaito's active shell sessions, avoid upstream's load-all versus concurrent-write race: briefly make the existing key unreadable, wait for existing user-owned Atuin processes to exit normally, and take private consistent SQLite snapshots. New normal clients cannot load an old key during this barrier; no shell/user process is killed. Re-encrypt only a snapshot, verify it, acquire an immediate transaction on the live record database, and require every original row still matches the snapshot before updating only its encrypted data/key fields. Preserve all other tables and all history. Replace the key atomically while it remains unreadable, commit, then restore private readable permissions. On pre-commit failure restore the original key and permissions; retain original and target keys with all snapshots in a private recovery directory. Temporary history encryption may report an error during this maintenance barrier; existing plaintext history is not deleted. The wrapper is temporary maintenance tooling, not a new daemon or device-login path.

The live migration completed with 1,302 original history IDs and 1,229 record IDs retained. Non-running zombie processes are excluded from quiescence checks because they cannot access keys or write records. Both initial quiescence failures restored original permissions without changing records. Recovery material is retained at Kaito's `~/.local/state/atuin/before-managed-key-qi96wu0j`. The re-encrypted snapshot passed the unmodified verifier before the live transaction. Kaito subsequently passed dry-run and real activation of `/nix/store/6y8lm2qv8fvxn7d4jzr5jy8nar4vgdn7-home-manager-generation`, with no root or device-login command. Native daemon/socket/import are active; Casper-owned runtime credentials are mode 0400; the API confirms caspersonn; 42 threads are discoverable (33 OpenCode, 9 Claude Code). All verified migrated rows still match their target-key snapshot after downloading 94,357 additional server records. The live audit of unit logs and daemon arguments/environment found none of the five decrypted credentials.

Whole-store verification after server download reports decryption failures on both gaming-casper and Kaito. A read-only classification of Kaito's encrypted record envelopes found 95,429 records naming the verified managed key and 204 records naming one unavailable key; all 204 have the `history` tag, not Threads. None names Kaito's retained original key. Classification uses only PASERK wrapping-key identifiers: release-matched binary CEK envelopes contain a 96-byte wrapped key followed by its 33-byte identifier. No conversation payload or key value is printed. This distinguishes the retained older shell-history records from the verified Kaito migration and working Threads. They are not deleted, overwritten, or declared recovered; their original key remains necessary for full archive verification. Existing plaintext history and discoverable Threads remain present. `store verify` alone returning zero is not evidence of success.

The isolated ten-second HTTP-503 outage test recovered background transfer within the same daemon without login or an explicit sync command. It used a one-second test interval and did not disrupt production networking. Full user-session restart and generation rollback remain unverified; active sessions were not terminated. All ten affected x86_64 Home Manager profiles have now built successfully; aarch64 remains evaluation-only and the global flake check retains its unrelated Nextcloud EOL blocker.

### Native cross-device restore acceptance

Selected real gaming-casper-origin conversations for both agents in `/home/casper/lkasper-flake`. Kaito had downloaded these through the actual managed background daemon, without an explicit sync or device login. The acceptance runner takes consistent SQLite snapshots of Kaito's Threads/metadata databases into a private temporary destination HOME/XDG, disables network sync and daemon startup there, and invokes `atuin resume --print` from the existing checkout. Both matching launch commands are prepared; Claude's native JSONL and OpenCode 2's native `session_v2` database contain restored sessions. OpenCode's legacy `session` table alone is not an appropriate acceptance check for version 2. No provider/model is launched and no existing agent transcript/database is overwritten. The snapshot and restored temporary storage are removed afterward. `tests/atuin/test_threads.py` now repeats this restoration with harmless fixtures in a separate destination HOME/XDG, asserting source hashes remain unchanged. The native-restore fixture skips when either agent executable is absent; all 16 tests actually ran and passed here. A fresh native OpenCode update also transferred automatically in 459.99 seconds with production's 300-second interval. Fresh Claude capture/latency and provider-backed continuation remain open under 4.3.

### One-time account enrollment

An administrator enrolls each user once, not once per device. Reuse that user's existing account/key when valid; otherwise register a separate account on the existing HTTPS endpoint in a private isolated runtime profile. Supply the generated password through stdin, capture the resulting metadata session token and key without printing them, and immediately encrypt exact bytes into `secrets/atuin-<username>-{session,key}.age`. Keep any recovery password in a separate administrator-only ciphertext, never runtime configuration. Use only explicitly approved recipients in `secrets/secrets.nix`; do not inherit broad shared recipients. Verify the authenticated username and encryption/decryption round trip without displaying credentials. Remove the temporary enrollment profile after encryption is verified.

Casper's existing server username is `caspersonn`; Antonia's is `antonia`. Casper's username-selected filenames intentionally remain `atuin-casper-*`. Antonia's runtime files authorize only Casper's administrative identity and Sakura's host identity; her recovery password authorizes only Casper.

### Automatic devices and service checks

Import `shared-atuin` in the user's Home Manager profile, build it, and activate it normally. Casper requires his authorized SSH identity for Home Manager agenix; Antonia requires the NixOS user module's system-agenix provisioning on an authorized host. No Atuin login, registration, manual secret copying, or connection command is needed on a device. Authorize another host recipient explicitly before adding another Antonia device. A different existing encryption key intentionally blocks startup until its data has a verified migration.

The daemon, socket, and import unit are managed by the user session. A terminal need not remain open; synchronization is scheduled every 300 seconds with retry/backoff after failures. Services need not run after logout. Check status without displaying credentials:

```sh
systemctl --user status atuin-daemon.service atuin-daemon.socket atuin-threads-import.service
```

An inactive successful `agenix.service` is expected for its oneshot lifecycle. Missing files, unsafe permissions, an invalid token, or an existing key mismatch produce an actionable initialization failure and leave existing data intact. Do not bypass that failure by replacing the local key or deleting databases.

### Session rotation and encryption-key migration

Replace only the affected user's encrypted session with a valid replacement token for the same account and encryption key, retaining exact bytes and approved recipients. Rebuild/reactivate the authorized devices: agenix updates the private runtime file and the daemon's startup initializer transactionally updates the metadata session. Repeated initialization is harmless. Revoke the previous session through the server/account administration only after recovery access and the replacement have been verified. No password fallback or per-device interactive login is used.

Changing the encryption key is a separate migration, not session rotation. Retain private consistent SQLite backups, original keys, and source transcripts; prove all old records decrypt, re-encrypt transactionally, then verify row identities and target-key decryption before switching managed credentials. Never pass key bytes or mnemonics through command arguments or environment variables. The temporary file-reading maintenance build under Kaito migration is not the production package and must pass fixture/snapshot checks before real migration.

### Finding and resuming conversations

In a suitable local checkout, run:

```sh
atuin resume
```

The picker searches Threads across devices. A known thread can be selected directly with `atuin resume <thread-id>`; `atuin resume --print <thread-id>` prepares the supported resume path but prints the launch command instead of executing the agent. The installed matching agent and its provider authentication are still required for actual continuation. Allow time for background synchronization, and do not assume a thread immediately appears in an agent's native list before restore/resume. Do not overwrite an agent session that is actively running; use upstream branch/fork handling when histories diverge.

Source transcripts and agent databases remain in place. Repository files, uncommitted changes, provider credentials, and running processes are not synchronized. Messages and captured tool calls can contain sensitive content: record encryption and the existing secret filters do not guarantee that every sensitive item is removed from a conversation. Rollback preserves data and already-synchronized records; it does not retract server records. Native cross-device restore is verified without provider execution; new continuation/capture, production latency, full user-session recovery/rollback, and Sakura's live decryption remain acceptance items until separately verified.

## Risks / Trade-offs

- [Agent/version differences] → Test real Claude Code and OpenCode sessions on two devices; use `atuin resume` rather than promise every synced conversation immediately appears in the agent's native list.
- [Transcripts can contain sensitive content] → Keep end-to-end encryption, user-separated keys, and existing secret filtering; document that filtering does not guarantee all sensitive content is removed.
- [Sakura runtime decryption remains unavailable] → Keep Antonia's live host-key provisioning tasks open until actual identity access and ownership can be verified; never treat offline evaluation as runtime acceptance.
- [Shared tokens can be revoked] → Rotate encrypted credentials for the affected user and redeploy their devices; do not put fallback passwords in configuration.
- [Different checkout paths and active sessions] → Verify resume in an appropriate local checkout and follow upstream safeguards; do not claim repository files or running processes are synchronized.
- [Existing multi-user and migration changes touch this area] → Keep edits scoped to Atuin and preserve unrelated user work, including the existing gaming-casper configuration modification.

## Migration Plan

1. Confirm locked release behavior and per-user credential enrollment/identity access; prepare encrypted secrets without exposing plaintext.
2. Implement shared settings, service ordering, and import; build affected configurations before deployment.
3. Activate first on a non-critical client, confirm import idempotence and user isolation, then verify kaito compatibility and deploy any necessary server changes with approval.
4. Test cross-device capture, background sync, and resume for both agents and verify a second user's isolated account. Roll out remaining client profiles only after successful checks.
5. Roll back using the previous NixOS/Home Manager generation and stop new user units if necessary. Preserve local transcripts, Atuin databases, and server records; rollback does not delete already synchronized records.
