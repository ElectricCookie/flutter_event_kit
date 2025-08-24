import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'flutter_event_kit_method_channel.dart';

abstract class FlutterEventKitPlatform extends PlatformInterface {
  /// Constructs a FlutterEventKitPlatform.
  FlutterEventKitPlatform() : super(token: _token);

  static final Object _token = Object();

  static FlutterEventKitPlatform _instance = MethodChannelFlutterEventKit();

  /// The default instance of [FlutterEventKitPlatform] to use.
  ///
  /// Defaults to [MethodChannelFlutterEventKit].
  static FlutterEventKitPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [FlutterEventKitPlatform] when
  /// they register themselves.
  static set instance(FlutterEventKitPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<String?> getPlatformVersion() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }
}
