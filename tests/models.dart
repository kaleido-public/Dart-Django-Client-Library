import '../lib/main.dart';

class Product extends Model {
  Product();
  static final objects = CollectionManager(() => new Product());

  dynamic get id => props['id'];

  String? get barcode => props['barcode'];
  set barcode(String? x) => props['barcode'] = x;

  int? get brand_id => props["brand_id"];
  set brand_id(int? x) => props["brand_id"] = x;

  RelatedObjectManager<Brand, Product> get brand =>
      RelatedObjectManager<Brand, Product>(() => new Brand(), this, "brand");

  @override
  Model clone() {
    return new Product.fromProperties(this.props);
  }

  @override
  Model fromJson(dynamic object) {
    Map<String, dynamic> map = object.map;
    map.forEach((key, val) => {this.props[key] = val});
    return this;
  }

  Product.fromProperties(Map<String, Object?> props) {
    this.props = new Map<String, Object?>.from(props);
  }
}

class Brand extends Model {
  Brand();
  static final objects = CollectionManager(() => new Brand());

  dynamic get id => props['id'];

  String? get name => props["name"];
  set name(String? x) => props["name"] = x;

  RelatedCollectionManager<Product, Brand> get products =>
      RelatedCollectionManager(() => new Product(), this, "products");

  Brand.fromProperties(Map<String, Object?> props) {
    this.props = new Map<String, Object?>.from(props);
  }

  @override
  Model clone() {
    return new Brand.fromProperties(this.props);
  }

  @override
  Model fromJson(dynamic object) {
    Map<String, dynamic> map = object.map;
    map.forEach((key, val) => {this.props[key] = val});
    return this;
  }
}
