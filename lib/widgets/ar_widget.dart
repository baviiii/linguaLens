import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:arcore_flutter_plugin/arcore_flutter_plugin.dart';
import '../services/ar_service.dart';

class ARWidget extends StatefulWidget {
  const ARWidget({super.key});

  static String routeName = 'AR';
  static String routePath = '/ar';

  @override
  State<ARWidget> createState() => _ARWidgetState();
}

class _ARWidgetState extends State<ARWidget> {
  bool _isLoading = false;
  String? _error;
  final scaffoldKey = GlobalKey<ScaffoldState>();
  String _sourceLanguage = 'en';
  String _targetLanguage = 'es';
  String _detectedText = '';
  String _translatedText = '';
  
  late final ARService _arService;
  bool _isARView = false;
  bool _isInitialized = false;

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
    _requestCameraPermission();
  }

  Future<void> _requestCameraPermission() async {
    final status = await Permission.camera.request();
    if (status.isGranted) {
      _initializeAR();
    } else {
      setState(() {
        _error = 'Camera permission is required to use AR features';
      });
    }
  }

  Future<void> _initializeAR() async {
    setState(() => _isLoading = true);
    try {
      await _arService.initializeAR();
      setState(() {
        _isInitialized = true;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to initialize AR: $e';
        _isLoading = false;
      });
    }
  }

  void _toggleARView() {
    setState(() {
      _isARView = !_isARView;
    });
  }

  Widget _buildARView() {
    return Stack(
      children: [
        ArCoreView(
          onArCoreViewCreated: _onArCoreViewCreated,
          enableTapRecognizer: true,
          enablePlaneRenderer: true,
        ),
        Positioned(
          top: 20,
          right: 20,
          child: IconButton(
            icon: const Icon(Icons.close, color: Colors.white),
            onPressed: _toggleARView,
          ),
        ),
      ],
    );
  }

  void _onArCoreViewCreated(ArCoreController controller) {
    _arService.arCoreController = controller;
  }

  void _showConversationTips() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF18191B),
      shape: RoundedRectangleBorder(
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
      shape: RoundedRectangleBorder(
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

  @override
  void dispose() {
    _arService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_isARView) {
      return _buildARView();
    }

    final theme = Theme.of(context);
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
                        _circleIconButton(Icons.history, onTap: () {/* TODO: History */}),
                        const SizedBox(width: 10),
                        _circleIconButton(Icons.language, onTap: () {/* TODO: Language */}),
                        const SizedBox(width: 10),
                        _circleIconButton(Icons.mic, onTap: () {/* TODO: Mic */}),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              // Glowing Center Button
              GestureDetector(
                onTap: _toggleARView,
                child: Center(
                  child: SizedBox(
                    width: 180,
                    height: 180,
                    child: Lottie.asset('assets/jsons/ar_animation.json'),
                  ),
                ),
              ),
              // Scan Object Button
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                child: SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton.icon(
                    onPressed: () {/* TODO: Scan Object */},
                    icon: const Icon(Icons.camera_alt, color: Colors.white),
                    label: Text(
                      'Scan Object',
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 18,
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
                              onPressed: () {/* TODO: Settings */},
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