import 'dart:io';
import 'dart:typed_data';

import 'package:crop_your_image/crop_your_image.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image/image.dart' as img;

class ImagePreviewScreen extends StatefulWidget {
  final File imageFile;
  final Function(String) onTextExtracted;

  const ImagePreviewScreen({
    super.key,
    required this.imageFile,
    required this.onTextExtracted,
  });

  @override
  State<ImagePreviewScreen> createState() => _ImagePreviewScreenState();
}

class _ImagePreviewScreenState extends State<ImagePreviewScreen> {
  final CropController _controller = CropController();
  late Uint8List _imageData;
  bool _isCropping = false;

  @override
  void initState() {
    super.initState();
    _loadImageBytes();
  }

  Future<void> _loadImageBytes() async {
    _imageData = await widget.imageFile.readAsBytes();
    setState(() {});
  }

  Future<void> _cropAndRecognize(Uint8List croppedData) async {
    setState(() => _isCropping = true);

    final tempFile = File('${widget.imageFile.parent.path}/cropped_${DateTime.now().millisecondsSinceEpoch}.png');
    await tempFile.writeAsBytes(croppedData);

    final inputImage = InputImage.fromFile(tempFile);
    final textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);
    final RecognizedText recognizedText = await textRecognizer.processImage(inputImage);

    widget.onTextExtracted(recognizedText.text);
    textRecognizer.close();

    if (mounted) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Crop to OCR")),
      body: _imageData.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : Column(
        children: [
          Expanded(
            child: Crop(
              controller: _controller,
              image: _imageData,
              onCropped: _cropAndRecognize,
              withCircleUi: false,
              baseColor: Colors.black,
              maskColor: Colors.black.withAlpha(100),
              cornerDotBuilder: (size, index) => const DotControl(color: Colors.deepPurple),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: ElevatedButton.icon(
              onPressed: _isCropping ? null : () => _controller.crop(),
              icon: const Icon(Icons.crop),
              label: const Text("Crop & Recognize Text"),
            ),
          )
        ],
      ),
    );
  }
}
