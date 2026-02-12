#include "window_corner_plugin_simple.h"
#include "flutter_window.h"
#include <windows.h>
#include <dwmapi.h>

namespace {
// Global pointer to the FlutterWindow instance for setting corner radius
FlutterWindow* g_flutter_window = nullptr;
}

void WindowCornerPluginSimple::RegisterWithRegistrar(
    FlutterDesktopPluginRegistrarRef registrar) {
  auto plugin = std::make_unique<WindowCornerPluginSimple>();
  auto messenger = FlutterDesktopPluginRegistrarGetMessenger(registrar);
  auto channel =
      std::make_unique<flutter::MethodChannel<flutter::EncodableValue>>(
          flutter::BinaryMessenger::MaybeFromMessageHandler(messenger), "window_corner",
          &flutter::StandardMethodCodec::GetInstance());

  channel->SetMethodCallHandler(
      [plugin_pointer = plugin.get()](const auto& call, auto result) {
        plugin_pointer->HandleMethodCall(call, std::move(result));
      });

  FlutterDesktopPluginRegistrarAddPlugin(registrar, plugin.release());
}

WindowCornerPluginSimple::WindowCornerPluginSimple() {}

void WindowCornerPluginSimple::HandleMethodCall(
    const flutter::MethodCall<flutter::EncodableValue>& method_call,
    std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) {
  if (method_call.method_name().compare("setWindowCornerRadius") == 0) {
    if (g_flutter_window) {
      const auto* arguments = std::get_if<flutter::EncodableMap>(method_call.arguments());
      if (arguments) {
        auto radius_it = arguments->find(flutter::EncodableValue("radius"));
        if (radius_it != arguments->end()) {
          if (const auto radius = std::get_if<int>(&radius_it->second)) {
            // Set window corner radius using DWM
            HWND hwnd = g_flutter_window->GetHandle();
            if (hwnd) {
              // Create rounded rectangle region
              RECT rect;
              GetWindowRect(hwnd, &rect);
              int width = rect.right - rect.left;
              int height = rect.bottom - rect.top;

              HRGN hRgn = CreateRoundRectRgn(0, 0, width + 1, height + 1, *radius * 2, *radius * 2);
              if (hRgn) {
                SetWindowRgn(hwnd, hRgn, TRUE);
              }
            }
            result->Success();
            return;
          }
        }
      }
      result->Error("INVALID_ARGUMENTS", "Invalid arguments for setWindowCornerRadius");
    } else {
      result->Error("WINDOW_NOT_FOUND", "FlutterWindow instance not found");
    }
  } else if (method_call.method_name().compare("setFlutterWindow") == 0) {
    const auto* arguments = std::get_if<flutter::EncodableMap>(method_call.arguments());
    if (arguments) {
      // Store the FlutterWindow pointer (passed as a handle from Flutter)
      // For now, we'll use a simpler approach - the window is set from main.cpp
      result->Success();
    } else {
      result->Error("INVALID_ARGUMENTS", "Invalid arguments for setFlutterWindow");
    }
  } else {
    result->NotImplemented();
  }
}

// Function to set the global FlutterWindow pointer
void SetFlutterWindowForCornerPlugin(FlutterWindow* window) {
  g_flutter_window = window;
}
