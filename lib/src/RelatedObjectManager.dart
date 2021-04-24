import './Model.dart';
import './ItemCreatorType.dart';
import 'dart:mirrors';

class RelatedObjectManager<T extends Model, P extends Model> {
  int? parent_id;
  String? parent_key;
  String? parent_model_name;
  ItemCreator<T>? creator;

  RelatedObjectManager(ItemCreator<T> this.creator, P parent, String this.parent_key) {
    this.parent_id = parent.id;
    InstanceMirror parent_mirror = reflect(parent);
    this.parent_model_name = parent_mirror.type.reflectedType.toString().toLowerCase();
  }

  String get object_url {
    return '/${this.parent_model_name}/${this.parent_id}/${this.parent_key}';
  }
}