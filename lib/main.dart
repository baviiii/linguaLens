import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:camera/camera.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';
import 'package:flutter/services.dart'; // For clipboard functionality
import 'package:flutter/foundation.dart' show kIsWeb;

// Check if we're running on web
bool get isWeb => kIsWeb;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Get available cameras
  final cameras = await availableCameras();
  final firstCamera = cameras.isNotEmpty ? cameras.first : null;

  runApp(MyApp(camera: firstCamera));
}

class MyApp extends StatelessWidget {
  final CameraDescription? camera;

  const MyApp({super.key, required this.camera});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'LinguaLens AR Translator',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: camera != null
          ? TranslatorScreen(camera: camera!)
          : const NoCameraScreen(),
    );
  }
}

// Screen to show when no camera is available
class NoCameraScreen extends StatelessWidget {
  const NoCameraScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('LinguaLens Translator'),
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // These are actual icons available in Flutter:
            Icon(Icons.no_photography, size: 100, color: Colors.grey),
            SizedBox(height: 16),
            Text('No camera detected on this device'),
            SizedBox(height: 16),
            Text('Please use a device with a camera for AR features'),
          ],
        ),
      ),
    );
  }
}

class TranslatorScreen extends StatefulWidget {
  final CameraDescription camera;

  const TranslatorScreen({super.key, required this.camera});

  @override
  TranslatorScreenState createState() => TranslatorScreenState();
}

class TranslatorScreenState extends State<TranslatorScreen> with WidgetsBindingObserver {
  CameraController? _cameraController;
  late TextRecognizer _textRecognizer;
  bool _isCameraInitialized = false;
  bool _isProcessingFrame = false;
  bool _isCameraPermissionGranted = false;
  bool _isARMode = false;

  final TextEditingController _textController = TextEditingController();
  String _translatedText = '';
  String _sourceLang = 'en';
  String _targetLang = 'es';
  bool _isLoading = false;
  String _errorMessage = '';
  bool _isOfflineMode = false;
  List<String> _detectedTexts = [];
  String _selectedDetectedText = '';

  // Dictionary for offline translations
  final Map<String, Map<String, Map<String, String>>> _offlineDictionary = {
    'en': {
      'es': {
        'hello': 'hola',
        'world': 'mundo',
        'hello world': 'hola mundo',
        'good morning': 'buenos días',
        'good afternoon': 'buenas tardes',
        'good evening': 'buenas noches',
        'goodbye': 'adiós',
        'thank you': 'gracias',
        'please': 'por favor',
        'yes': 'sí',
        'no': 'no',
        'how are you': 'cómo estás',
        'my name is': 'me llamo',
        'what is your name': 'cómo te llamas',
        'i don\'t understand': 'no entiendo',
        'sorry': 'lo siento',
        'excuse me': 'disculpe',
        'where is': 'dónde está',
        'help': 'ayuda',
        'water': 'agua',
        'food': 'comida',
        'restaurant': 'restaurante',
        'hotel': 'hotel',
        'airport': 'aeropuerto',
        'train station': 'estación de tren',
        'bus station': 'estación de autobús',
        'how much': 'cuánto cuesta',
        'book': 'libro',
        'pen': 'bolígrafo',
        'table': 'mesa',
        'chair': 'silla',
        'door': 'puerta',
        'window': 'ventana',
        'phone': 'teléfono',
        'computer': 'computadora',
        'car': 'coche',
        'house': 'casa',
      },
      'fr': {
        'hello': 'bonjour',
        'world': 'monde',
        'hello world': 'bonjour le monde',
        'good morning': 'bonjour',
        'good afternoon': 'bon après-midi',
        'good evening': 'bonsoir',
        'goodbye': 'au revoir',
        'thank you': 'merci',
        'please': 's\'il vous plaît',
        'yes': 'oui',
        'no': 'non',
        'how are you': 'comment allez-vous',
        'my name is': 'je m\'appelle',
        'what is your name': 'comment vous appelez-vous',
        'i don\'t understand': 'je ne comprends pas',
        'sorry': 'désolé',
        'excuse me': 'excusez-moi',
        'where is': 'où est',
        'help': 'aide',
        'water': 'eau',
        'food': 'nourriture',
        'restaurant': 'restaurant',
        'hotel': 'hôtel',
        'airport': 'aéroport',
        'train station': 'gare',
        'bus station': 'gare routière',
        'how much': 'combien ça coûte',
        'book': 'livre',
        'pen': 'stylo',
        'table': 'table',
        'chair': 'chaise',
        'door': 'porte',
        'window': 'fenêtre',
        'phone': 'téléphone',
        'computer': 'ordinateur',
        'car': 'voiture',
        'house': 'maison',
      },
      'de': {
        'hello': 'hallo',
        'world': 'welt',
        'hello world': 'hallo welt',
        'good morning': 'guten morgen',
        'good afternoon': 'guten tag',
        'good evening': 'guten abend',
        'goodbye': 'auf wiedersehen',
        'thank you': 'danke',
        'please': 'bitte',
        'yes': 'ja',
        'no': 'nein',
        'how are you': 'wie geht es dir',
        'my name is': 'ich heiße',
        'what is your name': 'wie heißt du',
        'i don\'t understand': 'ich verstehe nicht',
        'sorry': 'entschuldigung',
        'excuse me': 'entschuldigen sie',
        'where is': 'wo ist',
        'help': 'hilfe',
        'water': 'wasser',
        'food': 'essen',
        'restaurant': 'restaurant',
        'hotel': 'hotel',
        'airport': 'flughafen',
        'train station': 'bahnhof',
        'bus station': 'busbahnhof',
        'how much': 'wie viel kostet',
      }
    },
  };

