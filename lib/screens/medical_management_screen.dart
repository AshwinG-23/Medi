import 'dart:io';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:intl/intl.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/services.dart';
import 'package:photo_view/photo_view.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';

class MedicalManagementScreen extends StatefulWidget {
  const MedicalManagementScreen({super.key});

  @override
  _MedicalManagementScreenState createState() =>
      _MedicalManagementScreenState();
}

class _MedicalManagementScreenState extends State<MedicalManagementScreen>
    with SingleTickerProviderStateMixin {
  final _imagePicker = ImagePicker();
  Box? _prescriptionBox;
  final TextEditingController _searchController = TextEditingController();
  late AnimationController _animationController;
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    _initializeHive();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _initializeHive() async {
    _prescriptionBox = await Hive.openBox('prescriptions');
    setState(() {});
  }

  void _viewCompleteDocument(String filePath) {
    if (filePath.toLowerCase().endsWith('.pdf')) {
      // Handle PDF files
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => Scaffold(
            backgroundColor: const Color.fromARGB(255, 30, 30, 30),
            appBar: AppBar(
              backgroundColor: const Color.fromARGB(255, 30, 30, 30),
              leading: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
            body: PDFView(
              filePath: filePath,
              enableSwipe: true,
              swipeHorizontal: true,
              autoSpacing: true,
              pageFling: true,
              onRender: (pages) {
                // Called when the PDF is rendered
              },
              onError: (error) {
                // Handle errors
                print(error.toString());
              },
              onPageError: (page, error) {
                // Handle page-specific errors
                print('$page: ${error.toString()}');
              },
            ),
          ),
        ),
      );
    } else {
      // Handle image files
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => Scaffold(
            backgroundColor: const Color.fromARGB(255, 30, 30, 30),
            appBar: AppBar(
              backgroundColor: const Color.fromARGB(255, 30, 30, 30),
              leading: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
            body: PhotoView(
              imageProvider: FileImage(File(filePath)),
              minScale: PhotoViewComputedScale.contained,
              maxScale: PhotoViewComputedScale.covered * 2,
              backgroundDecoration: const BoxDecoration(color: Colors.black),
            ),
          ),
        ),
      );
    }
  }

  Future<void> _handleStorageSelection() async {
    try {
      // Check and request storage permission
      var status = await Permission.storage.status;
      if (!status.isGranted) {
        status = await Permission.storage.request();
      }

      if (status.isGranted) {
        final result = await FilePicker.platform.pickFiles(
          type: FileType.custom,
          allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf', 'doc', 'docx'],
        );

        if (result != null && result.files.single.path != null && mounted) {
          _showNameAndTagsDialog(result.files.single.path!);
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Storage permission is required')),
          );
        }
      }
    } on PlatformException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.message}')),
        );
      }
    }
  }

  Future<void> _handleImageSelection(ImageSource source) async {
    Permission permission =
        source == ImageSource.camera ? Permission.camera : Permission.photos;

    var status = await permission.status;
    if (!status.isGranted) {
      status = await permission.request();
    }

    if (status.isGranted) {
      final pickedFile = await _imagePicker.pickImage(source: source);
      if (pickedFile != null && mounted) {
        _showNameAndTagsDialog(pickedFile.path);
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Permission is required')),
        );
      }
    }
  }

  void _showNameAndTagsDialog(String filePath) {
    final nameController = TextEditingController();
    final tagsController = TextEditingController();
    showDialog(
      context: context,
      barrierDismissible: false, // Prevent closing by tapping outside
      builder: (BuildContext dialogContext) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text(
          'Add Name and Tags',
          style: TextStyle(color: Colors.white),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Enter prescription name',
                hintStyle: TextStyle(color: Colors.grey[400]),
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.grey[700]!),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: tagsController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Enter tags separated by commas',
                hintStyle: TextStyle(color: Colors.grey[400]),
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.grey[700]!),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () async {
              if (nameController.text.trim().isNotEmpty &&
                  tagsController.text.trim().isNotEmpty) {
                final name = nameController.text.trim();
                final tags = tagsController.text
                    .split(',')
                    .map((e) => e.trim().toLowerCase())
                    .where((e) => e.isNotEmpty)
                    .toList();
                final id = DateTime.now().toIso8601String();

                final prescription = {
                  'id': id,
                  'name': name,
                  'imagePath': filePath,
                  'tags': tags,
                  'timestamp': DateTime.now().toIso8601String(),
                };

                await _prescriptionBox?.put(id, prescription);

                // Close dialog using dialogContext
                if (mounted) {
                  Navigator.of(dialogContext).pop();

                  // Show success message
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Prescription saved successfully'),
                      backgroundColor: Colors.green,
                    ),
                  );

                  // Force refresh
                  setState(() {});
                }
              } else {
                // Show error for empty fields
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please enter a name and at least one tag'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child:
                const Text('Save', style: TextStyle(color: Colors.deepOrange)),
          ),
        ],
      ),
    );
  }

  Widget _buildPrescriptionCard(Map<String, dynamic> prescription) {
    final date = DateFormat('dd/MM/yyyy')
        .format(DateTime.parse(prescription['timestamp']));
    final name = prescription['name'];
    final tags = prescription['tags'] as List;
    final title = '$name Prescription';
    final isPdf = prescription['imagePath'].toLowerCase().endsWith('.pdf');

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF302D2D),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black,
            spreadRadius: 0.01,
            blurRadius: 5,
            offset: const Offset(0, 9),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(Icons.description_outlined,
                    color: const Color(0xFFE38233), size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        tags.join(', '),
                        style: TextStyle(
                          color: Colors.grey[500],
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(date, style: TextStyle(color: Colors.grey[500])),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16), // Add padding around the Stack
            child: Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  height: 150,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    border: Border.symmetric(
                      horizontal:
                          BorderSide(color: Colors.grey[800]!, width: 1),
                    ),
                  ),
                  child: isPdf
                      ? Center(
                          child: Icon(Icons.picture_as_pdf,
                              color: const Color(0xFFE38233), size: 64),
                        )
                      : ClipRRect(
                          borderRadius: BorderRadius.circular(
                              20), // Add border radius here
                          child: Image.file(
                            File(prescription['imagePath']),
                            fit: BoxFit.cover,
                          ),
                        ),
                ),
                Positioned(
                  bottom: 10,
                  left: 20,
                  right: 20,
                  child: ElevatedButton(
                    onPressed: () =>
                        _viewCompleteDocument(prescription['imagePath']),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black.withOpacity(0.8),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      elevation: 4,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(isPdf ? Icons.picture_as_pdf : Icons.list_alt,
                            color: Colors.orange),
                        const SizedBox(width: 8),
                        Text(
                          isPdf ? "View PDF" : "View Document",
                          style: TextStyle(
                            color: Colors.orange,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 30, 30, 30),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  const Text(
                    'Medical Prescriptions',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.grey,
                  borderRadius: BorderRadius.circular(17),
                ),
                child: TextField(
                  controller: _searchController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Example "heart"',
                    hintStyle: TextStyle(color: Colors.black),
                    prefixIcon: Icon(Icons.search, color: Colors.grey[600]),
                    suffixIcon: Container(
                      margin: const EdgeInsets.all(8),
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE38233),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child:
                          const Icon(Icons.tune, color: Colors.white, size: 20),
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 15),
                  ),
                  onChanged: (value) => setState(() {}),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: _prescriptionBox == null
                  ? const Center(
                      child:
                          CircularProgressIndicator(color: Color(0xFFE38233)))
                  : ValueListenableBuilder(
                      valueListenable: _prescriptionBox!.listenable(),
                      builder: (context, box, _) {
                        final prescriptions =
                            _getPrescriptions(_searchController.text);

                        if (prescriptions.isEmpty) {
                          return Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.description_outlined,
                                    size: 64, color: Colors.grey[600]),
                                const SizedBox(height: 16),
                                Text(
                                  'No prescriptions found',
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }

                        return ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: prescriptions.length,
                          itemBuilder: (context, index) {
                            return _buildPrescriptionCard(prescriptions[index]);
                          },
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
      floatingActionButton: Flow(
        delegate: FlowMenuDelegate(animation: _animationController),
        children: [
          FloatingActionButton(
            heroTag: 'storage',
            backgroundColor: Colors.grey,
            onPressed: _handleStorageSelection,
            child: const Icon(Icons.folder),
          ),
          FloatingActionButton(
            heroTag: 'gallery',
            backgroundColor: Colors.grey,
            child: const Icon(Icons.photo_library),
            onPressed: () => _handleImageSelection(ImageSource.gallery),
          ),
          FloatingActionButton(
            heroTag: 'camera',
            backgroundColor: Colors.grey,
            child: const Icon(Icons.camera_alt),
            onPressed: () => _handleImageSelection(ImageSource.camera),
          ),
          FloatingActionButton(
            heroTag: 'main',
            backgroundColor: const Color(0xFFE38233),
            child: AnimatedIcon(
              icon: AnimatedIcons.menu_close,
              progress: _animationController,
            ),
            onPressed: () {
              setState(() {
                _isExpanded = !_isExpanded;
                if (_isExpanded) {
                  _animationController.forward();
                } else {
                  _animationController.reverse();
                }
              });
            },
          ),
        ],
      ),
    );
  }

  List<Map<String, dynamic>> _getPrescriptions(String query) {
    if (_prescriptionBox == null) return [];

    final prescriptions = _prescriptionBox!.values
        .map((item) {
          // Convert Map<dynamic, dynamic> to Map<String, dynamic>
          final map = item as Map<dynamic, dynamic>;
          return map.map<String, dynamic>(
            (key, value) => MapEntry(key.toString(), value),
          );
        })
        .toList()
        .where((item) => File(item['imagePath']).existsSync())
        .toList();

    prescriptions.sort((a, b) => b['timestamp'].compareTo(a['timestamp']));

    if (query.trim().isEmpty) return prescriptions;

    return prescriptions.where((item) {
      return (item['tags'] as List)
          .any((tag) => tag.toLowerCase().contains(query.toLowerCase()));
    }).toList();
  }
}

class FlowMenuDelegate extends FlowDelegate {
  final Animation<double> animation;

  FlowMenuDelegate({required this.animation}) : super(repaint: animation);

  @override
  void paintChildren(FlowPaintingContext context) {
    final size = context.size;
    final xStart = size.width - 56; // Horizontal position (right side)
    final yStart =
        size.height - 76; // Shift buttons higher by reducing this value

    for (int i = 0; i < context.childCount; i++) {
      final childSize = context.getChildSize(i)?.width ?? 56;
      final isLastItem = i == context.childCount - 1;

      if (isLastItem) {
        // Position the main button (last item)
        context.paintChild(
          i,
          transform: Matrix4.translationValues(xStart, yStart, 0),
        );
      } else {
        // Position the other buttons with an offset
        final offset = 70.0 * (i + 1) * animation.value;
        context.paintChild(
          i,
          transform: Matrix4.translationValues(xStart, yStart - offset, 0),
        );
      }
    }
  }

  @override
  bool shouldRepaint(FlowMenuDelegate oldDelegate) {
    return animation != oldDelegate.animation;
  }
}
