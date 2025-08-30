import 'package:flusbserial/src/usb_endpoint.dart';

class UsbInterface {
  final int id;
  final int alternateSetting;
  final List<UsbEndpoint> endpoints;

  UsbInterface({
    required this.id,
    required this.alternateSetting,
    required this.endpoints,
  });

  factory UsbInterface.fromMap(Map<dynamic, dynamic> map) {
    var endpoints = (map['endpoints'] as List)
        .map((e) => UsbEndpoint.fromMap(e))
        .toList();
    return UsbInterface(
      id: map['id'],
      alternateSetting: map['alternateSetting'],
      endpoints: endpoints,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'alternateSetting': alternateSetting,
      'endpoints': endpoints.map((e) => e.toMap()).toList(),
    };
  }

  @override
  String toString() => toMap().toString();
}
