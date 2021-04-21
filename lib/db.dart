import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'alarm.dart';
import 'dart:convert';

/// Alarm在系统中以SharedPreferences的形式存储
class AlarmStore {
  factory AlarmStore() => getInstance();
  static AlarmStore _instance;

  AlarmStore._internal();

  static AlarmStore getInstance() {
    if (_instance == null) {
      _instance = AlarmStore._internal();
    }
    return _instance;
  }

  static const ALARM_KEY = 'alarm_key';

  /// 本地闹钟的缓存，不要直接使用。使用 [getAlarms] instead。
  List<Alarm> _cachedAlarmList;
  final _local = _LocalStore();
  final JsonCodec converter = JsonCodec();

  /// 更新闹钟
  Future<bool> update(Alarm alarm) async {
    List<Alarm> alarms = await getAlarms(); // id从小到大排列
    if (alarm.id == 0 || alarms.length == 0) {
      // 是新的闹钟
      int newId = _newId(alarms);
      if(newId == -1) return false;
      alarm.id = newId;
      alarms.add(alarm); // 添加到最后
    } else {
      // 已经存在的闹钟
      for (int i = 0; i < alarms.length; i++) {
        if (alarms[i].id == alarm.id) {
          alarms[i] = alarm; // 直接替换
        }
      }
    }
    List<String> jsonList = alarms.map((Alarm a) {
      return converter.encode(a);
    }).toList();
    print('db/ update: json = $jsonList');
    return _local.setStringList(ALARM_KEY, jsonList);
  }

  Future<bool> remove(int id) async {
    List<Alarm> alarms = await getAlarms();
    for (int i = 0; i < alarms.length; i++) {
      if (alarms[i].id == id) {
        alarms.removeAt(i);
        break;
      }
    }
    List<String> jsonList = alarms.map((Alarm a) {
      return converter.encode(a);
    }).toList();
    print('AlarmStore/ remove: json = $jsonList');
    return _local.setStringList(ALARM_KEY, jsonList);
  }

  /// 返回当前本地存储的闹钟列表，或者本地存储闹钟列表的缓存（如果存在）。按id排序。
  ///
  /// 注：不返回空值。
  ///
  /// [forceRefresh] 强制刷新，如果设置为true则强制重新从本地读取数据，否则就读缓存中的。
  Future<List<Alarm>> getAlarms({bool forceRefresh}) async {
    if (_cachedAlarmList == null) {
      _cachedAlarmList = await _loadAlarms();
    }
    if (_cachedAlarmList == null) _cachedAlarmList = []; // 不返回空值
    _cachedAlarmList.sort((a, b) => a.id - b.id); // 按id排序
    return _cachedAlarmList;
  }

  /// 立即从本地获取存储的闹钟列表
  Future<List<Alarm>> _loadAlarms() async {
    List<String> jsonList = await _local.getStringList(ALARM_KEY);
    print('loadAlarms: $jsonList');
    return jsonList == null
        ? []
        : jsonList.map((String s) {
            Map map = converter.decode(s);
            List<dynamic> repeat = map['repeat'];
            var repeatNew = <bool>[];
            for (int i = 0; i < repeat.length; i++) {
              repeatNew.add(repeat[i]);
            }
            map['repeat'] = repeatNew;
            return Alarm.fromJson(map);
          }).toList();
  }

  /// 获取一个最小的可获得的id
  int _newId(List<Alarm> alarms) {
    Set<int> idSet = Set();
    for (Alarm a in alarms) {
      idSet.add(a.id);
    }
    for (int i = 1; i <= 65535; i++) {
      if(!idSet.contains(i)) return i;
    }
    return -1;
  }
}

class _LocalStore {
  Future<String> getString(String key) async {
    final sp = await SharedPreferences.getInstance();
    return sp.getString(key);
  }

  Future<List<String>> getStringList(String key) async {
    final sp = await SharedPreferences.getInstance();
    return sp.getStringList(key);
  }

  void setString(String key, String value) async {
    final sp = await SharedPreferences.getInstance();
    sp.setString(key, value);
  }

  Future<bool> setStringList(String key, List<String> value) async {
    final sp = await SharedPreferences.getInstance();
    return sp.setStringList(key, value);
  }
}

class Faker {
  static Alarm _createAlarm() {
    return Alarm(TimeOfDay.now());
  }
}
