
@echo off
cd /d "%~dp0"
echo 正在启动独立音乐栏窗口...
flutter run -d windows -t lib/player_bar_window.dart
