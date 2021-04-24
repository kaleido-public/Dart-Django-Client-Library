import './Model.dart';
import './ItemCreatorType.dart';

abstract class AbstractCollectionManager<T extends Model> {
  String get collection_url;
  ItemCreator<T> get creator;
}