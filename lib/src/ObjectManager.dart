import 'package:dart_django_client_library/src/Model.dart';
import './AjaxDriver.dart';

class ObjectManager<T extends Model> {
  late T original;
  late T updated;

  // TODO: clarify whether or not ObjectManager is supposed to inherit all the fields of 
  // @model when constructed. If it is, need to initialize _properties as well
  ObjectManager(T model) {
    this.original = model.clone() as T;
    this.updated = model.clone() as T;
  }

  String get model_name {
    return T.toString().toLowerCase();
  }

  String get object_url {
    return '/${this.model_name}/${this.original.id}';
  }
  
  Future delete() async {
    return httpDriverImpl.request_void('DELETE', this.object_url, {});
  }

  Future refresh() async {
    var model = await httpDriverImpl.request_decode_from_model(this.updated, 'GET', this.object_url, data: {});
    this.original = model.clone() as T;
    this.updated = model.clone() as T;
  }

  Future save() async {
    Map<String, dynamic> to_send = {};
    this.updated.properties.forEach((key, val) => {
      if (val != this.original.properties[key]) {
        to_send[key] = val
      }
    });

    var model = await httpDriverImpl.request_decode_from_model(this.updated, 'PATCH', this.object_url, data: to_send);

    this.original = model.clone() as T;
    this.updated = model.clone() as T;
  }

  Future<ObjectManager<T>> update(data) async {
    var model = await httpDriverImpl.request_decode_from_model(this.updated, 'PATCH', this.object_url, data: data);
    this.original = model.clone() as T;
    this.updated = model.clone() as T;
    return this;
  }

  Model get model {
    return this.updated;
  }
}