abstract class Model {
  int? get id;
  Model clone();
  Map<String, Object?> properties = {};
  Model fromJson(dynamic obj);
}