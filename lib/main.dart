// Copyright 2018 The Flutter team. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:easy_alarm/add_alarm.dart';
import 'package:easy_alarm/db.dart';

import 'alarm.dart';
import 'global.dart';

const APP_NAME = 'Easy Alarm';

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
  AlarmClockMain();

  static _AlarmClockMainState instance;

  @override
  _AlarmClockMainState createState() {
    instance = _AlarmClockMainState();
    return instance;
  }
}

class _AlarmClockMainState extends State<AlarmClockMain> with SingleTickerProviderStateMixin {
  static _AlarmClockMainState instance;

  final _db = AlarmStore();
  List<Alarm> _items;

  @override
  void initState() {
    super.initState();
    instance = this;
    loadDataFromLocal();
  }

  @override
  Widget build(BuildContext context) {
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
      body: Center(child: makeBody()),
    );
  }

  void loadDataFromLocal() {
    _db.getAlarms(forceRefresh: true).then((List<Alarm> value) {
      value.sort((Alarm a, Alarm b) {
        if (a.enabled && !b.enabled) return -1;
        if (!a.enabled && b.enabled) return 1;
        return Alarm.timeOfDayToMinute(a.timeOfDay) - Alarm.timeOfDayToMinute(b.timeOfDay);
      });
      setState(() {
        _items = value;
      });
    });
  }

  // Body包括一个ListView
  Widget makeBody() {
    // log("makeBody: items = $_items");
    if (_items == null || _items.isEmpty) {
      return Text("No alarm clock yet.");
    }
    return ListView.builder(
      padding: EdgeInsets.all(8),
      itemBuilder: (context, index) {
        return index >= _items.length ? null : buildListItem(_items[index]);
      },
    );
  }

  /// 创建ListItem部件
  /// ListItem包含时间、备注、周期、开关
  Widget buildListItem(Alarm item) {
    log("_AlarmClockMainState/ buildListItem: $item");
    return AlarmListTile(item);
  }
}

class Intent {
  final Map<String, dynamic> data = Map();

  void setData(String key, dynamic value) {
    data[key] = value;
  }
}
