
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/theme_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/theme_toggle_button.dart';
import '../constants/app_icons.dart';

class HomePage extends StatelessWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('音乐播放器'),
            actions: const [
              ThemeToggleButton(), // 使用弹出菜单式的主题切换按钮
              // 如果想使用简单的切换按钮，可以替换为: SimpleThemeToggleButton()
            ],
          ),
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '当前主题: ${themeProvider.themeMode.toString().split('.').last}',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 20),
                Card(
                  margin: const EdgeInsets.all(16),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Text(
                          '主题切换演示',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 10),
                        const Text('点击右上角图标切换主题'),
                        const SizedBox(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            ElevatedButton(
                              onPressed: () => themeProvider.setThemeMode(ThemeMode.light),
                              child: const Text('浅色'),
                            ),
                            ElevatedButton(
                              onPressed: () => themeProvider.setThemeMode(ThemeMode.dark),
                              child: const Text('深色'),
                            ),
                            ElevatedButton(
                              onPressed: () => themeProvider.setThemeMode(ThemeMode.system),
                              child: const Text('跟随系统'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        const SimpleThemeToggleButton(), // 使用简单的切换按钮
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: () {
              themeProvider.toggleTheme();
            },
            tooltip: '切换主题',
            child: Icon(
              themeProvider.isDarkMode ? AppIcons.lightMode : AppIcons.darkMode,
            ),
          ),
        );
      },
    );
  }
}
