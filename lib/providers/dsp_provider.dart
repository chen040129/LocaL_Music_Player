
import 'package:flutter/foundation.dart';
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

/// DSP 音频效果管理 Provider
class DspProvider with ChangeNotifier {
  bool _isInitialized = false;
  bool _dspEnabled = false;

  final Map<DspFilterType, DspFilterState> _filterStates = {};
  List<EqBand> _eqBands = [];

  // Getters
  bool get isInitialized => _isInitialized;
  bool get dspEnabled => _dspEnabled;
  Map<DspFilterType, DspFilterState> get filterStates => _filterStates;
  List<EqBand> get eqBands => _eqBands;

  DspProvider() {
    _initDefaultFilterStates();
    _initEqBands();
  }

  void _initDefaultFilterStates() {
    for (final type in DspFilterType.values) {
      _filterStates[type] = DspFilterState(type: type);
    }
  }

  /// 8段均衡器（SoLoud 只支持 band1~band8）
  void _initEqBands() {
    _eqBands = [
      const EqBand(label: 'Band 1', frequency: 31.0),
      const EqBand(label: 'Band 2', frequency: 62.0),
      const EqBand(label: 'Band 3', frequency: 125.0),
      const EqBand(label: 'Band 4', frequency: 250.0),
      const EqBand(label: 'Band 5', frequency: 500.0),
      const EqBand(label: 'Band 6', frequency: 1000.0),
      const EqBand(label: 'Band 7', frequency: 2000.0),
      const EqBand(label: 'Band 8', frequency: 4000.0),
    ];
  }

  /// 初始化 SoLoud 引擎
  Future<bool> initSoLoud() async {
    if (_isInitialized) return true;

    try {
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
  Future<void> disposeSoLoud() async {
    if (!_isInitialized) return;

    try {
      SoLoud.instance.deinit();
      _isInitialized = false;
      debugPrint('SoLoud 引擎已释放');
      notifyListeners();
    } catch (e) {
      debugPrint('SoLoud 引擎释放异常: $e');
    }
  }

  /// 切换 DSP 总开关
  Future<void> toggleDsp(bool enabled) async {
    if (enabled && !_isInitialized) {
      final success = await initSoLoud();
      if (!success) return;
    }
    _dspEnabled = enabled;
    notifyListeners();
  }

  /// 切换滤波器开关
  void toggleFilter(DspFilterType type, bool enabled) {
    if (!_isInitialized) return;

    final state = _filterStates[type]!;
    _filterStates[type] = state.copyWith(isEnabled: enabled);

    try {
      final filter = _getFilter(type);
      if (filter != null) {
        if (enabled) {
          filter.activate();
        } else {
          filter.deactivate();
        }
      }
    } catch (e) {
      debugPrint('切换滤波器失败: $e');
    }

    notifyListeners();
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

  /// 设置均衡器频段增益
  void setEqBandGain(int bandIndex, double gain) {
    if (bandIndex < 0 || bandIndex >= _eqBands.length) return;

    _eqBands[bandIndex] = _eqBands[bandIndex].copyWith(
      gain: gain.clamp(-12.0, 12.0),
    );

    if (_filterStates[DspFilterType.equalizer]?.isEnabled == true) {
      try {
        final param = _getEqBandParam(bandIndex);
        param.value = _eqBands[bandIndex].gain;
      } catch (e) {
        debugPrint('更新均衡器频段失败: $e');
      }
    }

    notifyListeners();
  }

  /// 重置均衡器所有频段
  void resetEqBands() {
    for (int i = 0; i < _eqBands.length; i++) {
      _eqBands[i] = _eqBands[i].copyWith(gain: 0.0);
    }
    notifyListeners();
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
        _getEqBandParam(attributeId).value = value;
        break;
      case DspFilterType.compressor:
      case DspFilterType.limiter:
        // 这些滤波器通过 wet 控制混合比
        break;
    }
  }

  @override
  void dispose() {
    disposeSoLoud();
    super.dispose();
  }
}
