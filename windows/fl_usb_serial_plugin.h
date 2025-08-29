#ifndef FLUTTER_PLUGIN_FL_USB_SERIAL_PLUGIN_H_
#define FLUTTER_PLUGIN_FL_USB_SERIAL_PLUGIN_H_

#include <flutter/method_channel.h>
#include <flutter/plugin_registrar_windows.h>

#include <memory>

namespace fl_usb_serial {

class FlUsbSerialPlugin : public flutter::Plugin {
 public:
  static void RegisterWithRegistrar(flutter::PluginRegistrarWindows *registrar);

  FlUsbSerialPlugin();

  virtual ~FlUsbSerialPlugin();

  // Disallow copy and assign.
  FlUsbSerialPlugin(const FlUsbSerialPlugin&) = delete;
  FlUsbSerialPlugin& operator=(const FlUsbSerialPlugin&) = delete;

  // Called when a method is called on this plugin's channel from Dart.
  void HandleMethodCall(
      const flutter::MethodCall<flutter::EncodableValue> &method_call,
      std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);
};

}  // namespace fl_usb_serial

#endif  // FLUTTER_PLUGIN_FL_USB_SERIAL_PLUGIN_H_
