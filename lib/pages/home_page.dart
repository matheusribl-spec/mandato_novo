import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mandato_novo/pages/dashboard_page.dart';
import 'package:mandato_novo/pages/feed_page.dart';
import 'package:mandato_novo/pages/profile_page.dart';
import 'package:mandato_novo/pages/preferences_page.dart';
import 'package:mandato_novo/services/app_state.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;

  static const List<Widget> _pages = [
    FeedPage(),
    DashboardPage(),
    ProfilePage(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final userName = context.watch<AppState>().userName;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mandato'),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF111827),
        centerTitle: false,
        elevation: 0,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: IconButton(
              icon: const Icon(Icons.settings),
              tooltip: 'Preferências',
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const PreferencesPage()));
              },
            ),
          )
        ],
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
            ),
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Dashboard de insights', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF111827))),
                const SizedBox(height: 6),
                Text(
                  'Bem-vindo, $userName — explore notícias políticas, fontes e temas com facilidade.',
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
          Expanded(child: _pages[_selectedIndex]),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.feed), label: 'Feed'),
          BottomNavigationBarItem(icon: Icon(Icons.bar_chart), label: 'Analytics'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}
