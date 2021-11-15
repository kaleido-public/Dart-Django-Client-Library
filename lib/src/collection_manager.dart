import 'abstract_collection_manager.dart';
import 'ajax_driver.dart';
import 'errors.dart';
import 'model.dart';
import 'object_manager.dart';
import 'page_result.dart';
import 'types.dart';

class CollectionManager<T extends Model> extends AbstractCollectionManager<T> {
  @override
  Constructor<T> ctor;

  CollectionManager(this.ctor);

  @override
  String get collectionUrl {
    return "${T.toString().toLowerCase()}";
  }

  Future<ObjectManager<T>> create(Map<String, Object?> data) async {
    var object = await ajax.requestDecode(
      this.ctor,
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
    if (page.objects_count == 0) {
      return this.create({...defaults, ...query});
    } else if (page.objects_count == 1) {
      return ObjectManager<T>(page.objects[0]);
    } else {
      throw ProgrammingError(
        '.get() must receive exactly one object, but got ${page.objects_count}',
      );
    }
  }

  Future<ObjectManager<T>> updateOrCreate({
    Map<String, Object?> query = const {},
    Map<String, Object> defaults = const {},
  }) async {
    PageResult<T> page = await this.page(query: query, limit: 2);
    if (page.objects_count == 0) {
      return this.create({...defaults, ...query});
    } else if (page.objects_count == 1) {
      var manager = ObjectManager<T>(page.objects[0]);
      return manager.update(defaults);
    } else {
      throw ProgrammingError(
        '.get() must receive exactly 1 object, but got ${page.objects_count}',
      );
    }
  }
}
