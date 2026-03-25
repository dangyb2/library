import 'package:flutter/material.dart';

class Sidebar extends StatefulWidget {
  final String activePage;
  final Function(String) onNavigate;

  const Sidebar({
    super.key,
    required this.activePage,
    required this.onNavigate,
  });

  @override
  State<Sidebar> createState() => _SidebarState();
}

class _SidebarState extends State<Sidebar> {
  bool collapsed = false;
  bool showLabels = true;
  bool hoverToggle = false;
  String? hoveredId;

  final List<Map<String, dynamic>> navItems = [
    {"id": "dashboard", "label": "Tổng Quát", "icon": Icons.dashboard_outlined},
    {"id": "log_history", "label": "Lịch sử hệ thống", "icon": Icons.history_outlined},
    {"id": "notifications", "label": "Thông báo email", "icon": Icons.email_outlined},
    {"id": "books", "label": "Quản Lý Sách", "icon": Icons.menu_book_outlined},
    {"id": "members", "label": "Thành Viên", "icon": Icons.people_outline},
    {"id": "borrowing", "label": "Mượn / Trả", "icon": Icons.swap_horiz},
  ];

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [

        /// SIDEBAR
        AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          width: collapsed ? 80 : 250,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xFF1e1b4b),
                Color(0xFF312e81),
                Color(0xFF1e3a5f),
              ],
            ),
          ),
          child: Column(
            children: [
              _buildLogo(),

              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(10),
                  children: navItems
                      .map((item) => _navItem(item))
                      .toList(),
                ),
              ),
            ],
          ),
        ),

        /// TOGGLE BUTTON
        Positioned(
          right: -15,
          top: 24,
          child: Material(
            color: Colors.transparent,
            shape: const CircleBorder(),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              customBorder: const CircleBorder(),
              onHover: (value) {
                setState(() {
                  hoverToggle = value;
                });
              },
              onTap: _toggleSidebar,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 160),
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: hoverToggle
                      ? const Color(0xFF5B52F5)
                      : const Color(0xFF4F46E5),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 3),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: hoverToggle ? 10 : 8,
                      offset: Offset(0, 3),
                    )
                  ],
                ),
                child: Icon(
                  collapsed ? Icons.chevron_right : Icons.chevron_left,
                  color: Colors.white,
                  size: 18,
                ),
              ),
            ),
          ),
        )
      ],
    );
  }

  /// LOGO
  Widget _buildLogo() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 22),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.white10)),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              color: Colors.indigo.withOpacity(0.2),
            ),
            child: const Icon(
              Icons.local_library,
              color: Colors.indigoAccent,
            ),
          ),

          if (showLabels) ...[
            const SizedBox(width: 10),

            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "LibraManager",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                Text(
                  "Hệ thống thư viện",
                  style: TextStyle(
                    color: Colors.indigoAccent,
                    fontSize: 11,
                  ),
                ),
              ],
            )
          ]
        ],
      ),
    );
  }

  /// NAV ITEM
Widget _navItem(Map<String, dynamic> item) {
    final bool active = widget.activePage == item["id"];
    final bool hovered = hoveredId == item["id"];

    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onHover: (value) {
        setState(() {
          if (value) {
            hoveredId = item["id"];
          } else if (hoveredId == item["id"]) {
            hoveredId = null;
          }
        });
      },
      onTap: () => widget.onNavigate(item["id"]),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        margin: const EdgeInsets.only(bottom: 6),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: active
              ? Colors.white.withOpacity(0.15)
              : hovered
                  ? Colors.white.withOpacity(0.08)
                  : Colors.transparent,
        ),
        child: Row(
          children: [

            /// ICON
            Icon(
              item["icon"],
              size: 20,
              color: Colors.white,
            ),

            if (showLabels) ...[
              const SizedBox(width: 12),

              /// TEXT
              Text(
                item["label"],
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight:
                      active ? FontWeight.w600 : FontWeight.w400,
                ),
              ),

              const Spacer(),

              /// ACTIVE DOT
              if (active)
                const CircleAvatar(
                  radius: 3,
                  backgroundColor: Colors.indigoAccent,
                )
            ]
          ],
        ),
      ),
    );
  }

  void _toggleSidebar() {
    if (collapsed) {
      setState(() {
        collapsed = false;
      });
      Future.delayed(const Duration(milliseconds: 220), () {
        if (!mounted || collapsed) return;
        setState(() {
          showLabels = true;
        });
      });
    } else {
      setState(() {
        showLabels = false;
        collapsed = true;
      });
    }
  }
}
