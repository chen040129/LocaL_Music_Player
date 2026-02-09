import 'package:flutter/material.dart';
import '../services/performance_monitor_service.dart';

/// 性能监控小部件 - 显示应用的性能指标
class PerformanceMonitorWidget extends StatefulWidget {
  final bool showDetailedInfo;

  const PerformanceMonitorWidget({
    Key? key,
    this.showDetailedInfo = false,
  }) : super(key: key);

  @override
  State<PerformanceMonitorWidget> createState() => _PerformanceMonitorWidgetState();
}

class _PerformanceMonitorWidgetState extends State<PerformanceMonitorWidget> {
  final _performanceMonitor = PerformanceMonitorService();
  List<String> _warnings = [];

  @override
  void initState() {
    super.initState();
    _performanceMonitor.startMonitoring();
    _performanceMonitor.performanceWarningStream.listen((warning) {
      setState(() {
        _warnings.add(warning);
        if (_warnings.length > 5) {
          _warnings.removeAt(0);
        }
      });
    });
  }

  @override
  void dispose() {
    _performanceMonitor.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.speed,
                size: 16,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Text(
                '性能监控',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _buildMemoryInfo(),
          if (widget.showDetailedInfo) ...[
            const SizedBox(height: 8),
            _buildDetailedInfo(),
          ],
          if (_warnings.isNotEmpty) ...[
            const SizedBox(height: 8),
            _buildWarnings(),
          ],
        ],
      ),
    );
  }

  Widget _buildMemoryInfo() {
    final currentUsage = _performanceMonitor.getCurrentMemoryUsageMB();
    final peakUsage = _performanceMonitor.getPeakMemoryUsageMB();
    final averageUsage = _performanceMonitor.getAverageMemoryUsageMB();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildMemoryBar(
          '当前内存',
          currentUsage,
          PerformanceMonitorService.memoryWarningThreshold,
          PerformanceMonitorService.memoryCriticalThreshold,
        ),
        const SizedBox(height: 4),
        _buildMemoryBar(
          '峰值内存',
          peakUsage,
          PerformanceMonitorService.memoryWarningThreshold,
          PerformanceMonitorService.memoryCriticalThreshold,
        ),
        const SizedBox(height: 4),
        _buildMemoryBar(
          '平均内存',
          averageUsage.toInt(),
          PerformanceMonitorService.memoryWarningThreshold,
          PerformanceMonitorService.memoryCriticalThreshold,
        ),
      ],
    );
  }

  Widget _buildMemoryBar(String label, int value, int warning, int critical) {
    final percentage = value / critical;
    final color = percentage >= 1.0
        ? Colors.red
        : percentage >= 0.6
            ? Colors.orange
            : Colors.green;

    return Row(
      children: [
        SizedBox(
          width: 80,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              LinearProgressIndicator(
                value: percentage.clamp(0.0, 1.0),
                backgroundColor: Colors.grey[300],
                valueColor: AlwaysStoppedAnimation<Color>(color),
                minHeight: 8,
              ),
              const SizedBox(height: 2),
              Text(
                '$value MB',
                style: TextStyle(
                  fontSize: 10,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDetailedInfo() {
    final history = _performanceMonitor.getMemoryUsageHistory();
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '内存使用历史',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 4),
          SizedBox(
            height: 100,
            child: CustomPaint(
              painter: _MemoryHistoryPainter(history),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWarnings() {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.red[50],
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: Colors.red[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.warning,
                size: 16,
                color: Colors.red[700],
              ),
              const SizedBox(width: 4),
              Text(
                '性能警告',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.red[700],
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          ..._warnings.map((warning) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  warning,
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.red[900],
                  ),
                ),
              )),
        ],
      ),
    );
  }
}

/// 内存历史图表绘制器
class _MemoryHistoryPainter extends CustomPainter {
  final List<int> history;

  _MemoryHistoryPainter(this.history);

  @override
  void paint(Canvas canvas, Size size) {
    if (history.isEmpty) return;

    final paint = Paint()
      ..color = Colors.blue
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final maxMemory = history.reduce((a, b) => a > b ? a : b).toDouble();
    final path = Path();

    for (int i = 0; i < history.length; i++) {
      final x = (i / (history.length - 1)) * size.width;
      final y = size.height - (history[i] / maxMemory) * size.height;

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_MemoryHistoryPainter oldDelegate) {
    return oldDelegate.history != history;
  }
}
