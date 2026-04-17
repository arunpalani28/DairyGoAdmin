import 'package:flutter/material.dart';
import '../services/api_client.dart';
import '../widgets/theme.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});
  @override State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  Map<String, dynamic> _data = {};
  bool _loading = true;

  @override void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final res = await ApiClient.get('/admin/reports');
      setState(() { _data = res['data'] as Map<String, dynamic>; _loading = false; });
    } catch (_) { setState(() => _loading = false); }
  }

  double _num(String key) => (_data[key] as num?)?.toDouble() ?? 0;
  int _int(String key) => (_data[key] as num?)?.toInt() ?? 0;

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: kBg,
    body: Column(children: [
      aHeader('Reports', 'DairyGo Madurai'),
      if (_loading)
        const Expanded(child: Center(child: CircularProgressIndicator(color: kPrimary)))
      else
        Expanded(child: RefreshIndicator(onRefresh: _load, color: kPrimary,
          child: ListView(padding: const EdgeInsets.all(16), children: [
            // MRR breakdown
            const ASectionTitle(title: 'MRR Breakdown — This Month'),
            const SizedBox(height: 10),
            ACard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              _rRow('Subscription Revenue', '₹${_num('mrr').toStringAsFixed(0)}', kPrimary, bold: true),
              const Divider(color: kBorder, height: 16),
              _rRow('Full Cream 500ml (28 users)', '₹19,200', kTextMid),
              const SizedBox(height: 6),
              _rRow('Full Cream 1L (8 users)', '₹11,520', kTextMid),
              const SizedBox(height: 6),
              _rRow('Toned Milk 500ml (6 users)', '₹7,680', kTextMid),
              const Divider(color: kBorder, height: 16),
              _rRow('One-Time Sales', '₹${_num('oneTimeSales').toStringAsFixed(0)}', kGreen, bold: true),
              const Divider(color: kBorder, height: 16),
              // Extra fee — always orange and highlighted
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: kOrangeLt, borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFFFCC80))),
                child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Row(children: const [
                    Icon(Icons.warning_amber_rounded, color: kOrange, size: 16),
                    SizedBox(width: 8),
                    Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('Special Delivery Fees',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: kOrange)),
                      Text('₹10 per extra trip', style: TextStyle(fontSize: 10, color: kOrange)),
                    ]),
                  ]),
                  const Text('₹1,200',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: kOrange)),
                ]),
              ),
              const Divider(color: kBorder, height: 16),
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                const Text('TOTAL MRR',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: kTextDark)),
                Text('₹${(_num('mrr') + _num('oneTimeSales') + 1200).toStringAsFixed(0)}',
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: kPrimary)),
              ]),
            ])),
            const SizedBox(height: 18),

            // Delivery stats grid
            const ASectionTitle(title: 'Delivery Statistics'),
            const SizedBox(height: 10),
            Row(children: [
              Expanded(child: _statBox('Total Trips', '${_int('totalDeliveries')}', kPrimary, Icons.local_shipping_rounded)),
              const SizedBox(width: 8),
              Expanded(child: _statBox('On-time Rate', '97.4%', kGreen, Icons.timer_rounded)),
            ]),
            const SizedBox(height: 8),
            Row(children: [
              Expanded(child: _statBox('Active Users', '${_int('totalCustomers')}', kPrimary, Icons.group_rounded)),
              const SizedBox(width: 8),
              Expanded(child: _statBox('KYC Pending', '${_int('pendingKyc')}', kOrange, Icons.hourglass_empty_rounded)),
            ]),
            const SizedBox(height: 18),

            // Zone performance
            const ASectionTitle(title: 'Zone Performance'),
            const SizedBox(height: 10),
            ACard(padding: EdgeInsets.zero, child: Column(children: [
              _zoneRow('Madurai South', 18, 0.97, kGreen, false),
              _zoneRow('Madurai West', 12, 0.95, kGreen, false),
              _zoneRow('Madurai Central', 8, 1.0, kGreen, false),
              _zoneRow('Vilangudi', 4, 0.92, kOrange, true),
            ])),
            const SizedBox(height: 18),

            // Monthly trend card
            const ASectionTitle(title: 'Trend Summary'),
            const SizedBox(height: 10),
            ACard(child: Column(children: [
              Row(children: [
                Expanded(child: _trendTile('MoM Growth', '+8%', Icons.trending_up_rounded, kGreen)),
                const SizedBox(width: 10),
                Expanded(child: _trendTile('Avg Delivery', '42/day', Icons.local_shipping_rounded, kPrimary)),
                const SizedBox(width: 10),
                Expanded(child: _trendTile('₹10 Fees', '120/mo', Icons.receipt_rounded, kOrange)),
              ]),
            ])),
            const SizedBox(height: 18),

            // Export buttons
            const ASectionTitle(title: 'Export Reports'),
            const SizedBox(height: 10),
            Row(children: [
              Expanded(child: _exportBtn('Export PDF', Icons.picture_as_pdf_rounded, kRed, kRedLt)),
              const SizedBox(width: 8),
              Expanded(child: _exportBtn('Export Excel', Icons.table_chart_rounded, kGreen, kGreenLt)),
            ]),
            const SizedBox(height: 8),
            _exportBtn('Send Report via Email', Icons.email_rounded, kPrimary, kPrimaryLt),
            const SizedBox(height: 16),
          ]),
        )),
    ]),
  );

  Widget _rRow(String label, String val, Color color, {bool bold = false}) =>
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Expanded(child: Text(label,
            style: TextStyle(fontSize: bold ? 12 : 11,
                fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
                color: bold ? kTextDark : kTextMid))),
        Text(val, style: TextStyle(fontSize: bold ? 14 : 12, fontWeight: FontWeight.w700, color: color)),
      ]);

  Widget _statBox(String label, String value, Color color, IconData icon) =>
      ACard(padding: const EdgeInsets.all(14), child: Row(children: [
        Container(width: 38, height: 38,
          decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(11)),
          child: Icon(icon, color: color, size: 20)),
        const SizedBox(width: 10),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(value, style: TextStyle(fontSize: 19, fontWeight: FontWeight.w700, color: color)),
          Text(label, style: const TextStyle(fontSize: 10, color: kTextMid, fontWeight: FontWeight.w500)),
        ]),
      ]));

  Widget _zoneRow(String zone, int users, double rate, Color color, bool isLast) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    decoration: BoxDecoration(border: Border(bottom: BorderSide(color: isLast ? Colors.transparent : kBorder))),
    child: Row(children: [
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(zone, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: kTextDark)),
        Text('$users active users', style: const TextStyle(fontSize: 9, color: kTextLight)),
      ])),
      ClipRRect(borderRadius: BorderRadius.circular(4),
        child: SizedBox(width: 90, height: 7,
          child: LinearProgressIndicator(value: rate, backgroundColor: kBorder, color: color))),
      const SizedBox(width: 10),
      SizedBox(width: 38, child: Text('${(rate * 100).round()}%',
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: color),
          textAlign: TextAlign.right)),
    ]),
  );

  Widget _trendTile(String label, String value, IconData icon, Color color) =>
      Column(children: [
        Container(width: 40, height: 40,
          decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
          child: Icon(icon, color: color, size: 20)),
        const SizedBox(height: 6),
        Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: color)),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(fontSize: 9, color: kTextMid, fontWeight: FontWeight.w500),
            textAlign: TextAlign.center),
      ]);

  Widget _exportBtn(String label, IconData icon, Color color, Color bg) =>
      GestureDetector(
        onTap: () => ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('$label — feature coming soon'), backgroundColor: kPrimary)),
        child: Container(
          width: double.infinity, padding: const EdgeInsets.symmetric(vertical: 13),
          decoration: BoxDecoration(
            color: bg, borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withOpacity(0.3))),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(width: 8),
            Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: color)),
          ]),
        ),
      );
}
