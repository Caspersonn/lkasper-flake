# Spec Delta

## Purpose

Protects personal data in `/home` (including `~/git`) on the workstation hosts. Each host runs scheduled, client-side encrypted restic backups to two independent destinations: kaito's repository over the Nebula mesh and an offsite S3 bucket. This is a NixOS module (not Home Manager) in `modules/services/backup/` and is enabled by importing it.

## ADDED Requirements

### Requirement: Enabled by import on registered workstation hosts
The home backup SHALL be a NixOS module under `modules/services/backup/` that takes effect when a host imports it. It SHALL have no enable option. personal-casper, gaming-casper, technative-casper and sakura SHALL import it. Each importing host MUST be registered as a backup client in the flake-level backup registry. If a host is not registered, evaluation MUST fail with a message that names the missing registration.

#### Scenario: Registered host builds
- **WHEN** a workstation host imports the home backup feature and is registered as a backup client
- **THEN** its NixOS configuration evaluates and builds
- **AND** it contains exactly one backup job targeting kaito and one backup job targeting S3

#### Scenario: Unregistered host fails evaluation
- **WHEN** a host imports the home backup feature without registering as a backup client
- **THEN** evaluation fails with an assertion message that names the host and the missing registration

#### Scenario: Other hosts are unaffected
- **WHEN** server-casper, neko, kaito, basic-home or nixhost are built
- **THEN** their configurations contain no home backup jobs

### Requirement: Two independent destinations
Each client host SHALL back up `/home` to two separate restic repositories:
- its own private repository on kaito's REST server, reached through kaito's Nebula mesh name
- its own prefix in the S3 bucket

The two jobs MUST be independent. A failure of one destination MUST NOT stop, delay or fail the job for the other destination. If a repository does not exist yet, the first run SHALL initialise it.

#### Scenario: kaito unreachable
- **WHEN** the host is not connected to the mesh or kaito is down
- **THEN** the kaito job fails
- **AND** the S3 job still runs on its own schedule and can succeed

#### Scenario: Repositories are separated per host
- **WHEN** the snapshots of host X are listed on kaito and in S3
- **THEN** each destination contains only host X's snapshots, stored under host X's own repository path

#### Scenario: First run on a new host
- **WHEN** a newly registered host runs its jobs for the first time
- **THEN** each job initialises its repository and creates the first snapshot

### Requirement: Client-side encryption with per-host credentials
Backups SHALL be encrypted on the client with a repository password that is unique to the host. The host's repository password, REST credentials and S3 access key SHALL be provided as agenix secrets. Only the following MAY decrypt them:
- the host itself
- the admin user key
- kaito, for the repository password only

No secret SHALL appear in plain text in the Nix store or in the git repository.

#### Scenario: Another host cannot read the credentials
- **WHEN** host Y tries to decrypt host X's REST/S3 credential secret
- **THEN** decryption fails because host Y is not a recipient

#### Scenario: Bucket access without the password
- **WHEN** someone who can read the bucket inspects host X's prefix without host X's repository password
- **THEN** only encrypted data is visible

### Requirement: Schedule tolerant of sleeping and mobile hosts
The kaito job SHALL run hourly and the S3 job SHALL run daily. Both jobs SHALL be persistent: a run missed while the machine was off or asleep SHALL start soon after the machine is running again, after a random delay. Backups SHALL run with the lowest CPU and I/O priority. A backup SHALL NOT start while the host runs on battery power.

#### Scenario: Laptop wakes after missing runs
- **WHEN** a laptop was asleep during its scheduled S3 run and is later resumed on AC power
- **THEN** the missed S3 backup runs after a random delay without waiting for the next day

#### Scenario: Laptop on battery
- **WHEN** a scheduled run happens while the laptop is on battery
- **THEN** that run is skipped, and a later run starts once the laptop is on AC power

### Requirement: Personal-data selection policy
The backup SHALL include personal data and exclude caches, downloads, reproducible build output and AI history, for every user directory under `/home`. The policy SHALL include:
- every non-hidden entry directly under a user's home directory, with its contents, except `Downloads` and `go/pkg`
- these hidden paths, which are the only hidden paths included:
  - `.ssh`, `.gnupg` and `.docker`
  - `.aws`, without its SSO and CLI caches
  - `.mozilla` and `.thunderbird` profiles, without cache, site storage, startup cache, crash reports and telemetry
  - `.config`, without the denylisted application directories and without Electron/Chromium cache subdirectories at any depth
  - `.local/share/keyrings`, `.local/share/fish`, `.local/share/FreeCAD`, `.local/share/bambu-studio` and `.local/share/orca-slicer`
  - shell and tool dotfiles directly in the home directory: `.*rc`, `.*_history`, `.gitconfig`, `.git-credentials`, `.netrc` and `.profile`

