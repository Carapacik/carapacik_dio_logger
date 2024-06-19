// ignore_for_file: avoid_redundant_argument_values
import 'package:carapacik_dio_logger/carapacik_dio_logger.dart';
import 'package:dio/dio.dart';

void main() {
  final dio = Dio();

  dio.interceptors.add(
    const CarapacikDioLogger(
      error: true,
      request: true,
      requestHeader: true,
      requestQueryParameters: true,
      requestBody: true,
      response: true,
      responseHeader: true,
      responseBody: true,
      convertFormData: true,
      colorized: false,
      showCurl: true,
      chunkSize: 1024,
      logPrint: print,
    ),
  );
}
