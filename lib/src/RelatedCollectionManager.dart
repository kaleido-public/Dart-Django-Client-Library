import 'Model.dart';
import 'types.dart';
import 'AbstractCollectionManager.dart';
import 'AjaxDriver.dart';

class RelatedCollectionManager<T extends Model, P extends Model>
    extends AbstractCollectionManager<T> {
  dynamic parent_id;
  String? parent_key;
  String? parent_model_name;
  Constructor<T> ctor;

  RelatedCollectionManager(
      Constructor<T> this.ctor, P parent, String this.parent_key) {
    this.parent_id = parent.id;
    this.parent_model_name = P.toString().toLowerCase();
  }

  String get collection_url {
    return '/${this.parent_model_name}/${this.parent_id}/${this.parent_key}';
  }

  Future add_ids(List<int> ids) async {
    return Ajax.request_void('POST', this.collection_url, ids);
  }

  Future set_ids(List<int> ids) async {
    return Ajax.request_void('PATCH', this.collection_url, ids);
  }

  Future remove_ids(List<int> ids) async {
    return Ajax.request_void('DELETE', this.collection_url, ids);
  }

  Future add(List<T> objects) async {
    return Ajax.request_void(
        'POST', this.collection_url, objects.map((val) => val.id).toList());
  }

  Future set(List<T> objects) async {
    return Ajax.request_void(
        'PATCH', this.collection_url, objects.map((val) => val.id).toList());
  }

  Future remove(List<T> objects) async {
    return Ajax.request_void(
        'DELETE', this.collection_url, objects.map((val) => val.id).toList());
  }
}
