import 'dart:convert' show JsonEncoder;

import 'package:dio/dio.dart';

/// Dio interceptor that logs network calls in a pretty,
/// easy to read format with curl command
class CarapacikDioLogger extends Interceptor {
  /// Constructor for interceptor
  const CarapacikDioLogger({
    this.request = true,
    this.requestHeader = true,
    this.requestQueryParameters = true,
    this.requestBody = true,
    this.response = true,
    this.responseHeader = true,
    this.responseBody = true,
    this.error = true,
    this.convertFormData = true,
    this.colorized = false,
    this.showCurl = true,
    this.showLog = true,
    this.chunkSize = 1024,
    this.logPrint = print,
  });

  /// Defines selected method of printing outputs
  /// defaults to log to console
  final void Function(String message) logPrint;

  /// Print request [Options]
  final bool request;

  /// Print request header [Options.headers]
  final bool requestHeader;

  /// Print request body
  final bool requestBody;

  /// Print [Response]
  final bool response;

  /// Print [Response.data]
  final bool responseBody;

  /// Print [Response.headers]
  final bool responseHeader;

  /// Print error message
  final bool error;

  /// Print FormData
  final bool convertFormData;

  /// Print Request Query parameters
  final bool requestQueryParameters;

  /// Print with colors using ASCII escape codes
  final bool colorized;

  /// Print cURL
  final bool showCurl;

  /// Enables logging altogether
  final bool showLog;

  /// Size of each chunk for long messages
  final int chunkSize;

