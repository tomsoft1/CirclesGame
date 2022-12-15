import 'package:flutter/material.dart';
import 'package:test_flame/screens/mainScreen.dart';

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(home: MainScreen());
  }
}

void main() {
//  runApp(GameWidget(game: CirclesGame()));
  runApp(MyApp());
}
