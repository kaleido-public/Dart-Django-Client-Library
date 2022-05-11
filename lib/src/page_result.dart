import 'package:django_client_framework/django_client_framework.dart';

class PageResult<T extends Model> {
  int page = 0;
  int limit = 0;
  int objectsCount = 0;
  int pagesCount = 0;
  String? previous = "";
  String? next = "";
  List<T> objects = [];

  PageResult({
    required this.page,
    required this.limit,
    required this.objects,
    required this.objectsCount,
    required this.pagesCount,
    this.previous,
    this.next,
  });

  Iterable<ObjectManager<T>> get managers {
    return this.objects.map((val) => ObjectManager(val));
  }

  Future<void> prefetchRelatedObject<R extends Model>(
    RelatedObjectManager<R, T> Function(T) getRelatedManager, {
    int batchSize = 50,
    int pageSize = 100,
  }) {
    return prefetchRelatedObjectForEach(
      this.objects,
      getRelatedManager,
      batchSize: batchSize,
      pageSize: pageSize,
    );
  }

  Future<void> prefetchRelatedCollection<R extends Model>(
    RelatedCollectionManager<R, T> Function(T) getRelatedManager, {
    int batchSize = 50,
    int pageSize = 100,
  }) {
    return prefetchRelatedCollectionForEach(
      this.objects,
      getRelatedManager,
      batchSize: batchSize,
      pageSize: pageSize,
    );
  }
}
