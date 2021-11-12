// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility that Flutter provides. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.
import 'package:test/test.dart';
import '../lib/main.dart';
import 'models.dart';

void main() {
  setUp(() async {
    await AjaxDriverImpl().clear();
  });

  tearDown(() async {
    await AjaxDriverImpl().clear();
  });

  test('test get object none should fail', () async {
    CollectionManager<Product> cm = CollectionManager(() => new Product());
    try {
      ObjectManager<Product> om = await cm.get({
        "id__in": [1]
      });
      fail("shouldn't have reached here");
    } catch (error) {
      expect(
          error.toString(), '.get() must receive exactly 1 object, but got 0');
    }
  });

  test('test get object one should pass', () async {
    CollectionManager<Product> cm = CollectionManager(() => new Product());
    await cm.create({"barcode": "hello"});
    ObjectManager<Product> om = await cm.get({"barcode": "hello"});
    expect(om.updated!.barcode, 'hello');
    expect(om.updated!.id, 1);
  });

  test('test get object more than one should fail', () async {
    CollectionManager<Product> cm = CollectionManager(() => new Product());
    await cm.create({"barcode": "hello"});
    await cm.create({"barcode": "hello"});
    try {
      await cm.get({
        "id__in": [1]
      });
    } catch (error) {
      expect(
          error.toString(), '.get() must receive exactly 1 object, but got 2');
    }
  });

  test('test get object with array params', () async {
    CollectionManager<Product> cm = CollectionManager(() => new Product());
    await cm.create({"barcode": "osu"});
    await cm.create({"barcode": "goodbye"});
    ObjectManager<Product> om = await cm.get({
      "barcode__in": ["hello", "goodbye"]
    });
    expect(om.updated!.barcode, 'goodbye');
    expect(om.updated!.id, 2);
  });

  test('test get object with params', () async {
    CollectionManager<Product> cm = CollectionManager(() => new Product());
    await cm.create({"barcode": "osu"});
    ObjectManager<Product> om = await cm.get({"barcode__exact": "osu"});
    expect(om.updated!.barcode, 'osu');
    expect(om.updated!.id, 1);
  });

  test('test page default', () async {
    CollectionManager<Product> cm = CollectionManager(() => new Product());
    PageResult<Product> pr = await cm.page({});
    expect(pr.limit, 50);
    expect(pr.objects_count, 0);
    expect(pr.page, 1);
  });

  test('test page default with products', () async {
    CollectionManager<Product> cm = CollectionManager(() => new Product());
    for (int i = 0; i < 51; i++) {
      await cm.create({"barcode": "product ${i + 1}"});
    }

    PageResult<Product> pr = await cm.page({});
    expect(pr.limit, 50);
    expect(pr.objects_count, 51);
    expect(pr.page, 1);
  });

  test('test page search by null', () async {
    CollectionManager<Product> cm = CollectionManager(() => new Product());
    for (int i = 0; i < 10; i++) {
      if (i < 8)
        await cm.create({"barcode": null});
      else
        await cm.create({"barcode": "sup"});
    }

    PageResult<Product> pr = await cm.page({
      'query': {'barcode': null}
    });
    expect(pr.limit, 50);
    expect(pr.objects_count, 8);
    expect(pr.page, 1);
    expect(pr.objects[0].id, 1);
  });

  test('test page page 1', () async {
    CollectionManager<Product> cm = CollectionManager(() => new Product());
    for (int i = 0; i < 51; i++) {
      await cm.create({"barcode": "product ${i + 1}"});
    }

    PageResult<Product> pr = await cm.page({});
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
    CollectionManager<Product> cm = CollectionManager(() => new Product());
    for (int i = 0; i < 51; i++) {
      await cm.create({"barcode": "product ${i + 1}"});
    }

    PageResult<Product> pr = await cm.page({
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
    CollectionManager<Product> cm = CollectionManager(() => new Product());
    for (int i = 0; i < 15; i++) {
      await cm.create({"barcode": "product ${i + 1}"});
    }

    PageResult<Product> pr = await cm.page({
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
    CollectionManager<Product> cm = CollectionManager(() => new Product());
    for (int i = 0; i < 10; i++) {
      await cm.create({"barcode": "product ${i + 1}"});
    }

    PageResult<Product> pr = await cm.page({
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
    CollectionManager<Product> cm = CollectionManager(() => new Product());
    for (int i = 0; i < 10; i++) {
      await cm.create({"barcode": "product ${i + 1}"});
    }

    PageResult<Product> pr = await cm.page({
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
    CollectionManager<Product> cm = CollectionManager(() => new Product());
    for (int i = 0; i < 10; i++) {
      await cm.create({"barcode": "product ${i + 1}"});
    }

    PageResult<Product> pr = await cm.page({
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
    CollectionManager<Product> cm = CollectionManager(() => new Product());
    for (int i = 0; i < 10; i++) {
      await cm.create({"barcode": "product ${i + 1}"});
    }

    PageResult<Product> pr = await cm.page({
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
    CollectionManager<Product> cm = CollectionManager(() => new Product());
    for (int i = 0; i < 10; i++) {
      await cm.create({"barcode": "shoe ${i + 1}"});
    }

    PageResult<Product> pr = await cm.page({
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
    CollectionManager<Product> cm = CollectionManager(() => new Product());
    for (int i = 0; i < 10; i++) {
      await cm.create({"barcode": "product ${i + 1}"});
    }

    await cm.create({"barcode": "product 4"});

    PageResult<Product> pr = await cm.page({
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
    CollectionManager<Product> cm = CollectionManager(() => new Product());
    for (int i = 0; i < 10; i++) {
      await cm.create({"barcode": "product ${i + 1}"});
    }
    try {
      PageResult<Product> pr = await cm.page({
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
    CollectionManager<Product> cm = CollectionManager(() => new Product());
    ObjectManager<Product> om = await cm.create({"barcode": "hello"});
    expect(om.updated!.barcode, "hello");
  });

  test('test create object with null key', () async {
    CollectionManager<Product> cm = CollectionManager(() => new Product());
    ObjectManager<Product> om = await cm.create({"barcode": null});
    expect(om.updated.barcode, null);
    expect(om.updated.id, 1);
  });

  test('test create object with null key should fail ', () async {
    CollectionManager<Brand> cm = CollectionManager(() => new Brand());
    ObjectManager<Brand> om = await cm.create({"name": null});
    expect(om.updated.name, 'This field may not be null.');
    expect(om.updated.id, null);

    om = await cm.create({"name": ''});
    expect(om.updated.name, '');
    expect(om.updated.id, 1);
  });

  test('test create object with invalid key', () async {
    CollectionManager<Product> cm = CollectionManager(() => new Product());
    ObjectManager<Product> om = await cm.create({"barasdfcode": "hello"});
    expect(om.updated.barcode, null);
  });

  test('test create object with invalid key v2', () async {
    CollectionManager<Product> cm = CollectionManager(() => new Product());
    ObjectManager<Product> om =
        await cm.create({"barcode": "hello", "goodbye": "osu"});
    expect(om.updated.barcode, null);
    expect(om.updated.id, null);
  });

  test('test get or create', () async {
    CollectionManager<Product> cm = CollectionManager(() => new Product());
    ObjectManager<Product> om = await cm.get_or_create({
      "query": {"barcode": "product 1"},
      "defaults": {"brand_id": null}
    });
    expect(om.updated!.barcode, "product 1");
    expect(om.updated!.id, 1);
  });

  test('test get or create v2', () async {
    CollectionManager<Product> cm = CollectionManager(() => new Product());
    ObjectManager<Product> om = await cm.get_or_create({
      "query": {"barcode": "product 1"}
    });
    expect(om.updated!.barcode, "product 1");
    expect(om.updated!.id, 1);
  });

  test('test get or create v3', () async {
    CollectionManager<Product> cm = CollectionManager(() => new Product());
    await cm.create({"barcode": "product 1"});
    await cm.create({"barcode": "product 2"});
    ObjectManager<Product> om = await cm.get_or_create({
      "query": {"barcode": "product 2"},
      "defaults": {"brand_id": null}
    });
    expect(om.updated!.barcode, "product 2");
    expect(om.updated!.id, 2);
  });

  test('test update or create', () async {
    CollectionManager<Product> cm = CollectionManager(() => new Product());
    ObjectManager<Product> om = await cm.update_or_create({
      "query": {"barcode": "product 2"},
      "defaults": {"barcode": "product 3"}
    });
    expect(om.updated!.barcode, "product 2");
    expect(om.updated!.id, 1);
  });

  test('test update or create v2', () async {
    CollectionManager<Product> cm = CollectionManager(() => new Product());
    await cm.create({"barcode": "product 2"});
    ObjectManager<Product> om = await cm.update_or_create({
      "query": {"barcode": "product 2"},
      "defaults": {"barcode": "product 3"}
    });
    expect(om.updated!.barcode, "product 3");
    expect(om.updated!.id, 1);
  });
}
