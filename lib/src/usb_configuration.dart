import 'package:flusbserial/src/usb_interface.dart';

class UsbConfiguration {
  final int id;
  final int index;
  final List<UsbInterface> interfaces;

  UsbConfiguration({
    required this.id,
    required this.index,
    required this.interfaces,
  });

  factory UsbConfiguration.fromMap(Map<dynamic, dynamic> map) {
    var interfaces = (map['interfaces'] as List)
        .map((e) => UsbInterface.fromMap(e))
        .toList();
    return UsbConfiguration(
      id: map['id'],
      index: map['index'],
      interfaces: interfaces,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'index': index,
      'interfaces': interfaces.map((e) => e.toMap()).toList(),
    };
  }

  @override
  String toString() => toMap().toString();
}
