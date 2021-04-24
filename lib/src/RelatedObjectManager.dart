import './Model.dart';

class RelatedObjectManager<T extends Model, P extends Model> {
  int? parent_id;
  String? parent_key;
  String? parent_model_name;
}