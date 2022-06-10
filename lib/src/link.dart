import 'dart:async';
import 'dart:convert';

import 'package:gql_exec/src/request.dart';
import 'package:gql_exec/src/response.dart';
import 'package:gql_link/gql_link.dart';
import 'package:gql_rsocket_link/src/request_with_type.dart';
import 'package:rsocket/payload.dart';
import 'package:rsocket/rsocket.dart';
import 'package:rsocket/rsocket_connector.dart';

import 'exceptions.dart';

typedef RSocketPayloadDecoder = FutureOr<Map<String, dynamic>?> Function(
    Payload payload);

/// A simple RSocketLink implementation.

class RSocketLink extends Link {
  late final RSocket _rSocket;

  final RequestSerializer serializer;

  /// Parser used to parse response
  final ResponseParser parser;

  /// A function that decodes the incoming http response to `Map<String, dynamic>`,
  /// the decoded map will be then passes to the `RequestSerializer`.
  /// It is recommended for performance to decode the response using `compute` function.
  /// ```
  /// httpResponseDecoder : (http.Response httpResponse) async => await compute(jsonDecode, httpResponse.body) as Map<String, dynamic>,
  /// ```
  RSocketPayloadDecoder rSocketPayloadDecoder;

  static Map<String, dynamic>? _defaultRSocketPayloadDecoder(Payload payload) =>
      payload.data == null
          ? null
          : json.decode(
              payload.getDataUtf8()!,
            ) as Map<String, dynamic>?;

  RSocketLink({
    this.serializer = const RequestSerializer(),
    this.parser = const ResponseParser(),
    this.rSocketPayloadDecoder = _defaultRSocketPayloadDecoder,
  });

  @override
  Stream<Response> request(Request request, [NextLink? forward]) async* {
    final payload =
        Payload.fromJson(serializer.serializeRequest(request));

    if (request.isSubscription) {
      // request stream
      yield* _rSocket.requestStream!(payload).asyncMap((result) async {
        final response = await _parseResponse(result!);
        return response;
      });
    } else {
      final result = await _executeRequestResponse(payload);

      final response = await _parseResponse(result);

      yield response;
    }
  }

  Future<Payload> _executeRequestResponse(Payload payload) async {
    try {
      return _rSocket.requestResponse!(payload);
    } catch (e) {
      throw ServerException(
        originalException: e,
        parsedResponse: null,
      );
    }
  }

  Future<Response> _parseResponse(Payload payload) async {
    try {
      final responseBody = await rSocketPayloadDecoder(payload);
      return parser.parseResponse(responseBody!);
    } catch (e) {
      throw RSocketLinkParserException(
        originalException: e,
        payload: payload,
      );
    }
  }
}
