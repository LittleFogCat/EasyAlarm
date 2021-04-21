import 'package:flutter/material.dart';

class Pages {
  static Future<dynamic> gotoPage(BuildContext context, Widget page) {
    return Navigator.of(context).push(MaterialPageRoute(
      builder: (context) {
        return page;
      },
    ));
  }

  static void goBack(BuildContext context, [dynamic result]) {
    Navigator.of(context).pop(result);
  }
}

bool arrEqual(List l1, List l2) {
  if (l1 == l2) return true;
  if (l1 == null || l2 == null) return false;
  if (l1.length != l2.length) return false;
  for (int i = 0; i < l1.length; i++) {
    if (l1[i] != l2[i]) return false;
  }
  return true;
}

void arrCopy(List<dynamic> to, List<dynamic> from) {
  for (int i = 0; i < from.length && i < to.length; i++) {
    to[i] = from[i];
  }
}

List<T> copyOf<T>(List<T> src) {
  return List.of(src);
}

