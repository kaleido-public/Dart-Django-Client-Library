import '../django_client_framework.dart';

class ObjectManager<T extends Model> {
  late T _original;
  late T _updated;

  ObjectManager(T model) {
    this._original = model.clone() as T;
    this._updated = model.clone() as T;
  }

  @override
  bool operator ==(Object other) {
    if (other is ObjectManager) {
      return this.props == other.props;
    }
    return false;
  }

  @override
  int get hashCode => this.props.hashCode;

  String get modelName {
    return T.toString().toLowerCase();
  }

  String get objectUrl {
    return '/${this.modelName}/${this._original.id}';
  }

  Future<void> delete() async {
    return ajax.requestVoid('DELETE', this.objectUrl, {});
  }

  Future<void> refresh() async {
    var model = await ajax
        .requestDecodeFromModel(this._updated, 'GET', this.objectUrl, data: {});
    this._original = model.clone() as T;
    this._updated = model.clone() as T;
  }

  Future<void> save() async {
    Map<String, Object?> to_send = {};
    for (var key in this._updated.props.keys) {
      var newVal = this._updated.props[key];
      var oldVal = this._original.props[key];
      if (newVal != oldVal) {
        to_send[key] = newVal;
      }
    }

    var model = await ajax.requestDecodeFromModel(
      this._updated,
      'PATCH',
      this.objectUrl,
      data: to_send,
    );

    this._original = model.clone() as T;
    this._updated = model.clone() as T;
  }

  Future<ObjectManager<T>> update(data) async {
    var model = await ajax.requestDecodeFromModel(
      this._updated,
      'PATCH',
      this.objectUrl,
      data: data,
    );
    this._original = model.clone() as T;
    this._updated = model.clone() as T;
    return this;
  }

  T get props {
    return this._updated;
  }
}
