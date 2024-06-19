[![pub version](https://img.shields.io/pub/v/carapacik_dio_logger?logo=dart)](https://pub.dev/packages/carapacik_dio_logger)
[![pub likes](https://img.shields.io/pub/likes/carapacik_dio_logger?logo=dart)](https://pub.dev/packages/carapacik_dio_logger)
[![dart style](https://img.shields.io/badge/style-carapacik__lints%20-brightgreen?logo=dart)](https://pub.dev/packages/carapacik_lints)

`CarapacikDioLogger` is a [dio](https://github.com/cfug/dio) interceptor that logs in a easy to read format with curl command and colored output

## Usage

### Install

Add `CarapacikDioLogger` to your `Dio` interceptors:

```dart
final dio = Dio();

dio.interceptors.add(const CarapacikDioLogger());

// or customize your interceptor
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
    showLog: kDebugMode,
  ),
);
```