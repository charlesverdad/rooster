import 'package:flutter_test/flutter_test.dart';
import 'package:rooster_app/utils/invite_utils.dart';

void main() {
  group('extractTokenFromInviteUrl', () {
    test('extracts token from full HTTPS URL', () {
      expect(
        extractTokenFromInviteUrl('https://rooster.app/invite/abc123'),
        'abc123',
      );
    });

    test('extracts token from HTTP URL', () {
      expect(
        extractTokenFromInviteUrl('http://rooster.app/invite/token456'),
        'token456',
      );
    });

    test('extracts token from URL with trailing slash', () {
      expect(
        extractTokenFromInviteUrl('https://rooster.app/invite/tok789/'),
        'tok789',
      );
    });

    test('extracts token from app scheme URL', () {
      expect(extractTokenFromInviteUrl('rooster://invite/mytoken'), 'mytoken');
    });

    test('returns bare token as-is', () {
      expect(extractTokenFromInviteUrl('abc123def456'), 'abc123def456');
    });

    test('trims whitespace', () {
      expect(extractTokenFromInviteUrl('  abc123  '), 'abc123');
    });

    test('returns null for empty input', () {
      expect(extractTokenFromInviteUrl(''), isNull);
    });

    test('returns null for whitespace-only input', () {
      expect(extractTokenFromInviteUrl('   '), isNull);
    });

    test('extracts token from URL with extra path segments', () {
      expect(
        extractTokenFromInviteUrl('https://rooster.app/api/invite/xyz'),
        'xyz',
      );
    });

    test('handles URL with query parameters', () {
      final result = extractTokenFromInviteUrl(
        'https://rooster.app/invite/tok?ref=email',
      );
      expect(result, 'tok');
    });

    test('handles fallback split for malformed URL with /invite/', () {
      final result = extractTokenFromInviteUrl(
        'some-weird-thing/invite/mytoken',
      );
      expect(result, 'mytoken');
    });
  });
}
