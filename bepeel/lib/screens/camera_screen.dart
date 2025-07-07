import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:video_player/video_player.dart';

class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  File? _mediaFile;
  bool _isVideo = false;
  VideoPlayerController? _videoController;
  final TextEditingController _captionController = TextEditingController();
  final ImagePicker _picker = ImagePicker();

  @override
  void dispose() {
    _videoController?.dispose();
    _captionController.dispose();
    super.dispose();
  }

  Future<void> _pickMedia() async {
    try {
      if (_isVideo) {
        final XFile? pickedVideo = await _picker.pickVideo(source: ImageSource.gallery);
        if (pickedVideo != null) {
          _videoController?.dispose();
          _videoController = VideoPlayerController.file(File(pickedVideo.path))
            ..initialize().then((_) {
              setState(() {});
              _videoController?.play();
            });
          setState(() {
            _mediaFile = File(pickedVideo.path);
          });
        }
      } else {
        final XFile? pickedImage = await _picker.pickImage(source: ImageSource.gallery);
        if (pickedImage != null) {
          setState(() {
            _mediaFile = File(pickedImage.path);
            _videoController?.dispose();
            _videoController = null;
          });
        }
      }
    } catch (e) {
      print('Error picking media: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with title and media type toggle
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Create a Post',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  ToggleButtons(
                    isSelected: [!_isVideo, _isVideo],
                    onPressed: (index) {
                      setState(() {
                        _isVideo = index == 1;
                        _mediaFile = null;
                        _videoController?.dispose();
                        _videoController = null;
                      });
                    },
                    children: const [
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
                        child: Icon(Icons.photo_camera, color: Colors.white),
                      ),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
                        child: Icon(Icons.videocam, color: Colors.white),
                      ),
                    ],
                    borderRadius: BorderRadius.circular(20),
                    selectedColor: Colors.blue,
                    fillColor: Colors.blue.withOpacity(0.2),
                    borderColor: Colors.grey,
                    selectedBorderColor: Colors.blue,
                  ),
                ],
              ),
            ),
            
            // Media upload area - takes up available space
            Expanded(
              child: GestureDetector(
                onTap: _pickMedia,
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16.0),
                  width: double.infinity,
                  constraints: const BoxConstraints(
                    maxHeight: 400,
                  ),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: _mediaFile == null
                      ? Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              _isVideo ? Icons.videocam : Icons.camera_alt,
                              color: Colors.grey,
                              size: 64,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _isVideo ? 'Upload Video' : 'Upload Photo',
                              style: const TextStyle(
                                color: Colors.grey,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        )
                      : _isVideo
                          ? _videoController != null &&
                                  _videoController!.value.isInitialized
                              ? AspectRatio(
                                  aspectRatio: _videoController!.value.aspectRatio,
                                  child: Stack(
                                    alignment: Alignment.center,
                                    children: [
                                      VideoPlayer(_videoController!),
                                      FloatingActionButton(
                                        mini: true,
                                        onPressed: () {
                                          setState(() {
                                            _videoController!.value.isPlaying
                                                ? _videoController!.pause()
                                                : _videoController!.play();
                                          });
                                        },
                                        child: Icon(
                                          _videoController!.value.isPlaying
                                              ? Icons.pause
                                              : Icons.play_arrow,
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                              : const Center(child: CircularProgressIndicator())
                          : ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: Image.file(
                                _mediaFile!,
                                fit: BoxFit.cover,
                                width: double.infinity,
                                height: double.infinity,
                              ),
                            ),
                ),
              ),
            ),
            
            // Caption input and Create button
            Container(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: _captionController,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      hintText: 'Add a caption',
                      hintStyle: TextStyle(color: Colors.grey),
                      enabledBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: Colors.grey),
                      ),
                      focusedBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: Colors.white),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () {
                        if (_mediaFile != null) {
                          Navigator.of(context).pop({
                            'media': _mediaFile,
                            'isVideo': _isVideo,
                            'caption': _captionController.text.isEmpty 
                                ? 'My new post!' 
                                : _captionController.text,
                          });
                        } else {
                          // Show error if no media is selected
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Please select a photo or video first'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      },
                      child: const Text(
                        'Create',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
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
} 