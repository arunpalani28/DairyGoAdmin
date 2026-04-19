import 'dart:async';
import 'package:flutter/material.dart';
import '../services/api_client.dart';
import '../widgets/theme.dart';
import 'dashboard_screen.dart';
import 'users_screen.dart';
import 'reports_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override State<SplashScreen> createState() => _SplashState();
}
class _SplashState extends State<SplashScreen> {
  @override void initState() { super.initState(); _check(); }
  Future<void> _check() async {
    await Future.delayed(const Duration(milliseconds: 900));
    final token = await ApiClient.loadToken();
    if (!mounted) return;
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => token != null ? const AdminShell() : const LoginScreen()));
  }
  @override Widget build(BuildContext context) => Scaffold(
    backgroundColor: kPrimary,
    body: Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      const Text('🏢', style: TextStyle(fontSize: 72)),
      const SizedBox(height: 18),
      const Text('Aavinam Admin', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w700, color: Colors.white)),
      const SizedBox(height: 6),
      const Text('Management Panel', style: TextStyle(fontSize: 13, color: Color(0xFF90CAF9))),
      const SizedBox(height: 48),
      const CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
    ])),
  );
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override State<LoginScreen> createState() => _LoginState();
}
class _LoginState extends State<LoginScreen> {
  final _mobileCtrl = TextEditingController();
  final _otpCtrl    = TextEditingController();
  bool _loading = false, _otpSent = false;
  String? _error;String? _otpNumber; int _resendSecs = 0; Timer? _timer;
  @override void dispose() { _mobileCtrl.dispose(); _otpCtrl.dispose(); _timer?.cancel(); super.dispose(); }

  Future<void> _sendOtp() async {
    final m = _mobileCtrl.text.trim();
    if (m.length < 10) { setState(() => _error = 'Enter valid mobile'); return; }
    setState(() { _loading = true; _error = null; });
    try {
     final res= await ApiClient.post('/auth/send-otp', {'mobile': m});
      setState(() { _otpNumber= res["data"];_otpSent = true; _loading = false; _resendSecs = 30; });
      _timer?.cancel();
      _timer = Timer.periodic(const Duration(seconds: 1), (_) { if (_resendSecs <= 0) { _timer?.cancel(); setState(() {}); return; } setState(() => _resendSecs--); });
    } catch (e) { setState(() { _error = e.toString().replaceAll('Exception: ', ''); _loading = false; }); }
  }

