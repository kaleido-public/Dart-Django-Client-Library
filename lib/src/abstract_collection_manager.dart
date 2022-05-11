import 'ajax_driver.dart';
import 'errors.dart';
import 'model.dart';
import 'object_manager.dart';
import 'page_result.dart';
import 'types.dart';

abstract class AbstractCollectionManager<T extends Model> {
  String get collectionUrl;
  abstract Constructor<T> constructor;

  Future<PageResult<T>> page({
    Map<String, Object?> query = const {},
    int? page,
    String? orderBy,
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
    if (orderBy != null) {
      to_send["_order_by"] = orderBy;
    }
    if (limit != null) {
      to_send["_limit"] = limit;
    }
    if (fulltext != null) {
      to_send["_fulltext"] = fulltext;
    }

    return ajax.requestDecodePage(
      this.constructor,
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
    if (page.objectsCount != 1) {
      throw APIProgrammingError(
        '.get() must receive exactly 1 object, but got ${page.objectsCount}',
      );
    }

    return page.managers.first;
  }
}
