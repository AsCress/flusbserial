import 'package:libusb/libusb64.dart';

class UsbEndpoint {
  static const int maskNumber = 0x0F;
  static const int maskDirection = 0x80;

  static const int directionIn = 0x80;
  static const int directionOut = 0x00;

  final int endpointNumber;
  final int direction;
  final int transferType;
  final int maxPacketSize;

  UsbEndpoint({
    required this.endpointNumber,
    required this.direction,
    required this.transferType,
    required this.maxPacketSize,
  });

  factory UsbEndpoint.fromDescriptor(libusb_endpoint_descriptor desc) {
    return UsbEndpoint(
      endpointNumber: desc.bEndpointAddress & maskNumber,
      direction: desc.bEndpointAddress & maskDirection,
      transferType: desc.bmAttributes & 0x03,
      maxPacketSize: desc.wMaxPacketSize,
    );
  }

  int get endpointAddress => endpointNumber | direction;

  Map<String, dynamic> toMap() {
    return {
      'endpointNumber': endpointNumber,
      'direction': direction,
      'transferType': transferType,
      'maxPacketSize': maxPacketSize,
    };
  }

  @override
  String toString() => toMap().toString();
}
