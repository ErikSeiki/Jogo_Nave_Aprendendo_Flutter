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
      onPanStart: (_){
        game.beginFire();
      },
      onPanEnd: (_){
        game.stopFire();
      },
      onPanCancel: (){
        game.stopFire();
      },
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

class CollidableGameObject extends GameObject {
  List<GameObject> collidingObjects = [];

}


class SpaceShooterGame extends Game {

  final Size screenSize;

  Random random = Random();
  static const enemy_speed = 150;
  static const shoot_speed = -400;
  GameObject player;
  Timer enemyCreator;
  Timer shootCreator;

  List<CollidableGameObject> enemies =[];
  List<CollidableGameObject> shoots = [];

  SpaceShooterGame(this.screenSize){
    player = GameObject()
      ..position = Rect.fromLTWH(100, 100, 50, 50);
    enemyCreator = Timer(1.0,repeat:true,callback:() {
      enemies.add(
          CollidableGameObject()
            ..position = Rect.fromLTWH((screenSize.width - 50) * random.nextDouble(), 0, 50, 50)
      );
    });
    enemyCreator.start();

    shootCreator = Timer(0.5, repeat: true, callback: (){
      shoots.add(
          CollidableGameObject()
            ..position = Rect.fromLTWH(player.position.left + 20, player.position.top - 20, 20, 20)
      );

    });
  }

  void onPlayerMove(Offset delta) {
    player.position = player.position.translate(delta.dx,delta.dy);
  }

  void beginFire(){
    shootCreator.start();
  }

  void stopFire(){
    shootCreator.stop();
  }

  @override
  void update(double dt) {
    enemyCreator.update(dt);
    shootCreator.update(dt);
    
    enemies.forEach((enemy) {
      enemy.position = enemy.position.translate(0, enemy_speed * dt);
    });
    shoots.forEach((shoot) {
      shoot.position = shoot.position.translate(0, shoot_speed * dt);
    });

    shoots.forEach((shoot) {
      enemies.forEach((enemy) {
        if(shoot.position.overlaps(enemy.position)){
          shoot.collidingObjects.add(enemy);
          enemy.collidingObjects.add(shoot);
        }
      });
    });

    enemies.removeWhere((enemy) {
      return enemy.position.top >= screenSize.height || enemy.collidingObjects.isNotEmpty;
    });
    shoots.removeWhere((shoot) {
      return shoot.position.bottom <= 0 || shoot.collidingObjects.isNotEmpty;
    });
  }

  @override
  void render(Canvas canvas) {
    player.render(canvas);

    enemies.forEach((enemy) {
      enemy.render(canvas);
    });
    shoots.forEach((shoot) {
      shoot.render(canvas);
    });
  }
}