The policy SHALL exclude:
- all other hidden entries, including `.cache`, `.claude`, `.local/share/opencode`, `.local/share/atuin`, `.local/state`, `.local/share/Trash`, `.var`, `.terraform.d` and language toolchain directories
- the `.config` denylist: open-webui-desktop, teams-for-linux, Jan, discord, Electron, Slack, chromium, google-chrome, BraveSoftware, Cypress, clipse (clipboard history), elephant, feishin, coc, whatsapp-electron and vesktop
- at any depth: `node_modules`, `.venv`, `__pycache__`, `.terraform`, `.terragrunt-cache`, `.next`, `.direnv`, `.tox`, `.gradle`, `.serverless`, `.aws-sam` and `cdk.out`
- only below `~/git`: `target`, `dist`, `build`, `result`, `vendor` and `venv`
- any directory marked with a valid `CACHEDIR.TAG`

Git metadata (`.git`) SHALL be included, so unpushed branches, stashes and uncommitted work are preserved.

#### Scenario: Documents and repositories are included
- **WHEN** a snapshot is taken on a host with `~/Documents/report.pdf` and `~/git/gh.owner/repo/.git`
- **THEN** both are present in the snapshot

#### Scenario: Downloads and caches are excluded
- **WHEN** a snapshot is taken on a host with files in `~/Downloads` and `~/.cache`
- **THEN** neither directory's contents are in the snapshot

#### Scenario: Keys are included
- **WHEN** a snapshot is taken on a host with `~/.ssh/id_ed25519` and a `~/.gnupg` keyring
- **THEN** both are present in the snapshot

#### Scenario: AI history is excluded
- **WHEN** a snapshot is taken on a host with `~/.claude/projects` and `~/.local/share/opencode`
- **THEN** neither is in the snapshot

#### Scenario: Build output is excluded only where it is unambiguous
- **WHEN** a snapshot is taken on a host with `~/git/gh.owner/repo/node_modules`, `~/git/gh.owner/repo/target` and `~/Documents/target`
- **THEN** the two directories under `~/git` are excluded
- **AND** `~/Documents/target` is included

#### Scenario: Firefox profile without site storage
- **WHEN** a snapshot is taken on a host with a Firefox profile that has `places.sqlite`, `storage/` and `cache2/`
- **THEN** `places.sqlite` is included
- **AND** `storage/` and `cache2/` are excluded

#### Scenario: Application config without caches
- **WHEN** a snapshot is taken on a host with `~/.config/Signal`, `~/.config/clipse` and `~/.config/Code/Cache`
- **THEN** `~/.config/Signal` is included
- **AND** `~/.config/clipse` and `~/.config/Code/Cache` are excluded

#### Scenario: Other users are covered
- **WHEN** a snapshot is taken on sakura
- **THEN** both `/home/casper` and `/home/antonia` are covered by the same policy

### Requirement: Host-specific additions
The backup registry SHALL let each client host add its own extra exclude patterns and extra hidden paths to include. These additions SHALL NOT change the policy for any other host.

#### Scenario: Extra exclude on one host
- **WHEN** gaming-casper registers an extra exclude for `/home/casper/Games`
- **THEN** gaming-casper's snapshots no longer contain that directory
- **AND** the snapshots of other hosts are unchanged

### Requirement: Stable snapshot series
Every home snapshot SHALL meet all of the following:
- it uses the single backup path `/home`, the tag `home` and the host name as the snapshot host
- it does not cross into other filesystems mounted below `/home`

Changing the selection policy SHALL NOT start a new snapshot series.

#### Scenario: Policy change keeps the parent
- **WHEN** the exclude list changes between two runs
- **THEN** the next snapshot uses the previous snapshot as its parent
- **AND** retention treats both snapshots as one series

### Requirement: Clients cannot delete history
Client hosts SHALL NOT run `forget` or `prune` against either destination. Their credentials SHALL NOT allow deleting snapshot data:
- on kaito, the repository SHALL be append-only
- in S3, deletion SHALL be permitted only for restic lock files

If a client overwrites objects in S3, the earlier object versions SHALL remain recoverable for at least 30 days.

#### Scenario: Compromised client tries to delete
- **WHEN** someone holding host X's credentials runs `restic forget --prune` against kaito or S3
- **THEN** the deletions are refused and existing snapshots remain restorable

#### Scenario: Compromised client overwrites S3 objects
- **WHEN** someone holding host X's S3 key overwrites existing pack files
- **THEN** the previous versions of those objects can still be restored within 30 days

### Requirement: Backup status is observable on the host
Each backup job SHALL run as a systemd service, so its result appears in `systemctl status`, in `systemctl --failed` and in the journal. If some files could not be read, the snapshot SHALL be kept, and the run SHALL be reported as failed.

#### Scenario: Unreadable file
- **WHEN** a backup encounters a file it cannot read
- **THEN** a snapshot with all readable data is stored
- **AND** the systemd unit is marked failed, with the unreadable path in the journal
