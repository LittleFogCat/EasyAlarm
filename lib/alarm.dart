import 'package:date_format/date_format.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:easy_alarm/add_alarm.dart';
import 'package:easy_alarm/global.dart';
import 'package:easy_alarm/db.dart';

import 'db.dart';
import 'main.dart';

class AlarmListTile extends StatefulWidget {
  final Alarm item;

  AlarmListTile(this.item);

  @override
  State<StatefulWidget> createState() {
    return _AlarmListTileState(item);
  }
}

class _AlarmListTileState extends State<AlarmListTile> {
  final _titleFont = TextStyle(fontSize: 24.0);
  final _descFont = TextStyle(fontSize: 14, color: Colors.black45);
  final _repeatFont = TextStyle(fontSize: 14, color: Colors.black87);
  Alarm _item;

  _AlarmListTileState(this._item);

  @override
  void didUpdateWidget(covariant AlarmListTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    print('_AlarmListTileState/ didUpdateWidget:');
  }

  @override
  Widget build(BuildContext context) {
    print('_AlarmListTileState/ build: $_item');
    if (_item == null)
      return Container(
        width: 0,
        height: 0,
      );
    return Opacity(
      opacity: _item.enabled ? 1 : 0.5,
      child: ListTile(
        title: Row(
          children: [
            Text(
              _item.getTimeString(),
              style: _titleFont,
            ),
            Container(
              child: Text(
                _item.desc,
                style: _descFont,
              ),
              padding: EdgeInsets.fromLTRB(8, 0, 0, 0),
            ),
          ],
          crossAxisAlignment: CrossAxisAlignment.end,
        ),
        subtitle: Text(_item.repeatToString(), style: _repeatFont),
        trailing: Switch(
          value: _item.enabled,
          activeColor: Colors.green,
          onChanged: (enabled) {
            _enableAlarm(_item, !_item.enabled);
          },
        ),
        onTap: () {
          Pages.gotoPage(
            context,
            AddAlarmPage(_item),
          ).then((value) {
            if (value == null) return;
            print('add alarm result: $value');
            setState(() {
              _item = value;
            });
          });
        },
        onLongPress: () {
          showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: Text('删除当前闹钟？'),
              actions: [
                TextButton(
                  onPressed: () {
                    AlarmStore().remove(_item.id).then((value) {
                      Pages.goBack(context, true);
                    });
                  },
                  child: Text('确定'),
                ),
                TextButton(
                  onPressed: () {
                    Pages.goBack(context, false);
                  },
                  child: Text('取消'),
                ),
              ],
            ),
          ).then((bool deleted) {
            if (!deleted) return;
            if (AlarmClockMain.instance != null) {
              AlarmClockMain.instance.setState(() {});
            }
          });
        },
      ),
    );
  }

  void _enableAlarm(Alarm item, bool isEnabled) {
    item.enabled = isEnabled;
    AlarmStore().update(item);
    setState(() {});
  }
}

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
    return 'Alarm{id: $id, enabled: $enabled, timeOfDay: $timeOfDay, repeat: $repeat, vibrate: $vibrate, desc: $desc, autoDelete: $autoDelete}';
  }
}
