abstract class Model {
  String get id;
  Map<String, dynamic> props = {};
  Model clone();

  @override
  bool operator ==(Object other) {
    if (other is Model && other.runtimeType == this.runtimeType) {
      return this.id == other.id;
    } else {
      return false;
    }
  }

  @override
  int get hashCode => this.id.hashCode;
}

// obj.props.key //
// obj.updateProps.key = 2 // new
// obj.props.({"key", 2})
