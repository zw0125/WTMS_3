import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:wtms/model/Work.dart';
import 'dart:convert';
import 'package:wtms/model/workers.dart';
import 'package:wtms/myconfig.dart';

class SubmitWorkScreen extends StatefulWidget {
  final Work work;
  final Worker worker;

  const SubmitWorkScreen({Key? key, required this.work, required this.worker})
      : super(key: key);

  @override
  State<SubmitWorkScreen> createState() => _SubmitWorkScreenState();
}

class _SubmitWorkScreenState extends State<SubmitWorkScreen> {
  final _formKey = GlobalKey<FormState>();
  final _submissionController = TextEditingController();
  bool _isSubmitting = false;

  Future<void> _submitWork() async {
    if (!_formKey.currentState!.validate()) return;

    // Show confirmation dialog first
    final bool? confirmSubmit = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Submission'),
        content: const Text('Are you sure you want to submit this work?'),
        actions: [
          TextButton(
            child: const Text('Cancel'),
            onPressed: () => Navigator.pop(context, false),
          ),
          TextButton(
            child: const Text('Submit'),
            onPressed: () => Navigator.pop(context, true),
          ),
        ],
      ),
    );

    if (confirmSubmit != true) return;

    setState(() => _isSubmitting = true);

    try {
      final response = await http.post(
        Uri.parse('${MyConfig.MYURL}submit_work.php'),
        body: {
          'work_id': widget.work.id.toString(),
          'worker_id': widget.worker.id.toString(),
          'submission_text': _submissionController.text,
        },
      );

      if (!mounted) return;

      final data = json.decode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Work submitted successfully!'),
            backgroundColor: Colors.green,
          ),
        );

        // Return to previous screen with refresh flag
        if (mounted) {
          Navigator.of(context).pop(true);
        }
      } else {
        throw Exception(data['message'] ?? 'Failed to submit work');
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Submit Work'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context, false),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Task: ${widget.work.title}',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _submissionController,
                decoration: const InputDecoration(
                  labelText: 'What did you complete?',
                  border: OutlineInputBorder(),
                ),
                maxLines: 5,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your work completion details';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submitWork,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: _isSubmitting
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.white),
                              strokeWidth: 2,
                            ),
                          )
                        : const Text('Submit'),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
