
import 'package:flutter/material.dart';
import '../constants/app_icons.dart';

class LibraryPage extends StatefulWidget {
  const LibraryPage({Key? key}) : super(key: key);

  @override
  State<LibraryPage> createState() => _LibraryPageState();
}

class _LibraryPageState extends State<LibraryPage> {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme.of(context).colorScheme.surface,
      child: Column(
        children: [
          // 顶部工具栏
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 3,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Icon(AppIcons.library, color: Theme.of(context).iconTheme.color?.withOpacity(0.7)),
                const SizedBox(width: 8),
                Text(
                  '音乐库',
                  style: TextStyle(
                    color: Theme.of(context).iconTheme.color?.withOpacity(0.7),
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                // 刷新按钮
                IconButton(
                  icon: Icon(
                    AppIcons.refresh,
                    color: Theme.of(context).iconTheme.color?.withOpacity(0.7),
                  ),
                  onPressed: () {
                    // TODO: 实现刷新功能
                  },
                  tooltip: '刷新',
                ),
              ],
            ),
          ),
          // 音乐库内容
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    AppIcons.library,
                    size: 64,
                    color: Theme.of(context).iconTheme.color?.withOpacity(0.3),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '音乐库为空',
                    style: TextStyle(
                      color: Theme.of(context).iconTheme.color?.withOpacity(0.5),
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '扫描音乐后将自动添加到音乐库',
                    style: TextStyle(
                      color: Theme.of(context).iconTheme.color?.withOpacity(0.4),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
