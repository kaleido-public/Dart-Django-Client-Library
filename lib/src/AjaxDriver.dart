import 'errors.dart';
import 'types.dart';
import 'JSONDecoder.dart';
import 'Model.dart';

import 'PageResult.dart';
import 'package:http/http.dart' as http;
import 'CustomException.dart';
import 'dart:convert';
import 'package:logging/logging.dart';

var REQUEST_ID = 0;
final log = Logger('AjaxDriver');
final AjaxDriverLogger = log;

abstract class AjaxDriver {
  Future request(String method, String url, data);

  Future<T> request_decode<T extends Model>(
      Constructor<T> creator, String method, String url,
      {data = const {}});

  Future<T> request_decode_from_model<T extends Model>(
      T model, String method, String url,
      {data = const {}});

  Future<PageResult<T>> request_decode_page<T extends Model>(
      Constructor<T> creator, String method, String url, data);

  Future<void> request_void(String method, String url, data);

  var additional_headers;
  abstract String auth_token;
  abstract String url_prefix;
  abstract String host;
  abstract int port;
}

abstract class HttpError {
  abstract var json;
  abstract int? status;
}

class HttpErrorImpl extends HttpError {
  var error;
  HttpErrorImpl(this.error) {}

  get json {
    return null;
  }

  set json(input_json) {
    this.json = input_json;
  }

  int get status {
    return -1;
  }

  void set status(int? status) {
    this.status = status;
  }
}

class AjaxDriverImpl implements AjaxDriver {
  var global_target_holder = {};
  String auth_token = "";
  String url_prefix = "api/v1/";
  String host = "localhost";
  int port = 8001;

  // TODO: idk what this is
  get global_target {
    return global_target_holder;
  }

  get additional_headers {
    var add_headers = this.global_target['additional_headers'];
    if (add_headers != null) return add_headers;
    return {};
  }

  set additional_headers(val) {
    this.global_target['additional_headers'] = val;
  }

  get headers {
    Map<String, String> headers = Map<String, String>();
    headers['content-type'] = 'application/json; charset=UTF-8';
    this.additional_headers.forEach((key, val) => {headers[key] = val});

    if (this.auth_token.isNotEmpty) {
      headers['Authorization'] = 'Token ${this.auth_token}';
    }
    return headers;
  }

  Future request(String method, String url, data) async {
    var current_request_id = REQUEST_ID++;

    Uri uri;
    if (method == "GET") {
      var filler_val;
      Map<String, dynamic> queryDict = {};
      String curr_type;
      List<String> filterList;
      String newKey;

      data.forEach((key, val) => {
            curr_type = val.runtimeType.toString(),
            if (curr_type.length < 4 || curr_type.substring(0, 4) != "List")
              {
                filler_val = val,
                if (val.runtimeType.toString() != "String")
                  {
                    filler_val = val.toString(),
                  },
                queryDict[key] = filler_val
              }
            else
              {
                filterList = [],
                val = val as List,
                for (int i = 0; i < val.length; i++)
                  {
                    if (val[i].runtimeType.toString() != "String")
                      {
                        filterList.add(val[i].toString()),
                      }
                    else
                      filterList.add(val[i])
                  },
                newKey = key + '[]',
                queryDict[newKey] = filterList,
              }
          });

      // uri = new Uri(scheme: 'http', host: 'localhost:8080', path: url, queryParameters: new_obj);
      uri = Uri.http(
          "${this.host}:${this.port}", this.url_prefix + url, queryDict);
    }
    // else uri = new Uri(scheme: 'http', host: 'localhost:8080', path: url);
    else {
      uri = Uri.http("${this.host}:${this.port}", this.url_prefix + url);
    }

    http.Response response = http.Response('', 500);

    data = jsonEncode(data);

    log.finer(
      "AjaxDriver sent (#${current_request_id}) ${method} ${uri} ${data}",
    );

    switch (method) {
      case "GET":
        response = await http.get(uri, headers: this.headers);
        break;
      case "POST":
        response = await http.post(uri, headers: this.headers, body: data);
        break;
      case "DELETE":
        response = await http.delete(uri, headers: this.headers, body: data);
        break;
      case "PATCH":
        response = await http.patch(uri, headers: this.headers, body: data);
        break;
      case "PUT":
        response = await http.put(uri, headers: this.headers, body: data);
        break;
    }

    if (200 <= response.statusCode && response.statusCode < 300) {
      log.finer(
        "AjaxDriver received (#${current_request_id}) ${response.statusCode} ${response.reasonPhrase} ${response.body}",
      );
      return response.body;
    } else {
      log.warning(
        "AjaxDriver received (#${current_request_id}) ${response.statusCode} ${response.reasonPhrase} ${response.body}",
      );
      throw deduceError(response.statusCode, jsonDecode(response.body));
    }
  }

  Future<T> request_decode<T extends Model>(
      Constructor<T> creator, String method, String url,
      {data: const {}}) async {
    var response = await this.request(method, url, data);
    return JSONDecoder.decode_model_from_creator_and_string(creator, response);
  }

  Future<T> request_decode_from_model<T extends Model>(
      T model, String method, String url,
      {data: const {}}) async {
    var response = await this.request(method, url, data);
    return JSONDecoder.decode_model_from_model_and_string(model, response);
  }

  Future<PageResult<T>> request_decode_page<T extends Model>(
    Constructor<T> ctor,
    String method,
    String url,
    data,
  ) async {
    var response = await this.request(method, url, data);
    Map<String, dynamic> json_obj = jsonDecode(response);
    PageResult<T> page = new PageResult<T>();
    page.limit = json_obj['limit'] as int?;
    page.page = json_obj['page'] as int?;
    page.objects_count = json_obj['objects_count'] as int;
    page.pages_count = json_obj['pages_count'] as int;
    page.previous = json_obj['previous'] as String?;
    page.next = json_obj['next'] as String?;

    if (json_obj.containsKey("objects")) {
      List<T> page_objects = [];
      for (dynamic obj in json_obj['objects']) {
        page_objects.add(
          JSONDecoder.decode_model_from_creator_and_object(ctor, obj),
        );
      }
      page.objects = page_objects;
      // page.objects = json_obj['objects'].map((dynamic val) => JSONDecoder.decode_model(creator, val) as T).toList();
      return page;
    } else {
      throw CustomException(
          'Server did not return objects. Response: ${response.toString()}');
    }
  }

  Future<void> request_void(String method, String url, data) async {
    await this.request(method, url, data);
  }
}

var Ajax = new AjaxDriverImpl();
