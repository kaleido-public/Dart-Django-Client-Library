import 'package:django_client_framework/django_client_framework.dart';
import 'package:logging/logging.dart' as logging;
import 'package:test/test.dart';

import 'models.dart';

void main() {
  logging.hierarchicalLoggingEnabled = true;
  AjaxDriverLogger.level = logging.Level.WARNING;
  logging.Logger.root.onRecord.listen((record) {
    print('${record.level.name}: ${record.time}: ${record.message}');
  });

  ajax.endpoints = [
    APIEndpoint(scheme: "http", host: "server", urlPrefix: "", port: 8000),
    APIEndpoint(scheme: "http", host: "localhost", urlPrefix: "", port: 8001),
  ];

  setUp(() async {
    await ajax.request("GET", '/subapp/clear', {});
  });

  test('test get object none should fail', () async {
    expect(Product.objects.get(), throwsA(isA<ProgrammingError>()));
  });

  test('test get object one should pass', () async {
    await Product.objects.create({"barcode": "hello"});
    var om = await Product.objects.get({"barcode": "hello"});
    expect(om.props.barcode, 'hello');
  });

  test('test get object more than one should fail', () async {
    await Product.objects.create({"barcode": "hello"});
    await Product.objects.create({"barcode": "hello"});
    expect(Product.objects.get(), throwsA(isA<ProgrammingError>()));
  });

  test('test get object with array params', () async {
    await Product.objects.create({"barcode": "osu"});
    await Product.objects.create({"barcode": "goodbye"});
    var om = await Product.objects.get({
      "barcode__in": ["hello", "goodbye"]
    });
    expect(om.props.barcode, 'goodbye');
  });

  test('test get object with params', () async {
    await Product.objects.create({"barcode": "osu"});
    var om = await Product.objects.get({"barcode__exact": "osu"});
    expect(om.props.barcode, 'osu');
  });

  test('test page default', () async {
    var pr = await Product.objects.page(
      order_by: "barcode",
    );
    expect(pr.limit, 50);
    expect(pr.objects_count, 0);
    expect(pr.page, 1);
  });

  test('test page default with products', () async {
    for (int i = 0; i < 51; i++) {
      await Product.objects.create({"barcode": "product ${i + 1}"});
    }

    var pr = await Product.objects.page(
      order_by: "barcode",
    );
    expect(pr.limit, 50);
    expect(pr.objects_count, 51);
    expect(pr.page, 1);
  });

  test('test page search by null', () async {
    for (int i = 0; i < 10; i++) {
      if (i < 8) {
        await Product.objects.create({"barcode": null});
      } else {
        await Product.objects.create({"barcode": "sup"});
      }
    }

    PageResult<Product> pr = await Product.objects.page(
      query: {'barcode': null},
      order_by: "barcode",
    );
    expect(pr.limit, 50);
    expect(pr.objects_count, 8);
    expect(pr.page, 1);
  });

  test('test page page and limit', () async {
    for (int i = 0; i < 10; i++) {
      await Product.objects.create({"barcode": "product ${i}"});
    }

    PageResult<Product> pr = await Product.objects.page(
      page: 2,
      limit: 5,
      order_by: "barcode",
    );
    expect(pr.limit, 5);
    expect(pr.page, 2);
    expect(pr.objects_count, 10);
    expect(pr.objects.length, 5);
    expect(pr.objects[0].barcode, "product 5");
  });

  test('test page limit no page', () async {
    for (int i = 0; i < 10; i++) {
      await Product.objects.create({"barcode": "product ${i + 1}"});
    }

    PageResult<Product> pr = await Product.objects.page(
      limit: 5,
      order_by: "barcode",
    );
    expect(pr.limit, 5);
    expect(pr.page, 1);
    expect(pr.objects_count, 10);
    expect(pr.objects.length, 5);
    expect(pr.objects[0].barcode, "product 1");
  });

  test('test page query', () async {
    for (int i = 0; i < 10; i++) {
      await Product.objects.create({"barcode": "product ${i + 1}"});
    }

    PageResult<Product> pr = await Product.objects.page(
      query: {
        "barcode__in": ["product 1", "product 3", "product 5"],
      },
      order_by: "barcode",
    );
    expect(pr.limit, 50);
    expect(pr.page, 1);
    expect(pr.objects_count, 3);
    expect(pr.objects.length, 3);
    expect(pr.objects[1].barcode, "product 3");
  });

  test('test page query with page', () async {
    for (int i = 0; i < 10; i++) {
      await Product.objects.create({"barcode": "product ${i + 1}"});
    }

    PageResult<Product> pr = await Product.objects.page(
      query: {
        "barcode__in": ["product 1", "product 3", "product 5"]
      },
      limit: 1,
      page: 2,
      order_by: "barcode",
    );
    expect(pr.limit, 1);
    expect(pr.page, 2);
    expect(pr.pages_count, 3);
    expect(pr.objects_count, 3);
    expect(pr.objects.length, 1);
    expect(pr.objects[0].barcode, "product 3");
  });

  test('test page query order by', () async {
    for (int i = 0; i < 10; i++) {
      await Product.objects.create({"barcode": "shoe ${i + 1}"});
    }

    PageResult<Product> pr = await Product.objects.page(
      query: {
        "barcode__in": ["shoe 1", "shoe 3", "shoe 5"]
      },
      order_by: "-barcode",
    );
    expect(pr.limit, 50);
    expect(pr.page, 1);
    expect(pr.objects_count, 3);
    expect(pr.objects.length, 3);
    expect(pr.objects[0].barcode, "shoe 5");
    expect(pr.objects[2].barcode, "shoe 1");
  });

  test('test page query order by ver 2', () async {
    for (int i = 0; i < 10; i++) {
      await Product.objects.create({"barcode": "product ${i + 1}"});
    }

    await Product.objects.create({"barcode": "product 4"});

    PageResult<Product> pr = await Product.objects.page(
      query: {
        "barcode__in": ["product 1", "product 4", "product 5"]
      },
      order_by: "-barcode,-id",
    );
    expect(pr.limit, 50);
    expect(pr.page, 1);
    expect(pr.objects_count, 4);
    expect(pr.objects.length, 4);
    expect(pr.objects[0].barcode, "product 5");
    expect(pr.objects[1].barcode, "product 4");
    expect(pr.objects[2].barcode, "product 4");
  });

  test('test page typo', () async {
    for (int i = 0; i < 10; i++) {
      await Product.objects.create({"barcode": "product ${i + 1}"});
    }
    expect(
      Product.objects.page(
        query: {
          "barcode___in": ["product 1", "product 4", "product 5"]
        },
        order_by: "-barcode,-id",
      ),
      throwsA(isA<ProgrammingError>()),
    );
  });

  test('test create object', () async {
    var om = await Product.objects.create({"barcode": "hello"});
    expect(om.props.barcode, "hello");
  });

  test('test create object with null key', () async {
    var om = await Product.objects.create({"barcode": null});
    expect(om.props.barcode, null);
  });

  test('test create object with null key should fail ', () async {
    expect(Brand.objects.create({"name": null}), throwsA(isA<InvalidInput>()));
  });

  test('test create object with invalid key', () async {
    expect(
      Product.objects.create({"barasdfcode": "hello"}),
      throwsA(isA<InvalidInput>()),
    );
  });

  test('test get or create', () async {
    var om = await Product.objects.getOrCreate(
      query: {"barcode": "product 1"},
      defaults: {"brand_id": null},
    );
    expect(om.props.barcode, "product 1");
  });

  test('test get or create v2', () async {
    var om = await Product.objects.getOrCreate(
      query: {"barcode": "product 1"},
    );
    expect(om.props.barcode, "product 1");
  });

  test('test get or create v3', () async {
    await Product.objects.create({"barcode": "product 1"});
    await Product.objects.create({"barcode": "product 2"});
    var om = await Product.objects.getOrCreate(
      query: {"barcode": "product 2"},
      defaults: {"brand_id": null},
    );
    expect(om.props.barcode, "product 2");
  });

  test('test update or create', () async {
    var om = await Product.objects.updateOrCreate(
      query: {"barcode": "product 2"},
      defaults: {"barcode": "product 3"},
    );
    expect(om.props.barcode, "product 2");
  });

  test('test update or create v2', () async {
    await Product.objects.create({"barcode": "product 2"});
    var om = await Product.objects.updateOrCreate(
      query: {"barcode": "product 2"},
      defaults: {"barcode": "product 3"},
    );
    expect(om.props.barcode, "product 3");
  });
}
