import 'package:django_client_framework/main.dart';
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

  test('test set brand', () async {
    var om = await Brand.objects.create({"name": "nike"});
    var pom = await Product.objects.create({"barcode": "zoomfly v1"});
    await pom.props.brand.set(om.props);

    var refreshed = await Product.objects.get();
    expect(refreshed.props.barcode, "zoomfly v1");
  });

  test('test get brand', () async {
    var pom = await Product.objects.create({"barcode": "zoomfly v1"});

    var brand = await pom.props.brand.get();
    expect(brand, isNull);

    var om = await Brand.objects.create({"name": "nike"});
    await pom.props.brand.set(om.props);
    brand = await pom.props.brand.get();
    expect("nike", brand?.props.name);
  });
}
