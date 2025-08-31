import 'package:flutter/foundation.dart';

class Helpers {
  static int createDevice(int vendorId, int productId) {
    return (vendorId << 32) | (productId & 0xFFFFFFFF);
  }

  static List<int> createTable(List<int> entries) {
    entries.sort();
    return entries;
  }

  static bool exists(List<int> devices, int vendorId, int productId) {
    int key = createDevice(vendorId, productId);
    int index = binarySearch(devices, key);
    return index >= 0;
  }
}
