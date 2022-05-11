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

  test('test get object none should fail', () async {
    expect(Product.objects.get(), throwsA(isA<APIProgrammingError>()));
  });

  test('test refresh', () async {
    var om = await Product.objects.create({"barcode": "product 1"});
    await ajax.request(
      "PATCH",
      "/product/${om.props.id}",
      {"barcode": "product 2"},
    );
    expect(om.props.barcode, "product 1");
    await om.refresh();
    expect(om.props.barcode, "product 2");
  });

  test('test refresh without updates', () async {
    var om = await Product.objects.create({"barcode": "product 1"});
    await om.refresh();
    expect(om.props.barcode, "product 1");
  });

  test('test save', () async {
    var product = await Product.objects.create({"barcode": "product 1"});
    product.props.barcode = "osu!";
    await product.save();
    var other = await Product.objects.get({"barcode": "osu!"});
    expect(other.props.barcode, "osu!");
  });

  test('test update', () async {
    var om = await Product.objects.create({"barcode": "product 1"});
    await om.update({"barcode": "osu!"});
    expect(om.props.barcode, "osu!");
  });

  test('test update to empty', () async {
    var om = await Product.objects.create({"barcode": "product 1"});
    await om.update({"barcode": ""});
    expect(om.props.barcode, '');
    var om1 = await Product.objects.get();
    expect(om1.props.barcode, '');
  });

  test('test update to null', () async {
    var om = await Product.objects.create({"barcode": "product 1"});
    await om.update({"barcode": null});
    expect(om.props.barcode, null);
    var om1 = await Product.objects.get();
    expect(om1.props.barcode, null);
  });

  test('test update bad key', () async {
    var om = await Product.objects.create({"barcode": "product 1"});
    expect(
      om.update({"barcodeafaf": "osu!"}),
      throwsA(isA<APIValidationError>()),
    );
  });

  test('test delete', () async {
    var product = await Product.objects.create({"barcode": "product 1"});
    await product.delete();
    expect(product.refresh(), throwsA(isA<APINotFoundError>()));
  });

  test('test modify using properties to blank and null', () async {
    var om = await Product.objects.create({"barcode": "product 1"});
    om.props.barcode = '';
    await om.save();
    var find = await Product.objects.get();
    expect(find.props.barcode, '');
    om.props.barcode = null;
    await om.save();
    find = await Product.objects.get();
    expect(find.props.barcode, null);
  });

  test('test modify properties', () async {
    var om = await Brand.objects.create({"name": "nike"});
    om.props.name = "adidas";
    await om.save();
    var om1 = await Brand.objects.get();
    expect(om1.props.name, "adidas");
  });

  test('test modify foreign key', () async {
    var product = await Product.objects.create({
      "barcode": "product 1",
    });
    var brand = await Brand.objects.create({});
    product.props.brand_id = brand.props.id;
    await product.save();
    var refreshed = await Product.objects.get({
      "brand_id": product.props.brand_id,
    });
    expect(refreshed.props.barcode, "product 1");
  });

  test('test constructor pass in object', () async {
    for (int i = 0; i < 3; i++) {
      await Product.objects.create({"barcode": "pen ${i + 1}"});
    }

    PageResult<Product> page = await Product.objects.page(
      query: {
        'barcode__in': ["pen 1", "pen 2", "pen 3"],
      },
      orderBy: "barcode",
    );

    var objm = ObjectManager<Product>(page.objects[0]);
    expect(objm.props.barcode, "pen 1");
    expect(objm.props.brand_id, null);
  });
}
