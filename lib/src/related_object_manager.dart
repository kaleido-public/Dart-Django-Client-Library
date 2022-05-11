import 'dart:math';

import 'package:django_client_framework/django_client_framework.dart';

class RelatedObjectManagerCache<T> {
  T? value;
  RelatedObjectManagerCache(this.value);
}

/// For example, T is Brand (type of the related object), P is Product (type of
/// the parent object).
class RelatedObjectManager<T extends Model, P extends Model> {
  final String? parentID;
  final String parentAttrName;
  final String parentModelName;
  final Constructor<T> constructor;
  final RelatedObjectManagerCache<Model>? cache;
  final RelatedCollectionManager<P, T> Function(T)? reverseCollectionManager;
  final RelatedObjectManager<P, T> Function(T)? reverseObjectManager;

  RelatedObjectManager(
    this.constructor,
    P parent,
    this.parentAttrName,
    Map<String, dynamic> parentCacheMap, {
    this.reverseCollectionManager,
    this.reverseObjectManager,
  })  : cache = parentCacheMap[parentAttrName],
        parentModelName = P.toString().toLowerCase(),
        parentID = parent.id;

  String get objectUrl {
    return '/${this.parentModelName}/${this.parentID}/${this.parentAttrName}';
  }

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
      "Must provide at least one of reverseCollectionManager or reverseObjectManager when initializing ${T}.",
    );
  }

  Constructor<P> get parentCreator {
    if (reverseObjectManager != null) {
      return reverseObjectManager!(constructor()).constructor;
    } else if (reverseCollectionManager != null) {
      return reverseCollectionManager!(constructor()).constructor;
    }
    throw APIProgrammingError(
      "Must provide at least one of reverseCollectionManager or reverseObjectManager when initializing ${T}.",
    );
  }

  Future<ObjectManager<T>?> get() async {
    if (getCached() != null) {
      return getCached();
    }
    try {
      var model =
          await ajax.requestDecode(this.constructor, 'GET', this.objectUrl);
      return ObjectManager<T>(model);
    } on APINotFoundError {
      return null;
    }
  }

  ObjectManager<T>? getCached() {
    if (cache != null && cache!.value != null) {
      return ObjectManager<T>(cache!.value! as T);
    }
    return null;
  }

  Future<void> set(T val) async {
    if (cache != null) {
      cache!.value = val;
    }
    return ajax.requestVoid('PATCH', this.objectUrl, val.id);
  }
}

Future<List<R>> prepareToPrefetch<T extends Model, R extends Model>({
  required Iterable<T> objects,
  required Constructor<R> relatedObjectConstructor,
  required String reverseAttrName,
  int batchSize = 50,
  int pageSize = 100,
}) async {
  if (batchSize > 50) {
    throw APIProgrammingError("batchSize must be <= 50");
  }
  List<String> idList = [for (var o in objects) o.id];
  List<List<String>> idBatches = [];
  for (int i = 0; i < idList.length; i += batchSize) {
    idBatches.add(idList.sublist(i, min(i + batchSize, idList.length)));
  }
  String queryKey = reverseAttrName + "__in";
  List<R> relatedObjects = [];
  await Future.forEach(idBatches, (List<String> batch) async {
    PageResult<R> result =
        await CollectionManager(relatedObjectConstructor).page(
      query: {queryKey: batch},
      limit: pageSize,
    );
    relatedObjects.addAll(result.objects);
    if (result.pagesCount > 5) {
      AjaxDriverImpl.defaultLogger?.e(
        "During prefetchRelated, we need to look up the ${R} Collection with ${queryKey}. "
        "However, the lookup returned too many pages ${result.pagesCount}. This can make the query very slow. "
        "You should consider a different approach other than prefetchRelated.",
      );
    }
    List<PageResult<R>> resultOfNextPages = await Future.wait([
      for (var nextPage = 2; nextPage <= result.pagesCount; nextPage++)
        CollectionManager(relatedObjectConstructor).page(
          page: nextPage,
          query: {queryKey: batch},
          limit: pageSize,
        )
    ]);
    for (var next in resultOfNextPages) {
      relatedObjects.addAll(next.objects);
    }
  });
  return relatedObjects;
}

Future<void> prefetchRelatedObjectForEach<T extends Model, R extends Model>(
  Iterable<T> objects,
  RelatedObjectManager<R, T> Function(T) getRelatedManager, {
  int batchSize = 50,
  int pageSize = 100,
}) async {
  if (objects.isEmpty) {
    return;
  }
  RelatedObjectManager<R, T> relatedManager = getRelatedManager(objects.first);
  String reverseAttrName = relatedManager.reverseAttrName;
  List<R> relatedObjects = await prepareToPrefetch(
    objects: objects,
    relatedObjectConstructor: relatedManager.constructor,
    reverseAttrName: reverseAttrName,
    batchSize: batchSize,
    pageSize: pageSize,
  );
  // collection. Next, we map each related object to the corresponding main
  // object.
  Map<String, R> relObjsByID = {for (var r in relatedObjects) r.id: r};
  String? foreignKeyName = relatedManager.parentAttrName + "_id";
  for (var mainObj in objects) {
    String? foreignKeyValue = mainObj.props[foreignKeyName];
    String commonErrorMsg = "This looks like a bug on our end. "
        "We used the Collection API to look up ${R} objects that are related to the current PageResult<${T}>. "
        "The Collection API returned ${relatedObjects.length} ${R} object(s). "
        "Then, we look through each of the object in the PageResult<${T}> to map them to the ${R} objects. "
        "However, in one of the object ${T}(\"${mainObj.id}\")'s JSON data, the foreign key \"${foreignKeyName}\" is \"${foreignKeyValue}\". "
        "This means that maybe the object should not have been returned by the Collection API of ${R} during the lookup, "
        "or that maybe the foreign key is wrong.";
    if (foreignKeyValue == null) {
      throw APIProgrammingError(commonErrorMsg);
    }
    R? relObj = relObjsByID[foreignKeyValue];
    if (relObj == null) {
      throw APIProgrammingError(commonErrorMsg);
    }
    if (mainObj.cache[relatedManager.parentAttrName] == null) {
      mainObj.cache[relatedManager.parentAttrName] =
          RelatedObjectManagerCache(relObj);
    } else {
      mainObj.cache[relatedManager.parentAttrName]!.value = relObj;
    }
  }
}
