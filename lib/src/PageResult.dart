import './Model.dart';
import './ObjectManager.dart';
import './Activator.dart';
import 'dart:mirrors';

class PageResult<T extends Model> {
  final _properties = new Map<String, Object>();
  int page = 0;
  int limit = 0;
  int total = 0;
  String previous = "";
  String next = "";
  List<T> objects = [];

  noSuchMethod(Invocation invocation) {
    if (invocation.isAccessor) {
      final realName = MirrorSystem.getName(invocation.memberName);
      if (invocation.isSetter) {
        print("updating in model superclass");
        // for setter realname looks like "prop=" so we remove the "="
        final name = realName.substring(0, realName.length - 1);
        _properties[name] = invocation.positionalArguments.first;
        return;
      } else {
        print("getting from model superclass");
        return _properties[realName];
      }
    }
    return super.noSuchMethod(invocation);
  }

  T T_constructor() {
    return Activator.createInstance(T);
  }

  List<ObjectManager<T>> get managers {
    return this.objects.map((val) => new ObjectManager(val)).toList();
  }
}