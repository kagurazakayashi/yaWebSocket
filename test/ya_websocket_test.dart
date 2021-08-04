import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ya_websocket/ya_websocket.dart';

void main() {
  const MethodChannel channel = MethodChannel('ya_websocket');

  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    channel.setMockMethodCallHandler((MethodCall methodCall) async {
      return '42';
    });
  });

  tearDown(() {
    channel.setMockMethodCallHandler(null);
  });

  test('getPlatformVersion', () async {
    expect(await YaWebsocket.platformVersion, '42');
  });
}
