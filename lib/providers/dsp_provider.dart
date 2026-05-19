
import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_soloud/flutter_soloud.dart';

/// DSP 滤波器类型
enum DspFilterType {
  equalizer,
  bassboost,
  echo,
  reverb,
  flanger,
  pitchShift,
  compressor,
  limiter,
  waveShaper,
  robotize,
  lofi,
  biquadResonant,
}

/// DSP 滤波器状态
class DspFilterState {
  final DspFilterType type;
  final bool isEnabled;
  final Map<String, double> params;

  const DspFilterState({
    required this.type,
    this.isEnabled = false,
    this.params = const {},
  });

  DspFilterState copyWith({
    bool? isEnabled,
    Map<String, double>? params,
  }) {
    return DspFilterState(
      type: type,
      isEnabled: isEnabled ?? this.isEnabled,
      params: params ?? this.params,
    );
  }
}

/// 均衡器频段（8段，对应 SoLoud Equalizer 的 band1~band8）
class EqBand {
  final String label;
  final double frequency;
  final double gain;

  const EqBand({
    required this.label,
    required this.frequency,
    this.gain = 0.0,
  });

  EqBand copyWith({double? gain}) {
    return EqBand(
      label: label,
      frequency: frequency,
      gain: gain ?? this.gain,
    );
  }
}

/// 自定义均衡器预设
class CustomEqPreset {
  final String name;
  final List<double> gains; // 8个频段的增益值（dB）

