import 'package:flutter/material.dart';

class NavController {
  static final ValueNotifier<int> selectedIndex = ValueNotifier<int>(0);

  static void setIndex(int index) {
    selectedIndex.value = index;
  }
}
