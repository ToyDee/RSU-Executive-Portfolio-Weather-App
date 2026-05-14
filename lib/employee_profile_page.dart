import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class EmployeeProfilePage extends StatelessWidget {
  final Map<String, dynamic> employee;

  const EmployeeProfilePage({super.key, required this.employee});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F8),
      body: CustomScrollView(
        slivers: [
          // IMPROVEMENT: collapsible hero header
          SliverAppBar(
            expandedHeight: 240,
            pinned: true,
            backgroundColor: const Color(0xFF1B5E20),
            iconTheme: const IconThemeData(color: Colors.white),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF1B5E20), Color(0xFF388E3C)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 48),
                    CircleAvatar(
                      radius: 52,
                      backgroundColor: Colors.white,
                      child: CircleAvatar(
                        radius: 48,
                        backgroundImage: AssetImage(
                            'Assets/Images/${employee['id']}.jpg'),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      employee['name'] ?? '',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      employee['position'] ?? '',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.85),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Contact card
                  _SectionCard(
                    title: 'Contact Information',
                    children: [
                      _ContactRow(
                        icon: Icons.person_outline,
                        label: 'Secretary',
                        value: employee['secretary'],
                      ),
                      _ContactRow(
                        icon: Icons.phone_outlined,
                        label: 'Phone',
                        value: employee['phone'],
                        // IMPROVEMENT: tap to copy
                        onTap: employee['phone'] != null &&
                            employee['phone'] != '-'
                            ? () {
                          Clipboard.setData(
                              ClipboardData(text: employee['phone']));
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: const Text('Phone number copied'),
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(
                                  borderRadius:
                                  BorderRadius.circular(10)),
                              backgroundColor: const Color(0xFF1B5E20),
                            ),
                          );
                        }
                            : null,
                      ),
                      _ContactRow(
                        icon: Icons.print_outlined,
                        label: 'Fax',
                        value: employee['fax'],
                      ),
                      _ContactRow(
                        icon: Icons.email_outlined,
                        label: 'Email',
                        value: employee['email'],
                        isLast: true,
                        onTap: employee['email'] != null &&
                            employee['email'] != '-'
                            ? () {
                          Clipboard.setData(
                              ClipboardData(text: employee['email']));
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: const Text('Email copied'),
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(
                                  borderRadius:
                                  BorderRadius.circular(10)),
                              backgroundColor: const Color(0xFF1B5E20),
                            ),
                          );
                        }
                            : null,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Section card ──────────────────────────────────────────────────────────────
class _SectionCard extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _SectionCard({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title.toUpperCase(),
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: Colors.grey.shade500,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(children: children),
        ),
      ],
    );
  }
}

// ── Contact row ───────────────────────────────────────────────────────────────
class _ContactRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? value;
  final bool isLast;
  final VoidCallback? onTap;

  const _ContactRow({
    required this.icon,
    required this.label,
    required this.value,
    this.isLast = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final displayValue = (value == null || value!.isEmpty) ? '-' : value!;
    final isNA = displayValue == '-';

    return InkWell(
      onTap: onTap,
      borderRadius: isLast
          ? const BorderRadius.vertical(bottom: Radius.circular(16))
          : BorderRadius.zero,
      child: Column(
        children: [
          Padding(
            padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Icon(icon, size: 20, color: const Color(0xFF388E3C)),
                const SizedBox(width: 14),
                SizedBox(
                  width: 80,
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade500,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    displayValue,
                    style: TextStyle(
                      fontSize: 14,
                      color: isNA ? Colors.grey.shade400 : Colors.black87,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                if (onTap != null)
                  Icon(Icons.copy_outlined,
                      size: 16, color: Colors.grey.shade400),
              ],
            ),
          ),
          if (!isLast)
            Divider(
                height: 1,
                indent: 50,
                endIndent: 16,
                color: Colors.grey.shade100),
        ],
      ),
    );
  }
}