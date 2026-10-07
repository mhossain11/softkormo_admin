import 'package:flutter_test/flutter_test.dart';
import 'package:softkormoadmin/core/utils/slug.dart';
import 'package:softkormoadmin/core/utils/validators.dart';

void main() {
  group('Validators.required', () {
    test('rejects null, empty and whitespace only values', () {
      expect(Validators.required(null, 'Name'), 'Name is required.');
      expect(Validators.required('', 'Name'), 'Name is required.');
      expect(Validators.required('   ', 'Name'), 'Name is required.');
    });

    test('accepts a value', () {
      expect(Validators.required('SoftKormo', 'Name'), isNull);
    });
  });

  group('Validators.email', () {
    test('accepts valid addresses', () {
      expect(Validators.email('admin@softkormo.com'), isNull);
      expect(Validators.email('first.last+tag@sub.domain.co'), isNull);
    });

    test('rejects missing and malformed addresses', () {
      expect(Validators.email(null), 'Email is required.');
      expect(Validators.email('   '), 'Email is required.');
      expect(Validators.email('admin@'), 'Enter a valid email address.');
      expect(Validators.email('admin softkormo.com'), 'Enter a valid email address.');
      expect(Validators.email('admin@softkormo'), 'Enter a valid email address.');
    });
  });

  group('Validators.password', () {
    test('enforces a minimum length of six characters', () {
      expect(Validators.password(null), 'Password is required.');
      expect(Validators.password(''), 'Password is required.');
      expect(Validators.password('12345'), 'Password must be at least 6 characters.');
      expect(Validators.password('123456'), isNull);
    });
  });

  group('Validators.url', () {
    test('treats the field as optional', () {
      expect(Validators.url(null), isNull);
      expect(Validators.url(''), isNull);
      expect(Validators.url('   '), isNull);
    });

    test('validates http, https and ftp addresses', () {
      expect(Validators.url('https://softkormo.com'), isNull);
      expect(Validators.url('http://softkormo.com/projects?x=1'), isNull);
      expect(Validators.url('ftp://files.example.com/dump'), isNull);
      expect(Validators.url('softkormo.com'), 'Enter a valid URL (https://...).');
      expect(Validators.url('www.softkormo.com'), 'Enter a valid URL (https://...).');
    });
  });

  group('Validators.integer', () {
    test('parses whole numbers with optional bounds', () {
      expect(Validators.integer('5'), isNull);
      expect(Validators.integer('0', min: 1), 'Must be 1 or more.');
      expect(Validators.integer('1', min: 1), isNull);
      expect(Validators.integer('200', max: 100), 'Must be 100 or less.');
    });

    test('rejects empty and non numeric input', () {
      expect(Validators.integer(''), 'Enter a number.');
      expect(Validators.integer('abc'), 'Enter a whole number.');
      expect(Validators.integer('1.5'), 'Enter a whole number.');
    });
  });

  group('Validators.number', () {
    test('parses amounts including thousand separators', () {
      expect(Validators.number('1250.5'), isNull);
      expect(Validators.number('1,250.50'), isNull);
      expect(Validators.number('0', min: 1), 'Must be 1 or more.');
      expect(Validators.number('10', max: 9), 'Must be 9 or less.');
      expect(Validators.number('10.5', max: 9.5), 'Must be 9.5 or less.');
      expect(Validators.number('0.4', min: 0.5), 'Must be 0.5 or more.');
    });

    test('rejects empty and invalid input', () {
      expect(Validators.number(''), 'Enter an amount.');
      expect(Validators.number('cheap'), 'Enter a valid amount.');
    });
  });

  group('Validators.list', () {
    test('requires at least one entry', () {
      expect(Validators.list(null), 'Add at least one item');
      expect(Validators.list('  \n '), 'Add at least one item');
      expect(Validators.list('Flutter, Dart'), isNull);
    });

    test('uses the custom field label when provided', () {
      expect(Validators.list(null, 'Add features'), 'Add features');
    });
  });

  group('Validators.splitList', () {
    test('splits on commas and newlines and drops blanks', () {
      expect(Validators.splitList('Flutter,  Dart,\n Firebase ,,'), [
        'Flutter',
        'Dart',
        'Firebase',
      ]);
      expect(Validators.splitList(null), isEmpty);
      expect(Validators.splitList('  '), isEmpty);
    });
  });

  group('Validators.rating', () {
    test('accepts ratings between one and five', () {
      for (var value = 1; value <= 5; value++) {
        expect(Validators.rating(value), isNull);
      }
      expect(Validators.rating(0), 'Rating must be between 1 and 5.');
      expect(Validators.rating(6), 'Rating must be between 1 and 5.');
    });
  });

  group('SlugHelper', () {
    test('builds url friendly slugs', () {
      expect(SlugHelper.from('My Awesome Project!'), 'my-awesome-project');
      expect(SlugHelper.from('  Hello   World  '), 'hello-world');
      expect(SlugHelper.from('Flutter & Firebase CMS'), 'flutter-firebase-cms');
      expect(SlugHelper.from('already-a-slug'), 'already-a-slug');
    });

    test('drops characters that are not part of a slug', () {
      expect(SlugHelper.from('!!!'), '');
      expect(SlugHelper.from('Café Ünicode'), 'caf-nicode');
    });
  });
}
