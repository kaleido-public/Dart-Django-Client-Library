import 'package:django_client_framework/django_client_framework.dart';

class Product extends Model {
  static final objects = CollectionManager(() => Product());

  Product([Map<String, Object?>? props]) {
    this.props = props ?? {};
  }

  @override
  String get id => props['id'];

  String? get barcode => props['barcode'];
  set barcode(String? x) => props['barcode'] = x;

  String? get brand_id => props["brand_id"];
  set brand_id(String? x) => props["brand_id"] = x;

  get brand =>
      RelatedObjectManager<Brand, Product>(() => Brand(), this, "brand");

  @override
  Model clone() {
    return Product(Map.from(this.props));
  }
}

class Brand extends Model {
  static final objects = CollectionManager(() => Brand());

  Brand([Map<String, Object?>? props]) {
    this.props = props ?? {};
  }

  @override
  String get id => props['id'];

  String get name => props["name"];
  set name(String x) => props["name"] = x;

  RelatedCollectionManager<Product, Brand> get products =>
      RelatedCollectionManager(() => Product(), this, "products");

  @override
  Model clone() {
    return Brand(Map.from(this.props));
  }
}
