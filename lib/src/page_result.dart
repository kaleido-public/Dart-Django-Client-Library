import 'model.dart';
import 'object_manager.dart';

class PageResult<T extends Model> {
  int? page = 0;
  int? limit = 0;
  int? objects_count = 0;
  int? pages_count = 0;
  String? previous = "";
  String? next = "";
  List<T> objects = [];

  Iterable<ObjectManager<T>> get managers {
    return this.objects.map((val) => ObjectManager(val));
  }
}
