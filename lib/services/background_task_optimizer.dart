import 'dart:async';
import 'dart:isolate';
import '../config/app_config.dart';
import '../services/app_state_manager.dart';

/// Background task priority levels
enum TaskPriority {
  critical(0),
  high(1),
  normal(2),
  low(3);

  const TaskPriority(this.value);
  final int value;
}

/// Background task definition
class BackgroundTask {
  final String id;
  final String name;
  final Future<dynamic> Function() task;
  final TaskPriority priority;
  final Duration? timeout;
  final int maxRetries;
  final bool persistent;

  const BackgroundTask({
    required this.id,
    required this.name,
    required this.task,
    this.priority = TaskPriority.normal,
    this.timeout,
    this.maxRetries = 0,
    this.persistent = false,
  });
}

/// Background task result
class TaskResult {
  final String taskId;
  final bool success;
  final dynamic result;
  final String? error;
  final DateTime completedAt;
  final Duration executionTime;

  const TaskResult({
    required this.taskId,
    required this.success,
    this.result,
    this.error,
    required this.completedAt,
    required this.executionTime,
  });
}

/// High-performance background task optimizer
class BackgroundTaskOptimizer {
  static BackgroundTaskOptimizer? _instance;
  static BackgroundTaskOptimizer get instance =>
      _instance ??= BackgroundTaskOptimizer._();

  BackgroundTaskOptimizer._();

  // Task queues by priority
  final Map<TaskPriority, List<BackgroundTask>> _taskQueues = {};

  // Running tasks
  final Map<String, Completer<TaskResult>> _runningTasks = {};
  final Map<String, DateTime> _taskStartTimes = {};

  // Task history and stats
  final List<TaskResult> _taskHistory = [];
  final Map<String, int> _retryCounters = {};

  // Worker management
  int _activeWorkers = 0;
  final int _maxWorkers = 4;
  bool _isProcessing = false;

  Timer? _processingTimer;
  Timer? _cleanupTimer;

  /// Initialize background task optimizer
  void initialize() {
    // Initialize task queues
    for (final priority in TaskPriority.values) {
      _taskQueues[priority] = [];
    }

    _startProcessing();
    _startCleanup();
    print('🎯 Background task optimizer initialized');
  }

  /// Start task processing
  void _startProcessing() {
    _processingTimer = Timer.periodic(const Duration(milliseconds: 100), (_) {
      if (!_isProcessing && _activeWorkers < _maxWorkers) {
        _processPendingTasks();
      }
    });
  }

  /// Start cleanup timer
  void _startCleanup() {
    _cleanupTimer = Timer.periodic(const Duration(minutes: 5), (_) {
      _cleanupCompletedTasks();
    });
  }

  /// Schedule a background task
  Future<TaskResult> scheduleTask(BackgroundTask task) async {
    AppConfig.secureLog(
        '📋 Scheduling task: ${task.name} (${task.priority.name})');

    final completer = Completer<TaskResult>();
    _runningTasks[task.id] = completer;

    // Add to appropriate queue
    _taskQueues[task.priority]!.add(task);

    // Sort queue by priority (critical tasks first)
    _taskQueues[task.priority]!
        .sort((a, b) => a.priority.value.compareTo(b.priority.value));

    return completer.future;
  }

  /// Process pending tasks
  Future<void> _processPendingTasks() async {
    if (_isProcessing || _activeWorkers >= _maxWorkers) return;

    _isProcessing = true;

    try {
      // Process tasks by priority
      for (final priority in TaskPriority.values) {
        final queue = _taskQueues[priority]!;

        while (queue.isNotEmpty && _activeWorkers < _maxWorkers) {
          final task = queue.removeAt(0);
          _executeTask(task);
        }
      }
    } finally {
      _isProcessing = false;
    }
  }

  /// Execute a background task
  Future<void> _executeTask(BackgroundTask task) async {
    _activeWorkers++;
    _taskStartTimes[task.id] = DateTime.now();

    AppConfig.secureLog('🚀 Executing task: ${task.name}');

    try {
      // Execute task with timeout if specified
      final result = task.timeout != null
          ? await task.task().timeout(task.timeout!)
          : await task.task();

      final executionTime =
          DateTime.now().difference(_taskStartTimes[task.id]!);

      final taskResult = TaskResult(
        taskId: task.id,
        success: true,
        result: result,
        completedAt: DateTime.now(),
        executionTime: executionTime,
      );

      _completeTask(task.id, taskResult);
      AppConfig.secureLog(
          '✅ Task completed: ${task.name} (${executionTime.inMilliseconds}ms)');
    } catch (e) {
      await _handleTaskError(task, e);
    } finally {
      _activeWorkers--;
      _taskStartTimes.remove(task.id);
    }
  }

  /// Handle task execution error
  Future<void> _handleTaskError(BackgroundTask task, dynamic error) async {
    final retryCount = _retryCounters[task.id] ?? 0;

    AppConfig.secureLog(
        '❌ Task failed: ${task.name} - $error (retry $retryCount/${task.maxRetries})');

    if (retryCount < task.maxRetries) {
      // Retry task
      _retryCounters[task.id] = retryCount + 1;

      // Exponential backoff
      await Future.delayed(Duration(milliseconds: 100 * (retryCount + 1)));

      _taskQueues[task.priority]!.insert(0, task);
      AppConfig.secureLog('🔄 Retrying task: ${task.name}');
    } else {
      // Task failed permanently
      final executionTime =
          DateTime.now().difference(_taskStartTimes[task.id]!);

      final taskResult = TaskResult(
        taskId: task.id,
        success: false,
        error: error.toString(),
        completedAt: DateTime.now(),
        executionTime: executionTime,
      );

      _completeTask(task.id, taskResult);
      _retryCounters.remove(task.id);

      AppStateManager.instance.setError('Background task failed: ${task.name}');
    }
  }

