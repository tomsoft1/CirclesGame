// ignore_for_file: avoid_print

import 'dart:math';
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flutter/material.dart';
import 'package:flame/game.dart';

import 'package:flame/input.dart';
import 'package:google_fonts/google_fonts.dart';

double toDeg(double angle) {
  return angle * 360 / (2 * pi);
}

class Player extends PositionComponent {
  static final _paint = Paint()
    ..color = Colors.blueGrey
    ..strokeWidth = 2.0;

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    canvas.drawCircle(Offset.zero, width, _paint);
    //  canvas.drawRect(size.toRect(), _paint);
  }

  void move(Vector2 delta) {
    position.add(delta);
  }
}

class Power extends PositionComponent {
  static final _paint = Paint()
    ..color = const Color.fromARGB(255, 98, 240, 223)
    ..strokeWidth = 2.0;
  @override
  void render(Canvas canvas) {
    super.render(canvas);
    canvas.drawRect(size.toRect(), _paint);
  }
}

class Arrow extends PositionComponent {
  static final _paint = Paint()
    ..color = const Color.fromARGB(255, 240, 107, 98)
    ..strokeWidth = 2.0;
  static final _paintInner = Paint()..color = Color.fromARGB(255, 238, 255, 0);
  double power = 0;
  @override
  void render(Canvas canvas) {
    super.render(canvas);
    Path path = Path();
    path.moveTo(0, width * 1.2);
    path.lineTo(-width, width * 1.1);
    path.lineTo(0, height);
    path.lineTo(width, width * 1.2);
    path.close();
    Path circle = Path();
    circle.addOval(Rect.fromCircle(
        center: Offset.zero, radius: width + power * (height - width) / 100));
    var resulting = Path.combine(PathOperation.intersect, path, circle);
    canvas.drawPath(path, _paint); //  canvas.drawRect(size.toRect(), _paint);
    canvas.drawPath(
        resulting, _paintInner); //  canvas.drawRect(size.toRect(), _paint);
  }

  void move(Vector2 delta) {
    position.add(delta);
  }
}

class PowerEffect extends Effect with EffectTarget<Arrow> {
  PowerEffect(super.controller);

  @override
  void apply(double progress) {
    target.power = progress * 100;
  }
}

class Platform extends PositionComponent {
  static final _paint = Paint()..color = Colors.red;
  static final _paintInner = Paint()..color = Colors.orange;
  static final _paintTarget = Paint()..color = Color.fromARGB(255, 255, 251, 0);

  late int platformNumber;
  Platform(int number) {
    platformNumber = number;
    anchor = Anchor.bottomRight;
    width = 50;
    height = 50;
    final displayNum = TextComponent(
        textRenderer: TextPaint(
            style: GoogleFonts.lato(
          fontSize: 35,
          color: const Color.fromARGB(255, 105, 103, 104),
        )),
        text: "$platformNumber");
    add(displayNum);
  }
  @override
  void render(Canvas canvas) {
    super.render(canvas);
    var smallSize = 0.9 * width;
    var targetSize = 0.4 * width;

    canvas.drawCircle(Offset.zero, width, _paint);
    canvas.drawCircle(Offset.zero, smallSize, _paintInner);
    canvas.drawCircle(Offset.zero, targetSize, _paintTarget);
  }
}

const nbPlatforms = 10;

class CirclesGame extends FlameGame with TapDetector {
  late Player player;
  late Arrow arrow;
  late Arrow refArrow;
  late Power power;
  late PowerEffect powerEffect;
  late TextComponent scoreCounter;
  int score = 0;
  int targetPlatform = 1;

  List<Platform> platforms = [];
  var range = pi / 3;
  late SequenceEffect allEffect;
  final sizeEffect = SequenceEffect([
    SizeEffect.by(Vector2(0.0, 300.0), EffectController(duration: 0.5)),
    SizeEffect.by(Vector2(0.0, -300.0), EffectController(duration: 0.5))
  ], infinite: true);

  @override
  Color backgroundColor() => Colors.white;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    allEffect = SequenceEffect([
      RotateEffect.by(-range / 2, EffectController(duration: 1)),
      RotateEffect.by(range, EffectController(duration: 2)),
      RotateEffect.by(-range / 2, EffectController(duration: 1))
    ], infinite: true);
    powerEffect = PowerEffect(
        RepeatedEffectController(ZigzagEffectController(period: 4), 10));
    player = Player()
      ..position = size / 2
      ..width = 20
      ..height = 20
      ..anchor = Anchor.topLeft;

