import assert from 'node:assert/strict';
import fs from 'node:fs/promises';
import path from 'node:path';
import { execFileSync } from 'node:child_process';
import { createRequire } from 'node:module';
import { validateParsedQuality } from '/app/backend/services/qualityProfile.ts';
import { getEnabledDownloadSources } from '/app/backend/services/downloadSourceService.ts';
import { FlowTrackSource } from '/app/backend/services/flows/flowTrackSource.ts';

assert.equal(process.env.AURRAL_FIXTURE, '1');
const require = createRequire('/app/backend/services/qualityProfileService.ts');
const { parseFile } = await import(require.resolve('music-metadata'));
const root = '/config/quality-fixture';
await fs.mkdir(root, { recursive: true });
const cases = [
  ['standard.flac', ['-c:a', 'flac', '-sample_fmt', 's16', '-ar', '44100'], true, 'flac-standard'],
  ['hires.flac', ['-c:a', 'flac', '-sample_fmt', 's32', '-ar', '96000'], true, 'flac-hires'],
  ['low.mp3', ['-c:a', 'libmp3lame', '-b:a', '128k'], false, 'mp3-128'],
  ['accepted.mp3', ['-c:a', 'libmp3lame', '-b:a', '320k'], true, 'mp3-320'],
];
for (const [name, encoding, valid, tier] of cases) {
  const file = path.join(root, name);
  execFileSync('/usr/local/bin/ffmpeg', ['-v', 'error', '-y', '-f', 'lavfi', '-i', 'sine=frequency=440:duration=2', ...encoding, file]);
  const result = validateParsedQuality(await parseFile(file), file);
  assert.equal(result.valid, valid, name);
  assert.equal(result.quality.tier, tier, name);
}
const low = await parseFile(path.join(root, 'low.mp3'));
assert.equal(validateParsedQuality(low, path.join(root, 'disguised.flac')).valid, false);
assert.deepEqual(getEnabledDownloadSources().map(source => source.id), ['slskd']);
const source = new FlowTrackSource();
source._getRecommendations = () => { throw new Error('Listening history must not be required'); };
source._getLibraryArtistKeySet = async () => new Set();
source._buildFeedbackExcludeKeys = () => new Set();
source._getTrendingChart = async () => [
  { trackName: 'First', artistName: 'New Artist One', albumName: 'First Album' },
  { trackName: 'Duplicate Artist', artistName: 'New Artist One', albumName: 'Second Album' },
  { trackName: 'Second', artistName: 'New Artist Two', albumName: 'Third Album' },
  { trackName: 'Third', artistName: 'New Artist Three', albumName: 'Fourth Album' },
];
const plan = await source.buildFlowRunPlan({
  id: 'quality-fixture', ownerUserId: 1, size: 3,
  mix: { discover: 0, mix: 0, trending: 100, focus: 0, newReleases: 0 },
  tags: [], excludeTags: [], deepDive: false,
});
assert.equal(plan.primaryTracks.length, 3);
assert.equal(new Set(plan.primaryTracks.map(track => track.artistName)).size, 3);
await fs.rm(root, { recursive: true });
console.log('Full-file quality, exclusive Soulseek selection and cold-start mixed-artist contracts passed');
process.exit(0);
