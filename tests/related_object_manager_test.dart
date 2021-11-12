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

  test('test set brand', () async {
    CollectionManager<Brand> cm = new CollectionManager(() => new Brand());
    ObjectManager<Brand> om = await cm.create({"name": "nike"});
    CollectionManager<Product> pcm = new CollectionManager(() => new Product());
    ObjectManager<Product> pom = await pcm.create({"barcode": "zoomfly v1"});
    await pom.updated.brand.set(om.updated);

    ObjectManager<Product> refreshed = await pcm.get({"brand_id": 1});
    expect(refreshed.updated.barcode, "zoomfly v1");
  });

  test('test get brand', () async {
    CollectionManager<Brand> cm = new CollectionManager(() => new Brand());
    ObjectManager<Brand> om = await cm.create({"name": "nike"});
    CollectionManager<Product> pcm = new CollectionManager(() => new Product());
    ObjectManager<Product> pom = await pcm.create({"barcode": "zoomfly v1"});

    ObjectManager<Brand> temp = await pom.updated.brand.get();
    expect(null, temp.updated.id);

    await pom.updated.brand.set(om.updated);
    temp = await pom.updated.brand.get();
    expect("nike", temp.updated.name);
  });
}
