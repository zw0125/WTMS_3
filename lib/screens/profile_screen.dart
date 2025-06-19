import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:wtms/model/workers.dart';
import 'package:wtms/screens/login_screen.dart';
import 'package:wtms/myconfig.dart';

class TaskOverview {
  final int total;
  final int completed;
  final int pending;
  final int overdue; // Add overdue field

  TaskOverview({
    required this.total,
    required this.completed,
    required this.pending,
    required this.overdue, // Add to constructor
  });

  factory TaskOverview.fromJson(Map<String, dynamic> json) {
    return TaskOverview(
      total: int.parse(json['total'] ?? '0'),
      completed: int.parse(json['completed'] ?? '0'),
      pending: int.parse(json['pending'] ?? '0'),
      overdue: int.parse(json['overdue'] ?? '0'), // Parse overdue
    );
  }
}

class ProfileScreen extends StatefulWidget {
  final Worker worker;

  const ProfileScreen({super.key, required this.worker});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _addressController;
  bool _isEditing = false;
  bool _isSaving = false;
  final ImagePicker _picker = ImagePicker();
  File? _imageFile;
  bool _isUploading = false;
  TaskOverview? _taskOverview;
  bool _isLoadingTasks = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.worker.fullName);
    _phoneController = TextEditingController(text: widget.worker.phone ?? '');
    _addressController = TextEditingController(
      text: widget.worker.address ?? '',
    );
    loadTaskOverview();
  }

  Future<void> _updateProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final response = await http.post(
        Uri.parse('${MyConfig.MYURL}update_profile.php'),
        body: {
          'worker_id': widget.worker.id.toString(),
          'full_name': _nameController.text,
          'phone': _phoneController.text,
          'address': _addressController.text,
        },
      );

      final data = json.decode(response.body);
      if (data['success']) {
        // Update local worker data
        setState(() {
          widget.worker.fullName = _nameController.text;
          widget.worker.phone = _phoneController.text;
          widget.worker.address = _addressController.text;
          _isEditing = false;
        });

        // Update stored worker data
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(
          'worker_data',
          json.encode(widget.worker.toJson()),
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Profile updated successfully'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } else {
        throw Exception(data['message']);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      setState(() => _isSaving = false);
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        setState(() {
          _imageFile = File(pickedFile.path);
          _uploadImage();
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error picking image: $e')));
    }
  }

  Future<void> _uploadImage() async {
    if (_imageFile == null) return;

    setState(() => _isUploading = true);

    try {
      // Create multipart request
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('${MyConfig.MYURL}upload_profile_image.php'),
      );

      // Add headers
      request.headers['Accept'] = 'application/json';

      // Add fields and file
      request.fields['worker_id'] = widget.worker.id.toString();
      request.files.add(
        await http.MultipartFile.fromPath('image', _imageFile!.path),
      );

      // Send request and handle response
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      // Debug response
      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success']) {
          setState(() {
            widget.worker.profileImage = data['image_url'];
          });

          // Update stored data
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString(
            'worker_data',
            json.encode(widget.worker.toJson()),
          );

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Profile picture updated successfully'),
                backgroundColor: Colors.green,
              ),
            );
          }
        } else {
          throw Exception(data['message'] ?? 'Upload failed');
        }
      } else {
        throw Exception('Server error: ${response.statusCode}');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error uploading image: $e')));
      }
    } finally {
      setState(() => _isUploading = false);
    }
  }

  void _showImageSourceDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Image Source'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Take Photo'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Choose from Gallery'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> loadTaskOverview() async {
    setState(() => _isLoadingTasks = true);

    try {
      print(
          'Fetching overview for worker ID: ${widget.worker.id}'); // Debug print

      final response = await http.post(
        Uri.parse('${MyConfig.MYURL}get_task_overview.php'),
        body: {'worker_id': widget.worker.id.toString()},
      );

      print('Task Overview Response: ${response.body}'); // Debug print

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success']) {
          setState(() {
            _taskOverview = TaskOverview.fromJson(data['overview']);
          });
          print('Parsed Overview: $_taskOverview'); // Debug print
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading task overview: $e')),
        );
      }
    } finally {
      setState(() => _isLoadingTasks = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Worker Profile'),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: Icon(_isEditing ? Icons.save : Icons.edit),
            onPressed: _isSaving
                ? null
                : () {
                    if (_isEditing) {
                      // Show confirmation dialog before saving
                      showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return AlertDialog(
                            title: const Text('Save Changes?'),
                            content: const Text(
                              'Are you sure you want to save these changes?',
                            ),
                            actions: [
                              TextButton(
                                child: const Text('Cancel'),
                                onPressed: () {
                                  Navigator.of(context).pop(); // Close dialog
                                },
                              ),
                              TextButton(
                                child: const Text('Save'),
                                onPressed: () {
                                  Navigator.of(context).pop(); // Close dialog
                                  _updateProfile(); // Save changes
                                },
                              ),
                            ],
                          );
                        },
                      );
                    } else {
                      setState(() => _isEditing = true);
                    }
                  },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              final prefs = await SharedPreferences.getInstance();
              await prefs.clear();
              if (mounted) {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                  (route) => false,
                );
              }
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Stack(
                children: [
                  CircleAvatar(
                    radius: 60,
                    backgroundColor: Colors.grey[200],
                    backgroundImage: _imageFile != null
                        ? FileImage(_imageFile!)
                        : (widget.worker.profileImage != null
                            ? NetworkImage(
                                '${MyConfig.MYURL}${widget.worker.profileImage}',
                              )
                            : null) as ImageProvider?,
                    child:
                        widget.worker.profileImage == null && _imageFile == null
                            ? const Icon(
                                Icons.person,
                                size: 60,
                                color: Colors.grey,
                              )
                            : null,
                  ),
                  if (_isUploading)
                    const Positioned.fill(child: CircularProgressIndicator()),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Theme.of(context).primaryColor,
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.camera_alt, color: Colors.white),
                        onPressed: _showImageSourceDialog,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _buildTaskOverviewCard(),
              _buildInfoField('Worker ID', widget.worker.id.toString(), null),
              _buildInfoField('Email', widget.worker.email, null),
              _buildInfoField(
                'Full Name',
                widget.worker.fullName,
                _nameController,
                validator: (value) =>
                    value?.isEmpty ?? true ? 'Name is required' : null,
              ),
              _buildInfoField(
                'Phone',
                widget.worker.phone ?? '',
                _phoneController,
              ),
              _buildInfoField(
                'Address',
                widget.worker.address ?? '',
                _addressController,
                maxLines: 3,
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoField(
    String label,
    String value,
    TextEditingController? controller, {
    String? Function(String?)? validator,
    int maxLines = 1,
  }) {
    // Add icons for each field
    IconData getFieldIcon() {
      switch (label) {
        case 'Worker ID':
          return Icons.badge;
        case 'Email':
          return Icons.email;
        case 'Full Name':
          return Icons.person;
        case 'Phone':
          return Icons.phone;
        case 'Address':
          return Icons.location_on;
        default:
          return Icons.info;
      }
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(getFieldIcon(), size: 20, color: Colors.grey),
              const SizedBox(width: 8),
              Text(label,
                  style: const TextStyle(fontSize: 14, color: Colors.grey)),
            ],
          ),
          const SizedBox(height: 4),
          if (controller != null && _isEditing)
            TextFormField(
              controller: controller,
              validator: validator,
              maxLines: maxLines,
              decoration: InputDecoration(
                border: const OutlineInputBorder(),
                prefixIcon: Icon(getFieldIcon(), color: Colors.grey),
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.only(left: 28),
              child: Text(
                value,
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          const Divider(),
        ],
      ),
    );
  }

  Widget _buildTaskOverviewCard() {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Task Overview',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            _isLoadingTasks
                ? const Center(child: CircularProgressIndicator())
                : Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildTaskStat(
                        'Total',
                        _taskOverview?.total ?? 0,
                        Colors.blue,
                      ),
                      _buildTaskStat(
                        'Completed',
                        _taskOverview?.completed ?? 0,
                        Colors.green,
                      ),
                      _buildTaskStat(
                        'Pending',
                        _taskOverview?.pending ?? 0,
                        Colors.orange,
                      ),
                      _buildTaskStat(
                        'Overdue',
                        _taskOverview?.overdue ?? 0,
                        Colors.red,
                      ),
                    ],
                  ),
          ],
        ),
      ),
    );
  }

  Widget _buildTaskStat(String label, int value, Color color) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            value.toString(),
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
      ],
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }
}
