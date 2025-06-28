// import 'package:flutter/material.dart';
// import 'screens/dashboard.dart';
// import 'screens/detail_report.dart';
// import 'screens/edit_profile_page.dart';
// import 'screens/home.dart';
// import 'screens/Login.dart';
// import 'screens/pantau_laporan.dart';
// import 'screens/profile.dart';
// import 'screens/Register.dart';
// import 'screens/report_form.dart';
// import 'screens/report.dart';
// import 'screens/riwayat_page.dart';
// import 'screens/SelectLocationPage.dart';

// class BottomNavBarExample extends StatefulWidget {
//   @override
//   _BottomNavBarExampleState createState() => _BottomNavBarExampleState();
// }

// class _BottomNavBarExampleState extends State<BottomNavBarExample> {
//   int _selectedIndex = 0;  // Index untuk menandakan tab yang aktif

//   // Halaman yang akan ditampilkan sesuai tab yang dipilih
//   List<Widget> _pages = [
//     HomePage(),               // Halaman Home
//     PantauLaporanPage(),      // Halaman Pantau Laporan
//     ProfilePage(),            // Halaman Profile
//     LoginPage(),              // Halaman Login
//     RegisterPage(),           // Halaman Register
//     ReportPage(),             // Halaman Report
//     DetailReportPage(),       // Halaman Detail Report
//     RiwayatPage(),            // Halaman Riwayat
//     EditProfilePage(),        // Halaman Edit Profile
//     ReportFormPage(),         // Halaman Report Form
//     SelectLocationPage(),     // Halaman Select Location
//     DashboardPage(),          // Halaman Dashboard
//   ];

//   void _onItemTapped(int index) {
//     setState(() {
//       _selectedIndex = index;
//     });
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text('Bottom Navigation Example'),
//       ),
//       body: _pages[_selectedIndex],  // Menampilkan halaman yang dipilih
//       bottomNavigationBar: BottomNavigationBar(
//         currentIndex: _selectedIndex, // Menandakan tab yang aktif
//         onTap: _onItemTapped, // Fungsi untuk mengubah tab saat diklik
//         items: const <BottomNavigationBarItem>[
//           BottomNavigationBarItem(
//             icon: Icon(Icons.home),
//             label: 'Home',
//           ),
//           BottomNavigationBarItem(
//             icon: Icon(Icons.report),
//             label: 'Pantau Laporan',
//           ),
//           BottomNavigationBarItem(
//             icon: Icon(Icons.account_circle),
//             label: 'Profile',
//           ),
//           BottomNavigationBarItem(
//             icon: Icon(Icons.login),
//             label: 'Login',
//           ),
//           BottomNavigationBarItem(
//             icon: Icon(Icons.app_registration),
//             label: 'Register',
//           ),
//           BottomNavigationBarItem(
//             icon: Icon(Icons.report_problem),
//             label: 'Report',
//           ),
//           BottomNavigationBarItem(
//             icon: Icon(Icons.details),
//             label: 'Detail Report',
//           ),
//           BottomNavigationBarItem(
//             icon: Icon(Icons.history),
//             label: 'Riwayat',
//           ),
//           BottomNavigationBarItem(
//             icon: Icon(Icons.edit),
//             label: 'Edit Profile',
//           ),
//           BottomNavigationBarItem(
//             icon: Icon(Icons.assignment),
//             label: 'Report Form',
//           ),
//           BottomNavigationBarItem(
//             icon: Icon(Icons.location_on),
//             label: 'Select Location',
//           ),
//           BottomNavigationBarItem(
//             icon: Icon(Icons.dashboard),
//             label: 'Dashboard',
//           ),
//         ],
//       ),
//     );
//   }
// }
