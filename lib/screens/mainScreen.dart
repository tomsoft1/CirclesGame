// ignore_for_file: file_names

import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:test_flame/screens/CircleGameScreen.dart';

class MainScreen extends StatelessWidget {
  const MainScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text('Circle CI Games'),
        ),
        body: Center(
            child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
              const Text("Circle CI Game"),
              Container(
                height: 10,
              ),
              const Text("Simple flutter test game"),
              const Text("@Tomsoft 2022"),
              ElevatedButton(
                  onPressed: () {
                    print("pressed");
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) =>
                              GameWidget(game: CirclesGame())),
                    );
                  },
                  child: const Text("Start"))
            ])));
  }
}
