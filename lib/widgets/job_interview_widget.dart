import 'package:flutter/material.dart';

class JobInterviewWidget extends StatefulWidget {
  const JobInterviewWidget({super.key});

  @override
  State<JobInterviewWidget> createState() => _JobInterviewWidgetState();
}

class _JobInterviewWidgetState extends State<JobInterviewWidget> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.primary,
        title: const Text(
          'Job Interview',
          style: TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontFamily: 'Outfit',
          ),
        ),
        elevation: 2,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              _buildInterviewTipsCard(context),
              _buildCommonQuestionsCard(context),
              _buildPracticeCard(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInterviewTipsCard(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Material(
        elevation: 2,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Interview Tips',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 12),
                _buildTipItem(
                  context,
                  '1. Research the Company',
                  'Understand the company\'s mission, values, and recent developments.',
                ),
                _buildTipItem(
                  context,
                  '2. Prepare Your Answers',
                  'Practice common interview questions and prepare specific examples.',
                ),
                _buildTipItem(
                  context,
                  '3. Dress Professionally',
                  'Choose appropriate attire that matches the company culture.',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCommonQuestionsCard(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Material(
        elevation: 2,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Common Questions',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 12),
                _buildQuestionItem(
                  context,
                  'Tell me about yourself',
                  'Focus on your professional background and relevant experience.',
                ),
                _buildQuestionItem(
                  context,
                  'Why do you want to work here?',
                  'Show your knowledge of the company and align your goals with theirs.',
                ),
                _buildQuestionItem(
                  context,
                  'What are your strengths?',
                  'Highlight skills relevant to the position with specific examples.',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPracticeCard(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Material(
        elevation: 2,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Practice Interview',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 12),
                Text(
                  'Practice your interview skills with our AI-powered interview simulator.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: () {
                    // TODO: Implement practice interview
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    minimumSize: const Size(double.infinity, 45),
                  ),
                  child: const Text(
                    'Start Practice',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTipItem(BuildContext context, String title, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            description,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionItem(BuildContext context, String question, String tip) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            question,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            tip,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
} 