#include "flutter_window.h"

#include <dwmapi.h>
#include <optional>
#include <windowsx.h>

#include "flutter/generated_plugin_registrant.h"

FlutterWindow::FlutterWindow(const flutter::DartProject& project)
    : project_(project) {}

FlutterWindow::~FlutterWindow() {}

bool FlutterWindow::OnCreate() {
  if (!Win32Window::OnCreate()) {
    return false;
  }

  // Extend DWM frame into client area to achieve borderless effect
  MARGINS margins = {0};
  DwmExtendFrameIntoClientArea(GetHandle(), &margins);

  // Remove the standard title bar and make window borderless
  LONG style = GetWindowLong(GetHandle(), GWL_STYLE);
  style &= ~(WS_CAPTION | WS_THICKFRAME | WS_MINIMIZE | WS_MAXIMIZE | WS_SYSMENU);
  SetWindowLong(GetHandle(), GWL_STYLE, style);

  // Remove the extended window styles
  LONG exStyle = GetWindowLong(GetHandle(), GWL_EXSTYLE);
  exStyle &= ~(WS_EX_DLGMODALFRAME | WS_EX_CLIENTEDGE | WS_EX_STATICEDGE);
  SetWindowLong(GetHandle(), GWL_EXSTYLE, exStyle);

  // Set window to redraw
  SetWindowPos(GetHandle(), NULL, 0, 0, 0, 0, SWP_NOMOVE | SWP_NOSIZE | SWP_NOZORDER | SWP_FRAMECHANGED);

  RECT frame = GetClientArea();

  // The size here must match the window dimensions to avoid unnecessary surface
  // creation / destruction in the startup path.
  flutter_controller_ = std::make_unique<flutter::FlutterViewController>(
      frame.right - frame.left, frame.bottom - frame.top, project_);
  // Ensure that basic setup of the controller was successful.
  if (!flutter_controller_->engine() || !flutter_controller_->view()) {
    return false;
  }
  RegisterPlugins(flutter_controller_->engine());
  SetChildContent(flutter_controller_->view()->GetNativeWindow());

  flutter_controller_->engine()->SetNextFrameCallback([&]() {
    this->Show();
  });

  // Flutter can complete the first frame before the "show window" callback is
  // registered. The following call ensures a frame is pending to ensure the
  // window is shown. It is a no-op if the first frame hasn't completed yet.
  flutter_controller_->ForceRedraw();

  // Set window to be layered with transparent background
  LONG exstyle = GetWindowLong(GetHandle(), GWL_EXSTYLE);
  exstyle |= WS_EX_LAYERED;
  SetWindowLong(GetHandle(), GWL_EXSTYLE, exstyle);

  // Make the window background transparent
  SetLayeredWindowAttributes(GetHandle(), 0, 255, LWA_ALPHA);

  return true;
}

void FlutterWindow::OnDestroy() {
  if (flutter_controller_) {
    flutter_controller_ = nullptr;
  }

  Win32Window::OnDestroy();
}

LRESULT
FlutterWindow::MessageHandler(HWND hwnd, UINT const message,
                              WPARAM const wparam,
                              LPARAM const lparam) noexcept {
  // Give Flutter, including plugins, an opportunity to handle window messages.
  if (flutter_controller_) {
    std::optional<LRESULT> result =
        flutter_controller_->HandleTopLevelWindowProc(hwnd, message, wparam,
                                                      lparam);
    if (result) {
      return *result;
    }
  }

  switch (message) {
    case WM_FONTCHANGE:
      flutter_controller_->engine()->ReloadSystemFonts();
      break;
    case WM_THEMECHANGED:
      // Force window redraw when theme changes
      InvalidateRect(GetHandle(), NULL, TRUE);
      UpdateWindow(GetHandle());
      break;
    case WM_NCHITTEST: {
      // Handle WM_NCHITTEST message to support window dragging
      POINT pt;
      pt.x = GET_X_LPARAM(lparam);
      pt.y = GET_Y_LPARAM(lparam);
      ScreenToClient(hwnd, &pt);

      // Get window client area size
      RECT clientRect;
      GetClientRect(hwnd, &clientRect);

      // Define title bar area height
      const int captionHeight = 32;

      // If mouse is in title bar area, return HTCAPTION to make window draggable
      if (pt.y < captionHeight) {
        return HTCAPTION;
      }

      // Handle window edge resizing
      const int borderSize = 8;
      if (pt.x < borderSize && pt.y < borderSize) {
        return HTTOPLEFT;
      } else if (pt.x > clientRect.right - borderSize && pt.y < borderSize) {
        return HTTOPRIGHT;
      } else if (pt.x < borderSize && pt.y > clientRect.bottom - borderSize) {
        return HTBOTTOMLEFT;
      } else if (pt.x > clientRect.right - borderSize && pt.y > clientRect.bottom - borderSize) {
        return HTBOTTOMRIGHT;
      } else if (pt.y < borderSize) {
        return HTTOP;
      } else if (pt.y > clientRect.bottom - borderSize) {
        return HTBOTTOM;
      } else if (pt.x < borderSize) {
        return HTLEFT;
      } else if (pt.x > clientRect.right - borderSize) {
        return HTRIGHT;
      }

      break;
    }
  }

  return Win32Window::MessageHandler(hwnd, message, wparam, lparam);
}
