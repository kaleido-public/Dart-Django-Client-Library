import './Model.dart';
import './ObjectManager.dart';
import './Activator.dart';

class PageResult<T extends Model> {
  int page = 0;
  int limit = 0;
  int total = 0;
  String previous = "";
  String next = "";
  List<T> objects = [];

  T T_constructor() {
    return Activator.createInstance(T);
  }

  List<ObjectManager<T>> get managers {
    return this.objects.map((val) => new ObjectManager(val, T_constructor)).toList();
  }
}