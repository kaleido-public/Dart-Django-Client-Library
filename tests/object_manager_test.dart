// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility that Flutter provides. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.
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

  test('test refresh', () async {
    final om = await Product.objects.create({"barcode": "product 1"});
    var uri = Uri.http("localhost:8000", "product/1");
    // var headers = {'content-type': 'application/json; charset=UTF-8'};
    var data = {"barcode": "product 2"};
    await http.patch(uri, body: data);
    expect(om.updated.barcode, "product 1");
    await om.refresh();
    expect(om.updated.barcode, "product 2");
  });

  test('test refresh without updates', () async {
    final om = await Product.objects.create({"barcode": "product 1"});
    await om.refresh();
    expect(om.updated.barcode, "product 1");
  });

  test('test save', () async {
    final om = await Product.objects.create({"barcode": "product 1"});
    om.updated.barcode = "osu!";
    var om1 = await Product.objects.get({"barcode": "product 1"});
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
    final om = await Product.objects.create({"barcode": "product 1"});
    await om.update({"barcode": "osu!"});
    expect(om.updated.barcode, "osu!");
    var om1 = await Product.objects.get({"barcode": "osu!"});
    expect(om1.updated.id, 1);
  });

  test('test update to empty', () async {
    final om = await Product.objects.create({"barcode": "product 1"});
    await om.update({"barcode": ""});
    expect(om.updated.barcode, '');
    var om1 = await Product.objects.get({"id": 1});
    expect(om1.updated.barcode, '');
  });

  test('test update to null', () async {
    final om = await Product.objects.create({"barcode": "product 1"});
    await om.update({"barcode": null});
    expect(om.updated.barcode, null);
    var om1 = await Product.objects.get({"id": 1});
    expect(om1.updated.barcode, null);
  });

  test('test update bad key', () async {
    final om = await Product.objects.create({"barcode": "product 1"});
    await om.update({"barcodeafaf": "osu!"});
    expect(om.updated.barcode, "product 1");
    var om1 = await Product.objects.get({"barcode": "product 1"});
    expect(om1.updated.id, 1);
  });

  test('test delete', () async {
    final om = await Product.objects.create({"barcode": "product 1"});
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
    final om = await Product.objects.create({"barcode": "product 1"});
    om.updated.barcode = '';
    await om.save();
    var find = await Product.objects.get({"id": 1});
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
    var pom = await Product.objects.create({"barcode": "product 1"});

    CollectionManager<Brand> bcm = CollectionManager(() => new Brand());
    var bom = await bcm.create({"name": "nike"});

    pom.updated.brand_id = 1;
    await pom.save();

    var pom2 = await Product.objects.get({"brand_id": 1});
    expect(pom2.updated.barcode, "product 1");
  });

  test('test constructor pass in object', () async {
    CollectionManager<Product> pcm = CollectionManager(() => new Product());
    for (int i = 0; i < 3; i++) {
      await pcm.create({"barcode": "pen ${i + 1}"});
    }

    final ppr = await Product.objects.page({
      'query': {
        'id__in': [1, 2, 3]
      }
    });
    final objm = ObjectManager<Product>(ppr.objects[0]);
    expect(objm.updated.barcode, "pen 1");
    expect(objm.updated.id, 1);
    expect(objm.updated.brand_id, null);
  });
}
