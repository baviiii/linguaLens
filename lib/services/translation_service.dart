import 'dart:convert';
import 'package:http/http.dart' as http;

class TranslationService {
  // Offline dictionary for basic translations
  final Map<String, Map<String, Map<String, String>>> offlineDictionary = {
    'en': {
      'es': {
        'hello': 'hola',
        'world': 'mundo',
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
      },
      'fr': {
        'hello': 'bonjour',
        'world': 'monde',
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
      },
    },
  };

  // Supported languages map
  final Map<String, String> languages = {
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

  // Get offline translation
  String getOfflineTranslation(String text, String sourceLang, String targetLang) {
    final String lowerText = text.toLowerCase();
    
    if (offlineDictionary.containsKey(sourceLang) &&
        offlineDictionary[sourceLang]!.containsKey(targetLang) &&
        offlineDictionary[sourceLang]![targetLang]!.containsKey(lowerText)) {
      return offlineDictionary[sourceLang]![targetLang]![lowerText]!;
    }
    
    return text; // Return original text if no translation found
  }

  // Get online translation using Argos Translate API
  Future<String> getOnlineTranslation(
    String text,
    String sourceLang,
    String targetLang,
  ) async {
    try {
      final url = Uri.parse('https://translate.argosopentech.com/translate');
      
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'q': text,
          'source': sourceLang,
          'target': targetLang,
          'format': 'text',
        }),
      ).timeout(const Duration(seconds: 10));
      
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        return data['translatedText'];
      } else {
        throw Exception('Translation API returned status code ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Translation failed: $e');
    }
  }
}
