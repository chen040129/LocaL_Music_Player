#include "window_corner_plugin.h"
#include "flutter_window.h"
#include <flutter/method_channel.h>
#include <flutter/plugin_registrar_windows.h>
#include <flutter/standard_method_codec.h>
#include <memory>
#include <sstream>

WindowCornerPlugin::WindowCornerPlugin(flutter::FlutterViewController* controller)
    : controller_(controller) {}

WindowCornerPlugin::~WindowCornerPlugin() {}

void WindowCornerPlugin::RegisterWithRegistrar(flutter::PluginRegistrar* registrar) {
  auto channel =
      std::make_unique<flutter::MethodChannel<flutter::EncodableValue>>(
          registrar->messenger(), "window_corner",
          &flutter::StandardMethodCodec::GetInstance());

  auto plugin = std::make_unique<WindowCornerPlugin>(controller_);

  channel->SetMethodCallHandler(
      [plugin_pointer = plugin.get()](const auto& call, auto result) {
        plugin_pointer->HandleMethodCall(call, std::move(result));
      });

  registrar->AddPlugin(std::move(plugin));
}

void WindowCornerPlugin::HandleMethodCall(
    const flutter::MethodCall<>& method_call,
    std::unique_ptr<flutter::MethodResult<>> result) {
  if (method_call.method_name().compare("setWindowCornerRadius") == 0) {
    // Get the FlutterWindow instance
    auto* window = reinterpret_cast<FlutterWindow*>(
        GetWindowLongPtr(controller_->GetNativeWindow(), GWLP_USERDATA));

    if (window) {
      const auto* arguments = std::get_if<flutter::EncodableMap>(method_call.arguments());
      if (arguments) {
        auto radius_it = arguments->find(flutter::EncodableValue("radius"));
        if (radius_it != arguments->end()) {
          if (const auto radius = std::get_if<int>(&radius_it->second)) {
            window->SetWindowCornerRadius(*radius);
            result->Success();
            return;
          }
        }
      }
      result->Error("INVALID_ARGUMENTS", "Invalid arguments for setWindowCornerRadius");
    } else {
      result->Error("WINDOW_NOT_FOUND", "FlutterWindow instance not found");
    }
  } else {
    result->NotImplemented();
  }
}
