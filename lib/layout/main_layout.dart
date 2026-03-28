import 'package:flutter/material.dart';
import 'package:my_app/pages/dashboard_page.dart';

import '../pages/audit_log_page.dart';
import '../pages/books_page.dart';
import '../pages/borrow_page.dart';
import '../pages/notification_email_page.dart';
import '../pages/readers_page.dart';
import '../widgets/sidebar.dart';

class MainLayout extends StatefulWidget {
  const MainLayout({super.key});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  String currentPage = 'dashboard';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          Sidebar(
            activePage: currentPage,
            onNavigate: (page) {
              setState(() {
                currentPage = page;
              });
            },
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(left: 17),
              child: Container(
                color: const Color(0xFFF1F5F9),
                child: _buildPage(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPage() {
    switch (currentPage) {
      case 'dashboard':
        return const DashboardPage();
      case 'log_history':
        return const AuditLogPage();
      case 'notifications':
        return const NotificationPage();
      case 'books':
        return const BooksPage();
      case 'members':
        return const ReadersPage();
      case 'borrowing':
        return const BorrowPage();
      default:
        return const Center(child: Text('Page not found'));
    }
  }
}
