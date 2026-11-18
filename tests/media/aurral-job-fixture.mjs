import assert from 'node:assert/strict';
import fs from 'node:fs/promises';
import { flowPlaylistConfig } from '/app/backend/services/playlists/flowPlaylistConfig.ts';
import { downloadTracker } from '/app/backend/services/downloadJobs/downloadTracker.ts';

assert.equal(process.env.AURRAL_FIXTURE, '1');
const flow = flowPlaylistConfig.createFlow({
  name: 'Download State Fixture', size: 2, ownerUserId: 1, autoDownload: false,
});
flowPlaylistConfig.setEnabled(flow.id, true);
const failed = downloadTracker.addJob({
  artistName: 'Fixture Artist', trackName: 'Failed Source Fixture', albumName: 'Fixture Album',
}, flow.id);
const blocked = downloadTracker.addJob({
  artistName: 'Fixture Artist', trackName: 'Waiting Source Fixture', albumName: 'Fixture Album',
}, flow.id);
assert.ok(failed && blocked);
assert.equal(downloadTracker.setFailed(failed, 'No matching Soulseek file'), true);
assert.equal(downloadTracker.setBlocked(blocked, 'Waiting for Soulseek peer'), true);
await fs.writeFile('/config/job-fixture.json', JSON.stringify({ flowId: flow.id, failed, blocked }));
process.exit(0);
