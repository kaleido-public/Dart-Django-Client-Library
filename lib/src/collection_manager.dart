import 'abstract_collection_manager.dart';
import 'ajax_driver.dart';
import 'errors.dart';
import 'model.dart';
import 'object_manager.dart';
import 'page_result.dart';
import 'types.dart';

class CollectionManager<T extends Model> extends AbstractCollectionManager<T> {
  @override
  Constructor<T> constructor;

  CollectionManager(this.constructor);

  @override
  String get collectionUrl {
    return "/${T.toString().toLowerCase()}";
  }

  Future<ObjectManager<T>> create(Map<String, Object?> data) async {
    var object = await ajax.requestDecode(
      this.constructor,
      "POST",
      this.collectionUrl,
      data: data,
    );
    return ObjectManager<T>(object);
  }

  Future<ObjectManager<T>> getOrCreate({
    Map<String, Object?> query = const {},
    Map<String, Object?> defaults = const {},
  }) async {
    PageResult<T> page = await this.page(query: query, limit: 2);
    if (page.objectsCount == 0) {
      return this.create({...defaults, ...query});
    } else if (page.objectsCount == 1) {
      return ObjectManager<T>(page.objects[0]);
    } else {
      throw APIProgrammingError(
        '.get() must receive exactly one object, but got ${page.objectsCount}',
      );
    }
  }

  Future<ObjectManager<T>> updateOrCreate({
    Map<String, Object?> query = const {},
    Map<String, Object> defaults = const {},
  }) async {
    PageResult<T> page = await this.page(query: query, limit: 2);
    if (page.objectsCount == 0) {
      return this.create({...defaults, ...query});
    } else if (page.objectsCount == 1) {
      var manager = ObjectManager<T>(page.objects[0]);
      return manager.update(defaults);
    } else {
      throw APIProgrammingError(
        '.get() must receive exactly 1 object, but got ${page.objectsCount}',
      );
    }
  }
}
