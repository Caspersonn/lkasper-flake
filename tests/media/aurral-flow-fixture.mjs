import fs from 'node:fs/promises';
import path from 'node:path';
import { execFileSync } from 'node:child_process';
import { flowPlaylistConfig } from '/app/backend/services/playlists/flowPlaylistConfig.ts';
import { downloadTracker } from '/app/backend/services/downloadJobs/downloadTracker.ts';

if (process.env.AURRAL_FIXTURE !== '1') throw new Error('Disposable fixture only');
const saved = process.env.AURRAL_FIXTURE_KIND === 'saved';
const flow = flowPlaylistConfig.createFlow({
  name: saved ? 'Saved Playlist Fixture' : 'Retention Fixture', size: 2, ownerUserId: 1, autoDownload: false,
});
flowPlaylistConfig.setEnabled(flow.id, true);
const jobs = [];
for (const name of saved ? ['Explicit Keep Song', 'Playlist Favorite Song'] : ['Keep Song', 'Rotate Song']) {
  const file = path.join('/data/music-aurral/_flows', flow.id, `${name}.flac`);
  await fs.mkdir(path.dirname(file), { recursive: true });
  execFileSync('/usr/local/bin/ffmpeg', [
    '-hide_banner', '-loglevel', 'error', '-f', 'lavfi', '-i', 'sine=frequency=440:duration=2',
    '-metadata', 'artist=Fixture Artist', '-metadata', `title=${name}`,
    '-metadata', 'album=Fixture Album', '-c:a', 'flac', '-y', file,
  ]);
  const id = downloadTracker.addJob({
    artistName: 'Fixture Artist', albumName: 'Fixture Album', trackName: name, durationMs: 2000,
  }, flow.id);
  if (!id) throw new Error('Fixture job creation failed');
  downloadTracker.setDone(id, file, 'Fixture Album');
  jobs.push({ id, file, name });
}
await fs.writeFile(saved ? '/config/saved-fixture.json' : '/config/retention-fixture.json', JSON.stringify({ flowId: flow.id, jobs }));
process.exit(0);
