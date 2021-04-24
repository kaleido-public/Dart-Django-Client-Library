import './Model.dart';
import './ItemCreatorType.dart';
import './AbstractCollectionManager.dart';

class CollectionManager<T extends Model> extends AbstractCollectionManager {
  ItemCreator<T> creator;

  CollectionManager(ItemCreator<T> this.creator) {}

  String get collection_url {
    return "/${T.toString().toLowerCase()}";
  }
}