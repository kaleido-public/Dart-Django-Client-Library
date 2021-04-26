import './Activator.dart';
import './Model.dart';

T T_constructor<T extends Model>() {
  return Activator.createInstance(T);
}