  /// Defines encoder for intercepted json
  static const _encoder = JsonEncoder.withIndent('\t');

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (showLog) {
      try {
        _logOnError(err);
      } on Object catch (e) {
        logPrint('Error: $e');
      }
    }
    handler.next(err);
  }

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (showLog) {
      try {
        _logOnRequest(options);
      } on Object catch (e) {
        logPrint('LoggerError: $e');
      }
    }
    handler.next(options);
  }

  @override
  void onResponse(
    Response<dynamic> response,
    ResponseInterceptorHandler handler,
  ) {
    if (showLog) {
      try {
        _logOnResponse(response);
      } on Object catch (e) {
        logPrint('LoggerError: $e');
      }
    }
    handler.next(response);
  }

  void _logOnError(DioException err) {
    if (!error) {
      return;
    }
    _errorRepresentation(err);
  }

  void _logOnRequest(RequestOptions options) {
    if (showCurl) {
      _cURLRepresentation(options);
    }
    if (request) {
      _requestRepresentation(options);
    }
    if (requestHeader) {
      _requestHeadersRepresentation(options);
    }
    if (requestQueryParameters && options.queryParameters.isNotEmpty) {
      _requestQueryParametersRepresentation(options);
    }
    if (requestBody && options.method != 'GET' && options.data != null) {
      _requestBodyRepresentation(options);
    }
  }

  void _logOnResponse(Response<dynamic> res) {
    if (response) {
      _responseRepresentation(res);
    }
    if (responseHeader) {
      _responseHeadersRepresentation(res);
    }
    if (responseBody && res.data != null) {
      _responseBodyRepresentation(res);
    }
  }

  void _errorRepresentation(DioException err) {
    if (err.type == DioExceptionType.badResponse) {
      _printBoxed(
        'DioException ┃ ${err.response?.statusCode} ┃ ${err.response?.statusMessage}',
        err.response?.requestOptions.uri.toString() ?? 'Empty',
        _ConsoleColor.red.ansi,
      );

      if (err.response != null && err.response!.data != null) {
        final errorResponseJson = _encoder.convert(err.response!.data);
        _printBoxed(
          'DioExceptionBody ┃ ${err.type.name}',
          errorResponseJson,
          _ConsoleColor.red.ansi,
        );
      }
    } else {
      _printBoxed(
        'DioException ┃ ${err.type.name}',
        err.message ?? 'Empty',
        _ConsoleColor.red.ansi,
      );
    }
  }

  void _requestRepresentation(RequestOptions options) {
    final method = options.method;
    final uri = options.uri;
    _printBoxed('Request ┃ $method', uri.toString());
  }

  void _requestHeadersRepresentation(RequestOptions options) {
    final requestHeaders = <String, dynamic>{}..addAll(options.headers);
    requestHeaders['responseType'] = options.responseType.toString();
    requestHeaders['contentType'] = options.contentType;
    requestHeaders['connectTimeout'] = options.connectTimeout?.inMilliseconds;
    requestHeaders['receiveTimeout'] = options.receiveTimeout?.inMilliseconds;
    requestHeaders['followRedirects'] = options.followRedirects;

    final headersJson = _encoder.convert(requestHeaders);
    _printBoxed('Request Headers', headersJson);
  }

  void _requestQueryParametersRepresentation(RequestOptions options) {
    final queryParametersJson = _encoder.convert(options.queryParameters);
    _printBoxed('Query Parameters', queryParametersJson);
  }

  void _requestBodyRepresentation(RequestOptions options) {
    final dynamic data = options.data;
    if (data is Map) {
      final mapJson = _encoder.convert(data);
      _printBoxed('Request Body', mapJson);
    } else if (data is FormData) {
      final formDataMap = <String, String?>{}
        ..addEntries(data.fields)
        ..addEntries(data.files.map((e) => MapEntry(e.key, e.value.filename)));
      final formDataJson = _encoder.convert(formDataMap);
      _printBoxed('FormData', formDataJson);
    } else {
      _printBoxed('Request Body', data.toString());
    }
  }

  void _responseRepresentation(Response<dynamic> response) {
    final method = response.requestOptions.method;
    final uri = response.requestOptions.uri;
    _printBoxed(
      'Response ┃ $method ┃ ${response.statusCode}',
      uri.toString(),
      _ConsoleColor.green.ansi,
    );
  }

  void _responseHeadersRepresentation(Response<dynamic> response) {
    final responseHeaders = <String, String>{};
    response.headers.forEach((k, v) => responseHeaders[k] = v.toString());
    final responseHeadersJson = _encoder.convert(responseHeaders);
    _printBoxed(
      'Response Headers',
      responseHeadersJson,
      _ConsoleColor.green.ansi,
    );
  }

  void _responseBodyRepresentation(Response<dynamic> response) {
    final bodyJson = _encoder.convert(response.data);
    _printBoxed(
      'Response Body',
      bodyJson,
      _ConsoleColor.green.ansi,
    );
  }

  void _cURLRepresentation(RequestOptions options) {
    final components = ['curl -i', '-X ${options.method}'];

    options.headers.forEach((k, v) {
      if (k != 'Cookie') {
        components.add('-H "$k: $v"');
      }
    });

    final data = options.data;
    if (data != null) {
      if (data is FormData) {
        if (convertFormData) {
          for (final field in data.fields) {
            components.add('--form ${field.key}="${field.value}"');
          }
          for (final file in data.files) {
            components.add('--form =@"${file.value.filename}"');
          }
        }
      } else if (options.headers['content-type'] ==
          'application/x-www-form-urlencoded') {
        (data as Map).forEach((k, v) => components.add('-d "$k=$v"'));
      } else {
        final dataJson = _encoder.convert(data).replaceAll('"', r'\"');
        components.add('-d "$dataJson"');
      }
    }

    components.add('"${options.uri}"');
    _printBoxed(
      'cURL',
      components.join(' \\\n\t'),
      _ConsoleColor.blue.ansi,
    );
  }

  void _printBoxed(
    String header,
    String text, [
    String? color,
  ]) {
    var message = '''

┏━━━━━┫ $header ┣━━━━━
$text
┗━━━━━━━━━━━━━━━━━━━━━''';
    if (colorized && color != null) {
      message = _colorizeMessage(message, color);
    }
    if (message.length > chunkSize) {
      _logWithChunks(message, chunkSize);
    } else {
      logPrint(message);
    }
  }

  /// Logs the message in chunks if it exceeds the chunk size
  void _logWithChunks(String message, int chunkSize) {
    for (var start = 0; start < message.length; start += chunkSize) {
      final end = (start + chunkSize) < message.length
          ? (start + chunkSize)
          : message.length;
      final chunkMessage = message.substring(start, end);

      logPrint(chunkMessage);
    }
  }

  String _colorizeMessage(String message, String color) =>
      '\x1B[$color$message\x1B[0m';
}

/// Available console colors
enum _ConsoleColor {
  red,
  green,
  blue,
}

/// Extesion for colors
extension _ConsoleColorX on _ConsoleColor {
  /// Ansi colors for terminal
  String get ansi => switch (this) {
        _ConsoleColor.red => '31m',
        _ConsoleColor.green => '32m',
        _ConsoleColor.blue => '34m'
      };
}
