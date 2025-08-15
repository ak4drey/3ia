import 'package:flutter/material.dart';
import 'screens/chat_screen.dart';
import 'screens/image_generator_screen.dart';
import 'screens/text_to_audio_screen.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  final Color backgroundColor = Color.fromARGB(255, 241, 190, 149);
  final Color userBubbleColor = Color.fromARGB(255, 121, 67, 45);
  final Color botBubbleColor = Color.fromARGB(255, 241, 227, 214);
  final Color textUserColor = Colors.white;
  final Color textBotColor = Colors.black87;
  final Color inputFillColor = Color.fromARGB(255, 121, 67, 45);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '1437',
      theme: ThemeData(
        primarySwatch: Colors.teal,
        scaffoldBackgroundColor: backgroundColor, 
      ),
      home: MainNavigation(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class MainNavigation extends StatefulWidget {
  @override
  _MainNavigationState createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    ChatScreen(),
    ImageGeneratorScreen(),
    TextToAudioScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: Container(
        margin: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: botBubbleColor,
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              spreadRadius: 2,
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(30),
          child: BottomNavigationBar(
            currentIndex: _currentIndex,
            backgroundColor: botBubbleColor,
            selectedItemColor: userBubbleColor,
            unselectedItemColor: Colors.grey,
            showSelectedLabels: false,
            showUnselectedLabels: false,
            onTap: (index) {
              setState(() => _currentIndex = index);
            },
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.chat_bubble_rounded, size: 30),
                label: 'Chat',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.image_rounded, size: 30),
                label: 'Imagen',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.volume_up_rounded, size: 30),
                label: 'TTS',
              ),
            ],
            type: BottomNavigationBarType.fixed,
            elevation: 0,
          ),
        ),
      ),
    );
  }

  final Color userBubbleColor = Color.fromARGB(255, 121, 67, 45);
  final Color botBubbleColor = Color.fromARGB(255, 241, 227, 214);
}
