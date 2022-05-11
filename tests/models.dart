import 'package:django_client_framework/django_client_framework.dart';

class Product extends Model {
  static final objects = CollectionManager(() => Product());

  Product([Map<String, Object?>? props]) {
    this.props = props ?? {};
  }

  String? get barcode => props['barcode'];
  set barcode(String? x) => props['barcode'] = x;

  String? get brand_id => props["brand_id"];
  set brand_id(String? x) => props["brand_id"] = x;

  RelatedObjectManager<Brand, Product> get brand => RelatedObjectManager(
        Brand.new,
        this,
        "brand",
        cache,
        reverseCollectionManager: (b) => b.products,
      );

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

  String get name => props["name"];
  set name(String x) => props["name"] = x;

  RelatedCollectionManager<Product, Brand> get products =>
      RelatedCollectionManager(
        Product.new,
        this,
        "products",
        cache,
        reverseObjectManager: (p) => p.brand,
      );

  @override
  Model clone() {
    return Brand(Map.from(this.props));
  }
}
