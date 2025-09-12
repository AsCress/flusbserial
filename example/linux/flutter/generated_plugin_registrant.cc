//
//  Generated file. Do not edit.
//

// clang-format off

#include "generated_plugin_registrant.h"

#include <flusbserial/fl_usb_serial_plugin.h>

void fl_register_plugins(FlPluginRegistry* registry) {
  g_autoptr(FlPluginRegistrar) flusbserial_registrar =
      fl_plugin_registry_get_registrar_for_plugin(registry, "FlUsbSerialPlugin");
  fl_usb_serial_plugin_register_with_registrar(flusbserial_registrar);
}
