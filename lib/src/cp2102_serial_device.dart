import 'package:fl_usb_serial/src/usb_serial_device.dart';

class Cp2102SerialDevice extends UsbSerialDevice {
  Cp2102SerialDevice({
    required super.identifier,
    required super.vendorId,
    required super.productId,
    required super.configurationCount,
  });

  @override
  Future<void> close() {
    throw UnimplementedError();
  }

  @override
  Future<bool> open() {
    throw UnimplementedError();
  }

  @override
  Future<void> setBaudRate(int baudRate) {
    throw UnimplementedError();
  }

  @override
  Future<void> setBreak(bool state) {
    throw UnimplementedError();
  }

  @override
  Future<void> setDataBits(int dataBits) {
    throw UnimplementedError();
  }

  @override
  Future<void> setFlowControl(int flowControl) {
    throw UnimplementedError();
  }

  @override
  Future<void> setParity(int parity) {
    throw UnimplementedError();
  }

  @override
  Future<void> setStopBits(int stopBits) {
    throw UnimplementedError();
  }
}
