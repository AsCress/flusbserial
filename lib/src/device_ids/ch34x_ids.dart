import 'package:flusbserial/src/device_ids/helpers.dart';

class Ch34xIds {
  static final List<int> _ch34xDevices = Helpers.createTable([
    Helpers.createDevice(0x4348, 0x5523),
    Helpers.createDevice(0x1a86, 0x7523),
    Helpers.createDevice(0x1a86, 0x5523),
    Helpers.createDevice(0x1a86, 0x0445),
  ]);

  static bool isDeviceSupported(int vendorId, int productId) {
    return Helpers.exists(_ch34xDevices, vendorId, productId);
  }
}
