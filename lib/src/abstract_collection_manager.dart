import 'ajax_driver.dart';
import 'errors.dart';
import 'model.dart';
import 'object_manager.dart';
import 'page_result.dart';
import 'types.dart';

abstract class AbstractCollectionManager<T extends Model> {
  String get collectionUrl;
  abstract Constructor<T> ctor;

  Future<PageResult<T>> page({
    Map<String, Object?> query = const {},
    int? page,
    String? order_by,
    int? limit,
    String? fulltext,
  }) async {
    Map<String, Object> to_send = <String, Object>{};
    query.forEach((key, val) => {
          if (val == null) {key += '__isnull', val = true},
          to_send[key] = val
        });

    if (page != null) {
      to_send["_page"] = page;
    }
    if (order_by != null) {
      to_send["_order_by"] = order_by;
    }
    if (limit != null) {
      to_send["_limit"] = limit;
    }
    if (fulltext != null) {
      to_send["_fulltext"] = fulltext;
    }

    return ajax.requestDecodePage(
      this.ctor,
      "GET",
      this.collectionUrl,
      to_send,
    );
  }

  Future<ObjectManager<T>> get([Map<String, Object?> query = const {}]) async {
    PageResult<T> page = await this.page(
      query: query,
      limit: 2,
    );
    if (page.objects_count != 1) {
      throw ProgrammingError(
        '.get() must receive exactly 1 object, but got ${page.objects_count}',
      );
    }

    return page.managers.first;
  }
}
