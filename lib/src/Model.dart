abstract class Model {
  dynamic get id;
  var props = Map<String, dynamic>();
  Model clone();
}

// obj.props.key //
// obj.updateProps.key = 2 // new
// obj.updated.({"key", 2})
