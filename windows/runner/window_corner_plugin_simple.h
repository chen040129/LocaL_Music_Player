#ifndef RUNNER_WINDOW_CORNER_PLUGIN_SIMPLE_H_
#define RUNNER_WINDOW_CORNER_PLUGIN_SIMPLE_H_

#include <flutter/binary_messenger.h>
#include <flutter/method_channel.h>
#include <flutter/method_result_functions.h>
#include <flutter/standard_method_codec.h>
#include <flutter/plugin_registrar_windows.h>

#include <memory>
#include <sstream>

// Forward declaration
class FlutterWindow;

class WindowCornerPluginSimple {
 public:
  static void RegisterWithRegistrar(FlutterDesktopPluginRegistrarRef registrar);

 private:
  WindowCornerPluginSimple();

  // Called when a method is called on this plugin's channel.
  void HandleMethodCall(
      const flutter::MethodCall<flutter::EncodableValue>& method_call,
      std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);
};

// Function to set the global FlutterWindow pointer
void SetFlutterWindowForCornerPlugin(FlutterWindow* window);

#endif  // RUNNER_WINDOW_CORNER_PLUGIN_SIMPLE_H_
