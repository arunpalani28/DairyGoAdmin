import 'package:flutter/material.dart';
import '../services/api_client.dart';
import '../widgets/theme.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});
  @override State<DashboardScreen> createState() => _DashboardState();
}

class _DashboardState extends State<DashboardScreen> {
  DashboardData? _data;
  bool _loading = true;

  @override void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final res = await ApiClient.get('/admin/dashboard');
      setState(() { _data = DashboardData.fromJson(res['data']); _loading = false; });
    } catch (_) { setState(() => _loading = false); }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: kBg,
    body: Column(children: [
      aHeader('Admin Dashboard', 'DairyGo Madurai'),
      if (_loading) const Expanded(child: Center(child: CircularProgressIndicator(color: kPrimary)))
      else Expanded(child: RefreshIndicator(onRefresh: _load, color: kPrimary,
        child: ListView(padding: const EdgeInsets.all(16), children: [
          const ASectionTitle(title: 'Financial Overview'),
          const SizedBox(height: 10),
          Row(children: [
            Expanded(child: _finStat('Total MRR',
                '₹${(_data?.totalMrr ?? 0).toStringAsFixed(0)}', '+8%',
                Icons.trending_up_rounded, kPrimary, kPrimaryLt)),
            const SizedBox(width: 8),
            Expanded(child: _finStat('One-Time',
                '₹${(_data?.oneTimeSales ?? 0).toStringAsFixed(0)}', 'Sales',
                Icons.shopping_bag_rounded, kGreen, kGreenLt)),
            const SizedBox(width: 8),
            Expanded(child: _finStat('Svc Fees',
                '₹${(_data?.serviceFees ?? 0).toStringAsFixed(0)}', '₹10/trip',
                Icons.receipt_rounded, kOrange, kOrangeLt)),
          ]),
          const SizedBox(height: 18),
          // Revenue bar chart
          const ASectionTitle(title: 'Monthly Revenue Trend'),
          const SizedBox(height: 10),
          ACard(child: Column(children: [
            const _BarChart(),
            const SizedBox(height: 10),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              _lgd(kPrimary, 'Subscription'), const SizedBox(width: 14),
              _lgd(kOrange, 'One-time'), const SizedBox(width: 14),
              _lgd(kGreen, 'Fees'),
            ]),
          ])),
          const SizedBox(height: 18),
          // Today activity
          const ASectionTitle(title: "Today's Activity"),
          const SizedBox(height: 10),
          Row(children: [
            Expanded(child: _actCard(Icons.check_circle_rounded,
                '${_data?.deliveredToday ?? 0}/${_data?.totalDeliveriesToday ?? 0}', 'Delivered', kGreen, kGreenLt)),
            const SizedBox(width: 8),
            Expanded(child: _actCard(Icons.pending_rounded,
                '${_data?.pendingToday ?? 0}', 'Pending', kOrange, kOrangeLt)),
          ]),
          const SizedBox(height: 8),
          Row(children: [
            Expanded(child: _actCard(Icons.group_rounded,
                '${_data?.totalUsers ?? 0}', 'Active Users', kPrimary, kPrimaryLt)),
            const SizedBox(width: 8),
            Expanded(child: _actCard(Icons.warning_rounded,
                '${_data?.pendingKyc ?? 0}', 'KYC Pending', kRed, kRedLt)),
          ]),
          const SizedBox(height: 18),
          // Special delivery fee highlight
          const ASectionTitle(title: 'Special Delivery Fees — ₹10'),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: kOrangeLt, borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFFFCC80), width: 1.5)),
            child: Row(children: [
              Container(width: 48, height: 48, decoration: BoxDecoration(color: kOrange, borderRadius: BorderRadius.circular(13)),
                child: const Center(child: Text('🚚', style: TextStyle(fontSize: 24)))),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Service Fees Collected', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: kOrange)),
                Text('${(_data?.serviceFees ?? 0) ~/ 10} extra trips × ₹10 this month',
                    style: const TextStyle(fontSize: 10, color: kOrange)),
              ])),
              Text('₹${(_data?.serviceFees ?? 0).toStringAsFixed(0)}',
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: kOrange)),
            ]),
          ),
          const SizedBox(height: 8),
        ]),
      )),
    ]),
  );

  Widget _finStat(String label, String value, String badge, IconData icon, Color color, Color bg) =>
      ACard(padding: const EdgeInsets.all(12), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(width: 34, height: 34, decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, color: color, size: 17)),
        const SizedBox(height: 8),
        Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: color)),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(fontSize: 9, color: kTextMid, fontWeight: FontWeight.w500)),
        const SizedBox(height: 5),
        Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(10)),
          child: Text(badge, style: TextStyle(fontSize: 8, fontWeight: FontWeight.w700, color: color))),
      ]));

  Widget _actCard(IconData icon, String value, String label, Color color, Color bg) =>
      ACard(padding: const EdgeInsets.all(13), child: Row(children: [
        Container(width: 38, height: 38, decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(11)),
          child: Icon(icon, color: color, size: 20)),
        const SizedBox(width: 10),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: color)),
          Text(label, style: const TextStyle(fontSize: 10, color: kTextMid, fontWeight: FontWeight.w500)),
        ]),
      ]));

  Widget _lgd(Color c, String l) => Row(children: [
    Container(width: 10, height: 10, decoration: BoxDecoration(color: c, borderRadius: BorderRadius.circular(3))),
    const SizedBox(width: 4),
    Text(l, style: const TextStyle(fontSize: 9, color: kTextMid, fontWeight: FontWeight.w500)),
  ]);
}

class _BarChart extends StatelessWidget {
  const _BarChart();
  @override Widget build(BuildContext context) {
    const months  = ['Nov','Dec','Jan','Feb','Mar','Apr'];
    const subs    = [30.0,34.0,36.0,32.0,38.0,42.0];
    const onetime = [5.0, 6.0, 7.0, 5.0, 8.0, 8.0 ];
    const fees    = [1.0, 1.0, 1.0, 1.0, 1.0, 1.0 ];
    return SizedBox(height: 120, child: Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: List.generate(months.length, (i) => Expanded(child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2),
        child: Column(mainAxisAlignment: MainAxisAlignment.end, children: [
          Column(children: [
            _bar(fees[i] / 52, kGreen),
            const SizedBox(height: 1),
            _bar(onetime[i] / 52, kOrange),
            const SizedBox(height: 1),
            _bar(subs[i] / 52, kPrimary),
          ]),
          const SizedBox(height: 6),
          Text(months[i], style: const TextStyle(fontSize: 8, color: kTextLight, fontWeight: FontWeight.w500)),
        ]),
      ))),
    ));
  }
  Widget _bar(double fraction, Color color) => Container(
    width: double.infinity, height: fraction * 100,
    decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3)));
}
