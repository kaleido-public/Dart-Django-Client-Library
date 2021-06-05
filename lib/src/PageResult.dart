import './Model.dart';
import './ObjectManager.dart';

class PageResult<T extends Model> {
  int? page = 0;
  int? limit = 0;
  int? total = 0;
  String? previous = "";
  String? next = "";
  List<T> objects = [];

  List<ObjectManager<T>> get managers {
    return this.objects.map((val) => new ObjectManager(val)).toList();
  }
}