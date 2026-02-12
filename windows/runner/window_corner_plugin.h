#ifndef RUNNER_WINDOW_CORNER_PLUGIN_H_
#define RUNNER_WINDOW_CORNER_PLUGIN_H_

#include <flutter/flutter_view_controller.h>
#include <flutter/method_channel.h>

class WindowCornerPlugin {
 public:
  WindowCornerPlugin(flutter::FlutterViewController* controller);
  ~WindowCornerPlugin();

  // Register the plugin with the given engine.
  void RegisterWithRegistrar(flutter::PluginRegistrar* registrar);

 private:
  // Handle method calls from Flutter.
  void HandleMethodCall(
      const flutter::MethodCall<>& method_call,
      std::unique_ptr<flutter::MethodResult<>> result);

  // The Flutter view controller.
  flutter::FlutterViewController* controller_;
};

#endif  // RUNNER_WINDOW_CORNER_PLUGIN_H_
