
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

            if (dspProvider.dspEnabled) ...[
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
                        '开启 DSP 处理以使用音频效果',
                        style: TextStyle(
                          color: colorScheme.onSurface.withOpacity(0.4),
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '均衡器、混响、回声、变调等',
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
            Text(
              '预设',
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildPresetChip('默认', () => dspProvider.resetEqBands()),
                _buildPresetChip(
                    '低音增强', () => _applyPreset(dspProvider, _bassBoost)),
                _buildPresetChip(
                    '高音增强', () => _applyPreset(dspProvider, _trebleBoost)),
                _buildPresetChip(
                    '人声增强', () => _applyPreset(dspProvider, _vocalBoost)),
                _buildPresetChip('摇滚', () => _applyPreset(dspProvider, _rock)),
                _buildPresetChip('流行', () => _applyPreset(dspProvider, _pop)),
                _buildPresetChip(
                    '古典', () => _applyPreset(dspProvider, _classical)),
                _buildPresetChip(
                    '电子', () => _applyPreset(dspProvider, _electronic)),
              ],
            ),
            const SizedBox(height: 24),

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
          const SizedBox(width: 12),
          Expanded(
            child: SliderTheme(
              data: SliderThemeData(
                trackHeight: 3,
                thumbShape:
                    const RoundSliderThumbShape(enabledThumbRadius: 7),
                overlayShape:
                    const RoundSliderOverlayShape(overlayRadius: 14),
                activeTrackColor: band.gain > 0
                    ? Colors.orange
                    : band.gain < 0
                        ? Colors.blue
                        : colorScheme.onSurface.withOpacity(0.3),
                inactiveTrackColor: colorScheme.onSurface.withOpacity(0.15),
                thumbColor: colorScheme.primary,
              ),
              child: Slider(
                value: band.gain,
                min: -12.0,
                max: 12.0,
                divisions: 48,
                onChanged: (value) {
                  dspProvider.setEqBandGain(bandIndex, value);
                },
              ),
            ),
          ),
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

  Widget _buildPresetChip(String label, VoidCallback onTap) {
    final colorScheme = Theme.of(context).colorScheme;
    return ActionChip(
      label: Text(label),
      onPressed: onTap,
      backgroundColor: colorScheme.surface,
      side: BorderSide(color: colorScheme.onSurface.withOpacity(0.15)),
    );
  }

  void _applyPreset(DspProvider dspProvider, List<double> gains) {
    for (int i = 0; i < gains.length && i < dspProvider.eqBands.length; i++) {
      dspProvider.setEqBandGain(i, gains[i]);
    }
  }

  // 均衡器预设
  static const _bassBoost = [-2.0, 4.0, 6.0, 4.0, 1.0, 0.0, -1.0, -2.0];
  static const _trebleBoost = [-2.0, -1.0, 0.0, 0.0, 1.0, 3.0, 5.0, 6.0];
  static const _vocalBoost = [-1.0, 0.0, 2.0, 5.0, 5.0, 3.0, 1.0, 0.0];
  static const _rock = [4.0, 2.0, -1.0, 0.0, 1.0, 3.0, 4.0, 5.0];
  static const _pop = [-1.0, 1.0, 3.0, 4.0, 3.0, 0.0, -1.0, 1.0];
  static const _classical = [4.0, 3.0, 2.0, 1.0, -1.0, 0.0, 2.0, 3.0];
  static const _electronic = [5.0, 4.0, 0.0, -2.0, 0.0, 1.0, 4.0, 5.0];

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
      _EffectConfig(DspFilterType.echo, '回声', '添加回声延迟效果', Icons.waves,
          Colors.purple, [
        _ParamConfig(0, '延迟', 0.0, 10.0, 0.3),
        _ParamConfig(1, '衰减', 0.0, 1.0, 0.7),
        _ParamConfig(2, '滤波', 0.0, 100.0, 0.0),
      ]),
      _EffectConfig(DspFilterType.reverb, '混响', '模拟空间混响效果',
          Icons.spatial_audio_off, Colors.blue, [
        _ParamConfig(0, '冻结', 0.0, 1.0, 0.0),
        _ParamConfig(1, '反馈', 0.0, 1.0, 0.5),
      ]),
      _EffectConfig(DspFilterType.flanger, '镶边', '添加镶边/合唱效果',
          Icons.auto_fix_high, Colors.teal, [
        _ParamConfig(0, '延迟', 0.0, 0.1, 0.01),
        _ParamConfig(1, '频率', 0.1, 20.0, 0.5),
      ]),
      _EffectConfig(DspFilterType.pitchShift, '变调', '改变音高而不改变速度',
          Icons.tune, Colors.green, [
        _ParamConfig(0, '音高', -12.0, 12.0, 0.0),
      ]),
    ];

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
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
          Icons.compress, Colors.red, []),
      _EffectConfig(DspFilterType.limiter, '限幅器', '限制最大音量，防止削波',
          Icons.volume_up, Colors.amber, []),
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
        _ParamConfig(0, '采样率', 0.0, 1.0, 0.5),
        _ParamConfig(1, '比特深度', 0.0, 1.0, 0.5),
      ]),
      _EffectConfig(DspFilterType.biquadResonant, '谐振滤波器', '低通/高通/带通滤波器',
          Icons.filter_alt, Colors.cyan, [
        _ParamConfig(0, '类型', 0.0, 2.0, 0.0),
        _ParamConfig(1, '频率', 10.0, 16000.0, 1000.0),
        _ParamConfig(2, '谐振', 0.01, 20.0, 1.0),
      ]),
    ];

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
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
          Expanded(
            child: Slider(
              value: currentValue.clamp(param.min, param.max),
              min: param.min,
              max: param.max,
              onChanged: (value) {
                dspProvider.setFilterParam(type, param.id, value);
              },
            ),
          ),
          SizedBox(
            width: 50,
            child: Text(
              currentValue.toStringAsFixed(1),
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

  const _ParamConfig(this.id, this.label, this.min, this.max, this.defaultValue);
}
