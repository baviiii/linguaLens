import 'package:flutter/material.dart';
import 'package:arcore_flutter_plugin/arcore_flutter_plugin.dart';
import 'package:vector_math/vector_math_64.dart' as vector;
import 'dart:math' as math;

class ARService {
  ArCoreController? arCoreController;
  Function(String)? onObjectDetected;
  bool isDebug = true;

  Future<void> initializeAR() async {
    try {
      debugPrint('[ARService] Checking ARCore availability...');
      // Check if ARCore is available
      bool isAvailable = await ArCoreController.checkArCoreAvailability();
      if (!isAvailable) {
        debugPrint('[ARService] ARCore is not available on this device');
        throw Exception("ARCore is not available on this device");
      }
      
      debugPrint('[ARService] Checking if ARCore is installed...');
      // Check if AR services are installed
      bool isInstalled = await ArCoreController.checkIsArCoreInstalled();
      if (!isInstalled) {
        debugPrint('[ARService] ARCore is not installed');
        throw Exception("ARCore is not installed. Please install ARCore");
      }
      
      debugPrint('[ARService] ARCore checks passed');
    } catch (e) {
      debugPrint('[ARService] Error during AR initialization: $e');
      rethrow;
    }
  }

  void onArCoreViewCreated(ArCoreController controller) {
    debugPrint('[ARService] ArCoreController created');
    arCoreController = controller;
    
    // Set up plane detection
    arCoreController?.onPlaneTap = (hits) {
      debugPrint('[ARService] Plane tapped with ${hits.length} hit(s)');
      _handlePlaneTap(hits);
    };
    
    // Set up node tap
    arCoreController?.onNodeTap = (name) {
      debugPrint('[ARService] Node tapped: $name');
    };
    
    debugPrint('[ARService] AR view setup complete');
    
    // Test adding a simple sphere
    if (isDebug) {
      Future.delayed(Duration(seconds: 2), () {
        _addSphereAtOrigin();
        debugPrint('[ARService] Added debug sphere at origin');
      });
    }
  }

  void _addSphereAtOrigin() {
    final material = ArCoreMaterial(color: Colors.red);
    
    final sphere = ArCoreSphere(
      materials: [material],
      radius: 0.2,
    );
    
    final node = ArCoreNode(
      shape: sphere,
      position: vector.Vector3(0, 0, -1), // 1 meter in front of the camera
    );
    
    try {
      arCoreController?.addArCoreNode(node);
      debugPrint('[ARService] Debug sphere added successfully');
    } catch (e) {
      debugPrint('[ARService] Error adding debug sphere: $e');
    }
  }

  void _handlePlaneTap(List<ArCoreHitTestResult> hits) {
    if (hits.isEmpty) {
      debugPrint('[ARService] No hits detected on plane tap');
      return;
    }
    
    debugPrint('[ARService] Processing plane tap with ${hits.length} hits');
    final hit = hits.first;
    _addSphere(hit);
    
    // Simulate object detection after a delay
    Future.delayed(const Duration(seconds: 2), () {
      if (onObjectDetected != null) {
        // In a real app, this would use ML to detect the object
        final demoObjects = ["Coffee Cup", "Notebook", "Pen", "Keyboard", "Mouse"];
        final randomObject = demoObjects[math.Random().nextInt(demoObjects.length)];
        debugPrint('[ARService] Detected object: $randomObject');
        onObjectDetected!(randomObject);
      } else {
        debugPrint('[ARService] onObjectDetected callback is null');
      }
    });
  }
  
  void _addSphere(ArCoreHitTestResult hit) {
    debugPrint('[ARService] Adding sphere at hit position: ${hit.pose.translation}');
    final material = ArCoreMaterial(color: Color.fromARGB(200, 66, 134, 244));
    
    final sphere = ArCoreSphere(
      materials: [material],
      radius: 0.1,
    );
    
    final node = ArCoreNode(
      shape: sphere,
      position: hit.pose.translation,
      rotation: hit.pose.rotation,
    );
    
    try {
      arCoreController?.addArCoreNode(node);
      debugPrint('[ARService] Sphere added successfully');
    } catch (e) {
      debugPrint('[ARService] Error adding sphere: $e');
    }
  }

  Future<void> dispose() async {
    debugPrint('[ARService] Disposing AR resources');
    arCoreController?.dispose();
    arCoreController = null;
  }

  Future<void> startPlaneDetection() async {
    debugPrint('[ARService] Plane detection is enabled by default');
    // Plane detection is enabled by default in the ARCore view configuration
  }

  Future<void> stopPlaneDetection() async {
    debugPrint('[ARService] Stopping plane detection not applicable');
    // Not applicable in this implementation
  }

  Future<ArCoreHitTestResult?> hitTest(Offset position) async {
    debugPrint('[ARService] Hit testing is handled by the AR view');
    return null; // Hit testing is handled by the AR view
  }

  Future<void> addNode(ArCoreNode node) async {
    try {
      debugPrint('[ARService] Adding custom node');
      arCoreController?.addArCoreNode(node);
    } catch (e) {
      debugPrint('[ARService] Error adding custom node: $e');
    }
  }

  Future<void> removeNode(ArCoreNode node) async {
    try {
      debugPrint('[ARService] Removing node: ${node.name}');
      arCoreController?.removeNode(nodeName: node.name ?? '');
    } catch (e) {
      debugPrint('[ARService] Error removing node: $e');
    }
  }
} 