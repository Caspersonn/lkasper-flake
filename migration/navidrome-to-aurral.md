# Navidrome to Aurral migration on kaito

This runbook moves the music library and the listening history from Navidrome
into Aurral. The Aurral Flows instance on kaito serves Aurral on
`http://127.0.0.1:3002` and keeps its Library folder at `/data/music-aurral`.
Navidrome serves `http://127.0.0.1:4533` and keeps its music at
`/mnt/audio/music`.

The flake no longer ships Navidrome. Run this migration before the Navidrome
service is stopped, because Aurral reads the history from the live Navidrome
instance.

## The source path is a container path

Aurral reads the source folder inside its own container. The host path alone
is not enough: when the folder is not mounted into the container, the ingest
check answers with `The folder does not exist, or Aurral cannot read it`.

The kaito host mounts the Navidrome music folder read-only into the Aurral
container under the same path, so `/mnt/audio/music` works on both sides:

```nix
services.aurralFlows.legacyLibraryPath = "/mnt/audio/music";
```

The mount is read-only. Aurral copies or hardlinks the files into the Library
folder and never writes to the source.

## What the migration does

- Copies the Navidrome music folder into the Aurral Library folder through
  `POST /api/library/files/ingest`. The mode is `hardlink` when the source and
  the Library folder share a filesystem, and `copy` otherwise. The originals in
  `/mnt/audio/music` stay in place in both cases.
- Connects Navidrome to Aurral through `PUT /api/history-servers/navidrome`.
  Aurral imports the plays of that Navidrome user and checks for new plays
  every hour afterwards. The plays appear in Aurral's history, Wrapped and
  recommendations.
- Imports the Navidrome favorites through
  `POST /api/history-servers/navidrome/favorites`. Aurral matches them by
  MusicBrainz ID first and by name second.

The play counts are not read from the Navidrome database directly. Aurral
imports them through the Navidrome API while the server is still reachable.

## Prerequisites

- The Aurral Flows container runs and its first-run setup is complete.
- Navidrome runs and its music folder is readable.
- The Aurral account has the `accessSettings` permission, which the admin
  account holds.
- The Navidrome account holds the plays that should arrive in Aurral.
- The kaito host has the new configuration applied, so the Aurral container
  holds the read-only mount of the Navidrome music folder.

## Run the migration

Copy the script to kaito:

```bash
scp migration/navidrome-to-aurral.py kaito:/tmp/navidrome-to-aurral.py
```

Run it on kaito as root:

```bash
sudo env \
  AURRAL_PASSWORD='<aurral admin password>' \
  NAVIDROME_PASSWORD='<navidrome password>' \
  python3 /tmp/navidrome-to-aurral.py \
    --aurral-username '<aurral admin username>' \
    --navidrome-username '<navidrome username>'
```

The passwords can also be read from the environment on the machine instead of
being passed as arguments. The Aurral URL and the Navidrome URL default to the
loopback ports of the two services.

Useful switches:

| Switch | Effect |
| --- | --- |
| `--source PATH` | The Navidrome music folder as the container sees it, `/mnt/audio/music` by default |
| `--mode auto\|copy\|hardlink\|move` | How the files reach the Library folder, `auto` by default |
| `--monitor none\|tracks\|albums` | Whether Aurral keeps watching the source folder |
| `--skip-files` | Leave the music files alone and migrate the history only |
| `--skip-history` | Leave the listening history alone |
| `--skip-favorites` | Leave the favorites alone |
| `--timeout SECONDS` | How long the file ingest may run, 7200 seconds by default |

Run the file migration first with `--skip-history --skip-favorites` to see how
the ingest behaves before the history and the favorites are imported.

## Verify the result

In Aurral, open the Library and check that the artists and albums from
Navidrome appear. Open Settings > Listening and check that Navidrome shows as
connected. Open Wrapped or the listening history and check that the plays from
Navidrome are there.

The imported plays are not part of `GET /api/play-events`, which lists the
plays recorded inside Aurral itself.

## Stop Navidrome

After the history sync is done, stop Navidrome on kaito. The flake does not
declare the service any more, so a rebuild of the host leaves it stopped.

```bash
sudo systemctl disable --now navidrome
```

The files in `/mnt/audio/music` and the Navidrome database in `/var/lib` stay on
the machine. Removing them is a separate, manual step.

## Notes

- Aurral reads the music from the Library folder it owns. The Navidrome folder
  is not a read-only folder in Aurral, so the copy is the one Aurral indexes.
- Hardlinks only work when the source folder and the Library folder sit on the
  same filesystem and mount. On kaito both are ordinary directories on the
  root filesystem, so the automatic mode picks `hardlink` and the ingest costs
  no extra space.
- Aurral needs MusicBrainz tags for reliable matching. The ingest fills the
  missing tags when `fillTags` is on, which is the default.
- The Navidrome favorites stay in Aurral after the server is disconnected.
  Disconnecting Navidrome also removes the plays that Aurral imported.
- The ingest skips a file whose artist or album is unknown, and skips a file
  that the Library already holds. The operation lists each skipped file with
  its reason under `GET /api/library/files/operations/:id/items`.
- One folder in the source is not readable by the media user:
  `/mnt/audio/music/aurral` belongs to the old native Aurral and holds no
  music that Aurral needs.
