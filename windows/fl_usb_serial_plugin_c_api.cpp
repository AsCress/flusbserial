#include "include/fl_usb_serial/fl_usb_serial_plugin_c_api.h"

#include <flutter/plugin_registrar_windows.h>

#include "fl_usb_serial_plugin.h"

void FlUsbSerialPluginCApiRegisterWithRegistrar(
    FlutterDesktopPluginRegistrarRef registrar) {
  fl_usb_serial::FlUsbSerialPlugin::RegisterWithRegistrar(
      flutter::PluginRegistrarManager::GetInstance()
          ->GetRegistrar<flutter::PluginRegistrarWindows>(registrar));
}
