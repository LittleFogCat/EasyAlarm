import 'package:easy_alarm/add_alarm.dart';
import 'package:easy_alarm/global.dart';
import 'package:flutter/material.dart';


/// 闹钟对应实体类
class Alarm {
  int id = 0;
  bool enabled; // 是否开启
  TimeOfDay timeOfDay; // 响铃时间
  List<bool> repeat; // 重复周期
  bool vibrate; // 是否振动
  String desc; // 备注
  bool autoDelete; // 响铃后删除

  Alarm(
    this.timeOfDay, {
    this.enabled = false,
    this.repeat = const [false, false, false, false, false, false, false],
    this.vibrate = false,
    this.desc = '',
    this.autoDelete = false,
  });

  static minuteToTimeOfDay(int minute) {
    return TimeOfDay(hour: minute ~/ 60, minute: minute % 60);
  }

  static timeOfDayToMinute(TimeOfDay tod) {
    return tod.hour * 60 + tod.minute;
  }

  /// 返回格式化的时间 HH:mm
  String getTimeString() {
    int hour = timeOfDay.hour;
    int minute = timeOfDay.minute;
    String formatted;
    if (hour == 0)
      formatted = '00';
    else if (hour < 10)
      formatted = '0$hour';
    else
      formatted = '$hour';
    formatted += ':';
    if (minute == 0)
      formatted += '00';
    else if (minute < 10)
      formatted += '0$minute';
    else
      formatted += '$minute';
    return formatted;
  }

  void setTimeInMinute(int minute) {
    timeOfDay = minuteToTimeOfDay(minute);
  }

  /// 一次性的
  bool isOnce() {
    return repeat == null || repeat.every((element) => !element);
  }

  String repeatToString() {
    if (repeat == null || arrEqual(repeat, RepeatOption.ONCE.repeat)) return '只响一次';
    if (arrEqual(repeat, RepeatOption.EVERY_DAY.repeat)) return '每天';
    if (arrEqual(repeat, RepeatOption.WEEK_DAY.repeat)) return '工作日';
    if (arrEqual(repeat, RepeatOption.WEEKEND.repeat)) return '周末';
    List<int> enableDays = [];
    for (int i = 0; i < repeat.length; i++) {
      if (repeat[i]) {
        enableDays.add(i);
      }
    }
    String ret = weekdayToHan(enableDays[0]);
    for (int i = 1; i < enableDays.length; i++) {
      ret += ' ' + weekdayToHan(enableDays[i]);
    }
    return ret;
  }

  String weekdayToHan(int i) {
    if (i == 0) return '周一';
    if (i == 1) return '周二';
    if (i == 2) return '周三';
    if (i == 3) return '周四';
    if (i == 4) return '周五';
    if (i == 5) return '周六';
    if (i == 6) return '周日';
    return '';
  }

  Alarm.fromJson(Map<String, dynamic> json)
      : id = json['id'],
        enabled = json['enabled'],
        timeOfDay = minuteToTimeOfDay(json['timeOfDay']),
        repeat = json['repeat'],
        vibrate = json['vibrate'],
        desc = json['desc'],
        autoDelete = json['autoDelete'];

  Map<String, dynamic> toJson() => {
        'id': id,
        'enabled': enabled,
        'timeOfDay': timeOfDayToMinute(timeOfDay),
        'repeat': repeat,
        'vibrate': vibrate,
        'desc': desc,
        'autoDelete': autoDelete,
      };

  @override
  String toString() {
    return 'Alarm<${getTimeString()}>';
  }
}
