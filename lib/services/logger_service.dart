import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class LogEntry {
  final String id;
  final String message;
  final DateTime timestamp;
  final String level;
  final String source;

  LogEntry({
    required this.id,
    required this.message,
    required this.timestamp,
    required this.level,
    required this.source,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'message': message,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'level': level,
      'source': source,
    };
  }

  factory LogEntry.fromJson(Map<String, dynamic> json) {
    return LogEntry(
      id: json['id'],
      message: json['message'],
      timestamp: DateTime.fromMillisecondsSinceEpoch(json['timestamp']),
      level: json['level'],
      source: json['source'],
    );
  }
}

class LoggerService {
  static const String _logsKey = 'app_logs';
  static LoggerService? _instance;
  late SharedPreferences _prefs;

  LoggerService._internal();

  static Future<LoggerService> getInstance() async {
    if (_instance == null) {
      _instance = LoggerService._internal();
      await _instance!._init();
    }
    return _instance!;
  }

  Future<void> _init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  Future<void> log(String message,
      {String level = 'INFO', String source = 'APP'}) async {
    final logEntry = LogEntry(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      message: message,
      timestamp: DateTime.now(),
      level: level,
      source: source,
    );

    final logs = await getLogs();
    logs.insert(0, logEntry); // Insert at the beginning for latest first

    // Keep only the last 100 logs to prevent storage issues
    if (logs.length > 100) {
      logs.removeRange(100, logs.length);
    }

    await _saveLogs(logs);

    // Also print to console for immediate debugging
    print('[${logEntry.level}:${logEntry.source}] ${logEntry.message}');
  }

  Future<List<LogEntry>> getLogs() async {
    final logsJson = _prefs.getString(_logsKey);
    if (logsJson == null) return [];

    try {
      final logsList = jsonDecode(logsJson) as List;
      return logsList.map((json) => LogEntry.fromJson(json)).toList();
    } catch (e) {
      print('Error parsing logs: $e');
      return [];
    }
  }

  Future<void> clearLogs() async {
    await _prefs.remove(_logsKey);
  }

  Future<void> _saveLogs(List<LogEntry> logs) async {
    final logsJson = jsonEncode(logs.map((log) => log.toJson()).toList());
    await _prefs.setString(_logsKey, logsJson);
  }

  // Convenience methods for different log levels
  Future<void> info(String message, {String source = 'APP'}) async {
    await log(message, level: 'INFO', source: source);
  }

  Future<void> warning(String message, {String source = 'APP'}) async {
    await log(message, level: 'WARNING', source: source);
  }

  Future<void> error(String message, {String source = 'APP'}) async {
    await log(message, level: 'ERROR', source: source);
  }

  Future<void> debug(String message, {String source = 'APP'}) async {
    await log(message, level: 'DEBUG', source: source);
  }
}
