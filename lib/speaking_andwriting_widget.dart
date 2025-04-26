import 'package:flutter/material.dart';

class SpeakingAndWritingWidget extends StatefulWidget {
  const SpeakingAndWritingWidget({super.key});

  @override
  State<SpeakingAndWritingWidget> createState() => _SpeakingAndWritingWidgetState();
}

class _SpeakingAndWritingWidgetState extends State<SpeakingAndWritingWidget> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.primary,
        title: const Text(
          'Speaking & Writing',
          style: TextStyle(
            color: Colors.white,
            fontSize: 22,
          ),
        ),
        elevation: 2,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              _buildPracticeCard(
                context,
                'Personal Introduction',
                'Introduce yourself in 30 seconds',
                onPressed: () {
                  // TODO: Implement personal introduction practice
                },
              ),
              _buildPracticeCard(
                context,
                'Read Aloud',
                'Read the text aloud with correct pronunciation',
                onPressed: () {
                  // TODO: Implement read aloud practice
                },
              ),
              _buildPracticeCard(
                context,
                'Repeat Sentence',
                'Listen and repeat the sentence exactly as you hear it',
                onPressed: () {
                  // TODO: Implement repeat sentence practice
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPracticeCard(
    BuildContext context,
    String title,
    String description, {
    required VoidCallback onPressed,
  }) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Theme.of(context).colorScheme.outline,
            width: 2,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  description,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: SizedBox(
                  width: double.infinity,
                  height: 40,
                  child: ElevatedButton(
                    onPressed: onPressed,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'Start Practice',
                      style: TextStyle(
                        color: Colors.white,
                      ),
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
} 