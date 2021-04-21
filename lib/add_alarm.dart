import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/painting.dart';
import 'package:easy_alarm/db.dart';
import 'package:easy_alarm/global.dart';
import 'alarm.dart';

const String ADD_ALARM = "添加闹钟";

Alarm _alarm;

/// 添加闹钟界面
class AddAlarmPage extends StatefulWidget {
  AddAlarmPage(Alarm alarm) {
    _alarm = alarm != null ? alarm : Alarm(TimeOfDay.now());
  }

  @override
  _AddAlarmPageState createState() => _AddAlarmPageState();
}

class _AddAlarmPageState extends State<AddAlarmPage> {
  var _timePickerTimeInMinute = 0;

  @override
  Widget build(BuildContext context) {
    print('_AddAlarmPageState: now: ${DateTime.now()}');
    _timePickerTimeInMinute = Alarm.timeOfDayToMinute(_alarm.timeOfDay);
    return Scaffold(
      appBar: CommonAppBar(
        title: ADD_ALARM,
        context: context,
        onConfirm: () => _onConfirm(),
      ),
      body: Column(
        children: [
          CupertinoTimerPicker(
            mode: CupertinoTimerPickerMode.hm,
            initialTimerDuration: Duration(
              hours: _alarm.timeOfDay.hour,
              minutes: _alarm.timeOfDay.minute,
            ),
            onTimerDurationChanged: (Duration duration) {
              _timePickerTimeInMinute = duration.inMinutes;
            },
          ),
          AddAlarmSettingList(),
        ],
      ),
    );
  }

  void _onConfirm() {
    _alarm.setTimeInMinute(_timePickerTimeInMinute);

    AlarmStore db = AlarmStore();
    db.update(_alarm);
    Pages.goBack(context, _alarm);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('Done.'),
      duration: Duration(seconds: 2),
    ));
  }
}

/// 普通的ActionBar
class CommonAppBar extends AppBar {
  CommonAppBar({
    BuildContext context,
    String title,
    Function() onConfirm,
  }) : super(
          title: Text(title),
          centerTitle: true,
          leading: IconButton(
            icon: Icon(Icons.close),
            onPressed: () {
              Pages.goBack(context);
            },
          ),
          actions: [
            IconButton(
              icon: Icon(Icons.done),
              padding: EdgeInsets.fromLTRB(0, 0, 16, 0),
              onPressed: onConfirm,
            ),
          ],
        );
}

//
class AddAlarmSettingList extends StatefulWidget {
  @override
  _AddAlarmSettingListState createState() => _AddAlarmSettingListState();
}

class _AddAlarmSettingListState extends State<AddAlarmSettingList> {
  final _settingTitleStyle = TextStyle(fontSize: 15, fontWeight: FontWeight.bold);
  final _settingDescStyle = TextStyle(fontSize: 12, color: Colors.black54);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SettingTile(
          title: Text('重复', style: _settingTitleStyle),
          trailing: [
            Text(RepeatOption.fitName(_alarm.repeat), style: _settingDescStyle),
            Icon(Icons.chevron_right_rounded),
          ],
          onTap: () {
            showSelectRepeatSheet(context).then((value) {
              print('showSelectRepeatSheet value: $value');
              if (value == null) return;
              setState(() {
                _alarm.repeat = List.of(value);
              });
            });
          },
        ),
        SettingTile(
          title: Text('响铃时振动', style: _settingTitleStyle),
          trailing: [
            Switch(
              value: _alarm.vibrate,
              onChanged: (b) => setState(() {
                _alarm.vibrate = b;
              }),
            )
          ],
          onTap: () {
            setState(() {
              _alarm.vibrate = !_alarm.vibrate;
            });
          },
        ),
        if (_alarm.isOnce())
          SettingTile(
            title: Text('响铃后删除此闹钟', style: _settingTitleStyle),
            trailing: [
              Switch(
                  value: _alarm.autoDelete,
                  onChanged: (value) {
                    setState(() {
                      _alarm.autoDelete = value;
                    });
                  }),
            ],
            onTap: () {
              setState(() {
                _alarm.autoDelete = !_alarm.autoDelete;
              });
            },
          ),
        SettingTile(
          title: Text('备注', style: _settingTitleStyle),
          trailing: [
            Text(_alarm.desc, style: _settingDescStyle),
            Icon(Icons.chevron_right_rounded),
          ],
          onTap: () {
            Pages.gotoPage(context, TextInputPage()).then((text) {
              if (text == null) return;
              setState(() {
                _alarm.desc = text;
              });
            });
          },
        ),
      ],
    );
  }

  /// 点击选择闹钟重复周期 1 预配置
  Future<dynamic> showSelectRepeatSheet(BuildContext context) {
    return showModalBottomSheet<List<bool>>(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      builder: (context) {
        return RepeatSheet();
      },
    );
  }
}

