import 'package:plugin_platform_interface/plugin_platform_interface.dart';

abstract class FlUsbSerialPlatform extends PlatformInterface {
  /// Constructs a FlUsbSerialPlatform.
  FlUsbSerialPlatform() : super(token: _token);

  static final Object _token = Object();

  static late FlUsbSerialPlatform _instance;

  /// The default instance of [FlUsbSerialPlatform] to use.
  ///
  /// Defaults to [MethodChannelFlUsbSerial].
  static FlUsbSerialPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [FlUsbSerialPlatform] when
  /// they register themselves.
  static set instance(FlUsbSerialPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }
}
