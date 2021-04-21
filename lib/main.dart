// Copyright 2018 The Flutter team. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.
import 'package:easy_alarm/add_alarm.dart';
import 'package:easy_alarm/db.dart';
import 'package:flutter/material.dart';

import 'alarm.dart';
import 'global.dart';

// --- resources ---

const APP_NAME = 'Easy Alarm';
const _titleFont = TextStyle(fontSize: 24.0);
const _descFont = TextStyle(fontSize: 14, color: Colors.black45);
const _repeatFont = TextStyle(fontSize: 14, color: Colors.black87);

void main() => runApp(MyApp());

Widget test() {
  return Flex(
    children: [
      Flexible(
          child: Container(
        color: Colors.red,
      )),
      Flexible(
          child: Container(
        color: Colors.blue,
      )),
    ],
    direction: Axis.horizontal,
    textDirection: TextDirection.ltr,
  );
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // return test();
    return MaterialApp(
      title: APP_NAME,
      home: AlarmClockMain(),
      theme: ThemeData(primaryColor: Color.fromARGB(255, 246, 246, 246)),
      darkTheme: ThemeData.dark(),
    );
  }
}

class AlarmClockMain extends StatefulWidget {
  @override
  _AlarmClockMainState createState() => _AlarmClockMainState();
}

class _AlarmClockMainState extends State<AlarmClockMain> with SingleTickerProviderStateMixin {
  final _db = AlarmStore();
  List<Alarm> _items;

  @override
  void initState() {
    super.initState();
    loadDataFromLocal();
  }

  @override
  Widget build(BuildContext context) {
    print('_AlarmClockMainState/ build: items = $_items');
    return Scaffold(
      appBar: AppBar(
        title: Text(APP_NAME),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.add),
            onPressed: () {
              Pages.gotoPage(
                context,
                AddAlarmPage(Alarm(TimeOfDay.now(), enabled: true)),
              ).then((value) {
                if (value == null) return;
                Alarm alarm = value;
                _db.update(alarm).then((bool success) {
                  print('main/build: update ${success ? "success" : "failed"}');
                  loadDataFromLocal();
                });
              });
            },
          ),
        ],
      ),
      body: Center(
        child: (_items == null || _items.isEmpty)
            ? Text("No alarm clock yet.")
            : ListView.builder(
                padding: EdgeInsets.all(8),
                itemBuilder: (context, index) {
                  return index >= _items.length ? null : AlarmListTile(_items[index]);
                },
              ),
      ),
    );
  }

  /// 返回列表单元部件，包含时间、简介等。
  // ignore: non_constant_identifier_names
  Widget AlarmListTile(Alarm _item) {
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
            loadDataFromLocal();
          });
        },
      ),
    );
  }

  void _enableAlarm(Alarm item, bool isEnabled) async {
    item.enabled = isEnabled;
    bool success = await AlarmStore().update(item);
    if (success) setState(() {});
  }

  // void sortAlarms() {
  //   _items.sort((Alarm a, Alarm b) {
  //     if (a.enabled && !b.enabled) return -1;
  //     if (!a.enabled && b.enabled) return 1;
  //     return Alarm.timeOfDayToMinute(a.timeOfDay) - Alarm.timeOfDayToMinute(b.timeOfDay);
  //   });
  // }

  void loadDataFromLocal() {
    _db.getAlarms(forceRefresh: true).then((List<Alarm> value) {
      setState(() {
        _items = value;
        // sortAlarms();
      });
    });
  }
}

class Intent {
  final Map<String, dynamic> data = Map();

  void setData(String key, dynamic value) {
    data[key] = value;
  }
}
