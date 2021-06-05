import 'package:dart_django_client_library/src/AjaxDriver.dart';
import 'package:dart_django_client_library/src/PageResult.dart';

import './Model.dart';
import './ItemCreatorType.dart';
import './ObjectManager.dart';
import './CustomException.dart';

abstract class AbstractCollectionManager<T extends Model> {
  String get collection_url;
  ItemCreator<T> get creator;

  Future<PageResult<T>> page(Map<String, dynamic> obj) async {
    Map<String, dynamic> query = {}; 
    Map<String, dynamic> page = {};
    if (obj.containsKey('query')) {
      query = obj['query'] as Map<String, dynamic>;
    }
    if (obj.containsKey('page')) {
      page = obj['page'] as Map<String, dynamic>;
    }

    
    Map<String, dynamic> to_send = Map<String, dynamic>();
    query.forEach((key, val) => {
      if (val == null) {
        key += '__isnull',
        val = true
      },
      to_send[key] = val
    });

    page.forEach((key, val) => {
      to_send['_${key}'] = page[key]
    });

    return httpDriverImpl.request_decode_page(this.creator, "GET", this.collection_url, to_send);
  }

  Future<ObjectManager<T>> get(Map<String, dynamic> query) async {
    PageResult<T> page = await this.page({ 'query': query, 'page': { 'limit': 2 }});
    if (page.total != 1) {
      throw CustomException('.get() must receive exactly 1 object, but got ${page.total}');
    }

    return new ObjectManager<T>(page.objects[0]);
  }
}