  const CustomEqPreset({
    required this.name,
    required this.gains,
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'gains': gains,
      };

  factory CustomEqPreset.fromJson(Map<String, dynamic> json) =>
      CustomEqPreset(
        name: json['name'] as String,
        gains: (json['gains'] as List).cast<double>(),
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CustomEqPreset && runtimeType == other.runtimeType && name == other.name;

  @override
  int get hashCode => name.hashCode;
}

/// DSP 音频效果管理 Provider
class DspProvider with ChangeNotifier {
  bool _isInitialized = false;
  bool _dspEnabled = false;

  final Map<DspFilterType, DspFilterState> _filterStates = {};
  List<EqBand> _eqBands = [];

  // 自定义均衡器预设
  List<CustomEqPreset> _customPresets = [];
  static const String _customPresetsKey = 'dsp_custom_eq_presets';

  // Getters
  bool get isInitialized => _isInitialized;
  bool get dspEnabled => _dspEnabled;
  Map<DspFilterType, DspFilterState> get filterStates => _filterStates;
  List<EqBand> get eqBands => _eqBands;
  List<CustomEqPreset> get customPresets => List.unmodifiable(_customPresets);

  DspProvider() {
    _initDefaultFilterStates();
    _initEqBands();
    _loadCustomPresets();
  }

  void _initDefaultFilterStates() {
    for (final type in DspFilterType.values) {
      _filterStates[type] = DspFilterState(type: type);
    }
  }

  /// 8段均衡器（SoLoud 只支持 band1~band8）
  void _initEqBands() {
    _eqBands = [
      const EqBand(label: '31Hz', frequency: 31.0),
      const EqBand(label: '62Hz', frequency: 62.0),
      const EqBand(label: '125Hz', frequency: 125.0),
      const EqBand(label: '250Hz', frequency: 250.0),
      const EqBand(label: '500Hz', frequency: 500.0),
      const EqBand(label: '1kHz', frequency: 1000.0),
      const EqBand(label: '2kHz', frequency: 2000.0),
      const EqBand(label: '4kHz', frequency: 4000.0),
    ];
  }

  /// 初始化 SoLoud 引擎
  Future<bool> initSoLoud() async {
    if (_isInitialized) return true;

    try {
      // SoLoud 是单例，如果已经初始化则跳过
      if (SoLoud.instance.isInitialized) {
        _isInitialized = true;
        debugPrint('SoLoud 引擎已初始化，跳过重复初始化');
        notifyListeners();
        return true;
      }

      await SoLoud.instance.init();
      _isInitialized = true;
      debugPrint('SoLoud 引擎初始化成功');
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('SoLoud 引擎初始化异常: $e');
      return false;
    }
  }

  /// 释放 SoLoud 引擎
  /// 注意：SoLoud 是单例，由 PlayerProvider 管理生命周期，
  /// DspProvider 不负责 deinit
  Future<void> disposeSoLoud() async {
    if (!_isInitialized) return;

    // 只标记为未初始化，不调用 deinit()
    // SoLoud 引擎的生命周期由 PlayerProvider 管理
    _isInitialized = false;
    debugPrint('DspProvider 已断开 SoLoud 引擎连接');
    notifyListeners();
  }

  /// 切换 DSP 总开关
  Future<void> toggleDsp(bool enabled) async {
    if (enabled && !_isInitialized) {
      final success = await initSoLoud();
      if (!success) return;
    }

    _dspEnabled = enabled;
    if (enabled) {
      _activateAllEnabledFilters();
    } else {
      _deactivateAllFilters();
    }
    notifyListeners();
  }

  /// 切换滤波器开关
  void toggleFilter(DspFilterType type, bool enabled) {
    final state = _filterStates[type]!;
    _filterStates[type] = state.copyWith(isEnabled: enabled);

    if (!_isInitialized || !_dspEnabled) {
      notifyListeners();
      return;
    }

    try {
      if (enabled) {
        _activateFilter(type);
      } else {
        _deactivateFilter(type);
      }

      // 开启均衡器时自动激活限幅器防止削波失真
      if (type == DspFilterType.equalizer && enabled) {
        try {
          final limiter = SoLoud.instance.filters.limiterFilter;
          if (!limiter.isActive) {
            limiter.activate();
          }
          _filterStates[DspFilterType.limiter] = _filterStates[DspFilterType.limiter]!.copyWith(isEnabled: true);
          debugPrint('均衡器已开启，自动激活限幅器防削波');
        } catch (e) {
          debugPrint('自动激活限幅器失败: $e');
        }
        // 检查是否有频段增益不为0dB，决定EQ的wet值 + 自动增益补偿
        _updateEqWet();
      }
      // 关闭均衡器时移除自动增益补偿
      if (type == DspFilterType.equalizer && !enabled) {
        _removeEqAutoGain();
      }
      // 用户手动关闭低音增强时，如果 EQ 仍启用，重新应用自动增益补偿
      if (type == DspFilterType.bassboost && !enabled) {
        if (_filterStates[DspFilterType.equalizer]?.isEnabled == true) {
          _applyEqAutoGain();
        }
      }
      // 用户手动开启低音增强时，自动增益补偿不再借用 bassBoost
      // （用户的 bassBoost 设置优先，由 _applyEqAutoGain 中的 isBassBoostUserEnabled 判断处理）
    } catch (e) {
      debugPrint('切换滤波器失败: $e');
    }

    notifyListeners();
  }

  void _activateFilter(DspFilterType type) {
    final filter = _getFilter(type);
    if (filter == null) return;

    try {
      filter.activate();
      if (type == DspFilterType.equalizer) {
        _updateEqWet();
      } else {
        _setFilterWet(type, 1.0);
      }
    } catch (e) {
      debugPrint('激活滤波器失败($type): $e');
    }
  }

  void _deactivateFilter(DspFilterType type) {
    final filter = _getFilter(type);
    if (filter == null) return;

    try {
      filter.deactivate();
    } catch (e) {
      debugPrint('停用滤波器失败($type): $e');
    }
  }

  void _activateAllEnabledFilters() {
    if (!_isInitialized) return;
    for (final entry in _filterStates.entries) {
      if (entry.value.isEnabled) {
        _activateFilter(entry.key);
      }
    }
  }

  void _deactivateAllFilters() {
    if (!_isInitialized) return;
    for (final entry in _filterStates.entries) {
      if (entry.value.isEnabled) {
        _deactivateFilter(entry.key);
      }
    }
  }

  /// 设置滤波器 wet 参数（0=完全旁通，1=完全启用）
  void _setFilterWet(DspFilterType type, double value) {
    if (!_isInitialized) return;
    try {
      final filters = SoLoud.instance.filters;
      switch (type) {
        case DspFilterType.equalizer:
          filters.equalizerFilter.wet.value = value;
          break;
        case DspFilterType.bassboost:
          filters.bassBoostFilter.wet.value = value;
          break;
        case DspFilterType.echo:
          filters.echoFilter.wet.value = value;
          break;
        case DspFilterType.reverb:
          filters.freeverbFilter.wet.value = value;
          break;
        case DspFilterType.flanger:
          filters.flangerFilter.wet.value = value;
          break;
        case DspFilterType.pitchShift:
          filters.pitchShiftFilter.wet.value = value;
          break;
        case DspFilterType.compressor:
          filters.compressorFilter.wet.value = value;
          break;
        case DspFilterType.limiter:
          filters.limiterFilter.wet.value = value;
          break;
        case DspFilterType.waveShaper:
          filters.waveShaperFilter.wet.value = value;
          break;
        case DspFilterType.robotize:
          filters.robotizeFilter.wet.value = value;
          break;
        case DspFilterType.lofi:
          filters.lofiFilter.wet.value = value;
          break;
        case DspFilterType.biquadResonant:
          filters.biquadResonantFilter.wet.value = value;
          break;
      }
    } catch (e) {
      debugPrint('设置滤波器wet参数失败: $e');
    }
  }

  /// 更新均衡器 wet 参数：所有频段增益为0dB时旁通EQ，避免数字滤波器引入的音质损失
  /// 同时计算自动增益补偿，避免 EQ 导致整体音量下降（发焖）
  void _updateEqWet() {
    if (!_isInitialized) return;
    try {
      final hasGain = _eqBands.any((band) => band.gain.abs() > 0.01);
      // wet=0 完全旁通，wet=1 完全启用
      SoLoud.instance.filters.equalizerFilter.wet.value = hasGain ? 1.0 : 0.0;

      // 自动增益补偿
      // SoLoud EQ 是 FFT 乘法型均衡器，频段增益 < 1.0 时对应频率幅度被缩小
      // 多个频段同时衰减会导致整体音量急剧下降（发焖）
      // 解决方案：计算所有频段线性增益的几何平均值，用其倒数补偿
      _applyEqAutoGain();
    } catch (e) {
      debugPrint('更新均衡器wet参数失败: $e');
    }
  }

  /// 自动增益补偿
  /// SoLoud EQ 是 FFT 乘法型均衡器，频段增益 < 1.0 时对应频率幅度被缩小
  /// 多个频段同时衰减会导致整体音量急剧下降（发焖）
  ///
  /// 补偿策略：计算所有频段线性增益的几何平均值，
  /// 通过 bassBoost 滤波器作为增益节点来补偿整体音量损失
  /// （SoLoud 没有独立的增益滤波器，借用 bassBoost 的 boost 参数实现纯增益）
  void _applyEqAutoGain() {
    if (!_isInitialized) return;
    if (_filterStates[DspFilterType.equalizer]?.isEnabled != true) return;

    try {
      // 计算几何平均值
      double product = 1.0;
      int count = 0;
      for (final band in _eqBands) {
        final linearGain = _dbToLinear(band.gain);
        if (linearGain > 0.001) {
          product *= linearGain;
          count++;
        }
      }

      if (count == 0) return;

      // 几何平均值 = 乘积的 n 次方根
      final geometricMean = pow(product, 1.0 / count).toDouble();

      // 补偿增益 = 1 / 几何平均值
      // 几何平均 < 1.0（有衰减）时，补偿 > 1.0（提升音量）
      // 几何平均 > 1.0（有提升）时，补偿 < 1.0，但不应衰减用户主动提升的音量
      // 因此只在几何平均 < 1.0 时才补偿，否则不补偿
      double compensationGain;
      if (geometricMean < 1.0) {
        // 有衰减，需要补偿
        compensationGain = (1.0 / geometricMean).clamp(1.0, 4.0);
      } else {
        // 有提升或无变化，不需要补偿
        compensationGain = 1.0;
      }

      // 使用 bassBoost 滤波器作为增益补偿节点
      // bassBoost 的 boost 参数范围 0~10，1.0 = 无增益
      // 当 boost > 1 时提供额外增益，可用于补偿 EQ 衰减
      final bassBoost = SoLoud.instance.filters.bassBoostFilter;
      final isBassBoostUserEnabled =
          _filterStates[DspFilterType.bassboost]?.isEnabled ?? false;

      if (!isBassBoostUserEnabled) {
        // 用户未手动启用低音增强，可以安全地借用 bassBoost 做增益补偿
        if (!bassBoost.isActive) {
          bassBoost.activate();
        }
        bassBoost.boost.value = compensationGain;
        bassBoost.wet.value = 1.0;
      }

      // 同时激活 limiter 防止补偿后削波
      try {
        final limiter = SoLoud.instance.filters.limiterFilter;
        if (!limiter.isActive) {
          limiter.activate();
        }
        _filterStates[DspFilterType.limiter] =
            _filterStates[DspFilterType.limiter]!.copyWith(isEnabled: true);
      } catch (_) {}

      final compensationDb = 20.0 * log(compensationGain) / ln10;
      debugPrint('EQ 自动增益补偿: 几何平均=${geometricMean.toStringAsFixed(3)}, '
          '补偿=${compensationGain.toStringAsFixed(2)}x '
          '(+${compensationDb.toStringAsFixed(1)}dB)');
    } catch (e) {
      debugPrint('EQ 自动增益补偿失败: $e');
    }
  }

  /// 移除 EQ 自动增益补偿（EQ 关闭或重置时调用）
  void _removeEqAutoGain() {
    if (!_isInitialized) return;
    try {
      final isBassBoostUserEnabled =
          _filterStates[DspFilterType.bassboost]?.isEnabled ?? false;
      if (!isBassBoostUserEnabled) {
        // 只有当 bassBoost 是被自动增益借用时才停用
        final bassBoost = SoLoud.instance.filters.bassBoostFilter;
        bassBoost.boost.value = 1.0; // 恢复无增益
        if (bassBoost.isActive) {
          bassBoost.deactivate();
        }
      }
    } catch (e) {
      debugPrint('移除EQ自动增益补偿失败: $e');
    }
  }

  /// 设置滤波器参数
  void setFilterParam(
    DspFilterType type,
    int attributeId,
    double value,
  ) {
    if (!_isInitialized) return;

    final state = _filterStates[type]!;
    final newParams = Map<String, double>.from(state.params);
    newParams['attr_$attributeId'] = value;
    _filterStates[type] = state.copyWith(params: newParams);

    try {
      _setFilterParamValue(type, attributeId, value);
    } catch (e) {
      debugPrint('设置滤波器参数失败: $e');
    }

    notifyListeners();
  }

  /// 设置均衡器频段增益（dB 值，内部转换为 SoLoud 线性增益）
  void setEqBandGain(int bandIndex, double gainDb) {
    if (bandIndex < 0 || bandIndex >= _eqBands.length) return;

    _eqBands[bandIndex] = _eqBands[bandIndex].copyWith(
      gain: gainDb.clamp(-24.0, 12.0),
    );

    if (_filterStates[DspFilterType.equalizer]?.isEnabled == true) {
      try {
        // 将 dB 值转换为 SoLoud 线性增益（1.0 = 0dB）
        final linearGain = _dbToLinear(gainDb);
        final param = _getEqBandParam(bandIndex);
        param.value = linearGain;
        // 更新 wet 参数：所有频段增益为0dB时旁通EQ
        _updateEqWet();
      } catch (e) {
        debugPrint('更新均衡器频段失败: $e');
      }
    }

    notifyListeners();
  }

  /// dB 值转 SoLoud 线性增益
  /// SoLoud EQ band 范围: 0~4，1.0 = 0dB
  /// 公式: linear = 10^(dB/20)
  ///
  /// 注意：SoLoud 的最小值是 0（-∞dB，完全静音），
  /// 但实际使用中不应将频段完全静音，否则声音会发焖。
  /// 因此将最小线性增益限制为 0.063（约 -24dB），避免过度衰减。
  static double _dbToLinear(double db) {
    if (db <= -24.0) return 0.063; // 最低约 -24dB，避免完全静音导致发焖
    final linear = pow(10.0, db / 20.0).toDouble();
    return linear.clamp(0.063, 4.0); // SoLoud 范围限制，下限避免过度衰减
  }

  /// 线性增益转 dB 值
  static double _linearToDb(double linear) {
    if (linear <= 0.063) return -24.0;
    return 20.0 * log(linear) / ln10;
  }

  /// 重置均衡器所有频段
  void resetEqBands() {
    for (int i = 0; i < _eqBands.length; i++) {
      _eqBands[i] = _eqBands[i].copyWith(gain: 0.0);
      // 重置 SoLoud 频段增益为 1.0（0dB）
      if (_filterStates[DspFilterType.equalizer]?.isEnabled == true) {
        try {
          _getEqBandParam(i).value = 1.0;
        } catch (e) {
          debugPrint('重置均衡器频段失败: $e');
        }
      }
    }
    // 所有频段回到0dB，旁通EQ
    _updateEqWet();
    notifyListeners();
  }

  // ==================== 自定义均衡器预设管理 ====================

  /// 从 SharedPreferences 加载自定义预设
  Future<void> _loadCustomPresets() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = prefs.getString(_customPresetsKey);
      if (jsonStr != null && jsonStr.isNotEmpty) {
        final List<dynamic> jsonList = jsonDecode(jsonStr);
        _customPresets = jsonList
            .map((e) => CustomEqPreset.fromJson(e as Map<String, dynamic>))
            .toList();
        debugPrint('已加载 ${_customPresets.length} 个自定义均衡器预设');
        notifyListeners();
      }
    } catch (e) {
      debugPrint('加载自定义均衡器预设失败: $e');
    }
  }

