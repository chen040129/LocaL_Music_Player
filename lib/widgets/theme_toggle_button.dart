
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/theme_provider.dart';
import '../constants/app_icons.dart';

class ThemeToggleButton extends StatelessWidget {
  const ThemeToggleButton({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return PopupMenuButton<ThemeMode>(
      icon: Icon(
        themeProvider.isDarkMode ? AppIcons.darkMode : AppIcons.lightMode,
        color: Theme.of(context).iconTheme.color,
      ),
      tooltip: '切换主题',
      onSelected: (ThemeMode mode) {
        themeProvider.setThemeMode(mode);
      },
      itemBuilder: (BuildContext context) => <PopupMenuEntry<ThemeMode>>[
        PopupMenuItem<ThemeMode>(
          value: ThemeMode.light,
          child: Row(
            children: [
              Icon(AppIcons.lightMode, color: Colors.amber),
              const SizedBox(width: 8),
              Text('浅色主题'),
            ],
          ),
        ),
        PopupMenuItem<ThemeMode>(
          value: ThemeMode.dark,
          child: Row(
            children: [
              Icon(AppIcons.darkMode, color: Colors.indigo),
              const SizedBox(width: 8),
              Text('深色主题'),
            ],
          ),
        ),
        PopupMenuItem<ThemeMode>(
          value: ThemeMode.system,
          child: Row(
            children: [
              Icon(AppIcons.settingsBrightness, color: Colors.grey),
              const SizedBox(width: 8),
              Text('跟随系统'),
            ],
          ),
        ),
      ],
    );
  }
}

// 简单的切换按钮，用于直接在明暗主题之间切换
class SimpleThemeToggleButton extends StatelessWidget {
  const SimpleThemeToggleButton({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return IconButton(
      icon: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: Icon(
          themeProvider.isDarkMode ? AppIcons.darkMode : AppIcons.lightMode,
          key: ValueKey<bool>(themeProvider.isDarkMode),
          color: Theme.of(context).iconTheme.color,
        ),
      ),
      onPressed: () {
        themeProvider.toggleTheme();
      },
      tooltip: themeProvider.isDarkMode ? '切换到浅色主题' : '切换到深色主题',
    );
  }
}
