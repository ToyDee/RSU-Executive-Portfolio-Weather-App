import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'employee_profile_page.dart';
import 'login_page.dart';
import 'weather_page.dart';

// IMPROVEMENT: sort options enum
enum SortOption { nameAZ, nameZA, positionAZ }

class EmployeesPage extends StatefulWidget {
  const EmployeesPage({super.key});

  @override
  State<EmployeesPage> createState() => _EmployeesPageState();
}

class _EmployeesPageState extends State<EmployeesPage> {
  List<Map<String, dynamic>> _allEmployees      = [];
  List<Map<String, dynamic>> _filteredEmployees = [];
  List<String> _departments                     = ['All'];
  String _fullName     = '';
  bool _isLoading      = true;
  // IMPROVEMENT: error state with retry
  String? _loadError;
  // IMPROVEMENT: search + filter + sort state
  final TextEditingController _searchController = TextEditingController();
  String _selectedDept = 'All';
  SortOption _sortOption = SortOption.nameAZ;

  @override
  void initState() {
    super.initState();
    _loadEmployees();
    _loadUser();
    _searchController.addListener(_applyFilters);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // IMPROVEMENT: extract unique positions as "departments"
  void _buildDepartmentList() {
    final positions = _allEmployees
        .map((e) => e['position'].toString().split(' for ').last.trim())
        .toSet()
        .toList()
      ..sort();
    setState(() => _departments = ['All', ...positions]);
  }

  Future<void> _loadEmployees() async {
    setState(() { _isLoading = true; _loadError = null; });
    try {
      final data   = await rootBundle.loadString('Assets/Data/employees.json');
      final jsonMap = json.decode(data) as Map<String, dynamic>;
      final list   = jsonMap.entries.map((e) {
        final value = Map<String, dynamic>.from(e.value);
        return {'id': e.key, ...value};
      }).toList();

      setState(() {
        _allEmployees = list;
        _isLoading    = false;
      });
      _buildDepartmentList();
      _applyFilters();
    } catch (e) {
      // IMPROVEMENT: show error + retry button instead of silent empty screen
      setState(() {
        _loadError = 'Failed to load employee data.\nTap retry to try again.';
        _isLoading = false;
      });
    }
  }

  Future<void> _loadUser() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() => _fullName = prefs.getString('full_name') ?? 'Unknown User');
  }

  // IMPROVEMENT: combined search + department filter + sort
  void _applyFilters() {
    final query = _searchController.text.toLowerCase();
    var list = _allEmployees.where((emp) {
      final matchesSearch = emp['name'].toString().toLowerCase().contains(query) ||
          emp['position'].toString().toLowerCase().contains(query);
      final deptKey = emp['position'].toString().split(' for ').last.trim();
      final matchesDept = _selectedDept == 'All' || deptKey == _selectedDept;
      return matchesSearch && matchesDept;
    }).toList();

    // IMPROVEMENT: sort
    switch (_sortOption) {
      case SortOption.nameAZ:
        list.sort((a, b) => a['name'].toString().compareTo(b['name'].toString()));
        break;
      case SortOption.nameZA:
        list.sort((a, b) => b['name'].toString().compareTo(a['name'].toString()));
        break;
      case SortOption.positionAZ:
        list.sort((a, b) => a['position'].toString().compareTo(b['position'].toString()));
        break;
    }

    setState(() => _filteredEmployees = list);
  }

  void _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Logout', style: TextStyle(fontWeight: FontWeight.w700)),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false),
              child: Text('Cancel', style: TextStyle(color: Colors.grey.shade600))),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade700),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      Navigator.pushReplacement(context,
          PageRouteBuilder(
            pageBuilder: (_, __, ___) => const LoginPage(),
            transitionsBuilder: (_, anim, __, child) => FadeTransition(opacity: anim, child: child),
            transitionDuration: const Duration(milliseconds: 350),
          ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F8),
      appBar: AppBar(
        title: const Text('Executive Directory'),
        actions: [
          // IMPROVEMENT: sort button in app bar
          PopupMenuButton<SortOption>(
            icon: const Icon(Icons.sort, color: Colors.white),
            tooltip: 'Sort',
            onSelected: (opt) { setState(() => _sortOption = opt); _applyFilters(); },
            itemBuilder: (_) => [
              const PopupMenuItem(value: SortOption.nameAZ,
                  child: Text('Name A → Z')),
              const PopupMenuItem(value: SortOption.nameZA,
                  child: Text('Name Z → A')),
              const PopupMenuItem(value: SortOption.positionAZ,
                  child: Text('Position A → Z')),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.wb_sunny_outlined),
            tooltip: 'Weather',
            onPressed: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const WeatherPage())),
          ),
        ],
      ),
      drawer: _buildDrawer(),
      body: Column(
        children: [
          // Search + department filter
          Container(
            color: const Color(0xFF1B5E20),
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Column(
              children: [
                // Search bar
                TextField(
                  controller: _searchController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Search by name or position…',
                    hintStyle: TextStyle(color: Colors.white.withOpacity(0.6)),
                    prefixIcon: Icon(Icons.search, color: Colors.white.withOpacity(0.7)),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                      icon: Icon(Icons.clear, color: Colors.white.withOpacity(0.7)),
                      onPressed: () { _searchController.clear(); FocusScope.of(context).unfocus(); },
                    )
                        : null,
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.15),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
                const SizedBox(height: 10),
                // IMPROVEMENT: department filter chips
                SizedBox(
                  height: 32,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: _departments.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (_, i) {
                      final dept = _departments[i];
                      final selected = _selectedDept == dept;
                      return GestureDetector(
                        onTap: () { setState(() => _selectedDept = dept); _applyFilters(); },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                          decoration: BoxDecoration(
                            color: selected ? Colors.white : Colors.white.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            dept,
                            style: TextStyle(
                              color: selected ? const Color(0xFF1B5E20) : Colors.white,
                              fontSize: 12, fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),

          // Result count
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${_filteredEmployees.length} result${_filteredEmployees.length != 1 ? 's' : ''}',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 13, fontWeight: FontWeight.w600),
                ),
                Text(
                  _sortLabel(),
                  style: TextStyle(color: Colors.grey.shade400, fontSize: 12),
                ),
              ],
            ),
          ),

          // Body
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  String _sortLabel() {
    switch (_sortOption) {
      case SortOption.nameAZ:    return 'A → Z';
      case SortOption.nameZA:    return 'Z → A';
      case SortOption.positionAZ: return 'Position';
    }
  }

  Widget _buildBody() {
    // IMPROVEMENT: loading state
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFF1B5E20)));
    }

    // IMPROVEMENT: error state with retry button
    if (_loadError != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.cloud_off_rounded, size: 56, color: Colors.grey.shade300),
              const SizedBox(height: 16),
              Text(_loadError!,
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey.shade600, height: 1.5),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: _loadEmployees,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    // Empty search result
    if (_filteredEmployees.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.search_off, size: 56, color: Colors.grey.shade300),
            const SizedBox(height: 12),
            Text('No results found', style: TextStyle(color: Colors.grey.shade500)),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () { _searchController.clear(); setState(() => _selectedDept = 'All'); _applyFilters(); },
              child: const Text('Clear filters', style: TextStyle(color: Color(0xFF1B5E20))),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 20, top: 4),
      itemCount: _filteredEmployees.length,
      itemBuilder: (_, i) {
        final emp = _filteredEmployees[i];
        return _EmployeeCard(
          employee: emp,
          onTap: () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => EmployeeProfilePage(employee: emp))),
        );
      },
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(20, 52, 20, 24),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF1B5E20), Color(0xFF388E3C)],
                begin: Alignment.topLeft, end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 60, height: 60,
                  decoration: BoxDecoration(
                    color: Colors.white, shape: BoxShape.circle,
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 8)],
                  ),
                  padding: const EdgeInsets.all(8),
                  child: Image.asset('Assets/Images/RSU_Logo.png'),
                ),
                const SizedBox(height: 14),
                Text(_fullName,
                    style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
                const SizedBox(height: 2),
                Text('RSU Member',
                    style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 13)),
              ],
            ),
          ),
          const SizedBox(height: 8),
          _DrawerItem(icon: Icons.group_outlined, label: 'Executives',
              onTap: () => Navigator.pop(context)),
          _DrawerItem(icon: Icons.wb_sunny_outlined, label: 'Weather & Air Quality',
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (_) => const WeatherPage()));
              }),
          const Spacer(),
          const Divider(height: 1),
          _DrawerItem(icon: Icons.logout, label: 'Logout',
              color: Colors.red.shade700, onTap: () { Navigator.pop(context); _logout(); }),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _EmployeeCard extends StatelessWidget {
  final Map<String, dynamic> employee;
  final VoidCallback onTap;
  const _EmployeeCard({required this.employee, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              CircleAvatar(radius: 30,
                  backgroundImage: AssetImage('Assets/Images/${employee['id']}.jpg')),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(employee['name'],
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                    const SizedBox(height: 4),
                    Text(employee['position'],
                        style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }
}

class _DrawerItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;
  const _DrawerItem({required this.icon, required this.label, required this.onTap, this.color});

  @override
  Widget build(BuildContext context) {
    final c = color ?? const Color(0xFF1B5E20);
    return ListTile(
      leading: Icon(icon, color: c),
      title: Text(label, style: TextStyle(color: c, fontWeight: FontWeight.w600)),
      onTap: onTap,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      horizontalTitleGap: 0,
    );
  }
}