    arrow = Arrow()
      ..width = player.size.toSize().width
      ..height = player.size.toSize().width * 4
      ..anchor = Anchor.topLeft;
    refArrow = Arrow()
      ..width = player.size.toSize().width
      ..height = player.size.toSize().width * 4
      ..anchor = Anchor.topLeft;
    Random r = Random();
    Vector2 currentPos = Vector2(200.0, 200.0);
    for (int i = 0; i < nbPlatforms; i++) {
      var platform = Platform(i);

      platform.position = currentPos.clone();
      double dist = 200 + r.nextInt(200).toDouble();
      double angle = r.nextDouble() * pi / 2 - pi + pi / 4;
//      angle = pi;
//      dist = 100.0;
      Vector2 v = Vector2(dist, 0.0);
      v.rotate(angle);
      currentPos.add(v);
      print("Angle:$angle Dist:$dist currentPos:$currentPos");

      platform.anchor = Anchor.topLeft;
      platform.width = 60 + r.nextInt(30).toDouble();
      platform.height = platform.width;
      platforms.add(platform);
      add(platform);
    }
    final textStyle = GoogleFonts.lato(
      fontSize: 35,
      color: const Color.fromARGB(255, 105, 103, 104),
    );
    final scoreRendrer = TextPaint(
      style: textStyle.copyWith(fontSize: 25, fontWeight: FontWeight.bold),
    );
    scoreCounter = TextComponent(
        position: Vector2(100, 100),
        anchor: Anchor.center,
        textRenderer: scoreRendrer,
        text: "Score:$score Num:$targetPlatform");
    scoreCounter.positionType = PositionType.viewport;
    add(scoreCounter);

    add(player);

    player.position = platforms.first.position;
//    player.position.add(Vector2(-20.0, -40.0));
    player.add(arrow);
//    player.add(refArrow);
    camera.followComponent(player);

    setTarget(targetPlatform);
    print("After:");
    arrow.add(allEffect);
  }

  @override
  void onTapDown(TapDownInfo info) {
    print("Tap down: ${toDeg(arrow.angle)}");
    arrow.remove(allEffect);

    try {
      arrow.add(powerEffect);
    } catch (e) {}
  }

  @override
  void onTapUp(TapUpInfo info) {
    print("tap up");
    var dist = 10 + 5 * arrow.power;
    try {
      arrow.remove(powerEffect);
      arrow.power = 0;
    } catch (e) {
      print('Tring to remove, error: $e');
    }
    print('power dist:$dist');
    var dx = dist * cos(arrow.angle + pi / 2);
    var dy = dist * sin(arrow.angle + pi / 2);
    player.add(MoveEffect.by(
        Vector2(dx, dy), CurvedEffectController(0.5, Curves.easeOut),
        onComplete: () {
      var target = platforms[targetPlatform];
      var dist = target.position.distanceTo(player.position) - target.width;
      print('Distance:$dist');
      if (dist < 0) {
        print('You,ve made it....');
        targetPlatform = targetPlatform + 1;
        if (targetPlatform == nbPlatforms) {
          print("Level Ended!");
          targetPlatform = 1;
        }
        setTarget(targetPlatform);
        arrow.add(allEffect);
        scoreCounter.text = "Score:$score Num:$targetPlatform";
      } else {
        setTarget(targetPlatform);
        arrow.add(allEffect);
//        resetGame();
      }
    }));
  }

  resetGame() {
    targetPlatform = 1;
    player.position = platforms[0].position.clone();
    setTarget(targetPlatform);
  }

  @override
  void onPanUpdate(DragUpdateInfo info) {
    print("here");
    player.move(info.delta.game);
  }

  setTarget(int target) {
    powerEffect.reset();
    allEffect.controller.setToStart();
    allEffect.reset();

    var angle = computeTarget(targetPlatform);
    arrow.angle = angle;
    refArrow.angle = angle;
    arrow.power = 0;
  }

  double computeTarget(int target) {
    var dest = platforms[target].position;
    var delta = dest.clone();
    delta.sub(player.position);
    var angle = -delta.angleToSigned(Vector2(0.0, 200.0));
    var dist = dest.distanceTo(player.position);
    print(
        'Source: ${player.position} target:${platforms[target].position} delta:$delta Dist:$dist Angle:${toDeg(angle)}');
    return angle;
  }
}

void main() {
  runApp(GameWidget(game: CirclesGame()));
}
