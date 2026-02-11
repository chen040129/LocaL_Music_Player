import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import '../providers/settings_provider.dart';

class SystemSettingsPage extends StatefulWidget {
  final VoidCallback? onBack;

  const SystemSettingsPage({Key? key, this.onBack}) : super(key: key);

  @override
  State<SystemSettingsPage> createState() => _SystemSettingsPageState();
}

class _SystemSettingsPageState extends State<SystemSettingsPage> {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.transparent,
      child: Column(
        children: [
          // 顶部工具栏
          _buildTopBar(context),
          // 设置内容
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionHeader('系统设置'),
                  const SizedBox(height: 16),
                  _buildSystemSettings(context),
                  // 底部占位区域，确保内容滚动到底部时不被播放栏遮挡
                  const SizedBox(height: 90),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 构建顶部工具栏
  Widget _buildTopBar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.transparent,
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
          IconButton(
            icon: const Icon(CupertinoIcons.back),
            onPressed: widget.onBack,
            tooltip: '返回',
          ),
          const SizedBox(width: 12),
          const Icon(
            CupertinoIcons.settings,
            size: 20,
          ),
          const SizedBox(width: 8),
          const Text(
            '系统设置',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  /// 构建章节标题
  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, bottom: 12),
      child: Text(
        title,
        style: TextStyle(
          color: Theme.of(context).iconTheme.color?.withOpacity(0.7),
          fontSize: 14,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  /// 构建系统设置
  Widget _buildSystemSettings(BuildContext context) {
    return Consumer<SettingsProvider>(
      builder: (context, settings, child) {
        return Card(
          elevation: 0,
          color: Theme.of(context).colorScheme.surface.withOpacity(0.3),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: Theme.of(context).dividerColor.withOpacity(0.3),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 导出设置配置文件
                ListTile(
                  leading: const Icon(CupertinoIcons.arrow_up_doc),
                  title: const Text('导出设置配置文件'),
                  subtitle: const Text('将当前设置导出为配置文件'),
                  onTap: () async {
                    try {
                      // 获取当前设置
                      final settingsData = await settings.exportSettings();

                      // 选择保存位置
                      String? outputPath = await FilePicker.platform.saveFile(
                        dialogTitle: '导出设置配置文件',
                        fileName: 'music_settings_${DateTime.now().millisecondsSinceEpoch}.json',
                        type: FileType.custom,
                        allowedExtensions: ['json'],
                      );

                      if (outputPath != null) {
                        // 写入文件
                        final file = File(outputPath);
                        await file.writeAsString(settingsData);

                        // 显示成功消息
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('设置配置文件导出成功'),
                              duration: Duration(seconds: 2),
                            ),
                          );
                        }
                      }
                    } catch (e) {
                      // 显示错误消息
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('导出失败: $e'),
                            duration: const Duration(seconds: 3),
                          ),
                        );
                      }
                    }
                  },
                ),
                const Divider(height: 1),
                // 导入设置配置文件
                ListTile(
                  leading: const Icon(CupertinoIcons.arrow_down_doc),
                  title: const Text('导入设置配置文件'),
                  subtitle: const Text('从配置文件导入设置'),
                  onTap: () async {
                    try {
                      // 选择文件
                      FilePickerResult? result = await FilePicker.platform.pickFiles(
                        dialogTitle: '导入设置配置文件',
                        type: FileType.custom,
                        allowedExtensions: ['json'],
                      );

                      if (result != null && result.files.single.path != null) {
                        // 读取文件
                        final file = File(result.files.single.path!);
                        final settingsData = await file.readAsString();

                        // 导入设置
                        await settings.importSettings(settingsData);

                        // 显示成功消息
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('设置配置文件导入成功'),
                              duration: Duration(seconds: 2),
                            ),
                          );
                        }
                      }
                    } catch (e) {
                      // 显示错误消息
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('导入失败: $e'),
                            duration: const Duration(seconds: 3),
                          ),
                        );
                      }
                    }
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
