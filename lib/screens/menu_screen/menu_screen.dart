import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../../servises/models/level.dart';
import '../level_screen/level_screen.dart';

class MenuScreen extends StatefulWidget {
  const MenuScreen({super.key});

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> {
  late Future<List<Level>> levelsFuture;

  @override
  void initState() {
    super.initState();
    levelsFuture = fetchLevels();
  }

  Future<List<Level>> fetchLevels() async {
    final dio = Dio();
    final response = await dio.get('https://blogergramegame-backend.onrender.com/levels');

    final List data = response.data;
    return data.map((json) => Level.fromJson(json)).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: FutureBuilder<List<Level>>(
          future: levelsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return Center(child: Text('Ошибка: ${snapshot.error}'));
            } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const Center(child: Text('Нет уровней 😢'));
            }

            final level = snapshot.data![0]; // пока только первый уровень

            return Center(
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => LevelScreen(level: level),
                    ),
                  );
                },
                child: const Text('Играть', style: TextStyle(fontSize: 20)),
              ),
            );
          },
        ),
      ),
    );
  }
}
