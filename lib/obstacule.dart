import 'package:flutter/material.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'dart:async';
import 'dart:math';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: BallGame(),
    );
  }
}

class BallGame extends StatefulWidget {
  @override
  _BallGameState createState() => _BallGameState();
}

class _BallGameState extends State<BallGame> {
  double posX = 0.0;
  double posY = 0.0;
  double speedFactor = 5.0;
  List<Obstacle> obstacles = [];
  Timer? obstacleTimer;
  Timer? moveTimer;

  @override
  void initState() {
    super.initState();
    accelerometerEvents.listen((AccelerometerEvent event) {
      setState(() {
        posX += event.x * -1 * speedFactor;
        posY += event.y * speedFactor;
      });
    });

    // Generar obstáculos y moverlos
    startObstacleGeneration(context);
  }

  void generateObstacle(BuildContext context) {
    final random = Random();
    double randomX = random.nextDouble() * MediaQuery.of(context).size.width;

    // Selección de imagen aleatoria y tamaño
    List<String> images = ['assets/images/skibidi.png', 'assets/images/bad.jpg'];
    String selectedImage = images[random.nextInt(images.length)];
    double randomWidth = random.nextDouble() * 100 + 80;  // Ancho entre 30 y 80 píxeles
    double randomHeight = random.nextDouble() * 100 +80;  // Alto entre 30 y 80 píxeles

    obstacles.add(Obstacle(randomX, 0, selectedImage, randomWidth, randomHeight));
  }

  void moveObstacles() {
    setState(() {
      for (var obstacle in obstacles) {
        obstacle.posY += 5;

        // Comprobar si ha habido una colisión
        if (checkCollision(obstacle)) {
          showGameOverDialog();
          return;
        }
      }
      obstacles.removeWhere((obstacle) => obstacle.posY > MediaQuery.of(context).size.height);
    });
  }

  bool checkCollision(Obstacle obstacle) {
    double ballRadius = 25.0;
    double ballX = MediaQuery.of(context).size.width / 2 + posX;
    double ballY = MediaQuery.of(context).size.height / 2 + posY;

    return (obstacle.posX < ballX + ballRadius && obstacle.posX + obstacle.width > ballX &&
            obstacle.posY < ballY + ballRadius && obstacle.posY + obstacle.height > ballY);
  }

  void showGameOverDialog() {
    obstacleTimer?.cancel();
    moveTimer?.cancel();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Game Over"),
          content: Text("¡Has chocado con un obstáculo!"),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                resetGame();
              },
              child: Text("Volver a jugar"),
            ),
          ],
        );
      },
    );
  }

  void resetGame() {
    setState(() {
      posX = 0.0;
      posY = 0.0;
      obstacles.clear();
      startObstacleGeneration(context);
    });
  }

  void startObstacleGeneration(BuildContext context) {
    obstacleTimer?.cancel();
    moveTimer?.cancel();

    obstacleTimer = Timer.periodic(Duration(seconds: 2), (Timer timer) {
      generateObstacle(context);
    });

    moveTimer = Timer.periodic(Duration(milliseconds: 15), (timer) => moveObstacles());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Juego de Equilibrio con Obstáculos')),
      body: Stack(
        children: [
          Positioned(
            left: MediaQuery.of(context).size.width / 2 + posX,
            top: MediaQuery.of(context).size.height / 2 + posY,
            child: Ball(),
          ),
          ...obstacles.map((obstacle) {
            return Positioned(
              left: obstacle.posX,
              top: obstacle.posY,
              child: ObstacleWidget(obstacle),
            );
          }).toList(),
        ],
      ),
    );
  }
}

class Ball extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/images/grandma.png',
      width: 50,
      height: 50,
      fit: BoxFit.contain,
    );
  }
}

class Obstacle {
  double posX;
  double posY;
  String imagePath;
  double width;
  double height;

  Obstacle(this.posX, this.posY, this.imagePath, this.width, this.height);
}

class ObstacleWidget extends StatelessWidget {
  final Obstacle obstacle;

  ObstacleWidget(this.obstacle);

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      obstacle.imagePath,
      width: obstacle.width,
      height: obstacle.height,
      fit: BoxFit.contain,
    );
  }
}
