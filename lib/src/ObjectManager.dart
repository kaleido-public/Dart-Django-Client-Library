import 'package:dart_django_client_library/src/Model.dart';
import 'ItemCreatorType.dart';
import 'package:http/http.dart';
import 'dart:mirrors';

class ObjectManager<T extends Model> {
  T? original;
  T? updated;
  ItemCreator<T>? creator;
  final _properties = new Map<String, Object>();

  @override
  noSuchMethod(Invocation invocation) {
    if (invocation.isAccessor) {
      // is getter or setter
      final realName = MirrorSystem.getName(invocation.memberName);
      if (invocation.isSetter) {
        // is setter
        // for setter realname looks like "prop=" so we remove the "="
        final name = realName.substring(0, realName.length - 1);
        if (_properties.containsKey(name)) {
          print("updating properties");
          // the current ObjectManager object contains the key
          _properties[name] = invocation.positionalArguments.first;
          return true;
        } else {
          print("updating this.updated");
          // the current ObjectManager does not contain the key, instead search and return this.updated
          InstanceMirror updated_mir = reflect(this.updated);
          updated_mir.setField(Symbol(name), invocation.positionalArguments.first);
          this.updated = updated_mir.reflectee;
          return true;
        }
        
      } else {
        // getter
        try {
          InstanceMirror updated_mir = reflect(this.updated);
          InstanceMirror res = updated_mir.getField(Symbol(realName));
          print("found " + realName + " in updated");
          return res.reflectee;
        } catch (e) {
          try {
              if (e.runtimeType.toString() == "NoSuchMethodError") {
              InstanceMirror original_mir = reflect(this.original);
              print("didn't find " + realName + " in updated. searching in original now");
              InstanceMirror res = original_mir.getField(Symbol(realName));
              print("found " + realName + " in updated.");
              return res.reflectee;
            }
          } catch (e) {
            if (e.runtimeType.toString() == "NoSuchMethodError") {
              print("didn't find " + realName + " in original. searching the current object manager now");
              return _properties[realName];
            }
          }
        }
        return null;
        // return _properties[realName];
      }
    }
    return super.noSuchMethod(invocation);
  }

  // TODO: clarify whether or not ObjectManager is supposed to inherit all the fields of 
  // @model when constructed
  ObjectManager(T model, ItemCreator<T> this.creator) {
    T original_temp = this.creator!();
    InstanceMirror original_instance = reflect(original_temp);
    InstanceMirror im = reflect(model);
    ClassMirror classMirror = reflectClass(T);
    for(var attribute in classMirror.declarations.values){
      if(attribute is VariableMirror){
        var attributeName = MirrorSystem.getName(attribute.simpleName);
        print(attributeName);
        Symbol attributeNameSymbol = Symbol(attributeName);
        print("printing: " + im.getField(attributeNameSymbol).reflectee.toString());
        original_instance.setField(attributeNameSymbol, im.getField(attributeNameSymbol).reflectee);
      }
    }
    this.original = original_instance.reflectee;

    this.updated = model;
  }
}