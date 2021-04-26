import './Model.dart';
import './ItemCreatorType.dart';
import './AbstractCollectionManager.dart';
import './ObjectManager.dart';
import './AjaxDriver.dart';
import './PageResult.dart';
import './CustomException.dart';

class CollectionManager<T extends Model> extends AbstractCollectionManager {
  ItemCreator<T> creator;

  CollectionManager(ItemCreator<T> this.creator) {}

  String get collection_url {
    return "/${T.toString().toLowerCase()}";
  }

  Future<ObjectManager<T>> create(data) async {
    var object = await httpDriverImpl.request_decode(this.creator, "POST", this.collection_url, data: data);
    return new ObjectManager<T>(object, this.creator);
  }

  Future<ObjectManager<T>> get_or_create(obj) async {
    var query = {}, defaults = {};
    if (obj.containsKey('query')) query = obj.query;
    if (obj.containsKey('defaults')) defaults = obj.defaults;

    PageResult<T> page = await this.page({ 'query': query, 'page': { 'limit': 2 }}) as PageResult<T>;
    if (page.total == 0) {
      var create_input_obj = {...query, ...defaults};
      return this.create(create_input_obj);
    } else if (page.total == 1) {
      return new ObjectManager<T>(page.objects[0], this.creator);
    } else {
      throw CustomException('.get() must receive exactly one object, but got ${page.total}');
    }
  }

  Future<ObjectManager<T>> update_or_create(obj) async {
    var query = {}, defaults = {};
    if (obj.containsKey('query')) query = obj.query;
    if (obj.containsKey('defaults')) defaults = obj.defaults;

    PageResult<T> page = await this.page({ 'query': query, 'page': { 'limit': 2 }}) as PageResult<T>;
    if (page.total == 0) {
      return this.create({...query, ...defaults});
    } else if (page.total == 1) {
      var manager = new ObjectManager<T>(page.objects[0], this.creator);
      manager.update(defaults);
      return manager;
    } else {
      throw CustomException('.get() must receive exactly 1 object, but got ${page.total}');
    }
  }
}