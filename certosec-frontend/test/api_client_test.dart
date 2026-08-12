import 'dart:convert';

import 'package:certosec/services/api/api_client.dart';
import 'package:certosec/services/api/api_exception.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  group('ApiClient', () {
    test('decodes JSON and attaches the bearer token when present', () async {
      final client = ApiClient(
        baseUrl: 'https://api.test/api/v1',
        accessTokenProvider: () async => 'secret-token',
        httpClient: MockClient((request) async {
          expect(request.headers['Authorization'], 'Bearer secret-token');
          expect(request.headers['Content-Type'], 'application/json');
          expect(
            request.url.toString(),
            'https://api.test/api/v1/auth/me?include=extra',
          );
          return http.Response(
            jsonEncode({'id': 'u1', 'name': 'Jane'}),
            200,
            headers: {'content-type': 'application/json'},
          );
        }),
      );

      final response = await client.get(
        '/auth/me',
        queryParameters: {'include': 'extra'},
      );

      expect(response.statusCode, 200);
      expect(response.data, {'id': 'u1', 'name': 'Jane'});
    });

    test('sends a JSON body on POST', () async {
      final client = ApiClient(
        baseUrl: 'https://api.test/api/v1',
        httpClient: MockClient((request) async {
          expect(request.method, 'POST');
          expect(jsonDecode(request.body), {
            'email': 'admin@university.edu',
            'password': 'pw',
          });
          return http.Response('{}', 200);
        }),
      );

      await client.post(
        '/auth/login',
        body: {'email': 'admin@university.edu', 'password': 'pw'},
      );
    });

    test(
      'maps 401 to an unauthorized ApiException with the server message',
      () async {
        final client = ApiClient(
          baseUrl: 'https://api.test/api/v1',
          httpClient: MockClient(
            (_) async => http.Response(
              jsonEncode({'message': 'Invalid email or password.'}),
              401,
              headers: {'content-type': 'application/json'},
            ),
          ),
        );

        await expectLater(
          client.post('/auth/login', body: {}),
          throwsA(
            isA<ApiException>()
                .having((e) => e.kind, 'kind', ApiExceptionKind.unauthorized)
                .having(
                  (e) => e.message,
                  'message',
                  'Invalid email or password.',
                ),
          ),
        );
      },
    );

    test('maps 422 with field errors into a validation ApiException', () async {
      final client = ApiClient(
        baseUrl: 'https://api.test/api/v1',
        httpClient: MockClient(
          (_) async => http.Response(
            jsonEncode({
              'message': 'Validation failed',
              'errors': {'email': 'Email already registered'},
            }),
            422,
            headers: {'content-type': 'application/json'},
          ),
        ),
      );

      await expectLater(
        client.post('/auth/login', body: {}),
        throwsA(
          isA<ApiException>()
              .having((e) => e.kind, 'kind', ApiExceptionKind.validation)
              .having((e) => e.fieldErrors, 'fieldErrors', {
                'email': 'Email already registered',
              }),
        ),
      );
    });

    test('maps transport failures to the network kind', () async {
      final client = ApiClient(
        baseUrl: 'https://api.test/api/v1',
        httpClient: MockClient((_) async => throw http.ClientException('boom')),
      );

      await expectLater(
        client.get('/auth/me'),
        throwsA(
          isA<ApiException>().having(
            (e) => e.kind,
            'kind',
            ApiExceptionKind.network,
          ),
        ),
      );
    });

    test('maps 5xx to the server kind', () async {
      final client = ApiClient(
        baseUrl: 'https://api.test/api/v1',
        httpClient: MockClient(
          (_) async => http.Response('Internal Server Error', 500),
        ),
      );

      await expectLater(
        client.get('/auth/me'),
        throwsA(
          isA<ApiException>().having(
            (e) => e.kind,
            'kind',
            ApiExceptionKind.server,
          ),
        ),
      );
    });
  });
}
