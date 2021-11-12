import 'types.dart';
import 'Model.dart';
import 'dart:convert';

abstract class JSONDecoderInterface {
  T decode_model_from_model_and_string<T extends Model>(T model, object);
  T decode_model_from_creator_and_string<T extends Model>(
      Constructor<T> creator, String object);
  T decode_model_from_creator_and_object<T extends Model>(
      Constructor<T> creator, Map<String, dynamic> object);
}

class SimpleJSONDecoder extends JSONDecoderInterface {
  T decode_model_from_model_and_string<T extends Model>(T model, object) {
    T t = model.clone() as T;
    Map<String, dynamic> json_obj = jsonDecode(object);
    json_obj.forEach((key, value) => {
          t.props[key] = value,
        });

    return t;
  }

  T decode_model_from_creator_and_string<T extends Model>(
      Constructor<T> creator, String object) {
    T t = creator();
    Map<String, dynamic> json_object = jsonDecode(object);
    json_object.forEach((key, value) => {t.props[key] = value});

    return t;
  }

  T decode_model_from_creator_and_object<T extends Model>(
      Constructor<T> creator, Map<String, dynamic> object) {
    T t = creator();
    object.forEach((key, value) => {t.props[key] = value});

    return t;
  }
}

JSONDecoderInterface JSONDecoder = new SimpleJSONDecoder();
