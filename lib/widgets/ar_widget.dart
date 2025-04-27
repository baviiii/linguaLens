import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:math' as math;
import 'package:camera/camera.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';
import 'package:arcore_flutter_plugin/arcore_flutter_plugin.dart';
import '../services/ar_service.dart';
import '../services/ml_service.dart';

class ARWidget extends StatefulWidget {
  const ARWidget({super.key});

  static String routeName = 'AR';
  static String routePath = '/ar';

  @override
  State<ARWidget> createState() => _ARWidgetState();
}

class _ARWidgetState extends State<ARWidget> {
  String _sourceLanguage = 'en';
  String _targetLanguage = 'es';
  String _detectedText = '';
  String _translatedText = '';
  bool _isCameraMode = false;
  bool _isARMode = false;
  bool _isCameraInitialized = false;
  bool _isARInitialized = false;
  bool _isProcessing = false;
  CameraController? _cameraController;
  List<CameraDescription>? _cameras;
  File? _capturedImage;
  
  // AR related fields
  late final ARService _arService;
  ArCoreController? _arCoreController;
  
  // Add this new variable for ML service
  late final MLService _mlService;

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
    _arService = ARService();
    _mlService = MLService();
    _checkCameraPermission();
    _initializeMLService();
  }

  Future<void> _checkCameraPermission() async {
    final status = await Permission.camera.request();
    if (status.isGranted) {
      _initializeCamera();
      _initializeAR();
    }
  }

  Future<void> _initializeCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras != null && _cameras!.isNotEmpty) {
        _cameraController = CameraController(
          _cameras![0],
          ResolutionPreset.medium,
          enableAudio: false,
        );
        await _cameraController!.initialize();
        setState(() {
          _isCameraInitialized = true;
        });
      }
    } catch (e) {
      debugPrint('Error initializing camera: $e');
    }
  }
  
  Future<void> _initializeAR() async {
    try {
      await _arService.initializeAR();
      setState(() {
        _isARInitialized = true;
      });
    } catch (e) {
      debugPrint('Error initializing AR: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('AR not available: $e'),
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  Future<void> _initializeMLService() async {
    try {
      await _mlService.initialize();
    } catch (e) {
      debugPrint('Error initializing ML Service: $e');
    }
  }

  void _toggleCameraMode() {
    if (_isCameraInitialized) {
      setState(() {
        _isCameraMode = !_isCameraMode;
        // If we're turning off camera mode, also ensure AR mode is off
        if (!_isCameraMode) {
          _isARMode = false;
        }
      });
    } else {
      _checkCameraPermission();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Camera not available. Please grant camera permission.'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }
  
  void _toggleARMode() {
    if (_isARInitialized) {
      setState(() {
        _isARMode = !_isARMode;
        // If we're turning on AR mode, also ensure camera mode is off
        if (_isARMode) {
          _isCameraMode = false;
        }
      });
    } else {
      _initializeAR();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('AR not available. Please check if your device supports AR.'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _takePicture() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return;
    }
    
    if (_isProcessing) {
      return;
    }
    
    try {
      setState(() {
        _isProcessing = true;
      });
      
      final XFile photo = await _cameraController!.takePicture();
      final File imageFile = File(photo.path);
      
      setState(() {
        _capturedImage = imageFile;
        _isCameraMode = false;
      });
      
      // In a real app, here we would send this image to ML model
      // For now, we'll use the simulation
      _processImage();
      
    } catch (e) {
      debugPrint('Error taking picture: $e');
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }
  
  void _onArCoreViewCreated(ArCoreController controller) {
    _arCoreController = controller;
    _arService.arCoreController = controller;
    _arService.onObjectDetected = _handleObjectDetected;
    _arService.onArCoreViewCreated(controller);
    
    debugPrint('AR view created successfully');
  }
  
  void _handleObjectDetected(String objectName) {
    debugPrint('Object detected in AR: $objectName');
    
    setState(() {
      _detectedText = objectName;
      _translatedText = _translateObject(objectName);
      _isARMode = false; // Exit AR mode to show results
    });
    
    // Show dialog with result
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF18191B),
        title: Text(
          'Object Detected in AR!',
          style: GoogleFonts.inter(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'We detected: $objectName',
              style: GoogleFonts.inter(
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Translation: ${_translatedText}',
              style: GoogleFonts.inter(
                color: Colors.white,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'OK',
              style: GoogleFonts.inter(
                color: const Color(0xFF03A9F4),
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Future<void> _processImage() async {
    setState(() {
      _isProcessing = true;
    });
    
    try {
      if (_capturedImage == null) {
        throw Exception('No image captured');
      }
      
      // Use ML Kit for object detection
      final objects = await _mlService.detectObjectsInImage(_capturedImage!);
      
      // Use ML Kit for image labeling as a fallback
      final labels = await _mlService.labelImage(_capturedImage!);
      
      // Get the most likely object
      final detectedObject = _mlService.getMostLikelyObjectName(objects, labels);
      
      debugPrint('ML DETECTION RESULT: $detectedObject');
      
      // Translate the object
      final translation = _translateObject(detectedObject);
      
      // Update state with new values
      setState(() {
        _detectedText = detectedObject;
        _translatedText = translation;
        _isProcessing = false;
      });
      
      // Show dialog with result
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: const Color(0xFF18191B),
          title: Text(
            'Object Detected!',
            style: GoogleFonts.inter(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_capturedImage != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.file(
                    _capturedImage!,
                    height: 150,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
              const SizedBox(height: 16),
              Text(
                'We detected: $detectedObject',
                style: GoogleFonts.inter(
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Translation: $translation',
                style: GoogleFonts.inter(
                  color: Colors.white,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'OK',
                style: GoogleFonts.inter(
                  color: const Color(0xFF03A9F4),
                ),
              ),
            ),
          ],
        ),
      );
    } catch (e) {
      debugPrint('Error processing image: $e');
      setState(() {
        _isProcessing = false;
      });
      
      // Show error dialog
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error analyzing image: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
  
  String _translateObject(String objectName) {
    // Expanded mock translation map with all possible objects
    final translations = {
      'en': {
        'Coffee Cup': {'es': 'Taza de café', 'fr': 'Tasse à café', 'de': 'Kaffeetasse'},
        'Notebook': {'es': 'Cuaderno', 'fr': 'Cahier', 'de': 'Notizbuch'},
        'Pen': {'es': 'Bolígrafo', 'fr': 'Stylo', 'de': 'Stift'},
        'Keyboard': {'es': 'Teclado', 'fr': 'Clavier', 'de': 'Tastatur'},
        'Mouse': {'es': 'Ratón', 'fr': 'Souris', 'de': 'Maus'},
        'Phone': {'es': 'Teléfono', 'fr': 'Téléphone', 'de': 'Telefon'},
        'Watch': {'es': 'Reloj', 'fr': 'Montre', 'de': 'Uhr'},
        'Book': {'es': 'Libro', 'fr': 'Livre', 'de': 'Buch'},
        'Glasses': {'es': 'Gafas', 'fr': 'Lunettes', 'de': 'Brille'},
        'Headphones': {'es': 'Auriculares', 'fr': 'Écouteurs', 'de': 'Kopfhörer'},
      }
    };
    
    try {
      final result = translations['en']?[objectName]?[_targetLanguage] ?? 'Translation not available';
      debugPrint('Translating "$objectName" to $_targetLanguage: $result');
      return result;
    } catch (e) {
      debugPrint('Translation error for $objectName: $e');
      return 'Translation error';
    }
  }

  void _showConversationTips() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF18191B),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey[700],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Text('Conversation Tips',
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  )),
              const SizedBox(height: 16),
              Text(
                '• Greet politely\n• Ask open-ended questions\n• Listen actively\n• Use simple language',
                style: GoogleFonts.inter(
                  color: Colors.white70,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showLiveTranslation() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF18191B),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey[700],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Text('Live Translation',
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  )),
              const SizedBox(height: 16),
              Text(
                'This feature will listen and translate in real time. (Demo)',
                style: GoogleFonts.inter(
                  color: Colors.white70,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showLanguageSelector() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF18191B),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.grey[700],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Text('Select Language',
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                    )),
                const SizedBox(height: 24),
                Text('Source Language:',
                    style: GoogleFonts.inter(
                      color: Colors.white70,
                      fontSize: 16,
                    )),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF222328),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _sourceLanguage,
                      icon: const Icon(Icons.arrow_drop_down, color: Colors.white),
                      dropdownColor: const Color(0xFF222328),
                      isExpanded: true,
                      style: GoogleFonts.inter(color: Colors.white),
                      onChanged: (String? newValue) {
                        if (newValue != null) {
                          setModalState(() {
                            _sourceLanguage = newValue;
                          });
                          setState(() {
                            _sourceLanguage = newValue;
                          });
                        }
                      },
                      items: _languages.entries
                          .map<DropdownMenuItem<String>>((entry) {
                        return DropdownMenuItem<String>(
                          value: entry.key,
                          child: Text(entry.value),
                        );
                      }).toList(),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Text('Target Language:',
                    style: GoogleFonts.inter(
                      color: Colors.white70,
                      fontSize: 16,
                    )),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF222328),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _targetLanguage,
                      icon: const Icon(Icons.arrow_drop_down, color: Colors.white),
                      dropdownColor: const Color(0xFF222328),
                      isExpanded: true,
                      style: GoogleFonts.inter(color: Colors.white),
                      onChanged: (String? newValue) {
                        if (newValue != null) {
                          setModalState(() {
                            _targetLanguage = newValue;
                          });
                          setState(() {
                            _targetLanguage = newValue;
                            // Refresh translation if we have a detected object
                            if (_detectedText.isNotEmpty) {
                              _translatedText = _translateObject(_detectedText);
                            }
                          });
                        }
                      },
                      items: _languages.entries
                          .map<DropdownMenuItem<String>>((entry) {
                        return DropdownMenuItem<String>(
                          value: entry.key,
                          child: Text(entry.value),
                        );
                      }).toList(),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF03A9F4),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: Text(
                      'Apply',
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildARView() {
    return Stack(
      children: [
        ArCoreView(
          onArCoreViewCreated: _onArCoreViewCreated,
          enableTapRecognizer: true,
          enablePlaneRenderer: true,
          debug: true,
        ),
        Positioned(
          top: 40,
          left: 20,
          child: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white, size: 28),
            onPressed: _toggleARMode,
          ),
        ),
        Positioned(
          bottom: 30,
          left: 0,
          right: 0,
          child: Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.7),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                'Tap on a surface to place a marker',
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    _arCoreController?.dispose();
    _arService.dispose();
    _mlService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isARMode) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: _buildARView(),
      );
    }
    
    if (_isCameraMode) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          children: [
            if (_cameraController != null && _isCameraInitialized)
              Positioned.fill(
                child: AspectRatio(
                  aspectRatio: _cameraController!.value.aspectRatio,
                  child: CameraPreview(_cameraController!),
                ),
              ),
            Positioned(
              top: 40,
              left: 20,
              child: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white, size: 28),
                onPressed: _toggleCameraMode,
              ),
            ),
            Positioned(
              bottom: 30,
              left: 0,
              right: 0,
              child: Center(
                child: GestureDetector(
                  onTap: _takePicture,
                  child: Container(
                    width: 70,
                    height: 70,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.8),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white,
                        width: 3,
                      ),
                    ),
                    child: _isProcessing
                        ? const CircularProgressIndicator(color: Color(0xFF03A9F4))
                        : const Icon(Icons.camera_alt, size: 36),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    // Main UI
    return Scaffold(
      backgroundColor: const Color(0xFF111214),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Top Bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'AR Translator',
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 22,
                      ),
                    ),
                    Row(
                      children: [
                        _circleIconButton(Icons.history, onTap: () {}),
                        const SizedBox(width: 10),
                        _circleIconButton(Icons.language, onTap: _showLanguageSelector),
                        const SizedBox(width: 10),
                        _circleIconButton(Icons.mic, onTap: () {}),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              // Glowing Center Button
              GestureDetector(
                onTap: _toggleARMode,
                child: Center(
                  child: Container(
                    width: 180,
                    height: 180,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.black,
                      border: Border.all(
                        color: const Color(0xFF03A9F4),
                        width: 3,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF03A9F4).withOpacity(0.5),
                          blurRadius: 20,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.view_in_ar,
                      size: 80,
                      color: Color(0xFF03A9F4),
                    ),
                  ),
                ),
              ),
              // Action Buttons
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                child: Row(
                  children: [
                    // AR Button
                    Expanded(
                      child: SizedBox(
                        height: 56,
                        child: ElevatedButton.icon(
                          onPressed: _toggleARMode,
                          icon: const Icon(Icons.view_in_ar, color: Colors.white),
                          label: Text(
                            'AR Mode',
                            style: GoogleFonts.inter(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF03A9F4),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(28),
                            ),
                            elevation: 8,
                            shadowColor: const Color(0xFF03A9F4),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Camera Button
                    Expanded(
                      child: SizedBox(
                        height: 56,
                        child: ElevatedButton.icon(
                          onPressed: _toggleCameraMode,
                          icon: const Icon(Icons.camera_alt, color: Colors.white),
                          label: Text(
                            'Camera',
                            style: GoogleFonts.inter(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF222328),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(28),
                            ),
                            elevation: 8,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Translation Results Card
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF18191B),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Translation Results',
                              style: GoogleFonts.inter(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.settings, color: Color(0xFF03A9F4)),
                              onPressed: () {},
                            ),
                          ],
                        ),
                        const Divider(color: Color(0xFF222328), thickness: 1, height: 24),
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Detected Object:',
                                    style: GoogleFonts.inter(
                                      color: const Color(0xFF03A9F4),
                                      fontWeight: FontWeight.w500,
                                      fontSize: 14,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _detectedText.isNotEmpty ? _detectedText : '—',
                                    style: GoogleFonts.inter(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 16,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    'Translation:',
                                    style: GoogleFonts.inter(
                                      color: const Color(0xFF03A9F4),
                                      fontWeight: FontWeight.w500,
                                      fontSize: 14,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _translatedText.isNotEmpty ? _translatedText : '—',
                                    style: GoogleFonts.inter(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 16,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              // Speech Assistance Card
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF18191B),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Speech Assistance',
                          style: GoogleFonts.inter(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          children: [
                            _pillButton(
                              icon: Icons.record_voice_over,
                              label: 'Conversation Tips',
                              color: const Color(0xFF03A9F4),
                              onTap: _showConversationTips,
                            ),
                            _pillButton(
                              icon: Icons.hearing,
                              label: 'Live Translation',
                              color: const Color(0xFF03A9F4),
                              onTap: _showLiveTranslation,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _circleIconButton(IconData icon, {required VoidCallback onTap}) {
    return Material(
      color: const Color(0xFF222328),
      shape: const CircleBorder(),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: SizedBox(
          width: 40,
          height: 40,
          child: Icon(icon, color: Colors.white, size: 20),
        ),
      ),
    );
  }

  Widget _pillButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        height: 40,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Icon(icon, color: Colors.white, size: 20),
            ),
            Flexible(
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                softWrap: false,
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                  fontSize: 15,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
} 