import 'package:django_client_framework/django_client_framework.dart';

class RelatedCollectionManagerCache<T> {
  List<T> value;
  RelatedCollectionManagerCache(this.value);
}

class RelatedCollectionManager<T extends Model, P extends Model>
    extends AbstractCollectionManager<T> {
  final String? parentID;
  final String parentAttrName;
  final String parentModelName;
  final RelatedCollectionManagerCache<Model>? cache;
  final RelatedCollectionManager<P, T> Function(T)? reverseCollectionManager;
  final RelatedObjectManager<P, T> Function(T)? reverseObjectManager;

  @override
  Constructor<T> constructor;

  RelatedCollectionManager(
    this.constructor,
    P parent,
    this.parentAttrName,
    Map<String, dynamic> parentCacheMap, {
    this.reverseCollectionManager,
    this.reverseObjectManager,
  })  : cache = parentCacheMap[parentAttrName],
        parentID = parent.id,
        parentModelName = P.toString().toLowerCase();

  String get reverseAttrName {
    if (reverseObjectManager != null) {
      final RelatedObjectManager<P, T> reverseManager =
          reverseObjectManager!(constructor());
      return reverseManager.parentAttrName;
    }
    if (reverseCollectionManager != null) {
      final RelatedCollectionManager<P, T> reverseManager =
          reverseCollectionManager!(constructor());
      return reverseManager.parentAttrName;
    }
    throw APIProgrammingError(
      "Must provide at least one of reverseCollectionManager or reverseObjectManager when initializing ${T}.${parentAttrName}",
    );
  }

  @override
  Future<PageResult<T>> page({
    Map<String, Object?> query = const {},
    int? page,
    String? orderBy,
    int? limit,
    String? fulltext,
  }) async {
    if (cache != null) {
      return PageResult<T>(
        page: 1,
        pagesCount: 1,
        objects: cache!.value as List<T>,
        objectsCount: cache!.value.length,
        limit: cache!.value.length,
      );
    }
    return await super.page(
      query: query,
      page: page,
      orderBy: orderBy,
      limit: limit,
      fulltext: fulltext,
    );
  }

  @override
  String get collectionUrl {
    return '/${this.parentModelName}/${this.parentID}/${this.parentAttrName}';
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

  List<T>? getCached() {
    return cache?.value as List<T>;
  }
}

Future<void> prefetchRelatedCollectionForEach<T extends Model, R extends Model>(
  Iterable<T> objects,
  RelatedCollectionManager<R, T> Function(T) getRelatedManager, {
  int batchSize = 50,
  int pageSize = 100,
}) async {
  if (objects.isEmpty) {
    return;
  }
  RelatedCollectionManager<R, T> relatedManager =
      getRelatedManager(objects.first);
  if (relatedManager.reverseCollectionManager != null) {
    throw APIProgrammingError(
      ".prefetchRelatedCollection() on a many-to-many relation is not supported.",
    );
  }
  String reverseAttrName = relatedManager.reverseAttrName;
  List<R> relatedObjects = await prepareToPrefetch(
    objects: objects,
    relatedObjectConstructor: relatedManager.constructor,
    reverseAttrName: reverseAttrName,
    batchSize: batchSize,
    pageSize: pageSize,
  );
  Map<String, T> mainObjsByID = {for (var o in objects) o.id: o};
  String? foreignKeyName = relatedManager.reverseAttrName + "_id";
  for (var relObj in relatedObjects) {
    String? foreignKeyValue = relObj.props[foreignKeyName];
    String commonErrorMsg = "This looks like a bug on our end. "
        "We used the Collection API to look up ${R} objects that are related to the current PageResult<${T}>. "
        "The Collection API returned ${relatedObjects.length} ${R} object(s). "
        "Then, we look through each of the object to map them to the objects in the PageResult<${T}>. "
        "However, in one of the object ${R}(\"${relObj.id}\")'s JSON data, the foreign key \"${foreignKeyName}\" is \"${foreignKeyValue}\". "
        "This means that maybe the object should not have been returned by the Collection API of ${R} during the lookup, "
        "or that maybe the foreign key is wrong.";
    if (foreignKeyValue == null) {
      throw APIProgrammingError(commonErrorMsg);
    }
    T? mainObj = mainObjsByID[foreignKeyValue];
    if (mainObj == null) {
      throw APIProgrammingError(commonErrorMsg);
    }
    mainObj.cache[relatedManager.parentAttrName] ??=
        RelatedCollectionManagerCache<R>([]);
    RelatedCollectionManagerCache<R> cache =
        mainObj.cache[relatedManager.parentAttrName]!;
    cache.value.add(relObj);
  }
}
