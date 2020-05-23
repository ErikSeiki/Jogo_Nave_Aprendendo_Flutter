import 'package:flutter/material.dart';
import 'package:flame/game.dart';
import 'package:flame/time.dart';
import 'package:flame/flame.dart';
import 'dart:math';

void main() async {
  Size size = await Flame.util.initialDimensions();
  runApp(GameWidget(size));
}

class GameWidget extends StatelessWidget {
  final Size size;

  GameWidget(this.size);

  @override
  Widget build(BuildContext context){
    final game = SpaceShooterGame(size);
    return GestureDetector(
      onPanUpdate: (DragUpdateDetails details) {
        game.onPlayerMove(details.delta);
      },
      child: Container(
          color: Color(0xFF0000000),
          child: game.widget
      ),
    );
  }
}


Paint _white = Paint()..color = Color(0xFFFFFFFF);

class GameObject {
  Rect position;

  void render(Canvas canvas) {
    canvas.drawRect(position, _white);
  }
}

class SpaceShooterGame extends Game {

  final Size screenSize;

  Random random = Random();
  static const enemy_speed = 400;
  GameObject player;
  Timer enemyCreator;

  List<GameObject> enemies =[];

  SpaceShooterGame(this.screenSize){
    player = GameObject()
      ..position = Rect.fromLTWH(100, 100, 50, 50);
    enemyCreator = Timer(1.0,repeat:true,callback:() {
      enemies.add(
          GameObject()
            ..position = Rect.fromLTWH((screenSize.width - 50) * random.nextDouble(), 0, 50, 50)
      );
    });
    enemyCreator.start();
  }

  void onPlayerMove(Offset delta) {
    player.position = player.position.translate(delta.dx,delta.dy);
  }

  @override
  void update(double dt) {
    enemyCreator.update(dt);

    enemies.forEach((enemy) {
      enemy.position = enemy.position.translate(0, enemy_speed * dt);
    });
  }

  @override
  void render(Canvas canvas) {
    player.render(canvas);

    enemies.forEach((enemy) {
      enemy.render(canvas);
    });
  }
}