  /// Complete a task
  void _completeTask(String taskId, TaskResult result) {
    final completer = _runningTasks.remove(taskId);

    if (completer != null && !completer.isCompleted) {
      completer.complete(result);
    }

    _taskHistory.add(result);

    // Keep only recent history
    if (_taskHistory.length > 100) {
      _taskHistory.removeAt(0);
    }
  }

  /// Execute task in isolate for CPU-intensive work
  Future<TaskResult> executeInIsolate(BackgroundTask task) async {
    AppConfig.secureLog('🏝️ Executing task in isolate: ${task.name}');

    final startTime = DateTime.now();

    try {
      // Create isolate for CPU-intensive task
      final receivePort = ReceivePort();

      await Isolate.spawn(_isolateEntryPoint, {
        'sendPort': receivePort.sendPort,
        'task': task,
      });

      final result = await receivePort.first;
      final executionTime = DateTime.now().difference(startTime);

      return TaskResult(
        taskId: task.id,
        success: result['success'],
        result: result['data'],
        error: result['error'],
        completedAt: DateTime.now(),
        executionTime: executionTime,
      );
    } catch (e) {
      final executionTime = DateTime.now().difference(startTime);

      return TaskResult(
        taskId: task.id,
        success: false,
        error: e.toString(),
        completedAt: DateTime.now(),
        executionTime: executionTime,
      );
    }
  }

  /// Isolate entry point
  static void _isolateEntryPoint(Map<String, dynamic> message) async {
    final sendPort = message['sendPort'] as SendPort;
    final task = message['task'] as BackgroundTask;

    try {
      final result = await task.task();
      sendPort.send({
        'success': true,
        'data': result,
      });
    } catch (e) {
      sendPort.send({
        'success': false,
        'error': e.toString(),
      });
    }
  }

  /// Cancel a task
  bool cancelTask(String taskId) {
    final completer = _runningTasks.remove(taskId);

    if (completer != null && !completer.isCompleted) {
      final result = TaskResult(
        taskId: taskId,
        success: false,
        error: 'Task cancelled',
        completedAt: DateTime.now(),
        executionTime: Duration.zero,
      );

      completer.complete(result);
      AppConfig.secureLog('🚫 Task cancelled: $taskId');
      return true;
    }

    // Remove from queues
    for (final queue in _taskQueues.values) {
      queue.removeWhere((task) => task.id == taskId);
    }

    return false;
  }

  /// Get task queue status
  Map<String, dynamic> getStatus() {
    final queueSizes = <String, int>{};
    int totalQueued = 0;

    for (final entry in _taskQueues.entries) {
      queueSizes[entry.key.name] = entry.value.length;
      totalQueued += entry.value.length;
    }

    return {
      'activeWorkers': _activeWorkers,
      'maxWorkers': _maxWorkers,
      'queuedTasks': totalQueued,
      'runningTasks': _runningTasks.length,
      'queueSizes': queueSizes,
      'taskHistory': _taskHistory.length,
    };
  }

  /// Get task statistics
  Map<String, dynamic> getTaskStats() {
    final successful = _taskHistory.where((t) => t.success).length;
    final failed = _taskHistory.where((t) => !t.success).length;

    final avgExecutionTime = _taskHistory.isNotEmpty
        ? _taskHistory
                .map((t) => t.executionTime.inMilliseconds)
                .reduce((a, b) => a + b) /
            _taskHistory.length
        : 0.0;

    return {
      'totalTasks': _taskHistory.length,
      'successful': successful,
      'failed': failed,
      'successRate':
          _taskHistory.isNotEmpty ? (successful / _taskHistory.length) : 0.0,
      'avgExecutionTimeMs': avgExecutionTime,
    };
  }

  /// Clean up completed tasks
  void _cleanupCompletedTasks() {
    final now = DateTime.now();
    const maxAge = Duration(hours: 1);

    _taskHistory
        .removeWhere((task) => now.difference(task.completedAt) > maxAge);

    AppConfig.secureLog('🧹 Cleaned up old task history');
  }

  /// Pause task processing
  void pauseProcessing() {
    _processingTimer?.cancel();
    print('⏸️ Task processing paused');
  }

  /// Resume task processing
  void resumeProcessing() {
    _startProcessing();
    print('▶️ Task processing resumed');
  }

  /// Dispose background task optimizer
  void dispose() {
    _processingTimer?.cancel();
    _cleanupTimer?.cancel();

    // Cancel all running tasks
    for (final taskId in _runningTasks.keys.toList()) {
      cancelTask(taskId);
    }

    _taskQueues.clear();
    _runningTasks.clear();
    _taskStartTimes.clear();
    _taskHistory.clear();
    _retryCounters.clear();

    _activeWorkers = 0;
    _isProcessing = false;

    print('🎯 Background task optimizer disposed');
  }
}
