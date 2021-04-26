import 'package:dart_django_client_library/src/ItemCreatorType.dart';
import './Model.dart';
import 'dart:mirrors';

abstract class JSONDecoderInterface {
  T decode_model<T extends Model>(ItemCreator<T> creator, object);
}

class SimpleJSONDecoder extends JSONDecoderInterface {
  T decode_model<T extends Model>(ItemCreator<T> creator, object) {
    T t = creator();
    
    InstanceMirror t_mirror = reflect(t);
    object.forEach((key, value) => {
      t_mirror.setField(Symbol(key), value)
    });

    return t_mirror.reflectee;
  }
}

JSONDecoderInterface JSONDecoder = new SimpleJSONDecoder();