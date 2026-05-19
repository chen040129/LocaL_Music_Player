import 'dart:io';
import 'dart:math';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/dsp_provider.dart';

/// DSP 音频效果设置页面
class DspSettingsPage extends StatefulWidget {
  const DspSettingsPage({Key? key}) : super(key: key);

  @override
  State<DspSettingsPage> createState() => _DspSettingsPageState();
}

class _DspSettingsPageState extends State<DspSettingsPage>
    with TickerProviderStateMixin {
  late TabController _tabController;
  String? _selectedEqPreset;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _selectEqPreset(String? preset) {
    if (_selectedEqPreset == preset) return;
    setState(() {
      _selectedEqPreset = preset;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Consumer<DspProvider>(
      builder: (context, dspProvider, child) {
        return Column(
          children: [
            // 顶部标题栏 + DSP 总开关
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Row(
                children: [
                  Text(
                    '音频效果',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  // 导入/导出按钮
                  PopupMenuButton<String>(
                    icon: Icon(
                      Icons.more_vert,
                      color: colorScheme.onSurface.withOpacity(0.6),
                    ),
                    tooltip: '导入/导出配置',
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    onSelected: (value) {
                      if (value == 'export') {
                        _exportConfig(dspProvider);
                      } else if (value == 'import') {
                        _importConfig(dspProvider);
                      }
                    },
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        value: 'export',
                        child: Row(
                          children: [
                            Icon(Icons.upload_file,
                                size: 18, color: colorScheme.primary),
                            const SizedBox(width: 8),
                            const Text('导出配置'),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'import',
                        child: Row(
                          children: [
                            Icon(Icons.download,
                                size: 18, color: colorScheme.primary),
                            const SizedBox(width: 8),
                            const Text('导入配置'),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 4),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'DSP 处理',
                        style: TextStyle(
                          color: dspProvider.dspEnabled
                              ? colorScheme.primary
                              : colorScheme.onSurface.withOpacity(0.6),
                          fontWeight: dspProvider.dspEnabled
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Switch.adaptive(
                        value: dspProvider.dspEnabled,
                        onChanged: (value) {
                          dspProvider.toggleDsp(value);
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),

            if (dspProvider.dspEnabled && !dspProvider.isInitialized)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: LinearProgressIndicator(
                  borderRadius: BorderRadius.circular(4),
                ),
              ),

            if (dspProvider.dspEnabled && dspProvider.isInitialized) ...[
              TabBar(
                controller: _tabController,
                tabs: const [
                  Tab(text: '均衡器'),
                  Tab(text: '音效'),
                  Tab(text: '高级'),
                ],
                labelColor: colorScheme.primary,
                unselectedLabelColor: colorScheme.onSurface.withOpacity(0.6),
                indicatorColor: colorScheme.primary,
              ),
              const SizedBox(height: 8),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildEqualizerTab(dspProvider, theme, colorScheme),
                    _buildEffectsTab(dspProvider, theme, colorScheme),
                    _buildAdvancedTab(dspProvider, theme, colorScheme),
                  ],
                ),
              ),
            ] else ...[
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.graphic_eq_rounded,
                        size: 80,
                        color: colorScheme.onSurface.withOpacity(0.15),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        dspProvider.dspEnabled
                            ? '正在初始化 DSP，请稍候'
                            : '开启 DSP 处理以使用音频效果',
                        style: TextStyle(
                          color: colorScheme.onSurface.withOpacity(0.4),
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        dspProvider.dspEnabled
                            ? '均衡器、混响、回声、变调等正在准备'
                            : '均衡器、混响、回声、变调等',
                        style: TextStyle(
                          color: colorScheme.onSurface.withOpacity(0.3),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        );
      },
    );
  }

  // ==================== 均衡器 Tab ====================

  Widget _buildEqualizerTab(
    DspProvider dspProvider,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    final eqEnabled =
        dspProvider.filterStates[DspFilterType.equalizer]?.isEnabled ?? false;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 均衡器开关
          Row(
            children: [
              Icon(Icons.equalizer, color: colorScheme.primary, size: 20),
              const SizedBox(width: 8),
              Text(
                '均衡器',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              Switch.adaptive(
                value: eqEnabled,
                onChanged: (value) {
                  dspProvider.toggleFilter(DspFilterType.equalizer, value);
                },
              ),
            ],
          ),
          const SizedBox(height: 16),

          if (eqEnabled) ...[
            // 预设选择
            Row(
              children: [
                Text(
                  '预设',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
                const Spacer(),
                // 保存自定义预设按钮
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () => _showSavePresetDialog(dspProvider),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.save_outlined,
                            size: 14,
                            color: colorScheme.primary.withOpacity(0.8),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '保存当前',
                            style: TextStyle(
                              fontSize: 11,
                              color: colorScheme.primary.withOpacity(0.8),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildPresetChip(
                  '默认',
                  () {
                    dspProvider.resetEqBands();
                    _selectEqPreset('默认');
                  },
                  _selectedEqPreset == '默认',
                ),
                _buildPresetChip(
                  '低音增强',
                  () {
                    _applyPreset(dspProvider, _bassBoost);
                    _selectEqPreset('低音增强');
                  },
                  _selectedEqPreset == '低音增强',
                ),
                _buildPresetChip(
                  '高音增强',
                  () {
                    _applyPreset(dspProvider, _trebleBoost);
                    _selectEqPreset('高音增强');
                  },
                  _selectedEqPreset == '高音增强',
                ),
                _buildPresetChip(
                  '人声增强',
                  () {
                    _applyPreset(dspProvider, _vocalBoost);
                    _selectEqPreset('人声增强');
                  },
                  _selectedEqPreset == '人声增强',
                ),
                _buildPresetChip(
                  '摇滚',
                  () {
                    _applyPreset(dspProvider, _rock);
                    _selectEqPreset('摇滚');
                  },
                  _selectedEqPreset == '摇滚',
                ),
                _buildPresetChip(
                  '流行',
                  () {
                    _applyPreset(dspProvider, _pop);
                    _selectEqPreset('流行');
                  },
                  _selectedEqPreset == '流行',
                ),
                _buildPresetChip(
                  '古典',
                  () {
                    _applyPreset(dspProvider, _classical);
                    _selectEqPreset('古典');
                  },
                  _selectedEqPreset == '古典',
                ),
                _buildPresetChip(
                  '电子',
                  () {
                    _applyPreset(dspProvider, _electronic);
                    _selectEqPreset('电子');
                  },
                  _selectedEqPreset == '电子',
                ),
              ],
            ),

            // 自定义预设列表
            if (dspProvider.customPresets.isNotEmpty) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Text(
                    '自定义预设',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: dspProvider.customPresets.map((preset) {
                  final isSelected = _selectedEqPreset == preset.name;
                  return _buildCustomPresetChip(
                    preset: preset,
                    isSelected: isSelected,
                    dspProvider: dspProvider,
                    colorScheme: colorScheme,
                  );
                }).toList(),
              ),
            ],

            const SizedBox(height: 8),
            Text(
              '当前预设：${_selectedEqPreset ?? '自定义'}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
            const SizedBox(height: 16),

            // EQ 频率曲线预览图
            _EqCurvePreview(
              eqBands: dspProvider.eqBands,
              colorScheme: colorScheme,
            ),
            const SizedBox(height: 16),

            // 频段调节
            Text(
              '频段调节',
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
            const SizedBox(height: 12),
            ...List.generate(dspProvider.eqBands.length, (index) {
              final band = dspProvider.eqBands[index];
              return _buildEqBandSlider(
                dspProvider: dspProvider,
                bandIndex: index,
                band: band,
                colorScheme: colorScheme,
              );
            }),
            // 底部留白，避免被播放栏遮挡
            const SizedBox(height: 80),
          ],
        ],
      ),
    );
  }

  Widget _buildEqBandSlider({
    required DspProvider dspProvider,
    required int bandIndex,
    required EqBand band,
    required ColorScheme colorScheme,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 40,
            child: Text(
              band.label,
              style: TextStyle(
                fontSize: 12,
                color: colorScheme.onSurface.withOpacity(0.7),
              ),
              textAlign: TextAlign.right,
            ),
          ),
          const SizedBox(width: 8),
          // 最小值标注
          SizedBox(
            width: 28,
            child: Text(
              '-24',
              style: TextStyle(
                fontSize: 9,
                color: colorScheme.onSurface.withOpacity(0.35),
              ),
              textAlign: TextAlign.right,
            ),
          ),
          Expanded(
            child: SliderTheme(
              data: SliderThemeData(
                trackHeight: 3,
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
                overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
                activeTrackColor: band.gain > 0
                    ? Colors.orange
                    : band.gain < 0
                        ? Colors.blue
                        : colorScheme.onSurface.withOpacity(0.3),
                inactiveTrackColor: colorScheme.onSurface.withOpacity(0.15),
                thumbColor: colorScheme.primary,
              ),
              child: Slider(
                value: band.gain.clamp(-24.0, 12.0),
                min: -24.0,
                max: 12.0,
                divisions: 360,
                onChanged: (value) {
                  if (_selectedEqPreset != null) {
                    setState(() {
                      _selectedEqPreset = null;
                    });
                  }
                  dspProvider.setEqBandGain(bandIndex, value);
                },
              ),
            ),
          ),
          // 最大值标注
          SizedBox(
            width: 28,
            child: Text(
              '+12',
              style: TextStyle(
                fontSize: 9,
                color: colorScheme.onSurface.withOpacity(0.35),
              ),
              textAlign: TextAlign.left,
            ),
          ),
          const SizedBox(width: 4),
          SizedBox(
            width: 55,
            child: Text(
              '${band.gain > 0 ? '+' : ''}${band.gain.toStringAsFixed(1)} dB',
              style: TextStyle(
                fontSize: 11,
                color: colorScheme.onSurface.withOpacity(0.5),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPresetChip(String label, VoidCallback onTap, bool selected) {
    final colorScheme = Theme.of(context).colorScheme;
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      selectedColor: colorScheme.primary.withOpacity(0.14),
      onSelected: (_) {
        onTap();
      },
      backgroundColor: colorScheme.surface,
      side: BorderSide(color: colorScheme.onSurface.withOpacity(0.15)),
    );
  }

  /// 构建自定义预设芯片（带删除按钮）
  Widget _buildCustomPresetChip({
    required CustomEqPreset preset,
    required bool isSelected,
    required DspProvider dspProvider,
    required ColorScheme colorScheme,
  }) {
    return InputChip(
      label: Text(preset.name),
      selected: isSelected,
      selectedColor: colorScheme.primary.withOpacity(0.14),
      onSelected: (_) {
        dspProvider.applyCustomPreset(preset);
        _selectEqPreset(preset.name);
      },
      deleteIconColor: colorScheme.error.withOpacity(0.6),
      onDeleted: () {
        _showDeletePresetConfirmDialog(preset.name, dspProvider);
      },
      backgroundColor: colorScheme.surface,
      side: BorderSide(color: colorScheme.onSurface.withOpacity(0.15)),
    );
  }

  /// 显示保存预设对话框
  void _showSavePresetDialog(DspProvider dspProvider) {
    final textController = TextEditingController();
    final colorScheme = Theme.of(context).colorScheme;
    String? errorText;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('保存自定义预设'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '将当前均衡器设置保存为自定义预设',
                    style: TextStyle(
                      fontSize: 13,
                      color: colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: textController,
                    autofocus: true,
                    decoration: InputDecoration(
                      labelText: '预设名称',
                      hintText: '输入预设名称',
                      errorText: errorText,
                      border: const OutlineInputBorder(),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 10),
                    ),
                    onChanged: (value) {
                      if (errorText != null) {
                        setDialogState(() {
                          errorText = null;
                        });
                      }
                    },
                    onSubmitted: (_) {
                      _doSavePreset(
                        textController.text.trim(),
                        dspProvider,
                        dialogContext,
                        (err) {
                          setDialogState(() {
                            errorText = err;
                          });
                        },
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                  // 显示当前增益值预览
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: colorScheme.surface,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: colorScheme.onSurface.withOpacity(0.08),
                      ),
                    ),
                    child: Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: dspProvider.eqBands.map((band) {
                        return Text(
                          '${band.label}: ${band.gain > 0 ? '+' : ''}${band.gain.toStringAsFixed(1)}',
                          style: TextStyle(
                            fontSize: 10,
                            color: colorScheme.onSurface.withOpacity(0.5),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('取消'),
                ),
                FilledButton(
                  onPressed: () {
                    _doSavePreset(
                      textController.text.trim(),
                      dspProvider,
                      dialogContext,
                      (err) {
                        setDialogState(() {
                          errorText = err;
                        });
                      },
                    );
                  },
                  child: const Text('保存'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  /// 执行保存预设逻辑
  void _doSavePreset(
    String name,
    DspProvider dspProvider,
    BuildContext dialogContext,
    void Function(String?) onError,
  ) {
    if (name.isEmpty) {
      onError('请输入预设名称');
      return;
    }

    if (dspProvider.hasCustomPreset(name)) {
      // 名称已存在，弹出覆盖确认
      Navigator.of(dialogContext).pop();
      _showOverwriteConfirmDialog(name, dspProvider);
      return;
    }

    dspProvider.saveCustomPreset(name).then((_) {
      Navigator.of(dialogContext).pop();
      _selectEqPreset(name);
    });
  }

  /// 显示覆盖预设确认对话框
  void _showOverwriteConfirmDialog(String name, DspProvider dspProvider) {
    final colorScheme = Theme.of(context).colorScheme;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('覆盖预设'),
          content: Text(
            '预设"$name"已存在，是否覆盖？',
            style: TextStyle(color: colorScheme.onSurface.withOpacity(0.7)),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('取消'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: colorScheme.error,
              ),
              onPressed: () {
                dspProvider.overwriteCustomPreset(name).then((_) {
                  Navigator.of(dialogContext).pop();
                  _selectEqPreset(name);
                });
              },
              child: const Text('覆盖'),
            ),
          ],
        );
      },
    );
  }

  /// 显示删除预设确认对话框
  void _showDeletePresetConfirmDialog(String name, DspProvider dspProvider) {
    final colorScheme = Theme.of(context).colorScheme;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('删除预设'),
          content: Text(
            '确定删除自定义预设"$name"？',
            style: TextStyle(color: colorScheme.onSurface.withOpacity(0.7)),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('取消'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: colorScheme.error,
              ),
              onPressed: () {
                dspProvider.deleteCustomPreset(name).then((_) {
                  Navigator.of(dialogContext).pop();
                  // 如果删除的是当前选中的预设，切换为自定义
                  if (_selectedEqPreset == name) {
                    setState(() {
                      _selectedEqPreset = null;
                    });
                  }
                });
              },
              child: const Text('删除'),
            ),
          ],
        );
      },
    );
  }

  // ==================== 配置导出/导入 ====================

  /// 导出 DSP 配置
  Future<void> _exportConfig(DspProvider dspProvider) async {
    try {
      final jsonStr = dspProvider.exportConfig();
      final timestamp = DateTime.now()
          .toIso8601String()
          .replaceAll(':', '-')
          .substring(0, 19);
      final defaultFileName = 'dsp_config_$timestamp.json';

      // 使用 file_picker 选择保存位置
      final savePath = await FilePicker.platform.saveFile(
        dialogTitle: '保存 DSP 配置文件',
        fileName: defaultFileName,
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (savePath == null) return; // 用户取消

      // 确保文件扩展名为 .json
      final filePath = savePath.endsWith('.json') ? savePath : '$savePath.json';
      final file = File(filePath);
      await file.writeAsString(jsonStr);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('配置已导出至：$filePath'),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('导出失败：$e'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  /// 导入 DSP 配置
  Future<void> _importConfig(DspProvider dspProvider) async {
    try {
      // 使用 file_picker 选择 JSON 文件
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
        dialogTitle: '选择 DSP 配置文件',
      );

      if (result == null || result.files.isEmpty) return;

      final filePath = result.files.single.path;
      if (filePath == null) return;

      final file = File(filePath);
      final jsonStr = await file.readAsString();

      // 确认导入
      final confirmed = await _showImportConfirmDialog();
      if (confirmed != true) return;

      // 执行导入
      final error = await dspProvider.importConfig(jsonStr);
      if (mounted) {
        if (error != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('导入失败：$error'),
              behavior: SnackBarBehavior.floating,
              backgroundColor: Theme.of(context).colorScheme.error,
              duration: const Duration(seconds: 3),
            ),
          );
        } else {
          // 重置预设选择状态
          setState(() {
            _selectedEqPreset = null;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('配置导入成功'),
              behavior: SnackBarBehavior.floating,
              duration: Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('导入失败：$e'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  /// 显示导入确认对话框
  Future<bool?> _showImportConfirmDialog() {
    final colorScheme = Theme.of(context).colorScheme;
    return showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('导入配置'),
          content: Text(
            '导入配置将覆盖当前所有音频效果设置，包括均衡器、音效和高级参数。是否继续？',
            style: TextStyle(
              color: colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('取消'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('导入'),
            ),
          ],
        );
      },
    );
  }

  void _applyPreset(DspProvider dspProvider, List<double> gains) {
    for (int i = 0; i < gains.length && i < dspProvider.eqBands.length; i++) {
      dspProvider.setEqBandGain(i, gains[i]);
    }
  }

  // 均衡器预设
  // 设计原则：以提升为主，避免过多负增益导致声音发焖
  // SoLoud EQ 是 FFT 型均衡器，负增益衰减效果比正增益提升更明显
  static const _bassBoost = [0.0, 3.0, 5.0, 3.0, 1.0, 0.0, 0.0, 0.0];
  static const _trebleBoost = [0.0, 0.0, 0.0, 0.0, 1.0, 3.0, 5.0, 6.0];
  static const _vocalBoost = [0.0, 0.0, 2.0, 4.0, 4.0, 3.0, 1.0, 0.0];
  static const _rock = [3.0, 2.0, 0.0, 0.0, 1.0, 2.0, 3.0, 4.0];
  static const _pop = [0.0, 1.0, 3.0, 4.0, 3.0, 1.0, 0.0, 0.0];
  static const _classical = [3.0, 2.0, 1.0, 1.0, 0.0, 0.0, 2.0, 3.0];
  static const _electronic = [4.0, 3.0, 0.0, 0.0, 0.0, 1.0, 3.0, 4.0];

  // ==================== 音效 Tab ====================

  Widget _buildEffectsTab(
    DspProvider dspProvider,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    final effects = [
      _EffectConfig(DspFilterType.bassboost, '低音增强', '增强低频部分，让音乐更有力度',
          Icons.speaker, Colors.orange, [
        _ParamConfig(0, '增强', 0.0, 10.0, 2.0),
      ]),
      _EffectConfig(
          DspFilterType.echo, '回声', '添加回声延迟效果', Icons.waves, Colors.purple, [
        _ParamConfig(0, '延迟', 0.001, 5.0, 0.3),
        _ParamConfig(1, '衰减', 0.001, 1.0, 0.7),
        _ParamConfig(2, '滤波', 0.0, 1.0, 0.0),
      ]),
      _EffectConfig(DspFilterType.reverb, '混响', '模拟空间混响效果',
          Icons.spatial_audio_off, Colors.blue, [
        _ParamConfig(0, '冻结', 0.0, 1.0, 0.0),
        _ParamConfig(1, '空间大小', 0.0, 1.0, 0.5),
        _ParamConfig(2, '阻尼', 0.0, 1.0, 0.5),
      ]),
      _EffectConfig(DspFilterType.flanger, '镶边', '添加镶边/合唱效果',
          Icons.auto_fix_high, Colors.teal, [
        _ParamConfig(0, '延迟', 0.0, 3.0, 1.0),
        _ParamConfig(1, '立体声深度', -48.0, 48.0, 0.0),
      ]),
      _EffectConfig(DspFilterType.pitchShift, '变调', '改变音高而不改变速度', Icons.tune,
          Colors.green, [
        _ParamConfig(0, '音高', -36.0, 36.0, 0.0),
      ]),
    ];

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 80),
      itemCount: effects.length,
      itemBuilder: (context, index) {
        final effect = effects[index];
        final isEnabled =
            dspProvider.filterStates[effect.type]?.isEnabled ?? false;
        return _buildEffectCard(
          dspProvider: dspProvider,
          effect: effect,
          isEnabled: isEnabled,
          theme: theme,
          colorScheme: colorScheme,
        );
      },
    );
  }

  // ==================== 高级 Tab ====================

  Widget _buildAdvancedTab(
    DspProvider dspProvider,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    final effects = [
      _EffectConfig(DspFilterType.compressor, '压缩器', '压缩动态范围，使音量更均匀',
          Icons.compress, Colors.red, [
        _ParamConfig(1, '阈值', -80.0, 0.0, -6.0),
        _ParamConfig(2, '补偿增益', -40.0, 40.0, 0.0),
        _ParamConfig(3, '拐点宽度', 0.0, 40.0, 2.0),
        _ParamConfig(4, '比率', 1.0, 10.0, 3.0),
        _ParamConfig(5, '启动时间', 0.0, 100.0, 10.0),
        _ParamConfig(6, '释放时间', 0.0, 1000.0, 100.0),
      ]),
      _EffectConfig(DspFilterType.limiter, '限幅器', '限制最大音量，防止削波',
          Icons.volume_up, Colors.amber, [
        _ParamConfig(1, '阈值', -60.0, 0.0, -6.0),
        _ParamConfig(2, '输出上限', -60.0, 0.0, -1.0),
        _ParamConfig(3, '拐点宽度', 0.0, 30.0, 2.0),
        _ParamConfig(5, '释放时间', 1.0, 1000.0, 100.0),
        _ParamConfig(4, '启动时间', 0.1, 200.0, 1.0),
      ]),
      _EffectConfig(DspFilterType.waveShaper, '波形塑形', '改变波形产生失真效果',
          Icons.show_chart, Colors.pink, [
        _ParamConfig(0, '塑形', -1.0, 1.0, 0.0),
      ]),
      _EffectConfig(DspFilterType.robotize, '机器人声', '产生机器人般的声效',
          Icons.smart_toy, Colors.indigo, [
        _ParamConfig(0, '频率', 0.1, 100.0, 10.0),
        _ParamConfig(1, '波形', 0.0, 6.0, 0.0),
      ]),
      _EffectConfig(DspFilterType.lofi, 'Lo-Fi', '降低采样率产生复古效果',
          Icons.queue_music, Colors.brown, [
        _ParamConfig(0, '采样率', 100.0, 22000.0, 4000.0),
        _ParamConfig(1, '比特深度', 0.5, 16.0, 3.0),
      ]),
      _EffectConfig(DspFilterType.biquadResonant, '谐振滤波器', '低通/高通/带通滤波器',
          Icons.filter_alt, Colors.cyan, [
        _ParamConfig(0, '类型', 0.0, 2.0, 0.0),
        _ParamConfig(1, '频率', 10.0, 16000.0, 1000.0),
        _ParamConfig(2, '谐振', 0.01, 20.0, 1.0),
      ]),
    ];

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 80),
      itemCount: effects.length,
      itemBuilder: (context, index) {
        final effect = effects[index];
        final isEnabled =
            dspProvider.filterStates[effect.type]?.isEnabled ?? false;
        return _buildEffectCard(
          dspProvider: dspProvider,
          effect: effect,
          isEnabled: isEnabled,
          theme: theme,
          colorScheme: colorScheme,
        );
      },
    );
  }

  // ==================== 通用组件 ====================

  Widget _buildEffectCard({
    required DspProvider dspProvider,
    required _EffectConfig effect,
    required bool isEnabled,
    required ThemeData theme,
    required ColorScheme colorScheme,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOut,
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isEnabled
            ? colorScheme.primary.withOpacity(0.08)
            : colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isEnabled
              ? colorScheme.primary.withOpacity(0.3)
              : colorScheme.onSurface.withOpacity(0.08),
        ),
      ),
      child: Column(
        children: [
          // 标题行 + 开关
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Icon(effect.icon, color: effect.color, size: 22),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        effect.name,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        effect.description,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurface.withOpacity(0.5),
                        ),
                      ),
                    ],
                  ),
                ),
                // 重置参数按钮（仅在有参数且启用时显示）
                if (isEnabled && effect.params.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: () {
                          for (final param in effect.params) {
                            dspProvider.setFilterParam(
                                effect.type, param.id, param.defaultValue);
                          }
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.refresh,
                                size: 14,
                                color: colorScheme.primary.withOpacity(0.7),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '重置',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: colorScheme.primary.withOpacity(0.7),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                Switch.adaptive(
                  value: isEnabled,
                  onChanged: (value) {
                    dspProvider.toggleFilter(effect.type, value);
                  },
                ),
              ],
            ),
          ),
          // 参数滑块
          if (isEnabled && effect.params.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: effect.params.map((param) {
                  return _buildParamSlider(
                    dspProvider: dspProvider,
                    type: effect.type,
                    param: param,
                    colorScheme: colorScheme,
                  );
                }).toList(),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildParamSlider({
    required DspProvider dspProvider,
    required DspFilterType type,
    required _ParamConfig param,
    required ColorScheme colorScheme,
  }) {
    final currentValue =
        dspProvider.filterStates[type]?.params['attr_${param.id}'] ??
            param.defaultValue;

    // 格式化参数值显示：整数范围显示整数，小数范围保留合适位数
    String formatValue(double v) {
      if (param.max - param.min >= 100) return v.toStringAsFixed(0);
      if (param.max - param.min >= 10) return v.toStringAsFixed(1);
      return v.toStringAsFixed(2);
    }

    String formatBound(double v) {
      if (v == v.roundToDouble()) return v.toInt().toString();
      if (param.max - param.min >= 10) return v.toStringAsFixed(1);
      return v.toStringAsFixed(2);
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 60,
            child: Text(
              param.label,
              style: TextStyle(
                fontSize: 12,
                color: colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
          ),
          // 最小值标注
          SizedBox(
            width: 32,
            child: Text(
              formatBound(param.min),
              style: TextStyle(
                fontSize: 9,
                color: colorScheme.onSurface.withOpacity(0.35),
              ),
              textAlign: TextAlign.right,
            ),
          ),
          Expanded(
            child: SliderTheme(
              data: SliderThemeData(
                trackHeight: 3,
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
                activeTrackColor: colorScheme.primary,
                inactiveTrackColor: colorScheme.onSurface.withOpacity(0.15),
                thumbColor: colorScheme.primary,
              ),
              child: Slider(
                value: currentValue.clamp(param.min, param.max),
                min: param.min,
                max: param.max,
                onChanged: (value) {
                  dspProvider.setFilterParam(type, param.id, value);
                },
              ),
            ),
          ),
          // 最大值标注
          SizedBox(
            width: 32,
            child: Text(
              formatBound(param.max),
              style: TextStyle(
                fontSize: 9,
                color: colorScheme.onSurface.withOpacity(0.35),
              ),
              textAlign: TextAlign.left,
            ),
          ),
          const SizedBox(width: 4),
          SizedBox(
            width: 48,
            child: Text(
              formatValue(currentValue),
              style: TextStyle(
                fontSize: 11,
                color: colorScheme.onSurface.withOpacity(0.5),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 音效配置
class _EffectConfig {
  final DspFilterType type;
  final String name;
  final String description;
  final IconData icon;
  final Color color;
  final List<_ParamConfig> params;

  const _EffectConfig(
    this.type,
    this.name,
    this.description,
    this.icon,
    this.color,
    this.params,
  );
}

/// 参数配置
class _ParamConfig {
  final int id;
  final String label;
  final double min;
  final double max;
  final double defaultValue;

  const _ParamConfig(
      this.id, this.label, this.min, this.max, this.defaultValue);
}

/// EQ 频率曲线预览图
/// 根据 8 段均衡器的增益值，绘制平滑的频率响应曲线
class _EqCurvePreview extends StatelessWidget {
  final List<EqBand> eqBands;
  final ColorScheme colorScheme;

  const _EqCurvePreview({
    required this.eqBands,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 140,
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: colorScheme.onSurface.withOpacity(0.08),
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: CustomPaint(
          painter: _EqCurvePainter(
            eqBands: eqBands,
            primaryColor: colorScheme.primary,
            onSurfaceColor: colorScheme.onSurface,
            surfaceColor: colorScheme.surface,
          ),
          size: Size.infinite,
        ),
      ),
    );
  }
}

/// EQ 曲线绘制器
class _EqCurvePainter extends CustomPainter {
  final List<EqBand> eqBands;
  final Color primaryColor;
  final Color onSurfaceColor;
  final Color surfaceColor;

  _EqCurvePainter({
    required this.eqBands,
    required this.primaryColor,
    required this.onSurfaceColor,
    required this.surfaceColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (eqBands.isEmpty || size.width < 10 || size.height < 10) return;

    const double padLeft = 36.0;
    const double padRight = 12.0;
    const double padTop = 16.0;
    const double padBottom = 24.0;

    final plotWidth = size.width - padLeft - padRight;
    final plotHeight = size.height - padTop - padBottom;

    if (plotWidth <= 0 || plotHeight <= 0) return;

    // 绘制背景网格
    _drawGrid(canvas, size, padLeft, padTop, plotWidth, plotHeight);

    // 绘制 0dB 参考线（0dB 在 -24~+12 范围的 2/3 处）
    final zeroY = padTop + plotHeight * (1.0 - 24.0 / 36.0);
    final dashPaint = Paint()
      ..color = onSurfaceColor.withOpacity(0.2)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;
    _drawDashedLine(canvas, Offset(padLeft, zeroY),
        Offset(padLeft + plotWidth, zeroY), dashPaint);

    // 0dB 标签
    final zeroLabelPainter = TextPainter(
      text: TextSpan(
        text: '0dB',
        style: TextStyle(
          fontSize: 8,
          color: onSurfaceColor.withOpacity(0.35),
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    zeroLabelPainter.paint(
        canvas, Offset(2, zeroY - zeroLabelPainter.height / 2));

    // +12dB / -24dB 标签
    final plusLabelPainter = TextPainter(
      text: TextSpan(
        text: '+12',
        style: TextStyle(
          fontSize: 8,
          color: onSurfaceColor.withOpacity(0.25),
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    plusLabelPainter.paint(canvas, Offset(4, padTop - 2));

    final minusLabelPainter = TextPainter(
      text: TextSpan(
        text: '-24',
        style: TextStyle(
          fontSize: 8,
          color: onSurfaceColor.withOpacity(0.25),
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    minusLabelPainter.paint(
        canvas, Offset(4, padTop + plotHeight - minusLabelPainter.height + 2));

    // 构建频率响应曲线的控制点
    final points = <Offset>[];
    for (int i = 0; i < eqBands.length; i++) {
      final band = eqBands[i];
      // X: 对数频率映射
      final x = padLeft + (i / (eqBands.length - 1)) * plotWidth;
      // Y: 增益映射（+12dB 在顶部，-24dB 在底部）
      final normalizedGain = (band.gain + 24.0) / 36.0; // 0~1
      final y = padTop + plotHeight * (1.0 - normalizedGain);
      points.add(Offset(x, y));
    }

    if (points.length < 2) return;

    // 绘制填充区域
    final fillPath =
        _buildSmoothCurvePath(points, padLeft, padTop + plotHeight);
    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          primaryColor.withOpacity(0.25),
          primaryColor.withOpacity(0.05),
        ],
      ).createShader(Rect.fromLTWH(padLeft, padTop, plotWidth, plotHeight))
      ..style = PaintingStyle.fill;
    canvas.drawPath(fillPath, fillPaint);

    // 绘制曲线
    final curvePath = _buildSmoothCurveLine(points);
    final curvePaint = Paint()
      ..color = primaryColor
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(curvePath, curvePaint);

    // 绘制频段标记点
    for (int i = 0; i < points.length; i++) {
      final point = points[i];
      final band = eqBands[i];

      // 外圈光晕
      final glowPaint = Paint()
        ..color = primaryColor.withOpacity(0.2)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(point, 6, glowPaint);

      // 内圈实心点
      final dotPaint = Paint()
        ..color = primaryColor
        ..style = PaintingStyle.fill;
      canvas.drawCircle(point, 3, dotPaint);

      // 白色中心
      final centerPaint = Paint()
        ..color = surfaceColor
        ..style = PaintingStyle.fill;
      canvas.drawCircle(point, 1.5, centerPaint);

      // 频率标签
      final labelPainter = TextPainter(
        text: TextSpan(
          text: band.label,
          style: TextStyle(
            fontSize: 8,
            color: onSurfaceColor.withOpacity(0.4),
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      labelPainter.paint(
        canvas,
        Offset(
          point.dx - labelPainter.width / 2,
          padTop + plotHeight + 6,
        ),
      );
    }
  }

  /// 绘制背景网格线
  void _drawGrid(Canvas canvas, Size size, double padLeft, double padTop,
      double plotWidth, double plotHeight) {
    final gridPaint = Paint()
      ..color = onSurfaceColor.withOpacity(0.06)
      ..strokeWidth = 0.5;

    // 水平网格线（每 6dB 一条，共 5 条）
    for (int i = 0; i <= 4; i++) {
      final y = padTop + (i / 4) * plotHeight;
      canvas.drawLine(
          Offset(padLeft, y), Offset(padLeft + plotWidth, y), gridPaint);
    }

    // 垂直网格线（对应每个频段）
    for (int i = 0; i < eqBands.length; i++) {
      final x = padLeft + (i / (eqBands.length - 1)) * plotWidth;
      canvas.drawLine(
          Offset(x, padTop), Offset(x, padTop + plotHeight), gridPaint);
    }
  }

  /// 绘制虚线
  void _drawDashedLine(Canvas canvas, Offset start, Offset end, Paint paint,
      {double dashLength = 4, double gapLength = 3}) {
    final dx = end.dx - start.dx;
    final dy = end.dy - start.dy;
    final totalLength = sqrt(dx * dx + dy * dy);
    if (totalLength <= 0) return;

    final unitX = dx / totalLength;
    final unitY = dy / totalLength;

    double current = 0;
    while (current < totalLength) {
      final segEnd = min(current + dashLength, totalLength);
      canvas.drawLine(
        Offset(start.dx + unitX * current, start.dy + unitY * current),
        Offset(start.dx + unitX * segEnd, start.dy + unitY * segEnd),
        paint,
      );
      current = segEnd + gapLength;
    }
  }

  /// 构建平滑曲线填充路径（闭合到底部）
  Path _buildSmoothCurvePath(List<Offset> points, double left, double bottom) {
    final path = Path();
    path.moveTo(left, bottom);

    // 从左下角移到第一个点
    if (points.isNotEmpty) {
      path.lineTo(points.first.dx, points.first.dy);
    }

    // 使用 Catmull-Rom 样条绘制平滑曲线
    for (int i = 0; i < points.length - 1; i++) {
      final p0 = i > 0 ? points[i - 1] : points[i];
      final p1 = points[i];
      final p2 = points[i + 1];
      final p3 = i < points.length - 2 ? points[i + 2] : points[i + 1];

      final cp1x = p1.dx + (p2.dx - p0.dx) / 6;
      final cp1y = p1.dy + (p2.dy - p0.dy) / 6;
      final cp2x = p2.dx - (p3.dx - p1.dx) / 6;
      final cp2y = p2.dy - (p3.dy - p1.dy) / 6;

      path.cubicTo(cp1x, cp1y, cp2x, cp2y, p2.dx, p2.dy);
    }

    // 闭合到底部
    path.lineTo(points.last.dx, bottom);
    path.close();
    return path;
  }

  /// 构建平滑曲线线条路径（不闭合）
  Path _buildSmoothCurveLine(List<Offset> points) {
    final path = Path();
    if (points.isEmpty) return path;

    path.moveTo(points.first.dx, points.first.dy);

    for (int i = 0; i < points.length - 1; i++) {
      final p0 = i > 0 ? points[i - 1] : points[i];
      final p1 = points[i];
      final p2 = points[i + 1];
      final p3 = i < points.length - 2 ? points[i + 2] : points[i + 1];

      final cp1x = p1.dx + (p2.dx - p0.dx) / 6;
      final cp1y = p1.dy + (p2.dy - p0.dy) / 6;
      final cp2x = p2.dx - (p3.dx - p1.dx) / 6;
      final cp2y = p2.dy - (p3.dy - p1.dy) / 6;

      path.cubicTo(cp1x, cp1y, cp2x, cp2y, p2.dx, p2.dy);
    }

    return path;
  }

  @override
  bool shouldRepaint(covariant _EqCurvePainter oldDelegate) {
    return oldDelegate.eqBands != eqBands ||
        oldDelegate.primaryColor != primaryColor;
  }
}
