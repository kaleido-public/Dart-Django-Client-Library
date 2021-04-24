import 'dart:mirrors';

abstract class Model {
  final _properties = new Map<String, Object>();
  
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
  abstract double id;
}