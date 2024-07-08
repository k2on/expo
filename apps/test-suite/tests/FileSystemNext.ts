'use strict';
import * as FS from 'expo-file-system';
import { File, Directory } from 'expo-file-system/next';
import { Platform } from 'react-native';

export const name = 'FileSystem@next';

export async function test({ describe, expect, it, ...t }) {
  const testDirectory = FS.documentDirectory + 'tests/';
  t.beforeEach(async () => {
    try {
      await FS.makeDirectoryAsync(testDirectory);
    } catch {}
  });
  t.afterEach(async () => {
    try {
      await FS.deleteAsync(testDirectory);
    } catch {}
  });

  describe('FileSystem (Next)', () => {
    it('Creates a lazy file reference', () => {
      const file = new File('file:///path/to/file');
      expect(file.path).toBe('file:///path/to/file');
    });

    it('Supports different slash combinations', async () => {
      expect(new File('file:/path/to/file').path).toBe('file:///path/to/file');
      // FirstDirectory is a host when url parsing.
      expect(new File('file://firstDirectory/to/file').path).toBe('file:///to/file');
      expect(new File('file:/path/to/file').path).toBe('file:///path/to/file');
    });

    it("Doesn't allow changing the path property", () => {
      const file = new File('file:///path/to/file');
      expect(() => {
        file.path = 'file:///new/path';
      }).toThrow();
    });

    it('Writes a string to a file reference', () => {
      // Not doing concating path segments in constructor, to make sure the second argument can be an options dict.
      // Instead, we want to provide utilties for it in a path object.
      const outputFile = new File(testDirectory + 'file.txt');
      expect(outputFile.exists()).toBe(false);
      outputFile.write('Hello world');
      expect(outputFile.exists()).toBe(true);
    });

    it('Reads a string from a file reference', () => {
      const outputFile = new File(testDirectory + 'file2.txt');
      outputFile.write('Hello world');
      expect(outputFile.exists()).toBe(true);
      const content = outputFile.text();
      expect(content).toBe('Hello world');
    });

    it('Deletes a file reference', () => {
      const outputFile = new File(testDirectory + 'file3.txt');
      outputFile.write('Hello world');
      expect(outputFile.exists()).toBe(true);

      outputFile.delete();
      expect(outputFile.exists()).toBe(false);
    });

    it('Creates a folder', () => {
      const folder = new Directory(testDirectory + 'newFolder/');
      folder.create();
      expect(folder.exists()).toBe(true);
    });

    // TODO: Make this consistent on both platforms
    it('Creates a folder without a slash', () => {
      if (Platform.OS === 'ios') {
        expect(() => {
          // eslint-disable-next-line no-new
          new Directory(testDirectory + 'newFolder2');
        }).toThrow();
      } else if (Platform.OS === 'android') {
        const folder = new Directory(testDirectory + 'newFolder2');
        folder.create();
        expect(folder.exists()).toBe(true);
      }
    });

    it('Creates an empty file', () => {
      const file = new File(testDirectory + 'newFolder');
      file.create();
      expect(file.exists()).toBe(true);
      expect(file.text()).toBe('');
    });

    it('Deletes a folder', () => {
      const folder = new Directory(testDirectory + 'newFolder/');
      folder.create();
      expect(folder.exists()).toBe(true);

      folder.delete();
      expect(folder.exists()).toBe(false);
    });

    describe('When copying a file', () => {
      it('copies it to a folder', () => {
        const src = new File(testDirectory + 'file.txt');
        src.write('Hello world');
        const dstFolder = new Directory(testDirectory + 'destination/');
        dstFolder.create();
        src.copy(dstFolder);
        expect(src.exists()).toBe(true);
        expect(src.text()).toBe('Hello world');
        const dst = new File(testDirectory + '/destination/file.txt');
        expect(dst.exists()).toBe(true);
        expect(dst.text()).toBe('Hello world');
      });

      it('Throws an error when copying a file to a nonexistant folder without options', () => {
        const file = new File(testDirectory + 'file.txt');
        file.write('Hello world');
        const folder = new Directory(testDirectory + 'destination/');
        expect(() => file.copy(folder)).toThrow();
      });

      it('copies it to a file', () => {
        const src = new File(testDirectory + 'file.txt');
        src.write('Hello world');
        const dst = new File(testDirectory + 'file2.txt');
        src.copy(dst);
        expect(dst.exists()).toBe(true);
        expect(dst.text()).toBe('Hello world');
        expect(src.exists()).toBe(true);
      });
    });
  });
}
