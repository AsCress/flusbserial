/// Represents a USB device discovered on the system.
///
/// This model contains basic identifying information about a device,
/// including vendor/product IDs and the number of available configurations.
class UsbDevice {
  final String identifier;
  final int vendorId;
  final int productId;
  final int configurationCount;

  UsbDevice({
    required this.identifier,
    required this.vendorId,
    required this.productId,
    required this.configurationCount,
  });

  /// Creates a [UsbDevice] from a map (e.g., decoded JSON).
  factory UsbDevice.fromMap(Map<dynamic, dynamic> map) {
    return UsbDevice(
      identifier: map['identifier'],
      vendorId: map['vendorId'],
      productId: map['productId'],
      configurationCount: map['configurationCount'],
    );
  }

  /// Converts this [UsbDevice] into a map representation.
  Map<String, dynamic> toMap() {
    return {
      'identifier': identifier,
      'vendorId': vendorId,
      'productId': productId,
      'configurationCount': configurationCount,
    };
  }

  /// Returns a string representation of the device.
  @override
  String toString() => toMap().toString();
}
