import 'dart:convert';

import 'model.dart';
import 'types.dart';

abstract class JSONDecoderInterface {
  T decodeWithModel<T extends Model>(T model, String encoded);

  /// Used to decode a JSON object into a model object.
  T decodeWithCtor<T extends Model>(Constructor<T> ctor, String encoded);

  /// Used to decode a nested content when the parent is decoded. For example,
  /// when decoding the page result, the built-in library recursively decodes
  /// the JSON string in to an array of json objects. This method is used to
  /// convert the nested json object to a model object.
  T convertFromDecoded<T extends Model>(
    Constructor<T> ctor,
    Map<String, dynamic> object,
  );
}

class SimpleJSONDecoder extends JSONDecoderInterface {
  @override
  T decodeWithModel<T extends Model>(T model, String encoded) {
    T t = model.clone() as T;
    var json_obj = jsonDecode(encoded);
    json_obj.forEach((key, value) => {
          t.props[key] = value,
        });

    return t;
  }

  @override
  T decodeWithCtor<T extends Model>(Constructor<T> ctor, String encoded) {
    T t = ctor();
    var json_object = jsonDecode(encoded);
    json_object.forEach((key, value) => {t.props[key] = value});

    return t;
  }

  @override
  T convertFromDecoded<T extends Model>(
    Constructor<T> ctor,
    Map<String, dynamic> object,
  ) {
    T t = ctor();
    t.props = Map.from(object);
    return t;
  }
}

JSONDecoderInterface jsonDecoder = SimpleJSONDecoder();
