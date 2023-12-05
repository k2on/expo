/* eslint-env jest */
import execa from 'execa';
import fs from 'fs';
import klawSync from 'klaw-sync';
import path from 'path';

import { bin, getPageHtml, getRouterE2ERoot } from '../utils';
import { runExportSideEffects } from './export-side-effects';

runExportSideEffects();

describe('exports with tailwind and postcss', () => {
  const projectRoot = getRouterE2ERoot();
  const outputName = 'dist-tailwind-postcss';
  const outputDir = path.join(projectRoot, outputName);

  beforeAll(
    async () => {
      await execa('node', [bin, 'export', '-p', 'web', '--output-dir', outputName], {
        cwd: projectRoot,
        env: {
          NODE_ENV: 'production',
          EXPO_USE_STATIC: 'static',
          E2E_ROUTER_SRC: 'tailwind-postcss',
          E2E_ROUTER_ASYNC: 'development',
          EXPO_USE_FAST_RESOLVER: 'true',
        },
      });
    },
    // Could take 45s depending on how fast the bundler resolves
    560 * 1000
  );

  it('has expected files', async () => {
    // List output files with sizes for snapshotting.
    // This is to make sure that any changes to the output are intentional.
    // Posix path formatting is used to make paths the same across OSes.
    const files = klawSync(outputDir)
      .map((entry) => {
        if (entry.path.includes('node_modules') || !entry.stats.isFile()) {
          return null;
        }
        return path.posix.relative(outputDir, entry.path);
      })
      .filter(Boolean);

    // The wrapper should not be included as a route.
    expect(files).toEqual([
      '+not-found.html',
      expect.stringMatching(/_expo\/static\/css\/global-.*\.css/),
      expect.stringMatching(/_expo\/static\/js\/web\/index-.*\.js/),
      '_sitemap.html',
      'assets/__packages/expo-router/assets/error_ea95f4bb9132f841b426134607ffb6b9.png',
      'assets/__packages/expo-router/assets/file_93a9dd28e4dd3548679f5731a9c06a69.png',
      'assets/__packages/expo-router/assets/forward_b20dd094c666e0ef3b1e6b7f568554ec.png',
      'assets/__packages/expo-router/assets/pkg_1a2938de72edce9d3056b9c88a08cc66.png',
      'index.html',
    ]);
  });
  it('has tailwind classes', async () => {
    const indexHtml = await getPageHtml(outputDir, 'index.html');
    expect(indexHtml.querySelector('p.text-lg')).toBeDefined();
  });

  it('has tailwind CSS', async () => {
    const files = klawSync(outputDir)
      .map((entry) => {
        if (!entry.stats.isFile() || !entry.path.endsWith('.css')) {
          return null;
        }
        return entry.path;
      })
      .filter(Boolean);

    expect(files.length).toBe(1);

    const contents = fs.readFileSync(files[0]!, 'utf8');

    expect(contents).toMatch(/\.text-lg{/);
  });
});