  final Map<String, String> _languages = {
    'en': 'English',
    'es': 'Spanish',
    'fr': 'French',
    'de': 'German',
    'it': 'Italian',
    'pt': 'Portuguese',
    'ru': 'Russian',
    'zh': 'Chinese',
    'ja': 'Japanese',
    'ko': 'Korean',
  };

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _textController.text = "Hello world";
    _initializeTextRecognizer();
    _checkPermission();
    _checkConnection();
  }

  Future<void> _checkPermission() async {
    // Skip permission check on web platform
    if (isWeb) {
      setState(() {
        _isCameraPermissionGranted = true;
      });
      _initializeCamera();
      return;
    }

    final status = await Permission.camera.request();
    setState(() {
      _isCameraPermissionGranted = status == PermissionStatus.granted;
    });

    if (_isCameraPermissionGranted) {
      _initializeCamera();
    }
  }

  void _initializeTextRecognizer() {
    _textRecognizer = TextRecognizer();
  }

  Future<void> _initializeCamera() async {
    if (_cameraController != null) {
      await _cameraController!.dispose();
    }

    final CameraController cameraController = CameraController(
      widget.camera,
      ResolutionPreset.medium,
      enableAudio: false,
    );

    try {
      await cameraController.initialize();

      if (mounted) {
        setState(() {
          _cameraController = cameraController;
          _isCameraInitialized = true;
        });

        if (_isARMode) {
          _startTextRecognition();
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Camera initialization failed: ${e.toString()}';
        });
      }
    }
  }

  Future<void> _startTextRecognition() async {
    if (!_isCameraInitialized || _isProcessingFrame || _cameraController == null) return;

    try {
      await _cameraController!.startImageStream((CameraImage image) async {
        if (_isProcessingFrame) return;

        _isProcessingFrame = true;

        try {
          // Process frames here
          // This is simplified - in actual implementation you would:
          // 1. Convert CameraImage to InputImage
          // 2. Run TextRecognizer on the InputImage
          // 3. Update the UI with detected text

          // For now, just simulating detection
          await Future.delayed(const Duration(seconds: 1));

          if (mounted) {
            setState(() {
              _isProcessingFrame = false;
            });
          }
        } catch (e) {
          if (mounted) {
            setState(() {
              _isProcessingFrame = false;
              _errorMessage = 'Text recognition error: ${e.toString()}';
            });
          }
        }
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to start image stream: ${e.toString()}';
        });
      }
    }
  }

  // Take a picture and process it
  Future<void> _scanText() async {
    if (!_isCameraInitialized || _cameraController == null) return;

    if (mounted) {
      setState(() {
        _isLoading = true;
        _errorMessage = '';
        _detectedTexts = [];
      });
    }

    try {
      // Pause the stream if active
      if (_cameraController!.value.isStreamingImages) {
        await _cameraController!.stopImageStream();
      }

      final XFile file = await _cameraController!.takePicture();
      final InputImage inputImage = InputImage.fromFilePath(file.path);
      final RecognizedText recognizedText = await _textRecognizer.processImage(inputImage);

      // Extract text blocks
      final List<String> extractedTexts = [];
      for (TextBlock block in recognizedText.blocks) {
        extractedTexts.add(block.text);
        for (TextLine line in block.lines) {
          if (!extractedTexts.contains(line.text)) {
            extractedTexts.add(line.text);
          }
          // Also add individual words for simpler translations
          for (TextElement element in line.elements) {
            if (element.text.length > 2 && !extractedTexts.contains(element.text)) {
              extractedTexts.add(element.text);
            }
          }
        }
      }

      if (mounted) {
        setState(() {
          _detectedTexts = extractedTexts;
          _isLoading = false;
        });
      }

      // If we found text, show the selection dialog
      if (_detectedTexts.isNotEmpty && mounted) {
        _showTextSelectionDialog();
      } else if (mounted) {
        setState(() {
          _errorMessage = 'No text detected. Try again with clearer text.';
        });
      }

      // Resume AR mode if active
      if (_isARMode && mounted) {
        _startTextRecognition();
      }

    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Failed to process image: ${e.toString()}';
        });
      }
    }
  }

  void _showTextSelectionDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Select Text to Translate'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: _detectedTexts.length,
              itemBuilder: (context, index) {
                return ListTile(
                  title: Text(_detectedTexts[index]),
                  onTap: () {
                    setState(() {
                      _selectedDetectedText = _detectedTexts[index];
                      _textController.text = _detectedTexts[index];
                    });
                    Navigator.pop(context);
                    _translate();
                  },
                );
              },
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  // Check if we can connect to the internet
  Future<void> _checkConnection() async {
    try {
      final response = await http.get(Uri.parse('https://www.google.com'))
          .timeout(const Duration(seconds: 5));
      if (mounted) {
        setState(() {
          _isOfflineMode = response.statusCode != 200;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isOfflineMode = true;
        });
      }
    }
  }

  // Toggle between online and offline mode
  void _toggleOfflineMode() {
    setState(() {
      _isOfflineMode = !_isOfflineMode;
    });
  }

  // Toggle between AR and manual text entry modes
  void _toggleARMode() {
    setState(() {
      _isARMode = !_isARMode;
    });

    if (_cameraController != null && _isCameraInitialized) {
      if (_isARMode) {
        _cameraController!.resumePreview();
        _startTextRecognition();
      } else {
        if (_cameraController!.value.isStreamingImages) {
          _cameraController!.stopImageStream();
        }
        _cameraController!.pausePreview();
      }
    }
  }

  // Offline translation function
  String _getOfflineTranslation(String text) {
    // Convert to lowercase for dictionary lookup
    text = text.trim().toLowerCase();

    // Check if we have a direct translation
    if (_offlineDictionary.containsKey(_sourceLang) &&
        _offlineDictionary[_sourceLang]!.containsKey(_targetLang) &&
        _offlineDictionary[_sourceLang]![_targetLang]!.containsKey(text)) {
      return _offlineDictionary[_sourceLang]![_targetLang]![text]!;
    }

    // If not, try to translate word by word
    final words = text.split(' ');
    final translatedWords = words.map((word) {
      if (_offlineDictionary.containsKey(_sourceLang) &&
          _offlineDictionary[_sourceLang]!.containsKey(_targetLang) &&
          _offlineDictionary[_sourceLang]![_targetLang]!.containsKey(word.toLowerCase())) {
        return _offlineDictionary[_sourceLang]![_targetLang]![word.toLowerCase()]!;
      }
      return word; // Keep original if no translation found
    }).toList();

    return translatedWords.join(' ');
  }

  Future<void> _translate() async {
    if (_textController.text.trim().isEmpty) {
      setState(() {
        _errorMessage = 'Please enter text to translate';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    // Use offline translation if in offline mode
    if (_isOfflineMode) {
      await Future.delayed(const Duration(milliseconds: 500)); // Simulate network
      if (mounted) {
        setState(() {
          _translatedText = _getOfflineTranslation(_textController.text);
          _isLoading = false;
        });
      }
      return;
    }

    // Online translation
    final url = Uri.parse('https://translate.argosopentech.com/translate');

    try {
      // Set a longer timeout for the request
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'q': _textController.text,
          'source': _sourceLang,
          'target': _targetLang,
          'format': 'text',
        }),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        if (mounted) {
          setState(() {
            _translatedText = data['translatedText'];
            _isLoading = false;
          });
        }
      } else {
        // If online translation fails, fall back to offline
        if (mounted) {
          setState(() {
            _translatedText = _getOfflineTranslation(_textController.text);
            _errorMessage = 'Online translation failed. Using offline dictionary.';
            _isLoading = false;
            _isOfflineMode = true; // Switch to offline mode
          });
        }
      }
    } catch (e) {
      // If an error occurs, use offline translation
      if (mounted) {
        setState(() {
          _translatedText = _getOfflineTranslation(_textController.text);
          _errorMessage = 'Connection error: ${e.toString()}. Using offline dictionary.';
          _isLoading = false;
          _isOfflineMode = true; // Switch to offline mode
        });
      }
    }
  }

  // Copy text to clipboard with platform awareness
  Future<void> _copyToClipboard(String text) async {
    if (isWeb) {
      // For web
      try {
        await Clipboard.setData(ClipboardData(text: text));
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Copied to clipboard')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to copy: ${e.toString()}')),
        );
      }
    } else {
      // For mobile
      await Clipboard.setData(ClipboardData(text: text));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Copied to clipboard')),
      );
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _textController.dispose();

    if (_cameraController != null) {
      _cameraController!.dispose();
    }
    _textRecognizer.close();

    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // App state changed before we got the chance to initialize the camera
    if (!_isCameraInitialized || _cameraController == null || !_cameraController!.value.isInitialized) return;

    if (state == AppLifecycleState.inactive) {
      _cameraController!.dispose();
      setState(() {
        _isCameraInitialized = false;
      });
    } else if (state == AppLifecycleState.resumed) {
      _initializeCamera();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isARMode
            ? 'LinguaLens AR Mode'
            : (_isOfflineMode ? 'LinguaLens (Offline)' : 'LinguaLens')),
        backgroundColor: _isARMode
            ? Colors.green
            : (_isOfflineMode ? Colors.grey : Colors.blue),
        foregroundColor: Colors.white,
        actions: [
          // AR mode toggle button
          IconButton(
            icon: Icon(_isARMode ? Icons.camera_alt : Icons.text_fields),
            onPressed: _isCameraPermissionGranted ? _toggleARMode : _checkPermission,
            tooltip: _isARMode ? 'Switch to text mode' : 'Switch to AR mode',
          ),
          // Offline mode toggle button
          IconButton(
            icon: Icon(_isOfflineMode ? Icons.cloud_off : Icons.cloud),
            onPressed: _toggleOfflineMode,
            tooltip: _isOfflineMode ? 'Switch to online mode' : 'Switch to offline mode',
          ),
        ],
      ),
      body: _isARMode ? _buildARView() : _buildTextTranslationView(),
    );
  }

  Widget _buildARView() {
    if (!_isCameraPermissionGranted) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.camera_alt_outlined, size: 100, color: Colors.grey),
            const SizedBox(height: 16),
            const Text('Camera permission is required for AR mode'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _checkPermission,
              child: const Text('Grant Permission'),
            ),
          ],
        ),
      );
    }

    if (!_isCameraInitialized || _cameraController == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      children: [
        Expanded(
          child: Stack(
            children: [
              // Camera preview
              CameraPreview(_cameraController!),

              // Overlay to indicate scanning area
              Positioned.fill(
                child: Container(
                  alignment: Alignment.center,
                  child: Container(
                    width: 300,
                    height: 150,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.green, width: 3),
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),

              // Information message
              Positioned(
                bottom: 16,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'Point at text to translate',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
              ),

              // Loading indicator
              if (_isLoading)
                const Positioned.fill(
                  child: Center(
                    child: CircularProgressIndicator(),
                  ),
                ),
            ],
          ),
        ),

        // Language selection strip
        Container(
          color: Colors.grey[200],
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          child: Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  decoration: const InputDecoration(
                    labelText: 'From',
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(horizontal: 8),
                  ),
                  value: _sourceLang,
                  items: (_isOfflineMode ?
                  _offlineDictionary.keys.toList() :
                  _languages.keys.toList())
                      .map((code) {
                    return DropdownMenuItem<String>(
                      value: code,
                      child: Text(_languages[code] ?? code),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _sourceLang = value;
                      });
                    }
                  },
                ),
              ),
              IconButton(
                icon: const Icon(Icons.swap_horiz),
                onPressed: () {
                  // In offline mode, only allow swaps that we support
                  if (_isOfflineMode &&
                      (!_offlineDictionary.containsKey(_targetLang) ||
                          !_offlineDictionary[_targetLang]!.containsKey(_sourceLang))) {
                    setState(() {
                      _errorMessage = 'This language direction is not supported offline';
                    });
                    return;
                  }

                  setState(() {
                    final temp = _sourceLang;
                    _sourceLang = _targetLang;
                    _targetLang = temp;
                  });
                },
              ),
              Expanded(
                child: DropdownButtonFormField<String>(
                  decoration: const InputDecoration(
                    labelText: 'To',
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(horizontal: 8),
                  ),
                  value: _targetLang,
                  items: (_isOfflineMode && _offlineDictionary.containsKey(_sourceLang) ?
                  _offlineDictionary[_sourceLang]!.keys.toList() :
                  _languages.keys.toList())
                      .map((code) {
                    return DropdownMenuItem<String>(
                      value: code,
                      child: Text(_languages[code] ?? code),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _targetLang = value;
                      });
                    }
                  },
                ),
              ),
            ],
          ),
        ),

        // Scan button
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.camera_alt),
                  label: Text(_isLoading ? 'Scanning...' : 'Scan Text'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  onPressed: _isLoading ? null : _scanText,
                ),
              ),
            ],
          ),
        ),

        // Translation result (if any)
        if (_translatedText.isNotEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.grey[100],
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Original: $_selectedDetectedText',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  'Translation: $_translatedText',
                  style: const TextStyle(fontSize: 18),
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: IconButton(
                    icon: const Icon(Icons.content_copy),
                    onPressed: () => _copyToClipboard(_translatedText),
                    tooltip: 'Copy translation',
                  ),
                ),
              ],
            ),
          ),

        // Error message
        if (_errorMessage.isNotEmpty)
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              _errorMessage,
              style: const TextStyle(color: Colors.red),
            ),
          ),
      ],
    );
  }

  Widget _buildTextTranslationView() {
    return SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
            if (_isOfflineMode)
        Container(
        padding: const EdgeInsets.all(8),
    color: Colors.amber[100],
    child: const Row(
    children: [
    Icon(Icons.info_outline, color: Colors.amber),
    SizedBox(width: 8),
    Expanded(
    child: Text(
    'Working in offline mode with limited translations. '
    'Common phrases and words are available.',
    style: TextStyle(fontSize: 12),
    ),
    ),
    ],
    ),
    ),

    const SizedBox(height: 20),

    // Language selection
    Row(
    children: [
    Expanded(
    child: DropdownButtonFormField<String>(
    decoration: const InputDecoration(
    labelText: 'From',
    border: OutlineInputBorder(),
    ),
    value: _sourceLang,
    items: (_isOfflineMode ?
    _offlineDictionary.keys.toList() :
    _languages.keys.toList())
        .map((code) {
    return DropdownMenuItem<String>(
    value: code,
    child: Text(_languages[code] ?? code),
    );
    }).toList(),
    onChanged: (value) {
    if (value != null) {
    setState(() {
    _sourceLang = value;
    });
    }
    },
    ),
    ),
    const SizedBox(width: 16),
    IconButton(
    icon: const Icon(Icons.swap_horiz),
      onPressed: () {
        // In offline mode, only allow swaps that we support
        if (_isOfflineMode &&
            (!_offlineDictionary.containsKey(_targetLang) ||
                !_offlineDictionary[_targetLang]!.containsKey(_sourceLang))) {
          setState(() {
            _errorMessage = 'This language direction is not supported offline';
          });
          return;
        }

        setState(() {
          final temp = _sourceLang;
          _sourceLang = _targetLang;
          _targetLang = temp;
          if (_translatedText.isNotEmpty && _textController.text.isNotEmpty) {
            _textController.text = _translatedText;
            _translatedText = '';
          }
        });
      },
    ),
      const SizedBox(width: 16),
      Expanded(
        child: DropdownButtonFormField<String>(
          decoration: const InputDecoration(
            labelText: 'To',
            border: OutlineInputBorder(),
          ),
          value: _targetLang,
          items: (_isOfflineMode && _offlineDictionary.containsKey(_sourceLang) ?
          _offlineDictionary[_sourceLang]!.keys.toList() :
          _languages.keys.toList())
              .map((code) {
            return DropdownMenuItem<String>(
              value: code,
              child: Text(_languages[code] ?? code),
            );
          }).toList(),
          onChanged: (value) {
            if (value != null) {
              setState(() {
                _targetLang = value;
              });
            }
          },
        ),
      ),
    ],
    ),

              const SizedBox(height: 20),

              TextField(
                controller: _textController,
                decoration: const InputDecoration(
                  labelText: 'Enter text to translate',
                  border: OutlineInputBorder(),
                  hintText: 'Type or paste text here',
                ),
                maxLines: 5,
              ),

              const SizedBox(height: 16),

              ElevatedButton(
                onPressed: _isLoading ? null : _translate,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  backgroundColor: _isOfflineMode ? Colors.amber : Colors.blue,
                  foregroundColor: Colors.white,
                ),
                child: _isLoading
                    ? const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    ),
                    SizedBox(width: 10),
                    Text('Translating...'),
                  ],
                )
                    : Text(_isOfflineMode ? 'Translate (Offline)' : 'Translate'),
              ),

              if (_errorMessage.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: Text(
                    _errorMessage,
                    style: const TextStyle(color: Colors.red),
                  ),
                ),

              const SizedBox(height: 20),

              if (_translatedText.isNotEmpty) ...[
                const Text(
                  'Translation:',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SelectableText(
                        _translatedText,
                        style: const TextStyle(fontSize: 18),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.content_copy),
                            onPressed: () => _copyToClipboard(_translatedText),
                            tooltip: 'Copy translation',
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],

              // Offline dictionary list (expandable)
              if (_isOfflineMode)
                ExpansionTile(
                  title: const Text('Available Offline Translations'),
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      width: double.infinity,
                      color: Colors.grey[100],
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('English to Spanish/French/German common phrases'),
                          const SizedBox(height: 8),
                          const Text('Examples: hello, goodbye, thank you, please, yes, no...'),
                          const SizedBox(height: 16),
                          const Text('For a better experience, connect to the internet.'),
                        ],
                      ),
                    ),
                  ],
                ),
            ],
        ),
    );
  }
}