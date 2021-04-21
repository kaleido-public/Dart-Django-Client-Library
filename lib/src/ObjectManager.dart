import './Model.dart';
import './ItemCreatorType.dart';

class ObjectManager<T extends Model> {
  T? original;
  T? updated;
  ItemCreator<T>? creator;

  ObjectManager(T model, ItemCreator<T> this.creator) {
    
  }
}