import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_event_kit/flutter_event_kit.dart';
import 'package:flutter_event_kit/flutter_event_kit_platform_interface.dart';
import 'package:flutter_event_kit/flutter_event_kit_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockFlutterEventKitPlatform
    with MockPlatformInterfaceMixin
    implements FlutterEventKitPlatform {

  @override
  Future<String?> getPlatformVersion() => Future.value('42');
}

void main() {
  final FlutterEventKitPlatform initialPlatform = FlutterEventKitPlatform.instance;

  test('$MethodChannelFlutterEventKit is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelFlutterEventKit>());
  });

  test('getPlatformVersion', () async {
    FlutterEventKit flutterEventKitPlugin = FlutterEventKit();
    MockFlutterEventKitPlatform fakePlatform = MockFlutterEventKitPlatform();
    FlutterEventKitPlatform.instance = fakePlatform;

    expect(await flutterEventKitPlugin.getPlatformVersion(), '42');
  });
}