  Future<void> _verifyOtp() async {
    if (_otpCtrl.text.length != 6) { setState(() => _error = 'Enter 6-digit OTP'); return; }
    setState(() { _loading = true; _error = null; });
    try {
      final res = await ApiClient.post('/auth/verify-otp', {'mobile': _mobileCtrl.text.trim(), 'otp': _otpCtrl.text.trim()});
      final data = res['data'] as Map<String, dynamic>;
      if (data['role'] != 'ADMIN') { setState(() { _error = 'This app is for admins only.'; _loading = false; }); return; }
      await ApiClient.saveToken(data['token']);
      await ApiClient.saveUserData(data);
      if (!mounted) return;
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const AdminShell()));
    } catch (e) { setState(() { _error = e.toString().replaceAll('Exception: ', ''); _loading = false; }); }
    finally { if (mounted) setState(() => _loading = false); }
  }

  @override Widget build(BuildContext context) => Scaffold(
    backgroundColor: kPrimary,
    body: SafeArea(child: Column(children: [
      const Expanded(flex: 2, child: Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Text('🏢', style: TextStyle(fontSize: 60)),
        SizedBox(height: 12),
        Text('Aavinam Admin', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: Colors.white)),
        Text('Management Panel', style: TextStyle(fontSize: 13, color: Color(0xFF90CAF9))),
      ]))),
      Expanded(flex: 3, child: Container(
        decoration: const BoxDecoration(color: kBg, borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
        padding: const EdgeInsets.all(24),
        child: SingleChildScrollView(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(_otpSent ? 'Enter OTP' : 'Admin Login', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: kTextDark)),
          const SizedBox(height: 24),
          if (!_otpSent) _field('Admin Mobile Number', _mobileCtrl, TextInputType.phone, null)
          else ...[
            Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: kGreenLt, borderRadius: BorderRadius.circular(10)),
              child: Text('OTP is ${_otpNumber}', style: const TextStyle(fontSize: 12, color: kGreen, fontWeight: FontWeight.w600))),
            const SizedBox(height: 14),
            _field('6-digit OTP', _otpCtrl, TextInputType.number, 6),
            const SizedBox(height: 4),
            Align(alignment: Alignment.centerRight, child: GestureDetector(
              onTap: _resendSecs > 0 ? null : _sendOtp,
              child: Text(_resendSecs > 0 ? 'Resend in ${_resendSecs}s' : 'Resend OTP',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: _resendSecs > 0 ? kTextLight : kPrimary)))),
          ],
          if (_error != null) ...[const SizedBox(height: 12),
            Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: kRedLt, borderRadius: BorderRadius.circular(10)),
              child: Text(_error!, style: const TextStyle(color: kRed, fontSize: 12)))],
          const SizedBox(height: 24),
          SizedBox(width: double.infinity, child: ElevatedButton(
            onPressed: _loading ? null : (_otpSent ? _verifyOtp : _sendOtp),
            style: ElevatedButton.styleFrom(backgroundColor: kPrimary, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            child: _loading ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : Text(_otpSent ? 'Verify OTP' : 'Send OTP', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)))),
          const SizedBox(height: 16),
          Center(child: Text('Demo: use 9000000000 (Admin)', style: TextStyle(fontSize: 11, color: kTextLight))),
        ])),
      )),
    ])),
  );
  Widget _field(String label, TextEditingController ctrl, TextInputType type, int? maxLength) => TextField(
    controller: ctrl, keyboardType: type, maxLength: maxLength,
    style: const TextStyle(fontSize: 13, color: kTextDark, fontFamily: 'Aria'),
    decoration: InputDecoration(labelText: label, labelStyle: const TextStyle(fontSize: 12, color: kTextMid, fontFamily: 'Poppins'),
      filled: true, fillColor: kCard,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: kBorder)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: kBorder)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: kPrimary, width: 1.5)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13), counterText: ''));
}

class AdminShell extends StatefulWidget {
  const AdminShell({super.key});
  @override State<AdminShell> createState() => _ShellState();
}
class _ShellState extends State<AdminShell> {
  int _tab = 0;
  @override Widget build(BuildContext context) {
    const pages = [DashboardScreen(), UsersScreen(), ReportsScreen()];
    return Scaffold(
      backgroundColor: kBg,
      body: IndexedStack(index: _tab, children: pages),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(color: kCard, boxShadow: [BoxShadow(color: Color(0x18000000), blurRadius: 20, offset: Offset(0,-4))]),
        child: SafeArea(child: SizedBox(height: 66, child: Row(children: [
          _ni(0, Icons.dashboard_rounded, 'Dashboard'),
          _ni(1, Icons.people_rounded, 'Users'),
          _ni(2, Icons.bar_chart_rounded, 'Reports'),
        ]))),
      ),
    );
  }
  Widget _ni(int idx, IconData icon, String label) {
    final on = _tab == idx;
    return Expanded(child: GestureDetector(behavior: HitTestBehavior.opaque, onTap: () => setState(() => _tab = idx),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(icon, color: on ? kPrimary : kTextLight, size: 24),
        const SizedBox(height: 3),
        Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: on ? kPrimary : kTextLight)),
        const SizedBox(height: 3),
        AnimatedContainer(duration: const Duration(milliseconds: 200), width: on ? 6 : 0, height: on ? 6 : 0, decoration: const BoxDecoration(color: kPrimary, shape: BoxShape.circle)),
      ])));
  }
}
