import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:wtms/model/workers.dart';
import 'package:wtms/myconfig.dart';

class Submission {
  final int id;
  final String workTitle;
  final String workDescription;
  final String submissionText;
  final DateTime submissionDate;
  final DateTime dueDate;
  final String status;

  Submission({
    required this.id,
    required this.workTitle,
    required this.workDescription,
    required this.submissionText,
    required this.submissionDate,
    required this.dueDate,
    required this.status,
  });

  factory Submission.fromJson(Map<String, dynamic> json) {
    return Submission(
      id: int.parse(json['id'].toString()),
      workTitle: json['work_title'] ?? 'Untitled Work',
      workDescription: json['work_description'] ?? 'No description provided',
      submissionText: json['submission_text'] ?? 'No details provided',
      submissionDate: DateTime.parse(json['submission_date']),
      dueDate: DateTime.parse(json['due_date']),
      status: json['status'] ?? 'pending',
    );
  }
}

class SubmissionHistoryScreen extends StatefulWidget {
  final Worker worker;

  const SubmissionHistoryScreen({Key? key, required this.worker})
      : super(key: key);

  @override
  State<SubmissionHistoryScreen> createState() =>
      _SubmissionHistoryScreenState();
}

class _SubmissionHistoryScreenState extends State<SubmissionHistoryScreen> {
  List<Submission> _submissions = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadSubmissions();
  }

  Future<void> _loadSubmissions() async {
    try {
      final response = await http.post(
        Uri.parse('${MyConfig.MYURL}get_submissions.php'),
        body: {'worker_id': widget.worker.id.toString()},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success']) {
          setState(() {
            _submissions = (data['submissions'] as List)
                .map((sub) => Submission.fromJson(sub))
                .toList();
            _isLoading = false;
            _error = null;
          });
        } else {
          throw Exception(data['message'] ?? 'Failed to load submissions');
        }
      } else {
        throw Exception('Server error: ${response.statusCode}');
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _editSubmission(Submission submission) async {
    final TextEditingController editController = TextEditingController(
      text: submission.submissionText,
    );
    final formKey = GlobalKey<FormState>();
    bool isUpdating = false;

    final bool? result = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Edit Submission'),
          content: Form(
            key: formKey,
            child: TextFormField(
              controller: editController,
              maxLines: 5,
              decoration: const InputDecoration(
                labelText: 'Submission Details',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter submission details';
                }
                return null;
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: isUpdating
                  ? null
                  : () async {
                      if (!formKey.currentState!.validate()) return;

                      final confirmed = await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Confirm Changes'),
                          content: const Text(
                            'Are you sure you want to save these changes?',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(
                                context,
                                false,
                              ),
                              child: const Text('Cancel'),
                            ),
                            ElevatedButton(
                              onPressed: () => Navigator.pop(
                                context,
                                true,
                              ),
                              child: const Text('Save'),
                            ),
                          ],
                        ),
                      );

                      if (confirmed != true) return;

                      setState(() => isUpdating = true);

                      try {
                        final response = await http.post(
                          Uri.parse(
                            '${MyConfig.MYURL}edit_submission.php',
                          ),
                          body: {
                            'submission_id': submission.id.toString(),
                            'updated_text': editController.text,
                          },
                        );

                        final data = json.decode(response.body);
                        if (data['success']) {
                          Navigator.pop(context, true);
                        } else {
                          throw Exception(data['message']);
                        }
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Error: $e'),
                            backgroundColor: Colors.red,
                          ),
                        );
                        Navigator.pop(context, false);
                      }
                    },
              child: isUpdating
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                      ),
                    )
                  : const Text('Save Changes'),
            ),
          ],
        ),
      ),
    );

    if (result == true) {
      await _loadSubmissions(); // Refresh the list

      // Show success SnackBar
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Submission updated successfully'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Submission History'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh submissions',
            onPressed: () {
              setState(() {
                _isLoading = true;
                _error = null;
              });
              _loadSubmissions();
            },
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Icon(Icons.hourglass_empty, color: Colors.grey),
                SizedBox(width: 8),
                Text('Loading submissions...'),
              ],
            ),
          ],
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 80,
              color: Colors.redAccent,
            ),
            const SizedBox(height: 16),
            Text(
              'Oops! Something went wrong',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Colors.redAccent,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                setState(() {
                  _isLoading = true;
                  _error = null;
                });
                _loadSubmissions();
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Try Again'),
              style: ElevatedButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      );
    }

    if (_submissions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.assignment_outlined,
              size: 100,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No Submissions Yet',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Colors.grey[600],
                  ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.info_outline, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 8),
                Text(
                  'Your submitted work will appear here',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ],
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: _submissions.length,
      padding: const EdgeInsets.all(16),
      itemBuilder: (context, index) {
        final submission = _submissions[index];
        return Card(
          elevation: 2,
          margin: const EdgeInsets.only(bottom: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: submission.status == 'completed'
                          ? Colors.green[100]
                          : Colors.orange[100],
                      child: Icon(
                        submission.status == 'completed'
                            ? Icons.check_circle
                            : Icons.pending,
                        color: submission.status == 'completed'
                            ? Colors.green
                            : Colors.orange,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            submission.workTitle,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Status: ${submission.status}',
                            style: TextStyle(
                              color: submission.status == 'completed'
                                  ? Colors.green
                                  : Colors.orange,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const Divider(height: 24),

                // Task Description
                Text(
                  'Task Description:',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[700],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  submission.workDescription,
                  style: TextStyle(
                    color: Colors.grey[600],
                    height: 1.5,
                  ),
                ),

                const SizedBox(height: 16),

                // Dates Section
                Row(
                  children: [
                    Icon(Icons.calendar_today, size: 16, color: Colors.red),
                    const SizedBox(width: 8),
                    Text(
                      'Due: ${submission.dueDate.toString().split(' ')[0]}',
                      style: const TextStyle(color: Colors.red),
                    ),
                    const SizedBox(width: 16),
                    Icon(Icons.access_time, size: 16, color: Colors.green),
                    const SizedBox(width: 8),
                    Text(
                      'Submitted: ${submission.submissionDate.toString().split(' ')[0]}',
                      style: TextStyle(color: Colors.green),
                    ),
                  ],
                ),

                const Divider(height: 24),

                // Submission Details
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Submission Details',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[700],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.edit),
                      onPressed: () => _editSubmission(submission),
                      tooltip: 'Edit submission',
                      color: Colors.blue,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  submission.submissionText,
                  style: const TextStyle(height: 1.5),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
