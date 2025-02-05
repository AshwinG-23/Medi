import 'dart:io';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:intl/intl.dart';

class MedicalManagementScreen extends StatefulWidget {
  const MedicalManagementScreen({super.key});

  @override
  _MedicalManagementScreenState createState() => _MedicalManagementScreenState();
}

class _MedicalManagementScreenState extends State<MedicalManagementScreen> {
  final _imagePicker = ImagePicker();
  Box? _prescriptionBox;
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
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Camera permission is required')),
        );
      }
      return;
    }

    final pickedFile = await _imagePicker.pickImage(source: ImageSource.camera);
    if (pickedFile != null && mounted) {
      final tagsController = TextEditingController();
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: Colors.grey[900],
          title: const Text(
            'Add Tags',
            style: TextStyle(color: Colors.white),
          ),
          content: TextField(
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
          actions: [
            TextButton(
              onPressed: () {
                final tags = tagsController.text
                    .split(',')
                    .map((e) => e.trim().toLowerCase())
                    .where((e) => e.isNotEmpty)
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
              child: const Text('Save', style: TextStyle(color: Colors.deepOrange)),
            ),
          ],
        ),
      );
    }
  }

  List<Map<String, dynamic>> _getPrescriptions(String query) {
    if (_prescriptionBox == null) return [];

    final prescriptions = _prescriptionBox!.values
        .cast<Map<String, dynamic>>()
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text(
                'My Prescriptions',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.grey[900],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const SizedBox(width: 12),
                    Icon(Icons.search, color: Colors.grey[600]),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          hintText: 'Example "heart"',
                          hintStyle: TextStyle(color: Colors.grey[600]),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(vertical: 15),
                        ),
                        onChanged: (value) => setState(() {}),
                      ),
                    ),
                    Container(
                      margin: const EdgeInsets.all(8),
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.deepOrange,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Icon(Icons.tune, color: Colors.white, size: 20),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: _prescriptionBox == null
                  ? const Center(
                      child: CircularProgressIndicator(color: Colors.deepOrange))
                  : ValueListenableBuilder(
                      valueListenable: _prescriptionBox!.listenable(),
                      builder: (context, box, _) {
                        final prescriptions = _getPrescriptions(_searchController.text);

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
                            final prescription = prescriptions[index];
                            final date = DateFormat('dd/MM/yyyy').format(
                                DateTime.parse(prescription['timestamp']));
                            
                            return Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              decoration: BoxDecoration(
                                color: Colors.grey[900],
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: ListTile(
                                leading: Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: Colors.grey[800],
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.file(
                                      File(prescription['imagePath']),
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ),
                                title: Text(
                                  prescription['tags'].join(', '),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                subtitle: Text(
                                  date,
                                  style: TextStyle(color: Colors.grey[500]),
                                ),
                                trailing: IconButton(
                                  icon: const Icon(
                                    Icons.edit_outlined,
                                    color: Colors.deepOrange,
                                  ),
                                  onPressed: () {
                                    // Handle edit functionality
                                  },
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.deepOrange,
        onPressed: _addPrescription,
        child: const Icon(Icons.add),
      ),
    );
  }
}