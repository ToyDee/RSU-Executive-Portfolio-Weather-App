import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:finalassignment/app_security.dart';
import 'package:finalassignment/login_page.dart';

// ── Helper: replicate the filter/sort logic from EmployeesPage ───────────────
List<Map<String, dynamic>> filterAndSort(
    List<Map<String, dynamic>> employees, {
      String query = '',
      String dept = 'All',
      String sort = 'nameAZ',
    }) {
  var list = employees.where((emp) {
    final matchesSearch =
        emp['name'].toString().toLowerCase().contains(query.toLowerCase()) ||
            emp['position'].toString().toLowerCase().contains(query.toLowerCase());
    final deptKey = emp['position'].toString().split(' for ').last.trim();
    final matchesDept = dept == 'All' || deptKey == dept;
    return matchesSearch && matchesDept;
  }).toList();

  if (sort == 'nameAZ') {
    list.sort((a, b) => a['name'].toString().compareTo(b['name'].toString()));
  } else if (sort == 'nameZA') {
    list.sort((a, b) => b['name'].toString().compareTo(a['name'].toString()));
  }

  return list;
}

// ── Sample data (mirrors employees.json) ────────────────────────────────────
final sampleEmployees = [
  {'id': '1', 'name': 'Dr. Attawit Ourairat',        'position': 'President'},
  {'id': '2', 'name': 'Mr. Kasin Chanruang',          'position': 'Vice President for Management'},
  {'id': '3', 'name': 'Patamaporn Sukplang, Ph.D.',   'position': 'Vice President for Academic Affairs'},
  {'id': '4', 'name': 'Asst.Prof.Dr. Narupol Chaiyot','position': 'Vice President for Planning and Development'},
  {'id': '5', 'name': 'Assoc.Prof.Dr. Grit Thonglert','position': 'Vice President for Student Affairs'},
];

void main() {
  // ── 1. Security tests ──────────────────────────────────────────────────────
  group('AppSecurity', () {
    test('hashPassword returns "salt:hash" with correct lengths', () {
      final stored = AppSecurity.hashPassword('1234');
      expect(stored.contains(':'), isTrue);
      final parts = stored.split(':');
      expect(parts.length, equals(2));
      expect(parts[0].length, equals(32)); // 16-byte salt, hex-encoded
      expect(parts[1].length, equals(64)); // SHA-256 digest, hex-encoded
    });

    test('same password produces a different stored value each time (random salt)', () {
      final a = AppSecurity.hashPassword('hello');
      final b = AppSecurity.hashPassword('hello');
      expect(a, isNot(equals(b)));
    });

    test('verifyPassword returns true for correct password', () {
      final stored = AppSecurity.hashPassword('mypassword');
      expect(AppSecurity.verifyPassword('mypassword', stored), isTrue);
    });

    test('verifyPassword returns false for wrong password', () {
      final stored = AppSecurity.hashPassword('correctpass');
      expect(AppSecurity.verifyPassword('wrongpass', stored), isFalse);
    });

    test('verifyPassword trims whitespace', () {
      final stored = AppSecurity.hashPassword('1234');
      expect(AppSecurity.verifyPassword('  1234  ', stored), isTrue);
    });

    test('verifyPassword still accepts legacy unsalted MD5 hashes', () {
      // Simulates an old install that stored a bare MD5 hash, pre-migration.
      final legacyHash = md5.convert(utf8.encode('oldpass')).toString();
      expect(AppSecurity.verifyPassword('oldpass', legacyHash), isTrue);
      expect(AppSecurity.verifyPassword('wrongpass', legacyHash), isFalse);
    });

    test('isLegacyHash tells apart old MD5 hashes from new salted ones', () {
      final legacyHash = md5.convert(utf8.encode('oldpass')).toString();
      final newHash = AppSecurity.hashPassword('newpass');
      expect(AppSecurity.isLegacyHash(legacyHash), isTrue);
      expect(AppSecurity.isLegacyHash(newHash), isFalse);
    });
  });

  // ── 2. Employee filter & sort tests ───────────────────────────────────────
  group('Employee filtering', () {
    test('empty query returns all employees', () {
      final result = filterAndSort(sampleEmployees);
      expect(result.length, equals(5));
    });

    test('search by name is case-insensitive', () {
      final result = filterAndSort(sampleEmployees, query: 'grit');
      expect(result.length, equals(1));
      expect(result.first['name'], contains('Grit'));
    });

    test('search by position keyword', () {
      final result = filterAndSort(sampleEmployees, query: 'academic');
      expect(result.length, equals(1));
      expect(result.first['position'], contains('Academic'));
    });

    test('no match returns empty list', () {
      final result = filterAndSort(sampleEmployees, query: 'xyznotfound');
      expect(result.isEmpty, isTrue);
    });

    test('sort A→Z puts Assoc.Prof Grit first', () {
      final result = filterAndSort(sampleEmployees, sort: 'nameAZ');
      expect(result.first['name'], startsWith('Assoc.Prof'));
    });

    test('sort Z→A puts Patamaporn first', () {
      final result = filterAndSort(sampleEmployees, sort: 'nameZA');
      expect(result.first['name'], startsWith('Patamaporn'));
    });
  });

  // ── 3. Widget smoke test ──────────────────────────────────────────────────
  group('LoginPage widget', () {
    testWidgets('shows username and password fields and a Login button', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: LoginPage()));

      expect(find.byType(TextFormField), findsNWidgets(2));
      expect(find.text('Login'), findsOneWidget);
    });

    testWidgets('tapping Login with empty fields shows validation errors', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: LoginPage()));

      await tester.tap(find.text('Login'));
      await tester.pump();

      expect(find.text('Username is required'), findsOneWidget);
      expect(find.text('Password is required'), findsOneWidget);
    });
  });
}