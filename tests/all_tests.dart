// All tests in the package
import 'package:test/test.dart';
import '../lib/main.dart';
import 'models.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:logging/logging.dart' as logging;

void main() {
  logging.hierarchicalLoggingEnabled = true;
  AjaxDriverLogger.level = logging.Level.ALL;
  logging.Logger.root.onRecord.listen((record) {
    print('${record.level.name}: ${record.time}: ${record.message}');
  });

  setUp(() async {
    Ajax.url_prefix = "";
    Ajax.host = "win";
    Ajax.port = 8001;
    Uri.http("${Ajax.host}:${Ajax.port}", Ajax.url_prefix + '/subapp/clear');
  });

  // COLLECTION MANAGER TESTS
  test('test get object none should fail', () async {
    try {
      await Product.objects.get({});
      fail("shouldn't have reached here");
    } catch (error) {
      expect(
        error.toString(),
        '.get() must receive exactly 1 object, but got 0',
      );
    }
  });

  test('test get object one should pass', () async {
    await Product.objects.create({"barcode": "hello"});
    var om = await Product.objects.get({"barcode": "hello"});
    expect(om.updated.barcode, 'hello');
    expect(om.updated.id, 1);
  });

  test('test get object more than one should fail', () async {
    await Product.objects.create({"barcode": "hello"});
    await Product.objects.create({"barcode": "hello"});
    try {
      await Product.objects.get({});
    } catch (error) {
      expect(
          error.toString(), '.get() must receive exactly 1 object, but got 2');
    }
  });

  test('test get object with array params', () async {
    await Product.objects.create({"barcode": "osu"});
    await Product.objects.create({"barcode": "goodbye"});
    var om = await Product.objects.get({
      "barcode__in": ["hello", "goodbye"]
    });
    expect(om.updated.barcode, 'goodbye');
    expect(om.updated.id, 2);
  });

  test('test get object with params', () async {
    await Product.objects.create({"barcode": "osu"});
    var om = await Product.objects.get({"barcode__exact": "osu"});
    expect(om.updated.barcode, 'osu');
    expect(om.updated.id, 1);
  });

  test('test page default', () async {
    PageResult<Product> pr = await Product.objects.page({});
    expect(pr.limit, 50);
    expect(pr.objects_count, 0);
    expect(pr.page, 1);
  });

  test('test page default with products', () async {
    for (int i = 0; i < 51; i++) {
      await Product.objects.create({"barcode": "product ${i + 1}"});
    }

    PageResult<Product> pr = await Product.objects.page({});
    expect(pr.limit, 50);
    expect(pr.objects_count, 51);
    expect(pr.page, 1);
  });

  test('test page search by null', () async {
    for (int i = 0; i < 10; i++) {
      if (i < 8)
        await Product.objects.create({"barcode": null});
      else
        await Product.objects.create({"barcode": "sup"});
    }

    PageResult<Product> pr = await Product.objects.page({
      'query': {'barcode': null}
    });
    expect(pr.limit, 50);
    expect(pr.objects_count, 8);
    expect(pr.page, 1);
    expect(pr.objects[0].id, 1);
  });

  test('test page page 1', () async {
    for (int i = 0; i < 51; i++) {
      await Product.objects.create({"barcode": "product ${i + 1}"});
    }

    PageResult<Product> pr = await Product.objects.page({});
    expect(pr.limit, 50);
    expect(pr.objects_count, 51);
    expect(pr.page, 1);
    expect(pr.objects.length, 50);
    expect(pr.objects[0].id, 1);
    expect(pr.objects[0].barcode, "product 1");
    expect(pr.objects[49].id, 50);
    expect(pr.objects[49].barcode, "product 50");
  });

  test('test page page 2', () async {
    for (int i = 0; i < 51; i++) {
      await Product.objects.create({"barcode": "product ${i + 1}"});
    }

    PageResult<Product> pr = await Product.objects.page({
      "page": {"page": 2}
    });
    expect(pr.limit, 50);
    expect(pr.objects_count, 51);
    expect(pr.page, 2);
    expect(pr.objects.length, 1);
    expect(pr.objects[0].id, 51);
    expect(pr.objects[0].barcode, "product 51");
  });

  test('test page page and limit', () async {
    for (int i = 0; i < 15; i++) {
      await Product.objects.create({"barcode": "product ${i + 1}"});
    }

    PageResult<Product> pr = await Product.objects.page({
      "page": {"page": 2, "limit": 5}
    });
    expect(pr.limit, 5);
    expect(pr.page, 2);
    expect(pr.objects_count, 15);
    expect(pr.objects.length, 5);
    expect(pr.objects[0].id, 6);
    expect(pr.objects[0].barcode, "product 6");
  });

  test('test page limit no page', () async {
    for (int i = 0; i < 10; i++) {
      await Product.objects.create({"barcode": "product ${i + 1}"});
    }

    PageResult<Product> pr = await Product.objects.page({
      "page": {"limit": 5}
    });
    expect(pr.limit, 5);
    expect(pr.page, 1);
    expect(pr.objects_count, 10);
    expect(pr.objects.length, 5);
    expect(pr.objects[0].id, 1);
    expect(pr.objects[0].barcode, "product 1");
  });

  test('test page query', () async {
    for (int i = 0; i < 10; i++) {
      await Product.objects.create({"barcode": "product ${i + 1}"});
    }

    PageResult<Product> pr = await Product.objects.page({
      "query": {
        "barcode__in": ["product 1", "product 3", "product 5"]
      }
    });
    expect(pr.limit, 50);
    expect(pr.page, 1);
    expect(pr.objects_count, 3);
    expect(pr.objects.length, 3);
    expect(pr.objects[1].id, 3);
    expect(pr.objects[1].barcode, "product 3");
  });

  test('test page query with page', () async {
    for (int i = 0; i < 10; i++) {
      await Product.objects.create({"barcode": "product ${i + 1}"});
    }

    PageResult<Product> pr = await Product.objects.page({
      "query": {
        "id__in": [3, 5],
        "barcode__in": ["product 1", "product 3", "product 5"]
      },
      "page": {"limit": 1, "page": 2}
    });
    expect(pr.limit, 1);
    expect(pr.page, 2);
    expect(pr.objects_count, 2);
    expect(pr.objects.length, 1);
    expect(pr.objects[0].id, 5);
    expect(pr.objects[0].barcode, "product 5");
  });

  test('test page query with page', () async {
    for (int i = 0; i < 10; i++) {
      await Product.objects.create({"barcode": "product ${i + 1}"});
    }

    PageResult<Product> pr = await Product.objects.page({
      "query": {
        "id__in": [3, 5],
        "barcode__in": ["product 1", "product 3", "product 5"]
      },
      "page": {"limit": 1, "page": 2}
    });
    expect(pr.limit, 1);
    expect(pr.page, 2);
    expect(pr.objects_count, 2);
    expect(pr.objects.length, 1);
    expect(pr.objects[0].id, 5);
    expect(pr.objects[0].barcode, "product 5");
  });

  test('test page query order by', () async {
    for (int i = 0; i < 10; i++) {
      await Product.objects.create({"barcode": "shoe ${i + 1}"});
    }

    PageResult<Product> pr = await Product.objects.page({
      "query": {
        "barcode__in": ["shoe 1", "shoe 3", "shoe 5"]
      },
      "page": {"order_by": "-barcode"}
    });
    expect(pr.limit, 50);
    expect(pr.page, 1);
    expect(pr.objects_count, 3);
    expect(pr.objects.length, 3);
    expect(pr.objects[0].id, 5);
    expect(pr.objects[0].barcode, "shoe 5");
    expect(pr.objects[2].id, 1);
    expect(pr.objects[2].barcode, "shoe 1");
  });

  test('test page query order by ver 2', () async {
    for (int i = 0; i < 10; i++) {
      await Product.objects.create({"barcode": "product ${i + 1}"});
    }

    await Product.objects.create({"barcode": "product 4"});

    PageResult<Product> pr = await Product.objects.page({
      "query": {
        "barcode__in": ["product 1", "product 4", "product 5"]
      },
      "page": {"order_by": "-barcode,-id"}
    });
    expect(pr.limit, 50);
    expect(pr.page, 1);
    expect(pr.objects_count, 4);
    expect(pr.objects.length, 4);
    expect(pr.objects[0].id, 5);
    expect(pr.objects[0].barcode, "product 5");
    expect(pr.objects[1].id, 11);
    expect(pr.objects[1].barcode, "product 4");
    expect(pr.objects[2].id, 4);
    expect(pr.objects[2].barcode, "product 4");
  });

  test('test page typo', () async {
    for (int i = 0; i < 10; i++) {
      await Product.objects.create({"barcode": "product ${i + 1}"});
    }
    try {
      PageResult<Product> pr = await Product.objects.page({
        "query": {
          "barcode___in": ["product 1", "product 4", "product 5"]
        },
        "page": {"order_by": "-barcode,-id"}
      });
    } catch (error) {
      expect(error.toString(),
          'Server did not return objects. Response: {"non_field_error": "Unsupported lookup \'_in\' for CharField or join on the field not permitted, perhaps you meant in?"}');
    }
  });

  test('test create object', () async {
    var om = await Product.objects.create({"barcode": "hello"});
    expect(om.updated.barcode, "hello");
  });

  test('test create object with null key', () async {
    var om = await Product.objects.create({"barcode": null});
    expect(om.updated.barcode, null);
    expect(om.updated.id, 1);
  });

  test('test create object with null key should fail ', () async {
    CollectionManager<Brand> cm = CollectionManager(() => new Brand());
    var om = await Brand.objects.create({"name": null});
    expect(om.updated.name, 'This field may not be null.');
    expect(om.updated.id, null);

    om = await Brand.objects.create({"name": ''});
    expect(om.updated.name, '');
    expect(om.updated.id, 1);
  });

  test('test create object with invalid key', () async {
    var om = await Product.objects.create({"barasdfcode": "hello"});
    expect(om.updated.barcode, null);
  });

  test('test create object with invalid key v2', () async {
    var om =
        await Product.objects.create({"barcode": "hello", "goodbye": "osu"});
    expect(om.updated.barcode, null);
    expect(om.updated.id, null);
  });

  test('test get or create', () async {
    var om = await Product.objects.get_or_create({
      "query": {"barcode": "product 1"},
      "defaults": {"brand_id": null}
    });
    expect(om.updated.barcode, "product 1");
    expect(om.updated.id, 1);
  });

  test('test get or create v2', () async {
    var om = await Product.objects.get_or_create({
      "query": {"barcode": "product 1"}
    });
    expect(om.updated.barcode, "product 1");
    expect(om.updated.id, 1);
  });

  test('test get or create v3', () async {
    await Product.objects.create({"barcode": "product 1"});
    await Product.objects.create({"barcode": "product 2"});
    var om = await Product.objects.get_or_create({
      "query": {"barcode": "product 2"},
      "defaults": {"brand_id": null}
    });
    expect(om.updated.barcode, "product 2");
    expect(om.updated.id, 2);
  });

  test('test update or create', () async {
    var om = await Product.objects.update_or_create({
      "query": {"barcode": "product 2"},
      "defaults": {"barcode": "product 3"}
    });
    expect(om.updated.barcode, "product 2");
    expect(om.updated.id, 1);
  });

  test('test update or create v2', () async {
    await Product.objects.create({"barcode": "product 2"});
    var om = await Product.objects.update_or_create({
      "query": {"barcode": "product 2"},
      "defaults": {"barcode": "product 3"}
    });
    expect(om.updated.barcode, "product 3");
    expect(om.updated.id, 1);
  });

  // OBJECT MANAGER TESTS
  test('test refresh', () async {
    var om = await Product.objects.create({"barcode": "product 1"});
    var uri = Uri.http("localhost:8000", "product/1");
    // var headers = {'content-type': 'application/json; charset=UTF-8'};
    var data = {"barcode": "product 2"};
    await http.patch(uri, body: data);
    expect(om.updated.barcode, "product 1");
    await om.refresh();
    expect(om.updated.barcode, "product 2");
  });

  test('test refresh without updates', () async {
    var om = await Product.objects.create({"barcode": "product 1"});
    await om.refresh();
    expect(om.updated.barcode, "product 1");
  });

  test('test save', () async {
    var om = await Product.objects.create({"barcode": "product 1"});
    om.updated.barcode = "osu!";
    ObjectManager<Product> om1 =
        await Product.objects.get({"barcode": "product 1"});
    expect(om1.updated.barcode, "product 1");
    await om.save();
    try {
      om1 = await Product.objects.get({"barcode": "product 1"});
    } catch (error) {
      expect(
          error.toString(), ".get() must receive exactly 1 object, but got 0");
    }
    om1 = await Product.objects.get({"barcode": "osu!"});
    expect(om1.updated.id, 1);
  });

  test('test update', () async {
    var om = await Product.objects.create({"barcode": "product 1"});
    await om.update({"barcode": "osu!"});
    expect(om.updated.barcode, "osu!");
    ObjectManager<Product> om1 = await Product.objects.get({"barcode": "osu!"});
    expect(om1.updated.id, 1);
  });

  test('test update to empty', () async {
    var om = await Product.objects.create({"barcode": "product 1"});
    await om.update({"barcode": ""});
    expect(om.updated.barcode, '');
    ObjectManager<Product> om1 = await Product.objects.get({"id": 1});
    expect(om1.updated.barcode, '');
  });

  test('test update to null', () async {
    var om = await Product.objects.create({"barcode": "product 1"});
    await om.update({"barcode": null});
    expect(om.updated.barcode, null);
    ObjectManager<Product> om1 = await Product.objects.get({"id": 1});
    expect(om1.updated.barcode, null);
  });

  test('test update bad key', () async {
    var om = await Product.objects.create({"barcode": "product 1"});
    await om.update({"barcodeafaf": "osu!"});
    expect(om.updated.barcode, "product 1");
    ObjectManager<Product> om1 =
        await Product.objects.get({"barcode": "product 1"});
    expect(om1.updated.id, 1);
  });

  test('test delete', () async {
    var om = await Product.objects.create({"barcode": "product 1"});
    await om.delete();
    try {
      await Product.objects.get({"barcode": "product 1"});
      fail('should not have got here');
    } catch (error) {
      expect(
          error.toString(), ".get() must receive exactly 1 object, but got 0");
    }
  });

  test('test modify using properties to blank and null', () async {
    var om = await Product.objects.create({"barcode": "product 1"});
    om.updated.barcode = '';
    await om.save();
    ObjectManager<Product> find = await Product.objects.get({"id": 1});
    expect(find.updated.barcode, '');
    om.updated.barcode = null;
    await om.save();
    find = await Product.objects.get({"id": 1});
    expect(find.updated.barcode, null);
  });

  test('test modify properties', () async {
    var om = await Brand.objects.create({"name": "nike"});
    om.updated.name = "adidas";
    await om.save();
    var om1 = await Brand.objects.get({"id": 1});
    expect(om1.updated.name, "adidas");
  });

  test('test modify foreign key', () async {
    ObjectManager<Product> pom =
        await Product.objects.create({"barcode": "product 1"});

    pom.updated.brand_id = 1;
    await pom.save();

    ObjectManager<Product> pom2 = await Product.objects.get({"brand_id": 1});
    expect(pom2.updated.barcode, "product 1");
  });

  test('test constructor pass in object', () async {
    for (int i = 0; i < 3; i++) {
      await Product.objects.create({"barcode": "pen ${i + 1}"});
    }

    PageResult<Product> ppr = await Product.objects.page({
      'query': {
        'id__in': [1, 2, 3]
      }
    });
    ObjectManager<Product> objm = ObjectManager<Product>(ppr.objects[0]);
    expect(objm.updated.barcode, "pen 1");
    expect(objm.updated.id, 1);
    expect(objm.updated.brand_id, null);
  });

  // RELATED COLLECTION MANAGER TESTS

  test('test page empty', () async {
    var om = await Brand.objects.create({"name": "nike"});
    var products = await om.updated.products.page({
      "query": {"barcode": "product 1"}
    });
    expect(products.limit, 50);
    expect(products.page, 1);
    expect(products.objects_count, 0);
    expect(products.objects.length, 0);
  });

  test('test page with results', () async {
    CollectionManager<Brand> cmb = new CollectionManager(() => new Brand());
    CollectionManager<Product> cmp = new CollectionManager(() => new Product());
    var om = await cmb.create({"name": "nike"});

    List<Product> lst = [];
    for (int i = 0; i < 10; i++) {
      ObjectManager<Product> p =
          await cmp.create({"barcode": "product ${i + 1}"});
      lst.add(p.updated);
    }

    await om.updated.products.add(lst);

    var products = await om.updated.products.page({
      "query": {
        "barcode__in": ["product 1", "product 5", "product 10"]
      }
    });
    expect(products.limit, 50);
    expect(products.page, 1);
    expect(products.objects_count, 3);
    expect(products.objects.length, 3);
    expect(products.objects[0].barcode, "product 1");
  });

  test('test page with results and pagination', () async {
    CollectionManager<Brand> cmb = new CollectionManager(() => new Brand());
    CollectionManager<Product> cmp = new CollectionManager(() => new Product());
    var om = await cmb.create({"name": "nike"});

    List<Product> lst = [];
    for (int i = 0; i < 10; i++) {
      ObjectManager<Product> p =
          await cmp.create({"barcode": "product ${i + 1}"});
      lst.add(p.updated);
    }

    await om.updated.products.add(lst);

    var products = await om.updated.products.page({
      "page": {"limit": 5, "page": 2, "order_by": "-barcode"}
    });
    expect(products.limit, 5);
    expect(products.page, 2);
    expect(products.objects_count, 10);
    expect(products.objects.length, 5);
    expect(products.objects[0].barcode, "product 4");
  });

  test('test get with no result', () async {
    CollectionManager<Brand> cmb = new CollectionManager(() => new Brand());
    var om = await cmb.create({"name": "nike"});
    try {
      await om.updated.products.get({});
      fail("shouldn't have got here");
    } catch (error) {
      expect(
          error.toString(), ".get() must receive exactly 1 object, but got 0");
    }
  });

  test('test get with one result', () async {
    var bom = await Brand.objects.create({"name": "nike"});

    for (int i = 0; i < 10; i++) {
      await Product.objects.create({"barcode": "shoe ${i + 1}"});
    }

    // posting objects to relation
    Uri uri = Uri.http("localhost:8000", "/brand/1/products");
    var data = jsonEncode([5]);
    await http
        .post(uri, body: data, headers: {'content-type': 'application/json'});

    ObjectManager<Product> related_product = await bom.updated.products.get({});
    expect(related_product.updated.id, 5);
    expect(related_product.updated.barcode, "shoe 5");
  });

  test('test get with multiple results', () async {
    var bom = await Brand.objects.create({"name": "nike"});

    for (int i = 0; i < 10; i++) {
      await Product.objects.create({"barcode": "shoe ${i + 1}"});
    }

    // posting objects to relation
    Uri uri = Uri.http("localhost:8000", "/brand/1/products");
    var data = jsonEncode([5, 6]);
    await http
        .post(uri, body: data, headers: {'content-type': 'application/json'});
    try {
      ObjectManager<Product> related_product =
          await bom.updated.products.get({});
      fail("shouldn't have got here");
    } catch (error) {
      expect(
          error.toString(), ".get() must receive exactly 1 object, but got 2");
    }
  });

  test('test add ids', () async {
    var bom = await Brand.objects.create({"name": "nike"});
    for (int i = 0; i < 10; i++)
      await Product.objects.create({"barcode": "sneaker ${i + 1}"});

    await bom.updated.products.add_ids([2, 4, 6, 8]);
    var product_lst = await bom.updated.products.page({});
    expect(product_lst.objects_count, 4);
    expect(product_lst.objects.length, 4);
    expect(product_lst.objects[3].barcode, "sneaker 8");
  });

  test('test add ids some invalid', () async {
    var bom = await Brand.objects.create({"name": "nike"});
    for (int i = 0; i < 10; i++)
      await Product.objects.create({"barcode": "sneaker ${i + 1}"});

    bom.updated.products.add_ids([10, 15]);
    PageResult<Product> pr = await bom.updated.products.page({});
    expect(pr.objects_count, 0);
    expect(pr.objects.length, 0);
  });

  test('test set ids', () async {
    var bom = await Brand.objects.create({"name": "nike"});
    for (int i = 0; i < 10; i++)
      await Product.objects.create({"barcode": "sneaker ${i + 1}"});

    await bom.updated.products.add_ids([1, 2, 3, 4, 5, 6, 7, 8, 9, 10]);
    PageResult<Product> pr = await bom.updated.products.page({});
    expect(pr.objects_count, 10);
    expect(pr.objects.length, 10);
    expect(pr.objects[9].barcode, "sneaker 10");

    await bom.updated.products.set_ids([7]);
    PageResult<Product> pr1 = await bom.updated.products.page({});
    expect(pr1.objects_count, 1);
    expect(pr1.objects.length, 1);
    expect(pr1.objects[0].barcode, "sneaker 7");
  });

  test('test set ids to empty', () async {
    var bom = await Brand.objects.create({"name": "nike"});
    for (int i = 0; i < 10; i++)
      await Product.objects.create({"barcode": "sneaker ${i + 1}"});

    await bom.updated.products.add_ids([1, 2, 3, 4, 5, 6, 7, 8, 9, 10]);
    PageResult<Product> pr = await bom.updated.products.page({});
    expect(pr.objects_count, 10);
    expect(pr.objects.length, 10);
    expect(pr.objects[9].barcode, "sneaker 10");

    await bom.updated.products.set_ids([]);
    PageResult<Product> pr1 = await bom.updated.products.page({});
    expect(pr1.objects_count, 0);
    expect(pr1.objects.length, 0);
  });

  test('test set ids to invalid', () async {
    var bom = await Brand.objects.create({"name": "nike"});
    for (int i = 0; i < 10; i++)
      await Product.objects.create({"barcode": "sneaker ${i + 1}"});

    await bom.updated.products.add_ids([1, 2, 3, 4, 5, 6, 7, 8, 9, 10]);
    PageResult<Product> pr = await bom.updated.products.page({});
    expect(pr.objects_count, 10);
    expect(pr.objects.length, 10);
    expect(pr.objects[9].barcode, "sneaker 10");

    await bom.updated.products.set_ids([8, 7, 10, 30]);
    PageResult<Product> pr1 = await bom.updated.products.page({});
    expect(pr1.objects_count, 10);
    expect(pr1.objects.length, 10);
  });

  test('test remove ids', () async {
    var bom = await Brand.objects.create({"name": "nike"});
    for (int i = 0; i < 10; i++)
      await Product.objects.create({"barcode": "sneaker ${i + 1}"});

    await bom.updated.products.add_ids([1, 2, 3, 4, 5, 6, 7, 8, 9, 10]);

    await bom.updated.products.remove_ids([1, 3, 5, 7, 9]);
    PageResult<Product> pr1 = await bom.updated.products.page({});
    expect(pr1.objects_count, 5);
    expect(pr1.objects.length, 5);
    expect(pr1.objects[0].barcode, "sneaker 2");
  });

  // TODO: do something about this test lol
  // test ('test remove ids invalid', () async {
  //   CollectionManager<Brand> bcm = new CollectionManager<Brand>(() => new Brand());
  //   var bom = await Brand.objects.create({ "name": "nike" });
  //   CollectionManager<Product> pcm = new CollectionManager<Product>(() => new Product());
  //   for (int i = 0; i < 10; i++) await Product.objects.create({ "barcode": "sneaker ${i+1}"});

  //   await bom.updated.products.add_ids([1, 2, 3, 4, 5, 6, 7, 8, 9, 10]);

  //   await bom.updated.products.remove_ids([3, 11]);
  //   PageResult<Product> pr1 = await bom.updated.products.page({});
  //   expect(pr1.objects_count, 10);
  //   expect(pr1.objects.length, 10);
  //   expect(pr1.objects[9].barcode, "sneaker 10");
  // });

  test('test add objs', () async {
    var bom = await Brand.objects.create({"name": "nike"});
    List<Product> lst1 = [];
    List<Product> lst2 = [];
    for (int i = 0; i < 10; i++) {
      ObjectManager<Product> prod =
          await Product.objects.create({"barcode": "sneaker ${i + 1}"});
      if (i < 5) {
        lst1.add(prod.updated);
      } else
        lst2.add(prod.updated);
    }

    await bom.updated.products.add(lst1);
    PageResult<Product> related = await bom.updated.products.page({});
    expect(5, related.objects_count);
    expect("sneaker 5", related.objects[4].barcode);

    await bom.updated.products.add(lst2);
    related = await bom.updated.products.page({});
    expect(10, related.objects_count);
    expect("sneaker 10", related.objects[9].barcode);
  });

  test('test set objs', () async {
    var bom = await Brand.objects.create({"name": "nike"});
    List<Product> lst1 = [];
    List<Product> lst2 = [];
    for (int i = 0; i < 10; i++) {
      ObjectManager<Product> prod =
          await Product.objects.create({"barcode": "sneaker ${i + 1}"});
      if (i <= 8) {
        lst1.add(prod.updated);
      } else
        lst2.add(prod.updated);
    }

    await bom.updated.products.set(lst1);
    PageResult<Product> related = await bom.updated.products.page({});
    expect(9, related.objects_count);
    expect("sneaker 9", related.objects[8].barcode);

    await bom.updated.products.set(lst2);
    related = await bom.updated.products.page({});
    expect(1, related.objects_count);
    expect("sneaker 10", related.objects[0].barcode);
  });

  test('test remove objs', () async {
    var bom = await Brand.objects.create({"name": "nike"});
    List<Product> lst1 = [];
    List<Product> lst2 = [];
    List<Product> lst3 = [];
    for (int i = 0; i < 10; i++) {
      ObjectManager<Product> prod =
          await Product.objects.create({"barcode": "sneaker ${i + 1}"});
      if (i <= 8) {
        lst1.add(prod.updated);
      } else
        lst2.add(prod.updated);
      lst3.add(prod.updated);
    }

    await bom.updated.products.set(lst3);

    await bom.updated.products.remove(lst2);
    PageResult<Product> related = await bom.updated.products.page({});
    expect(9, related.objects_count);
    expect("sneaker 9", related.objects[8].barcode);

    await bom.updated.products.remove(lst1);
    related = await bom.updated.products.page({});
    expect(0, related.objects_count);
  });

  // RELATED OBJECT MANAGER TESTS
  test('test set brand', () async {
    var om = await Brand.objects.create({"name": "nike"});
    CollectionManager<Product> pcm = new CollectionManager(() => new Product());
    ObjectManager<Product> pom =
        await Product.objects.create({"barcode": "zoomfly v1"});
    await pom.updated.brand.set(om.updated);

    ObjectManager<Product> refreshed =
        await Product.objects.get({"brand_id": 1});
    expect(refreshed.updated.barcode, "zoomfly v1");
  });

  test('test get brand', () async {
    var om = await Brand.objects.create({"name": "nike"});
    CollectionManager<Product> pcm = new CollectionManager(() => new Product());
    ObjectManager<Product> pom =
        await Product.objects.create({"barcode": "zoomfly v1"});

    ObjectManager<Brand> temp = await pom.updated.brand.get();
    expect(null, temp.updated.id);

    await pom.updated.brand.set(om.updated);
    temp = await pom.updated.brand.get();
    expect("nike", temp.updated.name);
  });
}
