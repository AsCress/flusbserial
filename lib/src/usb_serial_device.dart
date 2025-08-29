import 'dart:typed_data';

import 'package:fl_usb_serial/src/usb_serial_interface.dart';

abstract class UsbSerialDevice implements UsbSerialInterface {
  final String identifier;
  final int vendorId;
  final int productId;
  final int configurationCount;

  UsbSerialDevice({
    required this.identifier,
    required this.vendorId,
    required this.productId,
    required this.configurationCount,
  });

  @override
  Future<Uint8List> read() {
    throw UnimplementedError();
  }

  @override
  Future<int> write() {
    throw UnimplementedError();
  }

  @override
  Future<void> close();

  @override
  Future<bool> open();

  @override
  Future<void> setBaudRate(int baudRate);

  @override
  Future<void> setBreak(bool state);

  @override
  Future<void> setDataBits(int dataBits);

  @override
  Future<void> setFlowControl(int flowControl);

  @override
  Future<void> setParity(int parity);

  @override
  Future<void> setStopBits(int stopBits);
}
