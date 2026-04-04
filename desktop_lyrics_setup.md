# 桌面歌词设置指南

## 重要说明

**关键发现**：ParticleMusic 使用的是修改版的 `window_manager` 和 `tray_manager` 插件（从 GitHub 的 AfalpHy 仓库获取的 fork 版本），而不是官方版本。这些修改版包含了对多窗口环境的特殊支持，这对于桌面歌词窗口的正常工作至关重要。

## 已完成的修改

1. ✅ 更新了 `pubspec.yaml`，使用与 ParticleMusic 相同的 fork 版本插件：
   - `window_manager`：使用 AfalpHy/window_manager fork
   - `tray_manager`：使用 AfalpHy/tray_manager fork
2. ✅ 更新了 `lib/desktop/extensions/window_controller_extension.dart`，添加了 `window_center`、`window_close` 和 `unlock` 方法的处理
3. ✅ 确认窗口配置与 ParticleMusic 一致

## 需要手动完成的步骤

### 1. 复制图标文件

从 ParticleMusic 项目复制以下图标文件到你的项目：

```bash
# 从 E:\Desktop\WATCH\ParticleMusicssets\images\ 复制到 E:\Desktop\WATCH\LocaL_Music_Playerssets\images
- previous_button.png
- next_button.png
```

### 2. 运行项目

完成图标复制后，运行以下命令：

```bash
cd E:\Desktop\WATCH\LocaL_Music_Player
flutter clean
flutter pub get
flutter run -d windows
```

## 桌面歌词功能说明

你的桌面歌词窗口现在已经与 ParticleMusic 使用相同的实现方式：

### 窗口特性
- ✅ 透明背景
- ✅ 无标题栏
- ✅ 无边框
- ✅ 始终置顶
- ✅ 不在任务栏显示（Windows 和 Linux）
- ✅ 鼠标悬停时显示半透明黑色背景和控制按钮
- ✅ 鼠标离开时变为完全透明
- ✅ 支持拖拽移动窗口
- ✅ 支持锁定功能（点击锁图标后窗口不再响应鼠标事件）

### 控制按钮
- 🔒 锁定按钮 - 锁定窗口，不再响应鼠标事件
- ⏮️ 上一首
- ⏯️ 播放/暂停
- ⏭️ 下一首
- ❌ 关闭桌面歌词

## 技术实现

使用的插件：
- `desktop_multi_window` - 创建独立的桌面歌词窗口
- `window_manager` - 管理窗口属性和行为

窗口间通信：
- 主窗口通过 `lyricsWindowController.updateLyric()` 向歌词窗口发送歌词更新
- 歌词窗口通过 `WindowController.getAll()` 获取主窗口控制器并控制播放

## 故障排除

如果桌面歌词无法正常显示：

1. 检查图标文件是否正确复制
2. 运行 `flutter clean` 清理构建缓存
3. 重新运行 `flutter pub get` 和 `flutter run`
4. 检查控制台输出，查看是否有错误信息

## 与 ParticleMusic 的差异

目前你的桌面歌词实现与 ParticleMusic 基本一致，主要区别在于：

1. 应用名称显示：ParticleMusic 显示 "Particle Music"，你的显示 "Local Music Player"
2. 图标样式：需要确保复制了相同的图标文件

如果需要完全一致的效果，建议：
- 使用与 ParticleMusic 相同的图标文件
- 调整字体大小和样式
- 确保使用相同的字体（Microsoft YaHei）