/// 选择重复周期：1 默认配置
class RepeatSheet extends StatefulWidget {
  @override
  _RepeatSheetState createState() => _RepeatSheetState();
}

class _RepeatSheetState extends State<RepeatSheet> {
  @override
  Widget build(BuildContext context) {
    List<RepeatOption> repeatOptions = [
      RepeatOption.ONCE,
      RepeatOption.EVERY_DAY,
      RepeatOption.WEEK_DAY,
      RepeatOption.WEEKEND,
      RepeatOption.CUSTOM
    ];
    RepeatOption selected = arrEqual(_alarm.repeat, RepeatOption.ONCE.repeat)
        ? RepeatOption.ONCE
        : arrEqual(_alarm.repeat, RepeatOption.EVERY_DAY.repeat)
            ? RepeatOption.EVERY_DAY
            : arrEqual(_alarm.repeat, RepeatOption.WEEK_DAY.repeat)
                ? RepeatOption.WEEK_DAY
                : arrEqual(_alarm.repeat, RepeatOption.WEEKEND.repeat)
                    ? RepeatOption.WEEKEND
                    : RepeatOption.CUSTOM;
    List<SettingTile> settingTiles = repeatOptions.map((RepeatOption e) {
      return SettingTile(
        title: Text(
          e.name,
          style: TextStyle(
            color: selected == e ? Colors.blue : null,
          ),
        ),
        trailing: selected == e ? [Icon(Icons.done, color: Colors.blue)] : [],
        background: selected == e ? Colors.lightBlue[50] : null,
        margin: EdgeInsets.zero,
        onTap: () {
          if (e == RepeatOption.CUSTOM) {
            showCustomRepeatSheet(context).then((value) {
              setState(() {
                if (value == null) return;
                _alarm.repeat = List<bool>.of(value);
                Pages.goBack(context, value);
              });
            });
          } else {
            Pages.goBack(context, e.repeat);
          }
        },
      );
    }).toList();

    return Container(
      padding: EdgeInsets.only(top: 20, bottom: 20),
      child: Wrap(
        children: settingTiles,
      ),
    );
  }

  /// 点击选择自定义闹钟重复周期 2 自定义
  Future<dynamic> showCustomRepeatSheet(BuildContext context) {
    return showModalBottomSheet<List<bool>>(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      builder: (context) {
        return CustomRepeatSheet();
      },
    );
  }
}

/// 选择重复周期：2 自定义
class CustomRepeatSheet extends StatefulWidget {
  @override
  _CustomRepeatSheetState createState() => _CustomRepeatSheetState();
}

class _CustomRepeatSheetState extends State<CustomRepeatSheet> {
  List<bool> _checkedCache;

  @override
  void initState() {
    super.initState();
    _checkedCache = copyOf(_alarm.repeat);
  }

