import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:speech_to_text/speech_to_text.dart' as stt;

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Asistente Integrado',
      theme: ThemeData(primarySwatch: Colors.teal),
      debugShowCheckedModeBanner: false,
      home: ChatScreen(),
    );
  }
}

class ChatScreen extends StatefulWidget {
  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatMessage {
  final String message;
  final bool isUser;
  final DateTime timestamp;
  final File? image;

  _ChatMessage({
    required this.message,
    required this.isUser,
    required this.timestamp,
    this.image,
  });
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final List<_ChatMessage> _messages = [];
  bool _isLoading = false;
  bool _objectDetection = false;

  File? _selectedImage;
  final picker = ImagePicker();

  // Speech to text
  late stt.SpeechToText _speech;
  bool _isListening = false;

  // Paleta colores
  final Color backgroundColor = Color.fromARGB(255, 241, 190, 149);
  final Color userBubbleColor = Color.fromARGB(255, 121, 67, 45);
  final Color botBubbleColor = Color.fromARGB(255, 241, 227, 214);
  final Color textUserColor = Colors.white;
  final Color textBotColor = Colors.black87;
  final Color inputFillColor = Color.fromARGB(255, 121, 67, 45);

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();

    // Mensaje inicial de bienvenida
    _messages.add(_ChatMessage(
      message: '¡Hola! ¿En qué puedo ayudarte hoy?',
      isUser: false,
      timestamp: DateTime.now(),
    ));
  }

  Future<void> _sendTextMessage(String text) async {
    if (text.trim().isEmpty) return;

    setState(() {
      _messages.add(_ChatMessage(
        message: text,
        isUser: true,
        timestamp: DateTime.now(),
      ));
      _isLoading = true;
      _controller.clear();
    });

    final response = await _askChatGPT(text);

    setState(() {
      _messages.add(_ChatMessage(
        message: response,
        isUser: false,
        timestamp: DateTime.now(),
      ));
      _isLoading = false;
    });
  }

  Future<String> _askChatGPT(String question) async {
    const apiKey = 'API'; 
    final url = Uri.parse('https://api.openai.com/v1/chat/completions');
    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $apiKey',
    };
    final body = jsonEncode({
      "model": "gpt-3.5-turbo",
      "messages": [
        {"role": "system", "content": "Eres un asistente útil."},
        {"role": "user", "content": question},
      ],
      "max_tokens": 300,
    });

    final response = await http.post(url, headers: headers, body: body);

