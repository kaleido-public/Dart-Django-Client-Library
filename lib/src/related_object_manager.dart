import 'ajax_driver.dart';
import 'errors.dart';
import 'model.dart';
import 'object_manager.dart';
import 'types.dart';

class RelatedObjectManager<T extends Model, P extends Model> {
  late String parent_id;
  String? parent_key;
  String? parent_model_name;
  Constructor<T> creator;

  RelatedObjectManager(
    this.creator,
    P parent,
    String this.parent_key,
  ) {
    this.parent_id = parent.id;
    this.parent_model_name = P.toString().toLowerCase();
  }

  String get objectUrl {
    return '${this.parent_model_name}/${this.parent_id}/${this.parent_key}';
  }

  Future<ObjectManager<T>?> get() async {
    try {
      var model = await ajax.requestDecode(this.creator, 'GET', this.objectUrl);
      return ObjectManager<T>(model);
    } on NotFound {
      return null;
    }
  }

  Future<void> set(T val) async {
    return ajax.requestVoid('PATCH', this.objectUrl, val.id);
  }
}
