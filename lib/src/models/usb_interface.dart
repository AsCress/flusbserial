import 'package:flusbserial/src/models/usb_endpoint.dart';

class UsbInterface {
  final int id;
  final int alternateSetting;
  final int interfaceClass;
  final List<UsbEndpoint> endpoints;

  UsbInterface({
    required this.id,
    required this.alternateSetting,
    required this.interfaceClass,
    required this.endpoints,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'alternateSetting': alternateSetting,
      'interfaceClass': interfaceClass,
      'endpoints': endpoints.map((e) => e.toMap()).toList(),
    };
  }

  @override
  String toString() => toMap().toString();
}
