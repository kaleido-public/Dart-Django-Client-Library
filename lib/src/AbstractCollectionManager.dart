import 'package:dart_django_client_library/src/AjaxDriver.dart';
import 'package:dart_django_client_library/src/PageResult.dart';

import './Model.dart';
import './ItemCreatorType.dart';
import './ObjectManager.dart';
import './CustomException.dart';

abstract class AbstractCollectionManager<T extends Model> {
  String get collection_url;
  ItemCreator<T> get creator;

  Future<PageResult<T>> page(obj) async {
    var query = {}; 
    var page = {};
    if (obj.containsKey('query')) {
      query = obj.query;
    }
    if (obj.containsKey('page')) {
      page = obj.page;
    }

    var to_send = query;
    page.forEach((key, val) => {
      to_send['_${key}'] = page[key]
    });

    return httpDriverImpl.request_decode_page(this.creator, "GET", this.collection_url, to_send);
  }

  Future<ObjectManager<T>> get(query) async {
    var page = await this.page({ 'query': query, 'page': { 'limit': 2 }});
    if (page.total != 1) {
      throw CustomException('.get() must receive exactly 1 object, but got ${page.total}');
    }

    return new ObjectManager<T>(page.objects[0]);
  }
}