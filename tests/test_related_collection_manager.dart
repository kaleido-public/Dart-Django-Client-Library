import 'package:django_client_framework/django_client_framework.dart';
import 'package:test/test.dart';

import 'models.dart';

void main() {
  ajax.enableDefaultLogger();
  ajax.endpoints = [
    APIEndpoint(scheme: "http", host: "server", urlPrefix: "", port: 8000),
    APIEndpoint(scheme: "http", host: "localhost", urlPrefix: "", port: 8001),
  ];

  setUp(() async {
    await ajax.request("GET", '/subapp/clear', {});
  });

  test('test page empty', () async {
    var om = await Brand.objects.create({"name": "nike"});
    var products =
        await om.props.products.page(query: {"barcode": "product 1"});
    expect(products.limit, 50);
    expect(products.page, 1);
    expect(products.objectsCount, 0);
    expect(products.objects.length, 0);
  });

  test('test page with results', () async {
    var om = await Brand.objects.create({"name": "nike"});

    List<Product> lst = [];
    for (int i = 0; i < 10; i++) {
      var p = await Product.objects.create({"barcode": "product $i"});
      lst.add(p.props);
    }

    await om.props.products.add(lst);

    var products = await om.props.products.page(
      query: {
        "barcode__in": ["product 0", "product 4", "product 9"]
      },
      orderBy: "barcode",
    );
    expect(products.limit, 50);
    expect(products.page, 1);
    expect(products.objectsCount, 3);
    expect(products.objects.length, 3);
    expect(products.objects[0].barcode, "product 0");
  });

  test('test page with results and pagination', () async {
    CollectionManager<Brand> cmb = CollectionManager(() => Brand());
    CollectionManager<Product> cmp = CollectionManager(() => Product());
    var om = await cmb.create({"name": "nike"});

    List<Product> lst = [];
    for (int i = 0; i < 10; i++) {
      var p = await cmp.create({"barcode": "product ${i + 1}"});
      lst.add(p.props);
    }

    await om.props.products.add(lst);

    var products = await om.props.products.page(
      limit: 5,
      page: 2,
      orderBy: "-barcode",
    );
    expect(products.limit, 5);
    expect(products.page, 2);
    expect(products.objectsCount, 10);
    expect(products.objects.length, 5);
    expect(products.objects[0].barcode, "product 4");
  });

  test('test get with no result', () async {
    var brand = await Brand.objects.create({"name": "nike"});
    expect(brand.props.products.get(), throwsA(isA<APIProgrammingError>()));
  });

  test('test get with one result', () async {
    var brand = await Brand.objects.create({"name": "nike"});
    var prod = await Product.objects.create({"barcode": "shoe 1"});
    await brand.props.products.add([prod.props]);
    await brand.refresh();
    var actual = await brand.props.products.get();
    expect(actual, prod);
  });

  test('test get with multiple results', () async {
    var brand = await Brand.objects.create({"name": "nike"});

    List<Product> products = [];
    for (int i = 0; i < 2; i++) {
      var prod = await Product.objects.create({"barcode": "shoe $i"});
      products.add(prod.props);
    }
    await brand.props.products.add(products);

    await brand.refresh();
    expect(brand.props.products.get(), throwsA(isA<APIProgrammingError>()));
  });

  test('test add objs', () async {
    var bom = await Brand.objects.create({"name": "nike"});
    List<Product> lst1 = [];
    List<Product> lst2 = [];
    for (int i = 0; i < 10; i++) {
      var prod = await Product.objects.create({"barcode": "sneaker $i"});
      if (i < 5) {
        lst1.add(prod.props);
      } else {
        lst2.add(prod.props);
      }
    }

    await bom.props.products.add(lst1);
    var related = await bom.props.products.page(
      orderBy: "barcode",
    );
    expect(5, related.objectsCount);
    expect("sneaker 4", related.objects[4].barcode);

    await bom.props.products.add(lst2);
    related = await bom.props.products.page(
      orderBy: "barcode",
    );
    expect(10, related.objectsCount);
    expect("sneaker 9", related.objects[9].barcode);
  });

  test('test set objs', () async {
    var bom = await Brand.objects.create({"name": "nike"});
    List<Product> lst1 = [];
    List<Product> lst2 = [];
    for (int i = 0; i < 10; i++) {
      var prod = await Product.objects.create({"barcode": "sneaker ${i + 1}"});
      if (i <= 8) {
        lst1.add(prod.props);
      } else {
        lst2.add(prod.props);
      }
    }

    await bom.props.products.set(lst1);
    var related = await bom.props.products.page(
      orderBy: "barcode",
    );
    expect(9, related.objectsCount);
    expect("sneaker 9", related.objects[8].barcode);

    await bom.props.products.set(lst2);
    related = await bom.props.products.page(
      orderBy: "barcode",
    );
    expect(1, related.objectsCount);
    expect("sneaker 10", related.objects[0].barcode);
  });

  test('test remove objs', () async {
    var brand = await Brand.objects.create({"name": "nike"});
    List<Product> lst1 = []; // 0-8
    List<Product> lst2 = []; // 9
    List<Product> lst3 = []; // 0-9
    for (int i = 0; i < 10; i++) {
      var prod = await Product.objects.create({"barcode": "sneaker ${i + 1}"});
      if (i <= 8) {
        lst1.add(prod.props);
      } else {
        lst2.add(prod.props);
      }
      lst3.add(prod.props);
    }

    await brand.props.products.set(lst3); // 0-9

    await brand.props.products.remove(lst2); // rm 9
    var related = await brand.props.products.page(
      orderBy: "barcode",
    ); // 0-8
    expect(9, related.objectsCount);
    expect("sneaker 1", related.objects[0].barcode);

    await brand.props.products.remove(lst1);
    related = await brand.props.products.page(
      orderBy: "barcode",
    );
    expect(0, related.objectsCount);
  });

  test('test page prefetchRelatedCollection (small batchSize)', () async {
    var brand = await Brand.objects.create({"name": "nike"});
    await Future.wait([
      for (var i = 0; i < 25; i++)
        Product.objects
            .create({"barcode": "product ${i}", "brand_id": brand.props.id})
    ]);
    var brandPage = await Brand.objects.page();
    await brandPage.prefetchRelatedCollection(
      (b) => b.products,
      batchSize: 1,
      pageSize: 1,
    );
    for (var brand in brandPage.objects) {
      expect(brand.products.getCached(), isNotNull);
      expect(brand.products.getCached()!.length, 25);
      expect((await brand.products.page()).objects.length, 25);
    }
  });

  test('test page prefetchRelatedCollection (large batchSize)', () async {
    var brand = await Brand.objects.create({"name": "nike"});
    await Future.wait([
      for (var i = 0; i < 25; i++)
        Product.objects
            .create({"barcode": "product ${i}", "brand_id": brand.props.id})
    ]);
    var brandPage = await Brand.objects.page();
    await brandPage.prefetchRelatedCollection(
      (b) => b.products,
      batchSize: 50,
      pageSize: 100,
    );
    for (var brand in brandPage.objects) {
      expect(brand.products.getCached(), isNotNull);
      expect(brand.products.getCached()!.length, 25);
      expect((await brand.products.page()).objects.length, 25);
    }
  });
}
