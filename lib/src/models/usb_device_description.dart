import 'package:flusbserial/src/models/usb_device.dart';

class UsbDeviceDescription {
  final UsbDevice device;
  final String? manufacturer;
  final String? product;
  final String? serialNumber;

  UsbDeviceDescription({
    required this.device,
    this.manufacturer,
    this.product,
    this.serialNumber,
  });

  factory UsbDeviceDescription.fromMap(Map<dynamic, dynamic> map) {
    return UsbDeviceDescription(
      device: UsbDevice.fromMap(map['device']),
      manufacturer: map['manufacturer'],
      product: map['product'],
      serialNumber: map['serialNumber'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'device': device.toMap(),
      'manufacturer': manufacturer,
      'product': product,
      'serialNumber': serialNumber,
    };
  }

  @override
  String toString() => toMap().toString();
}
