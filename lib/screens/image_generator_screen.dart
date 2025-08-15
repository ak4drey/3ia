import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; 
import 'package:http/http.dart' as http;

class ImageGeneratorScreen extends StatefulWidget {
  @override
  _ImageGeneratorScreenState createState() => _ImageGeneratorScreenState();
}

class _ImageGeneratorScreenState extends State<ImageGeneratorScreen> {
  final TextEditingController _controller = TextEditingController();
  String? _imageUrl;
  bool _isLoading = false;

  final Color backgroundColor = Color.fromARGB(255, 241, 190, 149);
  final Color userBubbleColor = Color.fromARGB(255, 121, 67, 45);
  final Color botBubbleColor = Color.fromARGB(255, 241, 227, 214);
  final Color textUserColor = Colors.white;
  final Color textBotColor = Colors.black87;
  final Color inputFillColor = Color.fromARGB(255, 121, 67, 45);

  Future<void> _generateImage() async {
    final prompt = _controller.text.trim();
    if (prompt.isEmpty) return;

    setState(() {
      _isLoading = true;
      _imageUrl = null;
    });

    final url = Uri.parse('https://api.openai.com/v1/images/generations');
    final apiKey = 'API';

    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiKey',
        },
        body: jsonEncode({
          'model': 'dall-e-3',
          'prompt': prompt,
          'n': 1,
          'size': '1024x1024',
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final imageUrlLocal = data['data'][0]['url'] as String;
        setState(() {
          _imageUrl = imageUrlLocal;
        });
      } else {
        final errorResponse = jsonDecode(response.body);
        final errorMessage = errorResponse['error']?['message'] ?? 'Error desconocido';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al generar imagen: $errorMessage')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _copyToClipboard() {
    if (_imageUrl != null) {
      Clipboard.setData(ClipboardData(text: _imageUrl!));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('URL copiada al portapapeles')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: Text('IMGen'),
        backgroundColor: userBubbleColor,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _controller,
              style: TextStyle(color: userBubbleColor),
              decoration: InputDecoration(
                labelText: 'imagina y crea',
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
            SizedBox(height: 12),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: userBubbleColor,
                foregroundColor: textUserColor,
              ),
              onPressed: _isLoading ? null : _generateImage,
              child: _isLoading
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : Text('Generar Imagen'),
            ),
            SizedBox(height: 12),
            if (_imageUrl != null) ...[
              Image.network(_imageUrl!),
              SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      _imageUrl!,
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                      style: TextStyle(color: Colors.blue),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.copy, color: userBubbleColor),
                    onPressed: _copyToClipboard,
                  )
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
