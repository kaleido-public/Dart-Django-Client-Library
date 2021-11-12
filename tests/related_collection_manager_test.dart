import 'dart:convert';

import 'package:test/test.dart';
import '../lib/main.dart';
import 'models.dart';
import 'package:http/http.dart' as http;

void main() {
  setUp(() async {
    await AjaxDriverImpl().clear();
  });

  tearDown(() async {
    await AjaxDriverImpl().clear();
  });

  test('test page empty', () async {
    CollectionManager<Brand> cm = new CollectionManager(() => new Brand());
    ObjectManager<Brand> om = await cm.create({"name": "nike"});
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
    ObjectManager<Brand> om = await cmb.create({"name": "nike"});

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
    ObjectManager<Brand> om = await cmb.create({"name": "nike"});

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
    ObjectManager<Brand> om = await cmb.create({"name": "nike"});
    try {
      await om.updated.products.get({});
      fail("shouldn't have got here");
    } catch (error) {
      expect(
          error.toString(), ".get() must receive exactly 1 object, but got 0");
    }
  });

  test('test get with one result', () async {
    CollectionManager<Brand> bcm =
        new CollectionManager<Brand>(() => new Brand());
    ObjectManager<Brand> bom = await bcm.create({"name": "nike"});

    CollectionManager<Product> pcm =
        new CollectionManager<Product>(() => new Product());
    for (int i = 0; i < 10; i++) {
      await pcm.create({"barcode": "shoe ${i + 1}"});
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
    CollectionManager<Brand> bcm =
        new CollectionManager<Brand>(() => new Brand());
    ObjectManager<Brand> bom = await bcm.create({"name": "nike"});

    CollectionManager<Product> pcm =
        new CollectionManager<Product>(() => new Product());
    for (int i = 0; i < 10; i++) {
      await pcm.create({"barcode": "shoe ${i + 1}"});
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
    CollectionManager<Product> pcm =
        new CollectionManager<Product>(() => new Product());
    CollectionManager<Brand> bcm =
        new CollectionManager<Brand>(() => new Brand());
    ObjectManager<Brand> bom = await bcm.create({"name": "nike"});
    for (int i = 0; i < 10; i++)
      await pcm.create({"barcode": "sneaker ${i + 1}"});

    await bom.updated.products.add_ids([2, 4, 6, 8]);
    var product_lst = await bom.updated.products.page({});
    expect(product_lst.objects_count, 4);
    expect(product_lst.objects.length, 4);
    expect(product_lst.objects[3].barcode, "sneaker 8");
  });

  test('test add ids some invalid', () async {
    CollectionManager<Brand> bcm =
        new CollectionManager<Brand>(() => new Brand());
    ObjectManager<Brand> bom = await bcm.create({"name": "nike"});
    CollectionManager<Product> pcm =
        new CollectionManager<Product>(() => new Product());
    for (int i = 0; i < 10; i++)
      await pcm.create({"barcode": "sneaker ${i + 1}"});

    bom.updated.products.add_ids([10, 15]);
    PageResult<Product> pr = await bom.updated.products.page({});
    expect(pr.objects_count, 0);
    expect(pr.objects.length, 0);
  });

  test('test set ids', () async {
    CollectionManager<Brand> bcm =
        new CollectionManager<Brand>(() => new Brand());
    ObjectManager<Brand> bom = await bcm.create({"name": "nike"});
    CollectionManager<Product> pcm =
        new CollectionManager<Product>(() => new Product());
    for (int i = 0; i < 10; i++)
      await pcm.create({"barcode": "sneaker ${i + 1}"});

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
    CollectionManager<Brand> bcm =
        new CollectionManager<Brand>(() => new Brand());
    ObjectManager<Brand> bom = await bcm.create({"name": "nike"});
    CollectionManager<Product> pcm =
        new CollectionManager<Product>(() => new Product());
    for (int i = 0; i < 10; i++)
      await pcm.create({"barcode": "sneaker ${i + 1}"});

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
    CollectionManager<Brand> bcm =
        new CollectionManager<Brand>(() => new Brand());
    ObjectManager<Brand> bom = await bcm.create({"name": "nike"});
    CollectionManager<Product> pcm =
        new CollectionManager<Product>(() => new Product());
    for (int i = 0; i < 10; i++)
      await pcm.create({"barcode": "sneaker ${i + 1}"});

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
    CollectionManager<Brand> bcm =
        new CollectionManager<Brand>(() => new Brand());
    ObjectManager<Brand> bom = await bcm.create({"name": "nike"});
    CollectionManager<Product> pcm =
        new CollectionManager<Product>(() => new Product());
    for (int i = 0; i < 10; i++)
      await pcm.create({"barcode": "sneaker ${i + 1}"});

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
  //   ObjectManager<Brand> bom = await bcm.create({ "name": "nike" });
  //   CollectionManager<Product> pcm = new CollectionManager<Product>(() => new Product());
  //   for (int i = 0; i < 10; i++) await pcm.create({ "barcode": "sneaker ${i+1}"});

  //   await bom.updated.products.add_ids([1, 2, 3, 4, 5, 6, 7, 8, 9, 10]);

  //   await bom.updated.products.remove_ids([3, 11]);
  //   PageResult<Product> pr1 = await bom.updated.products.page({});
  //   expect(pr1.objects_count, 10);
  //   expect(pr1.objects.length, 10);
  //   expect(pr1.objects[9].barcode, "sneaker 10");
  // });

  test('test add objs', () async {
    CollectionManager<Brand> bcm =
        new CollectionManager<Brand>(() => new Brand());
    ObjectManager<Brand> bom = await bcm.create({"name": "nike"});
    CollectionManager<Product> pcm =
        new CollectionManager<Product>(() => new Product());
    List<Product> lst1 = [];
    List<Product> lst2 = [];
    for (int i = 0; i < 10; i++) {
      ObjectManager<Product> prod =
          await pcm.create({"barcode": "sneaker ${i + 1}"});
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
    CollectionManager<Brand> bcm =
        new CollectionManager<Brand>(() => new Brand());
    ObjectManager<Brand> bom = await bcm.create({"name": "nike"});
    CollectionManager<Product> pcm =
        new CollectionManager<Product>(() => new Product());
    List<Product> lst1 = [];
    List<Product> lst2 = [];
    for (int i = 0; i < 10; i++) {
      ObjectManager<Product> prod =
          await pcm.create({"barcode": "sneaker ${i + 1}"});
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
    CollectionManager<Brand> bcm =
        new CollectionManager<Brand>(() => new Brand());
    ObjectManager<Brand> bom = await bcm.create({"name": "nike"});
    CollectionManager<Product> pcm =
        new CollectionManager<Product>(() => new Product());
    List<Product> lst1 = [];
    List<Product> lst2 = [];
    List<Product> lst3 = [];
    for (int i = 0; i < 10; i++) {
      ObjectManager<Product> prod =
          await pcm.create({"barcode": "sneaker ${i + 1}"});
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
}
