import './Model.dart';
import './ItemCreatorType.dart';
import './AbstractCollectionManager.dart';
import './ObjectManager.dart';
import './AjaxDriver.dart';
import './PageResult.dart';
import './CustomException.dart';

class CollectionManager<T extends Model> extends AbstractCollectionManager<T> {
  ItemCreator<T> creator;

  CollectionManager(ItemCreator<T> this.creator) {}

  String get collection_url {
    return "/${T.toString().toLowerCase()}";
  }

  Future<ObjectManager<T>> create(data) async {
    var object = await httpDriverImpl.request_decode(this.creator, "POST", this.collection_url, data: data);
    return new ObjectManager<T>(object);
  }

  Future<ObjectManager<T>> get_or_create(obj) async {
    Map<String, dynamic> query = {}; 
    Map<String, dynamic> defaults = {};
    if (obj.containsKey('query')) {
      query = obj['query'] as Map<String, dynamic>;
    }
    if (obj.containsKey('page')) {
      defaults = obj['defaults'] as Map<String, dynamic>;
    }

    PageResult<T> page = await this.page({ 'query': query, 'page': { 'limit': 2 }}) as PageResult<T>;
    if (page.total == 0) {
      return this.create({...defaults, ...query});
    } else if (page.total == 1) {
      return new ObjectManager<T>(page.objects[0]);
    } else {
      throw CustomException('.get() must receive exactly one object, but got ${page.total}');
    }
  }

  Future<ObjectManager<T>> update_or_create(obj) async {
    Map<String, dynamic> query = {}; 
    Map<String, dynamic> defaults = {};
    if (obj.containsKey('query')) {
      query = obj['query'] as Map<String, dynamic>;
    }
    if (obj.containsKey('defaults')) {
      defaults = obj['defaults'] as Map<String, dynamic>;
    }

    PageResult<T> page = await this.page({ 'query': query, 'page': { 'limit': 2 }}) as PageResult<T>;
    if (page.total == 0) {
      return this.create({...defaults, ...query});
    } else if (page.total == 1) {
      var manager = new ObjectManager<T>(page.objects[0]);
      return manager.update(defaults);
    } else {
      throw CustomException('.get() must receive exactly 1 object, but got ${page.total}');
    }
  }
}