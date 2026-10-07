import 'package:flutter_test/flutter_test.dart';
import 'package:softkormoadmin/core/data/media_storage.dart';

void main() {
  group('StoragePath.fromUrl', () {
    test('extracts the encoded object path from a download URL', () {
      const url = 'https://firebasestorage.googleapis.com/v0/b/softkormo-8ea9c'
          '/o/projects%2Fdemo-1%2Fthumbnail.webp?alt=media&token=abc123';
      expect(StoragePath.fromUrl(url), 'projects/demo-1/thumbnail.webp');
    });

    test('handles URLs without a query string', () {
      const url = 'https://firebasestorage.googleapis.com/v0/b/bucket/o/settings%2Flogo%2F1.png';
      expect(StoragePath.fromUrl(url), 'settings/logo/1.png');
    });

    test('returns null for empty values', () {
      expect(StoragePath.fromUrl(''), isNull);
      expect(StoragePath.fromUrl('   '), isNull);
    });

    test('returns null when the URL has no object segment', () {
      expect(StoragePath.fromUrl('https://example.com/assets/logo.png'), isNull);
      expect(StoragePath.fromUrl('not a url'), isNull);
      expect(StoragePath.fromUrl('https://example.com/storage/o'), isNull);
    });
  });

  group('MediaStorage.safeName', () {
    test('lowercases and replaces unsafe characters', () {
      expect(MediaStorage.safeName('My Photo (1).JPG'), 'my-photo-1-.jpg');
      expect(MediaStorage.safeName('  Report   Final.pdf '), 'report-final.pdf');
      expect(MediaStorage.safeName('a--b.txt'), 'a-b.txt');
    });

    test('drops characters outside the ascii set', () {
      expect(MediaStorage.safeName('Ünicode & Name.PNG'), 'nicode-name.png');
    });

    test('never returns leading or trailing separators', () {
      expect(MediaStorage.safeName('cover (final).png'), 'cover-final-.png');
      expect(MediaStorage.safeName('--logo--'), 'logo');
      expect(MediaStorage.safeName(''), '');
    });
  });
}