  /// 保存自定义预设到 SharedPreferences
  Future<void> _saveCustomPresets() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = jsonEncode(
        _customPresets.map((e) => e.toJson()).toList(),
      );
      await prefs.setString(_customPresetsKey, jsonStr);
      debugPrint('已保存 ${_customPresets.length} 个自定义均衡器预设');
    } catch (e) {
      debugPrint('保存自定义均衡器预设失败: $e');
    }
  }

  /// 保存当前均衡器设置为自定义预设
  /// 返回 true 表示保存成功，false 表示名称已存在
  Future<bool> saveCustomPreset(String name) async {
    // 检查名称是否已存在
    if (_customPresets.any((p) => p.name == name)) {
      return false;
    }

    final gains = _eqBands.map((b) => b.gain).toList();
    _customPresets.add(CustomEqPreset(name: name, gains: gains));
    await _saveCustomPresets();
    notifyListeners();
    return true;
  }

  /// 覆盖已有的自定义预设
  Future<void> overwriteCustomPreset(String name) async {
    final gains = _eqBands.map((b) => b.gain).toList();
    final index = _customPresets.indexWhere((p) => p.name == name);
    if (index >= 0) {
      _customPresets[index] = CustomEqPreset(name: name, gains: gains);
      await _saveCustomPresets();
      notifyListeners();
    }
  }

  /// 应用自定义预设
  void applyCustomPreset(CustomEqPreset preset) {
    for (int i = 0; i < preset.gains.length && i < _eqBands.length; i++) {
      setEqBandGain(i, preset.gains[i]);
    }
  }

  /// 删除自定义预设
  Future<void> deleteCustomPreset(String name) async {
    _customPresets.removeWhere((p) => p.name == name);
    await _saveCustomPresets();
    notifyListeners();
  }

  /// 检查自定义预设名称是否已存在
  bool hasCustomPreset(String name) {
    return _customPresets.any((p) => p.name == name);
  }

  // ==================== 配置导出/导入 ====================

  /// 导出所有 DSP 配置为 JSON 字符串
  String exportConfig() {
    final config = <String, dynamic>{
      'version': 1,
      'dspEnabled': _dspEnabled,
      'eqBands': _eqBands.map((b) => {
        'label': b.label,
        'frequency': b.frequency,
        'gain': b.gain,
      }).toList(),
      'eqEnabled': _filterStates[DspFilterType.equalizer]?.isEnabled ?? false,
      'filters': <String, dynamic>{},
      'customPresets': _customPresets.map((p) => p.toJson()).toList(),
    };

    // 导出所有滤波器的开关和参数
    for (final type in DspFilterType.values) {
      if (type == DspFilterType.equalizer) continue; // EQ 单独处理
      final state = _filterStates[type];
      if (state != null) {
        (config['filters'] as Map<String, dynamic>)[type.name] = {
          'isEnabled': state.isEnabled,
          'params': state.params,
        };
      }
    }

    return const JsonEncoder.withIndent('  ').convert(config);
  }

  /// 从 JSON 字符串导入 DSP 配置
  /// 返回 null 表示成功，返回字符串表示错误信息
  Future<String?> importConfig(String jsonStr) async {
    try {
      final config = jsonDecode(jsonStr) as Map<String, dynamic>;

      // 版本检查
      final version = config['version'] as int? ?? 0;
      if (version < 1) {
        return '不支持的配置文件版本';
      }

      // 先停用所有当前滤波器
      if (_isInitialized) {
        _deactivateAllFilters();
      }

      // 导入 DSP 总开关
      _dspEnabled = config['dspEnabled'] as bool? ?? false;

      // 导入 EQ 频段
      final eqBandsList = config['eqBands'] as List<dynamic>?;
      if (eqBandsList != null && eqBandsList.length == _eqBands.length) {
        for (int i = 0; i < _eqBands.length; i++) {
          final bandData = eqBandsList[i] as Map<String, dynamic>;
          _eqBands[i] = _eqBands[i].copyWith(
            gain: (bandData['gain'] as num).toDouble(),
          );
        }
      }

      // 导入 EQ 开关
      final eqEnabled = config['eqEnabled'] as bool? ?? false;
      _filterStates[DspFilterType.equalizer] = _filterStates[DspFilterType.equalizer]!
          .copyWith(isEnabled: eqEnabled);

      // 导入滤波器开关和参数
      final filtersConfig = config['filters'] as Map<String, dynamic>?;
      if (filtersConfig != null) {
        for (final type in DspFilterType.values) {
          if (type == DspFilterType.equalizer) continue;
          final filterData = filtersConfig[type.name] as Map<String, dynamic>?;
          if (filterData != null) {
            final isEnabled = filterData['isEnabled'] as bool? ?? false;
            final params = <String, double>{};
            final paramsData = filterData['params'] as Map<String, dynamic>?;
            if (paramsData != null) {
              for (final entry in paramsData.entries) {
                params[entry.key] = (entry.value as num).toDouble();
              }
            }
            _filterStates[type] = DspFilterState(
              type: type,
              isEnabled: isEnabled,
              params: params,
            );
          }
        }
      }

      // 导入自定义预设
      final customPresetsList = config['customPresets'] as List<dynamic>?;
      if (customPresetsList != null) {
        _customPresets = customPresetsList
            .map((e) => CustomEqPreset.fromJson(e as Map<String, dynamic>))
            .toList();
        await _saveCustomPresets();
      }

      // 如果 DSP 启用且已初始化，应用所有配置到 SoLoud
      if (_dspEnabled && _isInitialized) {
        _activateAllEnabledFilters();
        // 应用 EQ 频段增益
        if (eqEnabled) {
          for (int i = 0; i < _eqBands.length; i++) {
            final linearGain = _dbToLinear(_eqBands[i].gain);
            try {
              _getEqBandParam(i).value = linearGain;
            } catch (_) {}
          }
          _updateEqWet();
        }
        // 应用滤波器参数
        for (final type in DspFilterType.values) {
          if (type == DspFilterType.equalizer) continue;
          final state = _filterStates[type];
          if (state != null && state.isEnabled && state.params.isNotEmpty) {
            for (final entry in state.params.entries) {
              final attrId = int.tryParse(entry.key.replaceAll('attr_', ''));
              if (attrId != null) {
                try {
                  _setFilterParamValue(type, attrId, entry.value);
                } catch (_) {}
              }
            }
          }
        }
      }

      notifyListeners();
      return null; // 成功
    } catch (e) {
      debugPrint('导入 DSP 配置失败: $e');
      return '配置文件格式错误：$e';
    }
  }

  /// 获取均衡器频段参数
  dynamic _getEqBandParam(int bandIndex) {
    final eqFilter = SoLoud.instance.filters.equalizerFilter;
    switch (bandIndex) {
      case 0: return eqFilter.band1;
      case 1: return eqFilter.band2;
      case 2: return eqFilter.band3;
      case 3: return eqFilter.band4;
      case 4: return eqFilter.band5;
      case 5: return eqFilter.band6;
      case 6: return eqFilter.band7;
      case 7: return eqFilter.band8;
      default: return eqFilter.band1;
    }
  }

  /// 获取滤波器对象（返回 FilterBase 的子类）
  dynamic _getFilter(DspFilterType type) {
    if (!_isInitialized) return null;

    final filters = SoLoud.instance.filters;
    switch (type) {
      case DspFilterType.bassboost:
        return filters.bassBoostFilter;
      case DspFilterType.echo:
        return filters.echoFilter;
      case DspFilterType.reverb:
        return filters.freeverbFilter;
      case DspFilterType.flanger:
        return filters.flangerFilter;
      case DspFilterType.pitchShift:
        return filters.pitchShiftFilter;
      case DspFilterType.compressor:
        return filters.compressorFilter;
      case DspFilterType.limiter:
        return filters.limiterFilter;
      case DspFilterType.waveShaper:
        return filters.waveShaperFilter;
      case DspFilterType.robotize:
        return filters.robotizeFilter;
      case DspFilterType.lofi:
        return filters.lofiFilter;
      case DspFilterType.biquadResonant:
        return filters.biquadResonantFilter;
      case DspFilterType.equalizer:
        return filters.equalizerFilter;
    }
  }

  /// 设置滤波器参数值
  void _setFilterParamValue(DspFilterType type, int attributeId, double value) {
    if (!_isInitialized) return;

    final filters = SoLoud.instance.filters;
    switch (type) {
      case DspFilterType.bassboost:
        if (attributeId == 0) filters.bassBoostFilter.boost.value = value;
        break;
      case DspFilterType.echo:
        if (attributeId == 0) {
          filters.echoFilter.delay.value = value;
        } else if (attributeId == 1) {
          filters.echoFilter.decay.value = value;
        } else if (attributeId == 2) {
          filters.echoFilter.filter.value = value;
        }
        break;
      case DspFilterType.reverb:
        if (attributeId == 0) {
          filters.freeverbFilter.freeze.value = value;
        } else if (attributeId == 1) {
          filters.freeverbFilter.roomSize.value = value;
        } else if (attributeId == 2) {
          filters.freeverbFilter.damp.value = value;
        }
        break;
      case DspFilterType.flanger:
        if (attributeId == 0) {
          filters.flangerFilter.delay.value = value;
        } else if (attributeId == 1) {
          filters.flangerFilter.freq.value = value;
        }
        break;
      case DspFilterType.pitchShift:
        if (attributeId == 0) {
          filters.pitchShiftFilter.shift.value = value;
        }
        break;
      case DspFilterType.waveShaper:
        if (attributeId == 0) {
          filters.waveShaperFilter.amount.value = value;
        }
        break;
      case DspFilterType.robotize:
        if (attributeId == 0) {
          filters.robotizeFilter.frequency.value = value;
        } else if (attributeId == 1) {
          filters.robotizeFilter.waveform.value = value;
        }
        break;
      case DspFilterType.lofi:
        if (attributeId == 0) {
          filters.lofiFilter.samplerate.value = value;
        } else if (attributeId == 1) {
          filters.lofiFilter.bitdepth.value = value;
        }
        break;
      case DspFilterType.biquadResonant:
        if (attributeId == 0) {
          filters.biquadResonantFilter.type.value = value;
        } else if (attributeId == 1) {
          filters.biquadResonantFilter.frequency.value = value;
        } else if (attributeId == 2) {
          filters.biquadResonantFilter.resonance.value = value;
        }
        break;
      case DspFilterType.equalizer:
        // value 是 dB 值，需要转换为 SoLoud 线性增益
        _getEqBandParam(attributeId).value = _dbToLinear(value);
        break;
      case DspFilterType.compressor:
        // 压缩器参数：1=阈值, 2=补偿增益, 3=拐点宽度, 4=比率, 5=启动时间, 6=释放时间
        if (attributeId == 1) {
          filters.compressorFilter.threshold.value = value;
        } else if (attributeId == 2) {
          filters.compressorFilter.makeupGain.value = value;
        } else if (attributeId == 3) {
          filters.compressorFilter.kneeWidth.value = value;
        } else if (attributeId == 4) {
          filters.compressorFilter.ratio.value = value;
        } else if (attributeId == 5) {
          filters.compressorFilter.attackTime.value = value;
        } else if (attributeId == 6) {
          filters.compressorFilter.releaseTime.value = value;
        }
        break;
      case DspFilterType.limiter:
        // 限幅器参数：1=阈值, 2=输出上限, 3=拐点宽度, 4=启动时间, 5=释放时间
        if (attributeId == 1) {
          filters.limiterFilter.threshold.value = value;
        } else if (attributeId == 2) {
          filters.limiterFilter.outputCeiling.value = value;
        } else if (attributeId == 3) {
          filters.limiterFilter.kneeWidth.value = value;
        } else if (attributeId == 4) {
          filters.limiterFilter.attackTime.value = value;
        } else if (attributeId == 5) {
          filters.limiterFilter.releaseTime.value = value;
        }
        break;
    }
  }

  @override
  void dispose() {
    disposeSoLoud();
    super.dispose();
  }
}
