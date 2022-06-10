import "package:gql_exec/gql_exec.dart";
import "package:gql_link/gql_link.dart";
import "package:http/http.dart" as http;
import "package:meta/meta.dart";
import 'package:rsocket/payload.dart';
import 'package:rsocket/rsocket.dart';

/// Exception occurring when parsing fails.
@immutable
class RSocketLinkParserException extends ResponseFormatException {
  /// Payload which caused the exception
  final Payload payload;

  const RSocketLinkParserException({
    required dynamic originalException,
    required this.payload,
  }) : super(
    originalException: originalException,
  );
}

/// Exception occurring when network fails
/// or parsed response is missing both `data` and `errors`.
@immutable
class RSocketLinkServerException extends ServerException {
  /// Payload which caused the exception
  final Payload payload;

  const RSocketLinkServerException({
    required this.payload,
    required Response parsedResponse,
  }) : super(
    parsedResponse: parsedResponse,
  );
}