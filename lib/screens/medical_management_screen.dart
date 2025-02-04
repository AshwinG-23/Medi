import 'dart:io';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';

class MedicalManagementScreen extends StatefulWidget {
  const MedicalManagementScreen({super.key});

  @override
  _MedicalManagementScreenState createState() =>
      _MedicalManagementScreenState();
}

class _MedicalManagementScreenState extends State<MedicalManagementScreen> {
  final _imagePicker = ImagePicker();
  Box? _prescriptionBox; // Nullable

  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _initializeHive();
  }

  Future<void> _initializeHive() async {
    _prescriptionBox = await Hive.openBox('prescriptions');
    setState(() {});
  }

  Future<void> _addPrescription() async {
    var status = await Permission.camera.request();
    if (status.isDenied) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Camera permission is required')),
      );
      return;
    }

    final pickedFile = await _imagePicker.pickImage(source: ImageSource.camera);
    if (pickedFile != null) {
      final tagsController = TextEditingController();
      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text('Add Tags'),
            content: TextField(
              controller: tagsController,
              decoration: const InputDecoration(
                  hintText: 'Enter tags separated by commas'),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  final tags = tagsController.text
                      .split(',')
                      .map((e) => e.trim().toLowerCase())
                      .toList();
                  final id = DateTime.now().toIso8601String();
                  _prescriptionBox!.put(id, {
                    'id': id,
                    'imagePath': pickedFile.path,
                    'tags': tags,
                    'timestamp': DateTime.now().toIso8601String(),
                  });
                  Navigator.of(context).pop();
                  setState(() {});
                },
                child: const Text('Save'),
              ),
            ],
          );
        },
      );
    }
  }

  List<Map<String, dynamic>> _getPrescriptions(String query) {
    if (_prescriptionBox == null) return [];

    final prescriptions =
        _prescriptionBox!.values.cast<Map<String, dynamic>>().toList();

    if (query.trim().isEmpty) return prescriptions;

    return prescriptions.where((item) {
      return (item['tags'] as List)
          .any((tag) => tag.toLowerCase().contains(query.toLowerCase()));
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _searchController,
          decoration: const InputDecoration(
            hintText: 'Search by tags',
            border: InputBorder.none,
          ),
          onChanged: (query) => setState(() {}),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.camera_alt),
            onPressed: _addPrescription,
          ),
        ],
      ),
      body: _prescriptionBox == null
          ? const Center(child: CircularProgressIndicator())
          : ValueListenableBuilder(
              valueListenable: _prescriptionBox!.listenable(),
              builder: (context, box, _) {
                final prescriptions = _getPrescriptions(_searchController.text);

                if (prescriptions.isEmpty) {
                  return const Center(child: Text('No prescriptions found.'));
                }

                return ListView.builder(
                  itemCount: prescriptions.length,
                  itemBuilder: (context, index) {
                    final prescription = prescriptions[index];
                    return Card(
                      margin: const EdgeInsets.all(8.0),
                      child: ListTile(
                        leading: File(prescription['imagePath']).existsSync()
                            ? Image.file(File(prescription['imagePath']),
                                width: 50, height: 50, fit: BoxFit.cover)
                            : const Icon(Icons.image_not_supported,
                                size: 50, color: Colors.grey),
                        title: Text(prescription['tags'].join(', ')),
                        subtitle: Text(prescription['timestamp']),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () {
                            _prescriptionBox!.delete(prescription['id']);
                            setState(() {});
                          },
                        ),
                      ),
                    );
                  },
                );
              },
            ),
    );
  }
}
