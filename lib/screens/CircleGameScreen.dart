// ignore_for_file: avoid_print

import 'dart:math';

import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flutter/material.dart';
import 'package:flame/game.dart';

import 'package:flame/input.dart';
import 'package:google_fonts/google_fonts.dart';

class Player extends PositionComponent {
  static final _paint = Paint()
    ..color = Colors.blueGrey
    ..strokeWidth = 2.0;
  static final _clear = Paint()
    ..color = const Color.fromARGB(212, 146, 76, 76)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2.0;
  @override
  void render(Canvas canvas) {
    super.render(canvas);
    Path path = Path();
    path.addOval(Rect.fromCircle(center: Offset.zero, radius: width));
    Path pathRemove = Path();

    for (int i = 0; i < 12; i++) {
      Vector2 dir = Vector2(width, 0);
      dir.rotate(i.toDouble() * 2 * pi / 12);
      path.addOval(
          Rect.fromCircle(center: Offset(dir.x, dir.y), radius: width / 5));
    }
    pathRemove.addOval(Rect.fromCircle(center: Offset.zero, radius: width / 2));
    Path result = Path.combine(PathOperation.difference, path, pathRemove);
    canvas.drawPath(result, _paint);
    canvas.drawPath(result, _clear);
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

class Arrow extends PositionComponent with HasPaint {
  Arrow() {
    paint.color = const Color.fromARGB(255, 26, 15, 14);
    paint.strokeWidth = 2.0;
    anchor = Anchor.topLeft;
  }

  static final _paintInner = Paint()
    ..color = const Color.fromARGB(255, 255, 136, 0);
  double power = 0;
  @override
  void render(Canvas canvas) {
    super.render(canvas);
    Path path = Path();
    double arrowWidth = width / 2;
    path.moveTo(0, width * 1.4);
    path.lineTo(-arrowWidth, width * 1.1);
    path.lineTo(0, height);
    path.lineTo(arrowWidth, width * 1.2);
    path.close();
    Path circle = Path();
    circle.addOval(Rect.fromCircle(
        center: Offset.zero, radius: width + power * (height - width) / 100));
    var resulting = Path.combine(PathOperation.intersect, path, circle);
    canvas.drawPath(path, paint); //  canvas.drawRect(size.toRect(), _paint);
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
    target.power = progress.abs() * 100;
  }
}

class Platform extends PositionComponent {
  static final _paint = Paint()..color = Colors.red;
  static final _paintInner = Paint()
    ..color = const Color.fromARGB(255, 239, 236, 240);
  static final _paintTarget = Paint()
    ..color = const Color.fromARGB(255, 255, 174, 0);
  late int platformNumber;
  bool passed = false;
  double smallSize = 0.0;
  Platform(int number) {
    platformNumber = number;
    anchor = Anchor.bottomRight;
    size = Vector2(50, 50);
    final displayNum = TextComponent(
        position: Vector2(100, -15),
        textRenderer: TextPaint(
            style: GoogleFonts.lato(
          fontSize: 35,
          color: const Color.fromARGB(100, 105, 103, 104),
        )),
        text: "$platformNumber");
    add(displayNum);
  }
  @override
  void render(Canvas canvas) {
    super.render(canvas);
    smallSize = 0.8 * width;
    var targetSize = 0.4 * width;
    canvas.drawCircle(Offset.zero, width * 1.02, Paint()..color = Colors.white);
    canvas.drawCircle(Offset.zero, width, _paint);
    canvas.drawArc(Rect.fromCircle(center: Offset.zero, radius: width), 0,
        angle, true, _paintTarget);
    canvas.drawCircle(Offset.zero, smallSize, _paintInner);
    if (platformNumber != 0) {
      canvas.drawCircle(Offset.zero, targetSize, _paint);
      canvas.drawCircle(Offset.zero, targetSize * 0.9, _paintTarget);
    }
  }
}

class AngleEffect extends Effect with EffectTarget<Platform> {
  AngleEffect(super.controller);
  @override
  void apply(double progress) {
    target.angle = progress.abs() * 2 * pi;
  }
}

class CirclesGame extends FlameGame with TapDetector {
  late Player player;
  late Arrow arrow;
  late Power power;
  late PowerEffect powerEffect;
  late TextComponent scoreCounter;
  int score = 0;
  static final textPaint = TextPaint(
      style: GoogleFonts.lato(
          fontSize: 35, color: const Color.fromARGB(255, 105, 103, 104)));

  int nbPlatforms = 10;
  int targetPlatform = 1;
  Random r = Random();

  List<Platform> platforms = [];
  var range = pi / 3;
  late SequenceEffect allEffect;
  final sizeEffect = SequenceEffect([
    SizeEffect.by(Vector2(0.0, 300.0), EffectController(duration: 0.5)),
    SizeEffect.by(Vector2(0.0, -300.0), EffectController(duration: 0.5))
  ], infinite: true);

  @override
  Color backgroundColor() => const Color.fromARGB(255, 230, 241, 233);

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
      ..size = Vector2(20, 20)
      ..anchor = Anchor.topLeft;

    arrow = Arrow()
      ..width = player.size.toSize().width
      ..height = player.size.toSize().width * 6;

    initLevel(10);
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

//    player.position.add(Vector2(-20.0, -40.0));
    player.add(arrow);
    camera.followComponent(player, relativeOffset: const Anchor(0.5, 0.8));

    setTarget(targetPlatform);
    print("After:");
  }

  @override
  void onTapDown(TapDownInfo info) {
    print("Tap down: ${degrees(arrow.angle)}");
    if (allEffect.parent != null) arrow.remove(allEffect);
    if (powerEffect.parent == null) arrow.add(powerEffect);
  }

  @override
  void onTapUp(TapUpInfo info) {
    print("tap up");

    // Compute the destination of the player based on the power of the arrrow
    var dist = 10 + 7 * arrow.power;
    //Remove the arrow power
    if (powerEffect.parent != null) arrow.remove(powerEffect);
    arrow.power = 0;
    arrow.add(OpacityEffect.to(0.0, EffectController(duration: 0.5)));
    // Compute the desitnation of the player
    print('power dist:$dist');
    var dx = dist * cos(arrow.angle + pi / 2);
    var dy = dist * sin(arrow.angle + pi / 2);
    player.add(MoveEffect.by(
        Vector2(dx, dy), CurvedEffectController(0.5, Curves.easeOut),
        onComplete: () {
      var target = platforms[targetPlatform];
      var dist = target.position.distanceTo(player.position);
      print('Distance:$dist');
      if (dist < target.smallSize) {
        print("small size hit");
      }
      if (dist < target.width) {
        platforms[targetPlatform]
            .add(AngleEffect(EffectController(duration: 2)));
        print('You,ve made it....');
        targetPlatform = targetPlatform + 1;
        score += 1;
        if (targetPlatform == nbPlatforms) {
          print("Level Ended!");
          nextLevel();
        }
        setTarget(targetPlatform);
        if (allEffect.parent == null) arrow.add(allEffect);
        TextComponent textWellDone =
            TextComponent(text: "Well done", textRenderer: textPaint);
        textWellDone.add(RemoveEffect(delay: 1.0));
/*        textWellDone.add(SequenceEffect([
          SizeEffect.to(Vector2(1.1, 1.1), EffectController(duration: 0.5)),
          RemoveEffect()
        ]));*/
        player.add(textWellDone);
        scoreCounter.text = "Score:$score Num:$targetPlatform";
        arrow.add(OpacityEffect.to(1.0, EffectController(duration: 0.5)));
      } else {
        player.add(ScaleEffect.to(
            Vector2.zero(),
            EffectController(
              duration: 1.0,
            ), onComplete: () {
          resetGame();
        }));
      }
    }));
  }

  initLevel(int maxPlatforms) {
    nbPlatforms = maxPlatforms;

    Vector2 currentPos = Vector2(200.0, 200.0);
    for (int i = 0; i < nbPlatforms; i++) {
      var platform = Platform(i);
      platform.position = currentPos.clone();
      double dist = 200 + r.nextInt(200).toDouble();
      double angle = r.nextDouble() * pi / 2 - pi + pi / 4;

      Vector2 v = Vector2(dist, 0.0);
      v.rotate(angle);
      currentPos.add(v);

      platform.anchor = Anchor.topLeft;
      platform.width = 60 + r.nextInt(30).toDouble();
      platform.height = platform.width;
      platforms.add(platform);
      add(platform);
    }
    platforms.first.passed = false;
    player.position = platforms.first.position;
    if (allEffect.parent == null) arrow.add(allEffect);
  }

  resetGame() {
    score = -10;
    for (int i = 0; i < nbPlatforms; i++) {
      platforms[i].passed = false;
      platforms[i].angle = 0;
    }
    nextLevel();
  }

  nextLevel() {
    score += 10;
    targetPlatform = 1;
    player.scale = Vector2(1.0, 1.0);
    player.position = platforms[0].position.clone();
    arrow.setAlpha(255);
    setTarget(targetPlatform);
    if (allEffect.parent == null) arrow.add(allEffect);
  }

  setTarget(int target) {
    powerEffect.reset();
    allEffect.controller.setToStart();
    allEffect.reset();

    var angle = computeTarget(targetPlatform);
    arrow.angle = angle;
    arrow.power = 0;
  }

  // Compute the angle between the current position of the player and the next target
  double computeTarget(int target) {
    var dest = platforms[target].position;
    var delta = dest.clone();
    delta.sub(player.position);
    var angle = -delta.angleToSigned(Vector2(0.0, 200.0));
    var dist = dest.distanceTo(player.position);
    print(
        'Source: ${player.position} target:${platforms[target].position} delta:$delta Dist:$dist Angle:${degrees(angle)}');
    return angle;
  }
}
