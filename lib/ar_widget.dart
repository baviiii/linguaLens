import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';

/// for ar capabilities
class ArWidget extends StatefulWidget {
  const ArWidget({super.key});

  static String routeName = 'AR';
  static String routePath = '/ar';

  @override
  State<ArWidget> createState() => _ArWidgetState();
}

class _ArWidgetState extends State<ArWidget> {
  String _detectedText = 'Coffee Cup'; // Example detected object
  String _translatedText = 'Tasse à café'; // Example translation

  void _showConversationTips() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Conversation Tips', style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 12),
            Text('• Greet politely\n• Ask open-ended questions\n• Listen actively\n• Use simple language'),
          ],
        ),
      ),
    );
  }

  void _showLiveTranslation() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Live Translation', style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 12),
            Text('This feature will listen and translate in real time. (Demo)'),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      body: SafeArea(
        child: Stack(
          children: [
            // Main content
            SingleChildScrollView(
              child: Column(
                children: [
                  const SizedBox(height: 24),
                  // Lottie animation
                  Center(
                    child: SizedBox(
                      width: 180,
                      height: 180,
                      child: Lottie.asset('assets/jsons/ar_animation.json'),
                    ),
                  ),
                  const SizedBox(height: 24),
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
                                        _detectedText,
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
                                        _translatedText,
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
                            Row(
                              children: [
                                Expanded(
                                  child: _pillButton(
                                    icon: Icons.record_voice_over,
                                    label: 'Conversation Tips',
                                    color: const Color(0xFF03A9F4),
                                    onTap: _showConversationTips,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _pillButton(
                                    icon: Icons.hearing,
                                    label: 'Live Translation',
                                    color: const Color(0xFF03A9F4),
                                    onTap: _showLiveTranslation,
                                  ),
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
          ],
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
        height: 40,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min, // Allow the row to shrink
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 8, right: 4),
              child: Icon(icon, color: Colors.white, size: 16),
            ),
            Flexible(
              child: Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Text(
                  label,
                  overflow: TextOverflow.ellipsis, // Text will use ellipsis when overflowing
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                    fontSize: 13, // Slightly smaller font
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}