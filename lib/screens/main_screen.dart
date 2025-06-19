import 'package:flutter/material.dart';
import 'package:wtms/model/workers.dart';
import 'package:wtms/screens/task_list_screen.dart';
import 'package:wtms/screens/submission_history_screen.dart';
import 'package:wtms/screens/profile_screen.dart';

class MainScreen extends StatefulWidget {
  final Worker worker;

  const MainScreen({Key? key, required this.worker}) : super(key: key);

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;
  late List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = [
      TaskListScreen(worker: widget.worker),
      SubmissionHistoryScreen(worker: widget.worker),
      ProfileScreen(worker: widget.worker),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.task), label: 'Tasks'),
          BottomNavigationBarItem(icon: Icon(Icons.history), label: 'History'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}
