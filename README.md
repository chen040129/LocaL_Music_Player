# Flutter 音乐播放器

一款基于 Flutter 开发的现代化本地音乐播放器，采用 Material Design 3 设计风格，提供流畅的用户体验和丰富的功能。

![Flutter](https://img.shields.io/badge/Flutter-3.0+-blue.svg)
![License](https://img.shields.io/badge/License-MIT-green.svg)
![Platform](https://img.shields.io/badge/Platform-Windows%20%7C%20macOS%20%7C%20Linux-lightgrey.svg)

## ✨ 功能特点

- 🎵 **多格式支持**：支持 MP3、FLAC、WAV 等多种音频格式
- 🔍 **智能扫描**：快速扫描本地音乐文件，自动提取元数据和封面
- 📝 **歌词显示**：支持歌词显示和滚动同步
- 📋 **播放列表**：创建和管理自定义播放列表
- 🎨 **主题切换**：支持深色/浅色主题，可自定义主题颜色
- 📊 **音乐统计**：提供播放统计和音乐数据分析
- 🖼️ **专辑管理**：按专辑和艺术家浏览音乐
- ⚙️ **灵活设置**：丰富的播放和界面设置选项
- 🎭 **玻璃拟态**：采用现代化的玻璃拟态设计风格
-  **UI设计参考**：部分UI参考了salt_music,网易云等音乐软件

## 🛠️ 技术栈

- **Flutter** - 跨平台 UI 框架
- **Provider** - 状态管理
- **audioplayers** - 音频播放
- **audio_metadata_reader** - 音频元数据读取
- **flutter_lyric** - 歌词显示
- **file_picker** - 文件选择
- **shared_preferences** - 本地数据存储

## 📦 安装步骤

### 前置要求

- Flutter SDK 3.0 或更高版本
- Dart SDK 2.17 或更高版本
- Windows/macOS/Linux 操作系统

### 克隆项目

```bash
git clone https://github.com/yourusername/flutter_music_player.git
cd flutter_music_player/MUSIC
```

### 安装依赖

```bash
flutter pub get
```

### 运行应用

```bash
flutter run
```

## 📖 使用指南

### 添加音乐

1. 点击侧边栏的"扫描音乐"按钮
2. 选择包含音乐文件的文件夹
3. 等待扫描完成，音乐将自动添加到库中

### 播放音乐

1. 在"歌曲"、"专辑"或"艺术家"页面浏览音乐
2. 点击歌曲开始播放
3. 使用底部播放控制栏控制播放进度、音量等

### 创建播放列表

1. 进入"歌单"页面
2. 点击创建新歌单
3. 为歌单命名并添加歌曲

### 自定义主题

1. 进入"设置"页面
2. 选择"主题设置"
3. 自定义主题颜色、字体大小等

## 📄 开源许可

本项目采用 MIT 许可证 - 详见 [LICENSE](LICENSE) 文件

## 🤝 贡献

欢迎提交 Issue 和 Pull Request！

## 📮 联系方式

- GitHub Issues: [提交问题](https://github.com/yourusername/flutter_music_player/issues)

## 🙏 致谢

感谢以下开源项目的支持：

- [Flutter](https://flutter.dev/)
- [audioplayers](https://github.com/luanpotter/audioplayers)
- [audio_metadata_reader](https://github.com/SinoAppEngine/audio_metadata_reader)
- [flutter_lyric](https://github.com/fluttercandies/flutter_lyric)
- [Provider](https://pub.dev/packages/provider)
