import 'package:audioplayers/audioplayers.dart';
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

  AudioPlayer _audioPlayer = AudioPlayer();
  double posX = 0.0;
  double posY = 0.0;
  double speedFactor = 4.0;
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
    _startMusic();
  }


  // Función para detener la música
  void _stopMusic() async {
    await _audioPlayer.stop();  // Detener la reproducción
  }

  // Función para reproducir la música de fondo
  void _startMusic() async {
    await _audioPlayer.play(AssetSource('music/ski.mp3'), volume: 0.5);  // Reproducir el archivo de audio con volumen ajustado
  }

  @override
  void dispose() {
    _audioPlayer.dispose();  // Asegúrate de liberar el recurso de audio cuando el widget sea destruido
    super.dispose();
  }

  void generateObstacle(BuildContext context) {
    final random = Random();
    double randomX = random.nextDouble() * MediaQuery.of(context).size.width;

    // Selección de imagen aleatoria y tamaño
    List<String> images = ['assets/images/bad.jpg', 'assets/images/skibidi.png'];
    String selectedImage = images[random.nextInt(images.length)];
    double randomWidth = random.nextDouble() * 100 + 80;  // Ancho entre 30 y 80 píxeles
    double randomHeight = random.nextDouble() * 100 + 80;  // Alto entre 30 y 80 píxeles

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

  int obstacleSpawnInterval = 2000; // Tiempo inicial entre obstáculos en milisegundos

  void startObstacleGeneration(BuildContext context) {
    obstacleTimer?.cancel();
    moveTimer?.cancel();

    // Reiniciar la generación de obstáculos con tiempo ajustado
    obstacleTimer = Timer.periodic(Duration(milliseconds: obstacleSpawnInterval), (Timer timer) {
      generateObstacle(context);

      // Aumentar la velocidad de aparición cada 10 segundos
      if (obstacleSpawnInterval > 500) {  // Limitar a 500ms como mínimo
        obstacleSpawnInterval -= 100;  // Disminuye el intervalo 100ms cada ciclo
      }
    });

    moveTimer = Timer.periodic(Duration(milliseconds: 50), (timer) => moveObstacles());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Juego de Equilibrio con Obstáculos')),
      body: Stack(
        children: [
          // Imagen de fondo
          Positioned.fill(
            child: Image.asset(
              'assets/images/atars.jpg',
              fit: BoxFit.cover,  // Ajusta la imagen para que cubra toda la pantalla
            ),
          ),
          // Aquí van los elementos del juego, como la pelota y los obstáculos
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
    return ClipRRect(
      borderRadius: BorderRadius.circular(30.0),
      child: Image.asset(
        'assets/images/grandma.png',
        width: 60,  // Ajusta el tamaño según tus necesidades
        height: 60,
        fit: BoxFit.contain,  // Asegura que la imagen mantenga su proporción
      ),
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
