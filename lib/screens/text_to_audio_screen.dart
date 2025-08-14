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

  Future<void> _generateAudio() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _isLoading = true;
      _audioFilePath = null;  //
    });

    final url = Uri.parse('https://api.openai.com/v1/audio/speech');
    final apiKey = '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'; 

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
      appBar: AppBar(title: Text('Texto a Audio')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _controller,
              decoration: InputDecoration(
                labelText: 'Escribe el texto para generar audio',
                border: OutlineInputBorder(),
              ),
              maxLines: null,
            ),
            const SizedBox(height: 20),
            if (_isLoading)
              CircularProgressIndicator()
            else
              ElevatedButton.icon(
                icon: Icon(Icons.volume_up),
                label: Text('Generar Audio'),
                onPressed: _generateAudio,
              ),
            const SizedBox(height: 20),
            if (_audioFilePath != null)
              ElevatedButton.icon(
                icon: Icon(Icons.play_arrow),
                label: Text('Reproducir Audio'),
                onPressed: _playAudio,
              ),
          ],
        ),
      ),
    );
  }
}