    if (response.statusCode == 200) {
      final decoded = utf8.decode(response.bodyBytes);
      final data = jsonDecode(decoded);
      return data['choices'][0]['message']['content'].trim();
    } else {
      return 'Error: ${response.statusCode}';
    }
  }

  Future<void> _pickImage() async {
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      File imageFile = File(pickedFile.path);
      setState(() {
        _selectedImage = imageFile;
        _messages.add(_ChatMessage(
          message: '[Imagen seleccionada]',
          isUser: true,
          timestamp: DateTime.now(),
          image: imageFile,
        ));
      });

      if (_objectDetection) {
        await _sendImageToPredictionAPI(imageFile);
      } else {
        await _sendTextMessage('[Imagen enviada]');
      }
    }
  }

  Future<void> _takePhoto() async {
    final pickedFile = await picker.pickImage(source: ImageSource.camera);

    if (pickedFile != null) {
      File imageFile = File(pickedFile.path);
      setState(() {
        _selectedImage = imageFile;
        _messages.add(_ChatMessage(
          message: '[Imagen tomada]',
          isUser: true,
          timestamp: DateTime.now(),
          image: imageFile,
        ));
      });

      if (_objectDetection) {
        await _sendImageToPredictionAPI(imageFile);
      } else {
        await _sendTextMessage('[Imagen enviada]');
      }
    }
  }

  Future<void> _sendImageToPredictionAPI(File imageFile) async {
    setState(() {
      _isLoading = true;
    });

    try {
      final uri = Uri.parse('API'); // Tu URL
      final bytes = await imageFile.readAsBytes();
      final base64Image = base64Encode(bytes);

      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'image': base64Image}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final result = data['prediction'];

        setState(() {
          _messages.add(_ChatMessage(
            message: 'Predicción: $result',
            isUser: false,
            timestamp: DateTime.now(),
          ));
        });
      } else {
        setState(() {
          _messages.add(_ChatMessage(
            message: 'Error en predicción: ${response.statusCode}',
            isUser: false,
            timestamp: DateTime.now(),
          ));
        });
      }
    } catch (e) {
      setState(() {
        _messages.add(_ChatMessage(
          message: 'Error al conectar con el servidor de predicción',
          isUser: false,
          timestamp: DateTime.now(),
        ));
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _listen() async {
    if (!_isListening) {
      bool available = await _speech.initialize(
        onStatus: (val) {
          if (val == 'done' || val == 'notListening') {
            setState(() => _isListening = false);
            _sendTextMessage(_controller.text);
          }
        },
        onError: (val) {
          setState(() => _isListening = false);
        },
      );
      if (available) {
        setState(() => _isListening = true);
        _speech.listen(
          onResult: (val) {
            setState(() {
              _controller.text = val.recognizedWords;
            });
          },
        );
      }
    } else {
      setState(() => _isListening = false);
      _speech.stop();
      _sendTextMessage(_controller.text);
    }
  }

  String _formatTime(DateTime time) =>
      "${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: userBubbleColor,
        title: Text('Asistente', style: TextStyle(color: Colors.white)),
        actions: [
          Row(
            children: [
              Text('Detección objetos', style: TextStyle(color: Colors.white)),
              Switch(
                activeColor: Colors.white,
                value: _objectDetection,
                onChanged: (val) {
                  setState(() {
                    _objectDetection = val;
                  });
                },
              ),
              SizedBox(width: 12),
            ],
          )
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.all(8),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                return Align(
                  alignment:
                      msg.isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: EdgeInsets.symmetric(vertical: 6),
                    padding: EdgeInsets.all(14),
                    constraints: BoxConstraints(
                        maxWidth: MediaQuery.of(context).size.width * 0.7),
                    decoration: BoxDecoration(
                      color: msg.isUser ? userBubbleColor : botBubbleColor,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(16),
                        topRight: Radius.circular(16),
                        bottomLeft:
                            msg.isUser ? Radius.circular(16) : Radius.circular(0),
                        bottomRight:
                            msg.isUser ? Radius.circular(0) : Radius.circular(16),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color.fromARGB(255, 255, 255, 255),
                          blurRadius: 3,
                          offset: Offset(1, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (!msg.isUser) ...[
                          // Foto de perfil lado bot
                          Container(
                            margin: EdgeInsets.only(right: 8),
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border:
                                  Border.all(color: userBubbleColor, width: 2),
                              image: DecorationImage(
                                image: NetworkImage(
                                    'https://images-wixmp-ed30a86b8c4ca887773594c2.wixmp.com/f/cd15a8d7-9a25-4d6c-a8e4-c169431512f0/dg03tbi-888351ce-7bc3-44d0-ba2d-2504637c98b6.jpg/v1/fit/w_704,h_960,q_70,strp/cyborg_kratos_portrait_by_furystorm_dg03tbi-375w-2x.jpg?token=eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJzdWIiOiJ1cm46YXBwOjdlMGQxODg5ODIyNjQzNzNhNWYwZDQxNWVhMGQyNmUwIiwiaXNzIjoidXJuOmFwcDo3ZTBkMTg4OTgyMjY0MzczYTVmMGQ0MTVlYTBkMjZlMCIsIm9iaiI6W1t7ImhlaWdodCI6Ijw9OTYwIiwicGF0aCI6IlwvZlwvY2QxNWE4ZDctOWEyNS00ZDZjLWE4ZTQtYzE2OTQzMTUxMmYwXC9kZzAzdGJpLTg4ODM1MWNlLTdiYzMtNDRkMC1iYTJkLTI1MDQ2MzdjOThiNi5qcGciLCJ3aWR0aCI6Ijw9NzA0In1dXSwiYXVkIjpbInVybjpzZXJ2aWNlOmltYWdlLm9wZXJhdGlvbnMiXX0.WjU1EVVb6r-TV23UAzF-CEcpUKHnnTQD8PZam_-DrQI'),
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                        ],
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (msg.image != null)
                                Container(
                                  margin: EdgeInsets.only(bottom: 8),
                                  child: Image.file(msg.image!, height: 150),
                                ),
                              Text(
                                msg.message,
                                style: TextStyle(
                                  fontSize: 16,
                                  color: msg.isUser ? textUserColor : textBotColor,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                _formatTime(msg.timestamp),
                                style: TextStyle(
                                  fontSize: 11,
                                  color:
                                      msg.isUser ? Colors.white70 : const Color.fromARGB(255, 255, 255, 255),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          if (_isLoading)
            LinearProgressIndicator(
              backgroundColor: backgroundColor,
              valueColor: AlwaysStoppedAnimation<Color>(userBubbleColor),
            ),
          Padding(
            padding: EdgeInsets.all(8),
            child: Row(
              children: [
                IconButton(
                  icon: Icon(Icons.photo),
                  onPressed: _pickImage,
                  color: userBubbleColor,
                  tooltip: 'Seleccionar imagen',
                ),
                IconButton(
                  icon: Icon(_isListening ? Icons.mic : Icons.mic_none),
                  onPressed: _listen,
                  color: _isListening ? Colors.redAccent : userBubbleColor,
                  tooltip: 'Hablar',
                ),
                Expanded(
                  child: TextField(
                    controller: _controller,
                    onSubmitted: (_) => _sendTextMessage(_controller.text),
                    style: TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: '¿Qué duda tienes?',
                      hintStyle: TextStyle(color: Colors.white54),
                      filled: true,
                      fillColor: inputFillColor,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                    ),
                  ),
                ),
                SizedBox(width: 8),
                CircleAvatar(
                  backgroundColor: userBubbleColor,
                  child: IconButton(
                    icon: Icon(Icons.send, color: Colors.white),
                    onPressed: () => _sendTextMessage(_controller.text),
                  ),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}
