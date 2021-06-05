import 'package:dart_django_client_library/src/ItemCreatorType.dart';
import 'package:dart_django_client_library/src/JSONDecoder.dart';
import 'package:dart_django_client_library/src/Model.dart';

import './PageResult.dart';
import 'package:http/http.dart' as http;
import './CustomException.dart';
import 'dart:convert';

var REQUEST_ID = 0;

abstract class HttpDriver {
  Future request(String method, String url, data);
  
  Future<T> request_decode<T extends Model> (ItemCreator<T> creator, String method, String url, {data = const {}});

  Future<T> request_decode_from_model<T extends Model> (T model, String method, String url, {data = const {}});
  
  Future<PageResult<T>> request_decode_page<T extends Model>(ItemCreator<T> creator, 
  String method, String url, data);

  Future<void> request_void(String method, String url, data);

  var additional_headers;
  String? auth_token;
  String? url_prefix;
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

class HttpDriverImpl implements HttpDriver {
  var global_target_holder = {};

  // TODO: idk what this is
  get global_target {
    return global_target_holder;
  }

  get additional_headers {
    var add_headers = this.global_target['additional_headers'];
    if (add_headers != null) return add_headers;
    return {};
  }

  get auth_token {
    var auth_token = this.global_target['auth_token'];
    if (auth_token != null) return auth_token;
    return "";
  }

  String get url_prefix {
    var url_pre = this.global_target['url_prefix'];
    if (url_pre != null) return url_pre;
    return "";
  }

  set additional_headers(val) {
    this.global_target['additional_headers'] = val;
  }

  set auth_token(val) {
    this.global_target['auth_token'] = val;
  }

  set url_prefix(val) {
    this.global_target['url_prefix'] = val;
  }

  get headers {
    Map<String, String> headers = Map<String, String>();
    headers['content-type'] = 'application/json; charset=UTF-8';
    this.additional_headers.forEach((key, val) => {
      headers[key] = val
    });

    if (this.auth_token != null && this.auth_token != '') {
      headers['Authorization'] = 'Token ${this.auth_token}';
    }
    return headers;
  }

  Future clear() async {
    // used for testing purposes to clear database
    var uri = Uri.http('localhost:8000', 'subapp/clear');
    await http.get(uri);
  }

  Future request(String method, String url, data) async {
    var current_request_id = REQUEST_ID++;
    url = this.url_prefix + url;
    try {
      Uri uri;
      if (method == "GET") {
        var filler_val;
        Map<String, dynamic> new_obj = {};
        String curr_type;
        List<String> filler_list;
        String new_key;
          
        data.forEach((key, val) => {
          curr_type = val.runtimeType.toString(),
          if (curr_type.length < 4 || curr_type.substring(0, 4) != "List") {
            filler_val = val,
            if (val.runtimeType.toString() != "String") {
                filler_val = val.toString(),
            },
            new_obj[key] = filler_val
          } else {
            filler_list = [],
            val = val as List,
            for (int i = 0; i < val.length; i++) {
              if (val[i].runtimeType.toString() != "String") {
                filler_list.add(val[i].toString()),
              } else filler_list.add(val[i])
            },
            new_key = key + '[]',
            new_obj[new_key] = filler_list,
          }
        });

        // uri = new Uri(scheme: 'http', host: 'localhost:8080', path: url, queryParameters: new_obj);
        uri = Uri.http('localhost:8000', url, new_obj);
      }
      // else uri = new Uri(scheme: 'http', host: 'localhost:8080', path: url);
      else uri = Uri.http('localhost:8000', url);

      http.Response response = http.Response('', 500);
      data = jsonEncode(data);
      switch (method) {
        case "GET" : {
          response = await http.get(uri, headers: this.headers);
          break;
        }
        case "POST": {
          response = await http.post(uri, headers: this.headers, body: data);
          break;
        }
        case "DELETE": {
          response = await http.delete(uri, headers: this.headers, body: data);
          break;
        } 
        case "PATCH": {
          response = await http.patch(uri, headers: this.headers, body: data);
          break;
        } 
        case "PUT": {
          response = await http.put(uri, headers: this.headers, body: data);
          break;
        }
        default: {
          break;
        }
      }
      return response.body;
    } catch (error) {
      return HttpErrorImpl(error);
    }
  }

  Future<T> request_decode<T extends Model> (ItemCreator<T> creator, String method, String url, {data: const {}}) async {
    var response = await this.request(method, url, data);
    return JSONDecoder.decode_model_from_creator_and_string(creator, response);
  }
  
  Future<T> request_decode_from_model<T extends Model> (T model, String method, String url, {data: const {}}) async {
    var response = await this.request(method, url, data);
    return JSONDecoder.decode_model_from_model_and_string(model, response);
  }

  Future<PageResult<T>> request_decode_page<T extends Model> (ItemCreator<T> creator, String method, String url, data) async {
    var response = await this.request(method, url, data);
    Map<String, dynamic> json_obj = jsonDecode(response);
    PageResult<T> page = new PageResult<T>();
    page.limit = json_obj['limit'] as int?;
    page.page = json_obj['page'] as int?;
    page.total = json_obj['total'] as int?;
    page.previous = json_obj['previous'] as String?;
    page.next = json_obj['next'] as String?;
    
    if (json_obj.containsKey("objects")) {
      List<T> page_objects = [];
      for (dynamic obj in json_obj['objects']) {
        page_objects.add(JSONDecoder.decode_model_from_creator_and_object(creator, obj));
      }
      page.objects = page_objects;
      // page.objects = json_obj['objects'].map((dynamic val) => JSONDecoder.decode_model(creator, val) as T).toList();
      return page;
    } else {
      throw CustomException('Server did not return objects. Response: ${response.toString()}');
    }
  }

  Future<void> request_void(String method, String url, data) async {
    await this.request(method, url, data);
  }
}

var httpDriverImpl = new HttpDriverImpl();