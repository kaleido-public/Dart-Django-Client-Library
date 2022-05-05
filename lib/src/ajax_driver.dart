import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:logger/logger.dart';

import 'errors.dart';
import 'json_decoder.dart' as decoder;
import 'model.dart';
import 'page_result.dart';
import 'types.dart';

class APIEndpoint {
  String scheme;
  String urlPrefix;
  String host;
  int port;
  APIEndpoint({
    this.scheme = "https",
    this.urlPrefix = "",
    this.host = "",
    this.port = 443,
  });

  @override
  String toString() {
    return "APIEndpoint(${this.uri()})";
  }

  Uri uri({String path = "", Map<String, Object?> query = const {}}) {
    if (query.isEmpty) {
      return Uri(
        scheme: this.scheme,
        host: this.host,
        port: this.port,
        path: this.urlPrefix + path,
      );
    } else {
      return Uri(
          scheme: this.scheme,
          host: this.host,
          port: this.port,
          path: this.urlPrefix + path,
          queryParameters: query.map((key, value) {
            if (value is String) {
              return MapEntry(key, value);
            } else if (value is Iterable) {
              return MapEntry(key + "[]", value.join(","));
            } else {
              return MapEntry(key, jsonEncode(value));
            }
          }));
    }
  }
}

abstract class AjaxDriver {
  Future<void> request(String method, String url, data);

  Future<T> requestDecode<T extends Model>(
    Constructor<T> creator,
    String method,
    String url, {
    data = const {},
  });

  Future<T> requestDecodeFromModel<T extends Model>(
    T model,
    String method,
    String url, {
    data = const {},
  });

  Future<PageResult<T>> requestDecodePage<T extends Model>(
    Constructor<T> creator,
    String method,
    String url,
    data,
  );

  Future<void> requestVoid(String method, String url, data);

  void enableDefaultLogger();

  Map<String, String> additionalHeaders = {};
  abstract String authToken;
  List<APIEndpoint> endpoints = [];
  APIEndpoint? preferredEndpoint;
  Logger? logger;
}

class AjaxDriverImpl implements AjaxDriver {
  @override
  String authToken = "";
  @override
  List<APIEndpoint> endpoints = [];
  @override
  APIEndpoint? preferredEndpoint;
  @override
  Map<String, String> additionalHeaders = {};
  static var REQUEST_ID = 0;
  @override
  Logger? logger;

  get headers {
    Map<String, String> headers = <String, String>{};
    headers['content-type'] = 'application/json; charset=UTF-8';
    this.additionalHeaders.forEach((key, val) => {headers[key] = val});

    if (this.authToken.isNotEmpty) {
      headers['Authorization'] = 'Token ${this.authToken}';
    }
    return headers;
  }

  @override
  Future<String> request(String method, String url, Object? data) async {
    try {
      if (this.preferredEndpoint != null) {
        return await requestEndpoint(
          this.preferredEndpoint!,
          method,
          url,
          data,
        );
      }
    } on APINetworkError {
      logger?.w("Endpoint failure: ${this.preferredEndpoint}");
    }
    // if the preferredEndpoint succeeds, the code returns early.
    for (var endpoint in this.endpoints) {
      try {
        var response = await requestEndpoint(endpoint, method, url, data);
        this.preferredEndpoint = endpoint;
        return response;
      } on APINetworkError {
        logger?.w("Endpoint failure: ${endpoint}");
        continue;
      }
    }
    logger?.e("Have tried all endpoints.");
    throw APINetworkError();
  }

  Future<String> requestEndpoint(
    APIEndpoint endpoint,
    String method,
    String url,
    Object? data,
  ) async {
    var currentRequestID = REQUEST_ID++;

    Uri uri = endpoint.uri(
      path: url,
      query: method == "GET" ? Map.from(data as Map? ?? {}) : {},
    );

    http.Response response;
    var encoded = jsonEncode(data);

    String sendLog =
        "AjaxDriver sent (#${currentRequestID}) ${method} ${uri} ${encoded}";

    logger?.d(sendLog);

    try {
      switch (method) {
        case "GET":
          response = await http.get(uri, headers: this.headers);
          break;
        case "POST":
          response = await http.post(
            uri,
            headers: this.headers,
            body: encoded,
          );
          break;
        case "DELETE":
          response = await http.delete(
            uri,
            headers: this.headers,
            body: encoded,
          );
          break;
        case "PATCH":
          response = await http.patch(
            uri,
            headers: this.headers,
            body: encoded,
          );
          break;
        case "PUT":
          response = await http.put(
            uri,
            headers: this.headers,
            body: encoded,
          );
          break;
        default:
          throw APIProgrammingError("Not supported METHOD: " + method);
      }
    } on SocketException {
      throw APINetworkError();
    }

    String receiveLog =
        "AjaxDriver received (#${currentRequestID}) ${response.statusCode} ${response.reasonPhrase} ${response.body}";
    if (200 <= response.statusCode && response.statusCode < 300) {
      logger?.d(receiveLog);
      return response.body;
    } else {
      logger?.w(sendLog);
      logger?.w(receiveLog);
      throw deduceError(
          response.statusCode, Map.from(jsonDecode(response.body)));
    }
  }

  @override
  Future<T> requestDecode<T extends Model>(
    Constructor<T> creator,
    String method,
    String url, {
    Object? data,
  }) async {
    var response = await this.request(method, url, data);
    return decoder.jsonDecoder.decodeWithCtor(creator, response);
  }

  @override
  Future<T> requestDecodeFromModel<T extends Model>(
      T model, String method, String url,
      {data = const {}}) async {
    var response = await this.request(method, url, data);
    return decoder.jsonDecoder.decodeWithModel(model, response);
  }

  @override
  Future<PageResult<T>> requestDecodePage<T extends Model>(
    Constructor<T> ctor,
    String method,
    String url,
    data,
  ) async {
    var encoded = await this.request(method, url, data);
    var obj = jsonDecode(encoded);
    PageResult<T> page = PageResult<T>();
    page.limit = obj['limit'] as int?;
    page.page = obj['page'] as int?;
    page.objects_count = obj['objects_count'] as int;
    page.pages_count = obj['pages_count'] as int;
    page.previous = obj['previous'] as String?;
    page.next = obj['next'] as String?;
    List<T> page_objects = [];
    for (Object obj in obj['objects'] as List<dynamic>) {
      page_objects.add(
        decoder.jsonDecoder.convertFromDecoded(
          ctor,
          obj as Map<String, Object?>,
        ),
      );
    }
    page.objects = page_objects;
    return page;
  }

  @override
  Future<void> requestVoid(String method, String url, data) async {
    await this.request(method, url, data);
  }

  static Logger? defaultLogger = Logger(
    printer: PrettyPrinter(
      colors: true,
      methodCount: 0,
      errorMethodCount: 8,
      printEmojis: true,
      printTime: false,
      lineLength: 120,
    ),
  );

  @override
  enableDefaultLogger() {
    logger = defaultLogger;
  }
}

AjaxDriver ajax = AjaxDriverImpl();
