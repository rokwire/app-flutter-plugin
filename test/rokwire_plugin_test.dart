import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rokwire_plugin/rokwire_plugin.dart';

void main() {
  const MethodChannel channel = MethodChannel('edu.illinois.rokwire/plugin');

  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      channel,
      (MethodCall methodCall) async {
        return '42';
      },
    );
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(channel, null);
  });

  test('getPlatformVersion', () async {
    expect(await RokwirePlugin.platformVersion, '42');
  });
}
