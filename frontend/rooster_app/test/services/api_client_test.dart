import 'package:flutter_test/flutter_test.dart';
import 'package:rooster_app/services/api_client.dart';

void main() {
  group('ApiException', () {
    test('parses detail string from response body', () {
      final exception = ApiException(
        400,
        '{"detail": "Email already registered"}',
      );
      expect(exception.message, 'Email already registered');
      expect(exception.detail, 'Email already registered');
    });

    test('parses validation error list', () {
      final body =
          '{"detail": [{"msg": "field required", "loc": ["body", "email"]}]}';
      final exception = ApiException(422, body);
      expect(exception.message, 'field required');
    });

    test('returns friendly message for 401', () {
      final exception = ApiException(401, '{"detail": "Not authenticated"}');
      expect(exception.message, 'Session expired. Please login again.');
      expect(exception.isUnauthorized, true);
    });

    test('returns friendly message for 403', () {
      final exception = ApiException(403, '{"detail": "Forbidden"}');
      expect(exception.message, "You don't have permission to do this.");
      expect(exception.isForbidden, true);
    });

    test('returns friendly message for 404', () {
      final exception = ApiException(404, '{"detail": "Not found"}');
      expect(exception.message, 'Not found.');
      expect(exception.isNotFound, true);
    });

    test('returns friendly message for 500', () {
      final exception = ApiException(500, '{}');
      expect(exception.message, 'Server error. Please try again later.');
      expect(exception.isServerError, true);
    });

    test('handles non-JSON body gracefully', () {
      final exception = ApiException(400, 'plain text error');
      expect(exception.message, 'Request failed (400)');
      expect(exception.detail, isNull);
    });

    test('handles empty body', () {
      final exception = ApiException(400, '');
      expect(exception.message, 'Request failed (400)');
    });

    test('toString returns message', () {
      final exception = ApiException(400, '{"detail": "Bad request"}');
      expect(exception.toString(), 'Bad request');
    });

    test('isServerError for 500+', () {
      expect(ApiException(500, '{}').isServerError, true);
      expect(ApiException(502, '{}').isServerError, true);
      expect(ApiException(499, '{}').isServerError, false);
    });
  });

  group('NetworkException', () {
    test('stores message and original error', () {
      final original = Exception('socket closed');
      final ne = NetworkException('Connection error', original);
      expect(ne.message, 'Connection error');
      expect(ne.originalError, original);
      expect(ne.toString(), 'Connection error');
    });

    test('works without original error', () {
      final ne = NetworkException('Timeout');
      expect(ne.message, 'Timeout');
      expect(ne.originalError, isNull);
    });
  });
}