  @override
  Widget build(BuildContext context) {
    final week = ['星期一', '星期二', '星期三', '星期四', '星期五', '星期六', '星期日'];
    List<SettingTile> tiles = [0, 1, 2, 3, 4, 5, 6].map((i) {
      return SettingTile(
        title: Text(week[i]),
        trailing: [
          Checkbox(
            value: _checkedCache[i],
            onChanged: (checked) {
              setState(() {
                _checkedCache[i] = checked;
                print('_CustomRepeatSheetState: checked = $_checkedCache');
              });
            },
          )
        ],
      );
    }).toList();
    tiles.add(SettingTile(
      padding: EdgeInsets.only(left: 10, right: 10, bottom: 10),
      title: Center(
        child: Row(
          children: [
            TextButton(
              onPressed: () {
                print('click 取消');
                Pages.goBack(context, null);
              },
              child: Container(
                child: Text('取消', style: TextStyle(fontSize: 17, color: Colors.black54, fontWeight: FontWeight.bold)),
                padding: EdgeInsets.symmetric(vertical: 4, horizontal: 50),
              ),
              style: ButtonStyle(backgroundColor: MaterialStateProperty.all(Colors.grey[200])),
            ),
            Container(
              width: 26,
            ),
            TextButton(
              onPressed: () {
                print('click 确定');
                Pages.goBack(context, _checkedCache);
              },
              child: Container(
                child: Text('确定', style: TextStyle(fontSize: 17, color: Colors.white, fontWeight: FontWeight.bold)),
                padding: EdgeInsets.symmetric(vertical: 4, horizontal: 50),
              ),
              style: ButtonStyle(backgroundColor: MaterialStateProperty.all(Colors.lightBlue)),
            ),
          ],
        ),
      ),
    ));
    return Container(
      padding: EdgeInsets.only(top: 20),
      child: Wrap(
        // direction: Axis.vertical,
        // padding: EdgeInsets.only(top: 20),
        children: tiles,
      ),
    );
  }
}

/// 输入文字的页面
class TextInputPage extends StatefulWidget {
  TextInputPage();

  @override
  _TextInputPageState createState() => _TextInputPageState();
}

class _TextInputPageState extends State<TextInputPage> {
  String _input;
  FocusNode _focusNode = FocusNode();
  TextEditingController _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    _input = _alarm.desc;
    _controller.text = _input;
    _focusNode.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonAppBar(
        context: context,
        title: '编辑闹钟备注',
        onConfirm: () {
          print('_TextInputPageState: input = $_input');
          Pages.goBack(context, _input);
        },
      ),
      body: Column(
        children: [
          Container(
            padding: EdgeInsets.symmetric(vertical: 10, horizontal: 28),
            child: TextField(
              controller: _controller,
              onChanged: (s) {
                _input = s;
              },
              focusNode: _focusNode,
            ),
          )
        ],
      ),
    );
  }
}

/// 设置列表的一行元素
class SettingTile extends StatelessWidget {
  final _stuff = Expanded(child: Text(''));
  final Widget title;
  final List<Widget> trailing;
  final Function() onTap;
  final Color background;
  final margin;
  final padding;

  SettingTile({
    this.title = const Text(''),
    this.trailing = const [],
    this.onTap,
    this.background,
    this.margin = const EdgeInsets.all(0),
    this.padding = const EdgeInsets.only(left: 12, right: 12),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: margin,
      child: ListTile(
        onTap: onTap,
        title: Container(
          padding: padding,
          child: Row(children: [title, _stuff]..addAll(trailing)),
        ),
      ),
      color: background,
    );
  }
}

class RepeatOption {
  static const ONCE = RepeatOption('只响一次', [false, false, false, false, false, false, false]);
  static const EVERY_DAY = RepeatOption('每天', [true, true, true, true, true, true, true]);
  static const WEEK_DAY = RepeatOption('工作日', [true, true, true, true, true, false, false]);
  static const WEEKEND = RepeatOption('周末', [false, false, false, false, false, true, true]);
  static const CUSTOM = RepeatOption("自定义", null);

  final String name;
  final List<bool> repeat;

  const RepeatOption(this.name, this.repeat);

  operator ==(Object o) {
    if (o is RepeatOption) {
      return o.name == this.name && arrEqual(o.repeat, this.repeat);
    }
    return false;
  }

  static String fitName(List<bool> repeat) {
    if (arrEqual(repeat, ONCE.repeat)) return '只响一次';
    if (arrEqual(repeat, EVERY_DAY.repeat)) return '每天';
    if (arrEqual(repeat, WEEK_DAY.repeat)) return '工作日';
    if (arrEqual(repeat, WEEKEND.repeat)) return '周末';
    return '自定义';
  }

  @override
  int get hashCode => super.hashCode;
}
