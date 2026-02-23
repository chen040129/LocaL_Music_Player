import 'dart:convert';
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

                      // 添加版本信息和元数据
                      final exportData = {
                        'version': '1.0.0',
                        'exportDate': DateTime.now().toIso8601String(),
                        'appName': 'Local Music Player',
                        'settings': settingsData,
                      };

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
                        await file.writeAsString(jsonEncode(exportData));

                        // 显示顶部通知
                        if (context.mounted) {
                          OverlayEntry? overlayEntry;
                          overlayEntry = OverlayEntry(
                            builder: (context) => Positioned(
                              top: 50,
                              left: 20,
                              right: 20,
                              child: Material(
                                color: Colors.transparent,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).colorScheme.inverseSurface,
                                    borderRadius: BorderRadius.circular(8),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.2),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        CupertinoIcons.checkmark_circle,
                                        color: Theme.of(context).colorScheme.primary,
                                        size: 20,
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Text(
                                          '设置配置文件已导出',
                                          style: TextStyle(
                                            color: Theme.of(context).colorScheme.onInverseSurface,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ),
                                      IconButton(
                                        icon: Icon(
                                          CupertinoIcons.clear,
                                          color: Theme.of(context).colorScheme.onInverseSurface,
                                          size: 16,
                                        ),
                                        onPressed: () {
                                          overlayEntry?.remove();
                                        },
                                        padding: EdgeInsets.zero,
                                        constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );

                          Overlay.of(context).insert(overlayEntry!);

                          // 3秒后自动移除
                          Future.delayed(const Duration(seconds: 3), () {
                            overlayEntry?.remove();
                          });
                        }
                      }
                    } catch (e) {
                      // 显示错误消息
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('导出失败: $e'),
                            duration: const Duration(seconds: 3),
                            action: SnackBarAction(
                              label: '重试',
                              onPressed: () {
                                // 重新尝试导出
                                // 这里可以添加重新尝试的逻辑
                              },
                            ),
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
                        final fileContent = await file.readAsString();

                        // 解析文件内容
                        final Map<String, dynamic> fileData = jsonDecode(fileContent);

                        // 检查文件格式
                        if (!fileData.containsKey('settings')) {
                          throw Exception('无效的配置文件格式');
                        }

                        // 显示导入确认对话框
                        final confirmed = await showDialog<bool>(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('确认导入设置'),
                            content: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('应用: ${fileData['appName'] ?? '未知'}'),
                                Text('版本: ${fileData['version'] ?? '未知'}'),
                                Text('导出日期: ${fileData['exportDate'] != null ? 
                                  DateTime.parse(fileData['exportDate']).toString().substring(0, 19) : '未知'}'),
                                const SizedBox(height: 16),
                                const Text('导入此配置文件将覆盖当前所有设置，是否继续？'),
                              ],
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.of(context).pop(false),
                                child: const Text('取消'),
                              ),
                              TextButton(
                                onPressed: () => Navigator.of(context).pop(true),
                                child: const Text('导入'),
                              ),
                            ],
                          ),
                        );

                        if (confirmed == true) {
                          // 导入设置
                          await settings.importSettings(fileData['settings']);

                          // 显示成功消息
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: const Text('设置配置文件导入成功，正在应用更改...'),
                                duration: const Duration(seconds: 3),
                                action: SnackBarAction(
                                  label: '查看',
                                  onPressed: () {
                                    // 这里可以添加跳转到设置页面的逻辑
                                  },
                                ),
                              ),
                            );
                          }
                        }
                      }
                    } catch (e) {
                      // 显示错误消息
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('导入失败: $e'),
                            duration: const Duration(seconds: 3),
                            action: SnackBarAction(
                              label: '重试',
                              onPressed: () {
                                // 重新尝试导入
                                // 这里可以添加重新尝试的逻辑
                              },
                            ),
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
