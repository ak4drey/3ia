import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:audioplayers/audioplayers.dart';

class TextToAudioScreen extends StatefulWidget {
  @override
  _TextToAudioScreenState createState() => _TextToAudioScreenState();
}

class _TextToAudioScreenState extends State<TextToAudioScreen> {
  final TextEditingController _controller = TextEditingController();
  bool _isLoading = false;
  String? _audioFilePath;
  final AudioPlayer _audioPlayer = AudioPlayer();

  final Color backgroundColor = Color.fromARGB(255, 241, 190, 149);
  final Color userBubbleColor = Color.fromARGB(255, 121, 67, 45);
  final Color botBubbleColor = Color.fromARGB(255, 241, 227, 214);
  final Color textUserColor = Colors.white;
  final Color textBotColor = Colors.black87;

  Future<void> _generateAudio() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _isLoading = true;
      _audioFilePath = null;
    });

    final url = Uri.parse('https://api.openai.com/v1/audio/speech');
    final apiKey = 'API';

    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiKey',
        },
        body: jsonEncode({
          "model": "tts-1",
          "input": text,
          "voice": "nova",
          "response_format": "mp3",
        }),
      );

      if (response.statusCode == 200) {
        final bytes = response.bodyBytes;

        final tempDir = await getTemporaryDirectory();
        final file = File('${tempDir.path}/output.mp3');
        await file.writeAsBytes(bytes);

        setState(() {
          _audioFilePath = file.path;
        });

        await _audioPlayer.play(DeviceFileSource(file.path));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al generar audio: ${response.statusCode}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al generar audio: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _playAudio() async {
    if (_audioFilePath != null) {
      await _audioPlayer.play(DeviceFileSource(_audioFilePath!));
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: Text('Texto a Audio'),
        backgroundColor: userBubbleColor,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _controller,
              maxLines: null,
              style: TextStyle(color: userBubbleColor),
              decoration: InputDecoration(
                labelText: 'Escribe el texto para generar audio',
                labelStyle: TextStyle(color: userBubbleColor),
                filled: true,
                fillColor: botBubbleColor,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: userBubbleColor),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: userBubbleColor, width: 2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            if (_isLoading)
              CircularProgressIndicator(color: userBubbleColor)
            else
              ElevatedButton.icon(
                icon: Icon(Icons.volume_up),
                label: Text('Generar Audio'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: userBubbleColor,
                  foregroundColor: textUserColor,
                ),
                onPressed: _generateAudio,
              ),
            const SizedBox(height: 20),
            if (_audioFilePath != null)
              ElevatedButton.icon(
                icon: Icon(Icons.play_arrow),
                label: Text('Reproducir Audio'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: userBubbleColor,
                  foregroundColor: textUserColor,
                ),
                onPressed: _playAudio,
              ),
          ],
        ),
      ),
    );
  }
}
