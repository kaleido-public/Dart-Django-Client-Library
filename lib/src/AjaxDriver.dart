import 'package:dart_django_client_library/src/ItemCreatorType.dart';
import 'package:dart_django_client_library/src/JSONDecoder.dart';
import 'package:dart_django_client_library/src/Model.dart';

import './PageResult.dart';
import 'package:http/http.dart' as http;
import 'dart:mirrors';
import './CustomException.dart';

var REQUEST_ID = 0;

abstract class HttpDriver {
  Future request(String method, String url, data);
  
  Future<T> request_decode<T extends Model> (ItemCreator<T> creator, String method, String url, {data});
  
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
    var headers = {
      'content-type': 'application/json; charset=UTF-8',
      ...this.additional_headers
    };
    if (this.auth_token != null && this.auth_token != '') {
      headers = {'Authorization': 'Token ${this.auth_token}', ...headers};
    }
    return headers;
  }

  Future request(String method, String url, data) async {
    var current_request_id = REQUEST_ID++;
    url = this.url_prefix + url;
    try {
      Uri uri;
      if (method == "GET") uri = new Uri(scheme: 'http', host: 'localhost:8080', path: url, queryParameters: data);
      else uri = new Uri(scheme: 'http', host: 'localhost:8080', path: url);
      print(uri);

      http.Response response = http.Response('', 500);
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

  Future<T> request_decode<T extends Model> (ItemCreator<T> creator, String method, String url, {data}) async {
    var response = await this.request(method, url, data);
    return JSONDecoder.decode_model(creator, response.body);
  }

  Future<PageResult<T>> request_decode_page<T extends Model> (ItemCreator<T> creator, String method, String url, data) async {
    var response = await this.request(method, url, data);
    PageResult<T> page = new PageResult<T>();

    InstanceMirror page_mirror = reflect(page);
    response.forEach((key, val) => page_mirror.setField(Symbol(key), val));
    page = page_mirror.reflectee;
    
    if (response.containsKey("objects")) {
      page.objects = response.objects.map((dynamic val) => JSONDecoder.decode_model(creator, val));
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