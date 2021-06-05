import './AjaxDriver.dart';
import './Model.dart';
import './ItemCreatorType.dart';
import './ObjectManager.dart';

class RelatedObjectManager<T extends Model, P extends Model> {
  int? parent_id;
  String? parent_key;
  String? parent_model_name;
  ItemCreator<T> creator;

  RelatedObjectManager(ItemCreator<T> this.creator, P parent, String this.parent_key) {
    this.parent_id = parent.id;
    this.parent_model_name = P.toString().toLowerCase();
  }

  String get object_url {
    return '/${this.parent_model_name}/${this.parent_id}/${this.parent_key}';
  }

  Future<ObjectManager<T>> get() async {
    try {
      var model = await httpDriverImpl.request_decode(this.creator, 'GET', this.object_url);
      return new ObjectManager<T>(model);
    } catch (error) {
      // TODO: handle case where error is 404: how to get code?
      throw error;
    }
  }

  Future set(T val) async {
    // Map<String, dynamic> data = {};
    // data[this.parent_key!] = val.id;
    int? data = val.id;
    return httpDriverImpl.request_void('PATCH', this.object_url, data);
  }
}