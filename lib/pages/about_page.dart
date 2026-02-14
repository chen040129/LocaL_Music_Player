
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../constants/app_icons.dart';

class AboutPage extends StatefulWidget {
  final VoidCallback? onSidebarToggle;

  const AboutPage({Key? key, this.onSidebarToggle}) : super(key: key);

  @override
  State<AboutPage> createState() => _AboutPageState();
}

class _AboutPageState extends State<AboutPage> {
  // 标题悬停状态
  bool _isTitleHovered = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.transparent,
      child: Column(
        children: [
          // 顶部工具栏
          Container(
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
                MouseRegion(
                  onEnter: (_) => setState(() => _isTitleHovered = true),
                  onExit: (_) => setState(() => _isTitleHovered = false),
                  child: GestureDetector(
                    onTap: () {
                      // 通知父组件展开侧边栏
                      if (widget.onSidebarToggle != null) {
                        widget.onSidebarToggle!();
                      }
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _isTitleHovered 
                            ? Theme.of(context).colorScheme.primary.withOpacity(0.1)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            AppIcons.info, 
                            color: _isTitleHovered 
                                ? Theme.of(context).colorScheme.primary
                                : Theme.of(context).iconTheme.color?.withOpacity(0.7),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '关于',
                            style: TextStyle(
                              color: _isTitleHovered 
                                  ? Theme.of(context).colorScheme.primary
                                  : Theme.of(context).iconTheme.color?.withOpacity(0.7),
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // 关于内容
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  // 应用图标
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Icon(
                      AppIcons.musicNote,
                      size: 64,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // 应用名称
                  Text(
                    '音乐播放器',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // 版本号
                  Text(
                    '版本 1.0.0',
                    style: TextStyle(
                      color: Theme.of(context).iconTheme.color?.withOpacity(0.7),
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 32),

                  // 功能介绍
                  _buildInfoSection(
                    '功能特点',
                    [
                      '🎵 支持多种音频格式（MP3、FLAC、WAV、AAC等）',
                      '🔍 智能扫描本地音乐文件，快速建立音乐库',
                      '📝 歌词显示与滚动同步，支持多种歌词格式',
                      '🖼️ 自动提取音乐元数据和封面艺术',
                      '📋 创建和管理自定义播放列表',
                      '🎨 个性化主题设置，支持深色/浅色模式',
                      '📊 音乐统计和播放数据分析',
                      '⚙️ 丰富的播放和界面设置选项',
                      '🎭 现代化玻璃拟态设计风格',
                    ],
                  ),
                  const SizedBox(height: 24),

                  // 技术栈
                  _buildInfoSection(
                    '技术栈',
                    [
                      'Flutter - 跨平台UI框架',
                      'Provider - 状态管理',
                      'audioplayers - 音频播放引擎',
                      'audio_metadata_reader - 元数据提取',
                      'flutter_lyric - 歌词显示组件',
                      'file_picker - 文件选择器',
                      'shared_preferences - 本地数据存储',
                    ],
                  ),
                  const SizedBox(height: 24),

                  // 开源信息
                  _buildInfoSection(
                    '开源许可',
                    [
                      '本项目采用 CC BY-NC 4.0 (署名-非商业性使用 4.0) 许可证',
                      '源代码可在 GitHub 上查看和贡献',
                      '欢迎提交 Issue 和 Pull Request',
                    ],
                  ),
                  const SizedBox(height: 24),

                  // 联系方式
                  _buildContactSection(),
                  const SizedBox(height: 24),

                  // 致谢
                  _buildInfoSection(
                    '致谢',
                    [
                      '感谢以下开源项目和社区的支持：',
                      'Flutter 团队和社区',
                      '所有贡献者的努力',
                      '开源软件生态系统的支持',
                    ],
                  ),
                  const SizedBox(height: 24),

                  // 版本历史
                  _buildVersionHistory(),
                  const SizedBox(height: 100), // 底部留白，避免被音乐栏遮挡
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 构建信息章节
  Widget _buildInfoSection(String title, List<String> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        ...items.map((item) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: 6),
                    width: 4,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Theme.of(context).iconTheme.color?.withOpacity(0.5),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      item,
                      style: TextStyle(
                        color: Theme.of(context).iconTheme.color?.withOpacity(0.7),
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            )),
      ],
    );
  }

  /// 构建联系方式章节
  Widget _buildContactSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '联系我们',
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        _buildContactItem(
          icon: AppIcons.info,
          label: 'GitHub',
          value: 'https://github.com/chen040129',
          onTap: () async {
            final Uri url = Uri.parse('https://github.com/chen040129');
            if (await canLaunchUrl(url)) {
              await launchUrl(url, mode: LaunchMode.externalApplication);
            } else {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('无法打开链接'),
                    duration: Duration(seconds: 2),
                  ),
                );
              }
            }
          },
        ),
      ],
    );
  }

  /// 构建联系方式项
  Widget _buildContactItem({
    required IconData icon,
    required String label,
    required String value,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primary.withOpacity(0.05),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: Theme.of(context).colorScheme.primary,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      color: Theme.of(context).iconTheme.color?.withOpacity(0.5),
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: Theme.of(context).iconTheme.color?.withOpacity(0.3),
            ),
          ],
        ),
      ),
    );
  }

  /// 构建版本历史章节
  Widget _buildVersionHistory() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '版本历史',
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        _buildVersionItem(
          version: '1.0.0',
          date: '2024-01-15',
          features: [
            '初始版本发布',
            '支持基础音乐播放功能',
            '实现音乐扫描和元数据提取',
            '添加播放列表管理',
            '实现主题切换功能',
          ],
        ),
      ],
    );
  }

  /// 构建版本项
  Widget _buildVersionItem({
    required String version,
    required String date,
    required List<String> features,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'v$version',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                date,
                style: TextStyle(
                  color: Theme.of(context).iconTheme.color?.withOpacity(0.5),
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...features.map((feature) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.check_circle,
                      size: 16,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        feature,
                        style: TextStyle(
                          color: Theme.of(context).iconTheme.color?.withOpacity(0.7),
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }
}
