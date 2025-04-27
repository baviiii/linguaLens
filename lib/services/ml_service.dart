import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_mlkit_object_detection/google_mlkit_object_detection.dart';
import 'package:google_mlkit_image_labeling/google_mlkit_image_labeling.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart';

class MLService {
  // Singleton pattern
  static final MLService _instance = MLService._internal();
  factory MLService() => _instance;
  MLService._internal();

  ObjectDetector? _objectDetector;
  ImageLabeler? _imageLabeler;
  bool _isInitialized = false;

  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Initialize Object Detector
      final options = ObjectDetectorOptions(
        mode: DetectionMode.single,
        classifyObjects: true,
        multipleObjects: true,
      );
      _objectDetector = ObjectDetector(options: options);

      // Initialize Image Labeler (as a fallback)
      final imageLabelerOptions = ImageLabelerOptions(confidenceThreshold: 0.7);
      _imageLabeler = ImageLabeler(options: imageLabelerOptions);

      _isInitialized = true;
      debugPrint('ML Service initialized successfully');
    } catch (e) {
      debugPrint('Error initializing ML Service: $e');
      rethrow;
    }
  }

  Future<List<DetectedObject>> detectObjectsInImage(File imageFile) async {
    if (!_isInitialized) await initialize();
    
    try {
      final inputImage = InputImage.fromFile(imageFile);
      final objects = await _objectDetector?.processImage(inputImage) ?? [];
      
      // Log detection results
      for (final object in objects) {
        debugPrint('Detected object with ${object.labels.length} labels');
        for (final label in object.labels) {
          debugPrint('Label: ${label.text}, Confidence: ${label.confidence}');
        }
      }
      
      return objects;
    } catch (e) {
      debugPrint('Error detecting objects: $e');
      return [];
    }
  }

  Future<List<ImageLabel>> labelImage(File imageFile) async {
    if (!_isInitialized) await initialize();
    
    try {
      final inputImage = InputImage.fromFile(imageFile);
      final labels = await _imageLabeler?.processImage(inputImage) ?? [];
      
      // Log labeling results
      for (final label in labels) {
        debugPrint('Image label: ${label.label}, Confidence: ${label.confidence}');
      }
      
      return labels;
    } catch (e) {
      debugPrint('Error labeling image: $e');
      return [];
    }
  }

  // Get the most likely object name from detection results
  String getMostLikelyObjectName(List<DetectedObject> objects, List<ImageLabel> labels) {
    // First try from detected objects
    if (objects.isNotEmpty && objects.first.labels.isNotEmpty) {
      return objects.first.labels.first.text;
    }
    
    // Fallback to image labels if no objects detected
    if (labels.isNotEmpty) {
      return labels.first.label;
    }
    
    return "Unknown Object";
  }

  void dispose() {
    _objectDetector?.close();
    _imageLabeler?.close();
    _isInitialized = false;
  }
} 