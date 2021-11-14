import 'abstract_collection_manager.dart';
import 'ajax_driver.dart';
import 'model.dart';
import 'types.dart';

class RelatedCollectionManager<T extends Model, P extends Model>
    extends AbstractCollectionManager<T> {
  dynamic parent_id;
  String? parent_key;
  String? parent_model_name;
  @override
  Constructor<T> ctor;

  RelatedCollectionManager(this.ctor, P parent, String this.parent_key) {
    this.parent_id = parent.id;
    this.parent_model_name = P.toString().toLowerCase();
  }

  @override
  String get collectionUrl {
    return '/${this.parent_model_name}/${this.parent_id}/${this.parent_key}';
  }

  Future<void> addIDs(Iterable<Object> ids) async {
    return ajax.requestVoid('POST', this.collectionUrl, ids.toList());
  }

  Future<void> setIDs(Iterable<Object> ids) async {
    return ajax.requestVoid('PATCH', this.collectionUrl, ids.toList());
  }

  Future<void> removeIDs(Iterable<Object> ids) async {
    return ajax.requestVoid('DELETE', this.collectionUrl, ids.toList());
  }

  Future<void> add(Iterable<T> objects) async {
    return this.addIDs(objects.map((e) => e.id));
  }

  Future<void> set(Iterable<T> objects) async {
    return this.setIDs(objects.map((e) => e.id));
  }

  Future<void> remove(Iterable<T> objects) async {
    return this.removeIDs(objects.map((e) => e.id));
  }
}
