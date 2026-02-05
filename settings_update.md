
# 设置系统更新说明

## 概述
本次更新为音乐播放器应用添加了完整的设置系统，包括用户界面设置、歌词设置和播放器设置。

## 新增文件

### 1. 设置提供者 (SettingsProvider)
**文件路径**: `lib/providers/settings_provider.dart`

这是一个使用Provider模式实现的设置管理类，负责管理所有应用设置，并将设置持久化到本地存储。

#### 主要功能：
- 用户界面设置管理
  - 模糊背景开关
  - 专辑封面显示开关
  - 动画效果开关
  - UI缩放比例

- 歌词设置管理
  - 歌词对齐方式（左对齐、居中、右对齐）
  - 歌词字体大小
  - 当前歌词字体大小
  - 翻译显示开关
  - 歌词模糊效果开关
  - 歌词不透明度
  - 歌词行间距

- 播放器设置管理
  - 自动播放下一首开关
  - 保存播放进度开关
  - 显示播放次数开关
  - 淡入淡出效果开关
  - 淡入淡出时长
  - 默认音量
  - 播放器中显示歌词开关

### 2. 用户界面设置页面
**文件路径**: `lib/pages/ui_settings_page.dart`

提供用户界面相关的设置选项，包括：
- 模糊背景开关
- 显示专辑封面开关
- 启用动画开关
- UI缩放滑块

### 3. 歌词设置页面
**文件路径**: `lib/pages/lyrics_settings_page.dart`

提供歌词显示相关的设置选项，包括：
- 歌词对齐方式选择
- 歌词字体大小滑块
- 当前歌词字体大小滑块
- 显示翻译开关
- 启用歌词模糊开关
- 歌词不透明度滑块
- 歌词行间距滑块

### 4. 播放器设置页面
**文件路径**: `lib/pages/player_settings_page.dart`

提供播放器相关的设置选项，包括：
- 自动播放下一首开关
- 保存播放进度开关
- 显示播放次数开关
- 启用淡入淡出效果开关
- 淡入淡出时长滑块
- 默认音量滑块
- 播放器中显示歌词开关

### 5. 更新的设置页面
**文件路径**: `lib/pages/settings_page_updated.dart`

更新后的主设置页面，包含：
- 导航到各个设置子页面的功能
- 卡片式设置类别展示
- 悬停效果和动画

### 6. 更新的歌词小部件
**文件路径**: `lib/widgets/lyrics_widget_new_updated.dart`

更新后的歌词小部件，现在可以：
- 使用SettingsProvider中的设置
- 根据用户设置调整歌词显示
- 支持歌词对齐方式
- 支持歌词字体大小调整
- 支持歌词不透明度调整
- 支持歌词模糊效果开关

## 使用方法

### 1. 在main.dart中添加SettingsProvider

在main.dart中，需要将SettingsProvider添加到应用的Provider树中：

```dart
void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => SettingsProvider()), // 添加SettingsProvider
        // 其他providers...
      ],
      child: MyApp(),
    ),
  );
}
```

### 2. 替换现有文件

将以下文件替换为新版本：
- 将 `settings_page_updated.dart` 替换 `settings_page.dart`
- 将 `lyrics_widget_new_updated.dart` 替换 `lyrics_widget_new.dart`

### 3. 在需要使用设置的地方访问SettingsProvider

在任何需要访问设置的Widget中，可以使用以下方式：

```dart
class MyWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();

    // 使用设置
    final fontSize = settings.lyricsFontSize;
    final showBlur = settings.useBlurBackground;

    // 更新设置
    settings.setLyricsFontSize(18.0);
    settings.setUseBlurBackground(false);

    return Container();
  }
}
```

## 设置项说明

### 用户界面设置

| 设置项 | 类型 | 默认值 | 说明 |
|--------|------|--------|------|
| 模糊背景 | 布尔值 | true | 是否使用专辑封面作为模糊背景 |
| 显示专辑封面 | 布尔值 | true | 是否在播放器中显示专辑封面 |
| 启用动画 | 布尔值 | true | 是否启用界面过渡动画效果 |
| UI缩放 | 浮点数 | 1.0 | 界面元素的大小缩放比例(0.8-1.5) |

### 歌词设置

| 设置项 | 类型 | 默认值 | 说明 |
|--------|------|--------|------|
| 歌词对齐 | 枚举 | center | 歌词的对齐方式(left/center/right) |
| 歌词字体大小 | 浮点数 | 16.0 | 普通歌词的字体大小(12-24) |
| 当前歌词字体大小 | 浮点数 | 22.0 | 当前播放歌词的字体大小(16-32) |
| 显示翻译 | 布尔值 | true | 是否显示歌词的翻译文本 |
| 启用歌词模糊 | 布尔值 | true | 是否在歌词上下区域添加模糊效果 |
| 歌词不透明度 | 浮点数 | 1.0 | 歌词的透明度(0.3-1.0) |
| 歌词行间距 | 整数 | 8 | 歌词行之间的间距(4-16) |

### 播放器设置

| 设置项 | 类型 | 默认值 | 说明 |
|--------|------|--------|------|
| 自动播放下一首 | 布尔值 | true | 当前歌曲播放结束后自动播放下一首 |
| 保存播放进度 | 布尔值 | true | 记住每首歌的播放位置 |
| 显示播放次数 | 布尔值 | true | 在歌曲列表中显示播放次数 |
| 启用淡入淡出 | 布尔值 | true | 播放和暂停时使用淡入淡出效果 |
| 淡入淡出时长 | 浮点数 | 2.0 | 淡入淡出效果的时长(0.5-5.0秒) |
| 默认音量 | 整数 | 70 | 播放器的默认音量(0-100) |
| 播放器中显示歌词 | 布尔值 | true | 在播放器界面中显示歌词 |

## 注意事项

1. 所有设置都会自动保存到本地存储，下次启动应用时会自动加载
2. 设置更改会立即生效，并通知所有监听的Widget更新
3. 可以通过调用`resetToDefaults()`方法重置所有设置为默认值
4. 所有设置值都有合理的范围限制，防止用户设置极端值

## 未来改进

1. 添加更多设置类别（如快捷键设置、高级设置等）
2. 添加设置导入/导出功能
3. 添加设置预设功能
4. 添加设置搜索功能
5. 添加设置分组功能
