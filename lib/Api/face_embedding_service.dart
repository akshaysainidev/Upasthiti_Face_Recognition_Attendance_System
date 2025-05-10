import 'dart:io';
import 'dart:math';
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';

class FaceEmbeddingService {
  static const String _modelFile = 'mobilefacenet.tflite';
  static const int _inputSize = 112;
  static const int _embeddingSize = 128;
  
  late Interpreter _interpreter;

  Future<void> initialize() async {
    try {
      // Load model
      final modelPath = await _getModelPath();
      _interpreter = await Interpreter.fromAsset(modelPath);
      
      // Warm up model
      final input = List.filled(_inputSize * _inputSize * 3, 0.0)
          .reshape([1, _inputSize, _inputSize, 3]);
      final output = List.filled(_embeddingSize, 0.0).reshape([1, _embeddingSize]);
      _interpreter.run(input, output);
    } catch (e) {
      throw Exception('Failed to initialize face embedding service: $e');
    }
  }

  Future<String> _getModelPath() async {
    return _modelFile;
  }

  Future<List<double>> extractFaceEmbedding(File imageFile) async {
    try {
      // Load and preprocess image
      final imageBytes = await imageFile.readAsBytes();
      final image = img.decodeImage(imageBytes)!;
      
      // Resize and normalize
      final processedImage = img.copyResize(image, width: _inputSize, height: _inputSize);
      final input = _preprocessImage(processedImage);
      
      // Run inference
      final output = List.filled(_embeddingSize, 0.0).reshape([1, _embeddingSize]);
      _interpreter.run(input, output);
      
      // Normalize embedding
      final embedding = List<double>.from(output[0]);
      return _normalizeEmbedding(embedding);
    } catch (e) {
      throw Exception('Failed to extract face embedding: $e');
    }
  }

  List<List<List<List<double>>>> _preprocessImage(img.Image image) {
  // Create a 4D list with proper typing
  final input = List.generate(1, (_) => 
      List.generate(_inputSize, (_) => 
          List.generate(_inputSize, (_) => 
              List<double>.filled(3, 0.0))));
  
  for (var y = 0; y < image.height; y++) {
    for (var x = 0; x < image.width; x++) {
      final pixel = image.getPixel(x, y);
      input[0][y][x][0] = (pixel.r.toDouble() - 127.5) / 128.0;   // R
      input[0][y][x][1] = (pixel.g.toDouble() - 127.5) / 128.0;   // G
      input[0][y][x][2] = (pixel.b.toDouble() - 127.5) / 128.0;   // B
    }
  }
  
  return input;
}

  List<double> _normalizeEmbedding(List<double> embedding) {
    double norm = 0.0;
    for (var value in embedding) {
      norm += value * value;
    }
    norm = sqrt(norm);
    
    return embedding.map((value) => value / norm).toList();
  }

  void dispose() {
    _interpreter.close();
  }
}