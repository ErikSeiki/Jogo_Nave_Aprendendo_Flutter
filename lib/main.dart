import 'package:flutter/material.dart';
import 'package:flame/game.dart';
import 'package:flame/time.dart';
import 'package:flame/flame.dart';
import 'package:flame/animation.dart' as FlameAnimation;

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

class AnimationCollidableGameObject extends AnimationGameObject{
  List<AnimationCollidableGameObject> collidingObjects = [];
}

class AnimationGameObject {
  Rect position;
  FlameAnimation.Animation animation;

  void render(Canvas canvas) {
    if(animation.loaded()){
      animation.getSprite().renderRect(canvas, position);
    }
  }

  void update(double dt){
    animation.update(dt);
  }
}

class SpaceShooterGame extends Game {

  final Size screenSize;

  Random random = Random();
  static const enemy_speed = 150;
  static const shoot_speed = -400;
  AnimationGameObject player;
  Timer enemyCreator;
  Timer shootCreator;

  List<AnimationCollidableGameObject> enemies =[];
  List<AnimationCollidableGameObject> shoots = [];
  List<AnimationCollidableGameObject> explosions = [];

  SpaceShooterGame(this.screenSize){
    player = AnimationGameObject()
      ..position = Rect.fromLTWH(100, 500, 50, 75)
      ..animation = FlameAnimation.Animation.sequenced("player.png", 4, textureHeight: 48, textureWidth: 32);
    enemyCreator = Timer(1.0,repeat:true,callback:() {
      enemies.add(
          AnimationCollidableGameObject()
            ..position = Rect.fromLTWH((screenSize.width - 25) * random.nextDouble(), 0, 25, 25)
            ..animation = FlameAnimation.Animation.sequenced("enemy.png", 4, textureHeight: 16, textureWidth: 16)
      );
    });
    enemyCreator.start();

    shootCreator = Timer(0.5, repeat: true, callback: (){
      shoots.add(
          AnimationCollidableGameObject()
            ..position = Rect.fromLTWH(player.position.left + 20, player.position.top - 20, 10, 20)
            ..animation = FlameAnimation.Animation.sequenced("bullet.png", 4, textureHeight: 16, textureWidth: 8)
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

  void createAplosionAt(double x, double y){
    final animation = FlameAnimation.Animation.sequenced("explosion.png", 4, textureHeight: 32, textureWidth: 32, stepTime:0.05)
      ..loop = false;
    explosions.add(
      AnimationCollidableGameObject()
        ..position = Rect.fromLTWH(x - 25, y - 25, 50, 50)
          ..animation = animation
    );
  }

  @override
  void update(double dt) {
    enemyCreator.update(dt);
    shootCreator.update(dt);


    player.update(dt);
    enemies.forEach((enemy) {
      enemy.update(dt);
      enemy.position = enemy.position.translate(0, enemy_speed * dt);
    });
    shoots.forEach((shoot) {
      shoot.update(dt);
      shoot.position = shoot.position.translate(0, shoot_speed * dt);
    });

    shoots.forEach((shoot) {
      enemies.forEach((enemy) {
        if(shoot.position.overlaps(enemy.position)){
          createAplosionAt(shoot.position.left, shoot.position.top);
          shoot.collidingObjects.add(enemy);
          enemy.collidingObjects.add(shoot);
        }
      });
    });

    explosions.forEach((explosion) {
      explosion.update(dt);
    });

    enemies.removeWhere((enemy) {
      return enemy.position.top >= screenSize.height || enemy.collidingObjects.isNotEmpty;
    });
    shoots.removeWhere((shoot) {
      return shoot.position.bottom <= 0 || shoot.collidingObjects.isNotEmpty;
    });
    explosions.removeWhere((explosion) {
      return explosion.animation.isLastFrame;
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

    explosions.forEach((explosion) {
      explosion.render(canvas);
    });
  }
}
