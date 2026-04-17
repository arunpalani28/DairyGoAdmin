import 'dart:async';

import 'package:flutter/material.dart';
import '../services/api_client.dart';
import '../widgets/theme.dart';

class SubscriptionPlan {
  final String name;
  final double price;

  SubscriptionPlan({required this.name, required this.price});

  factory SubscriptionPlan.fromJson(Map<String, dynamic> json) =>
    SubscriptionPlan(
      name: json['planName'], // ✅ FIXED
      price: (json['pricePerUnit'] as num).toDouble(), // ✅ FIXED
    );
}
class UsersScreen extends StatefulWidget {
  const UsersScreen({super.key});
  @override State<UsersScreen> createState() => _UsersScreenState();
}

class _UsersScreenState extends State<UsersScreen> {
  List<ManagedUser> _users = [];
  List<KycItem> _pendingKyc = [];
  List<ExtraReq> _extraRequests = [];
  List<ManagedUser> _filtered = [];
  bool _loading = true;
  String _filter = 'All';
  int _subtab = 0; // 0=Users, 1=KYC, 2=Extra
  final _searchCtrl = TextEditingController();

  @override void initState() { super.initState(); _load(); _searchCtrl.addListener(_applyFilter); }
  @override void dispose() { _searchCtrl.dispose(); super.dispose(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final results = await Future.wait([
        ApiClient.get('/admin/users'),
        ApiClient.get('/admin/kyc/pending'),
        ApiClient.get('/admin/extra-requests?all=false'),
      ]);
      setState(() {
        _users = (results[0]['data'] as List).map((e) => ManagedUser.fromJson(e)).toList();
        _pendingKyc = (results[1]['data'] as List).map((e) => KycItem.fromJson(e)).toList();
        _extraRequests = (results[2]['data'] as List).map((e) => ExtraReq.fromJson(e)).toList();
        _applyFilter(); _loading = false;
      });
    } catch (_) { setState(() => _loading = false); }
  }



  void _applyFilter() {
    final q = _searchCtrl.text.toLowerCase().trim();
    setState(() {
      _filtered = _users.where((u) {
        final matchQ = q.isEmpty || u.name.toLowerCase().contains(q) || u.mobile.contains(q);
        final matchF = _filter == 'All' || (_filter == 'Verified' && u.isVerified) || (_filter == 'Pending' && u.isPending) || (_filter == 'Rejected' && u.isRejected);
        return matchQ && matchF;
      }).toList();
    });
  }

  Future<void> _approveKyc(int userId) async {
    try {
      await ApiClient.patch('/admin/users/$userId/approve-kyc');
      final u = _users.firstWhere((u) => u.id == userId);
      setState(() { u.kycStatus = 'VERIFIED'; _applyFilter(); _pendingKyc.removeWhere((k) => k.userId == userId); });
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('KYC Approved ✓'), backgroundColor: kGreen));
    } catch (e) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()), backgroundColor: Colors.red)); }
  }

  Future<void> _rejectKyc(int userId) async {
    try {
      await ApiClient.patch('/admin/users/$userId/reject-kyc');
      final u = _users.firstWhere((u) => u.id == userId);
      setState(() { u.kycStatus = 'REJECTED'; _applyFilter(); _pendingKyc.removeWhere((k) => k.userId == userId); });
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('KYC Rejected'), backgroundColor: Colors.red));
    } catch (e) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()), backgroundColor: Colors.red)); }
  }
  Future<void> _generateBill(int userId, String name) async {
    try {
      final res = await ApiClient.post('/admin/users/$userId/generate-bill');
      final bill = GeneratedBill.fromJson(res['data']);
      if (!mounted) return;
      showDialog(context: context, builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Bill — $name', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          _brow('Subscription', '₹${bill.subscriptionAmount.toStringAsFixed(0)}', kTextDark),
          const SizedBox(height: 6),
          _brow('One-time orders', '₹${bill.oneTimeAmount.toStringAsFixed(0)}', kTextDark),
          const SizedBox(height: 6),
          _brow('Extra deliveries', '₹${bill.extraFeeAmount.toStringAsFixed(0)}', kTextDark),
          const SizedBox(height: 6),
          Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7), decoration: BoxDecoration(color: kOrangeLt, borderRadius: BorderRadius.circular(8), border: Border.all(color: const Color(0xFFFFCC80))), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Row(children: const [Icon(Icons.local_shipping_rounded, color: kOrange, size: 14), SizedBox(width: 6), Text('Delivery charges', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: kOrange))]),
            Text('₹${bill.extraFeeAmount.toStringAsFixed(0)}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: kOrange)),
          ])),
          const Divider(height: 16),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            const Text('Total', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
            Text('₹${bill.totalAmount.toStringAsFixed(0)}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: kPrimary)),
          ]),
        ]),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close'))],
      ));
    } catch (e) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()), backgroundColor: Colors.red)); }
  }

  Future<void> _assignExtra(int requestId) async {
    // Show driver list (simplified: assign to driver id 2 for demo)
   // final driversRes = await ApiClient.get('/admin/users');
    if (!mounted) return;
   // final drivers = (driversRes['data'] as List).where((u) => false).toList(); // would filter by role
    // For demo: assign to driver 2
    try {
      await ApiClient.patch('/admin/extra-requests/$requestId/assign?driverId=2');
      setState(() { _extraRequests.removeWhere((e) => e.id == requestId); });
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Driver assigned to extra delivery'), backgroundColor: kGreen));
    } catch (e) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()), backgroundColor: Colors.red)); }
  }

  Widget _brow(String label, String val, Color color) => Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
    Text(label, style: const TextStyle(fontSize: 12, color: kTextMid)),
    Text(val, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: color)),
  ]);

  @override Widget build(BuildContext context) => Scaffold(
    backgroundColor: kBg,
    body: Column(children: [
      Container(color: kPrimary, child: SafeArea(bottom: false, child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
        child: Column(children: [
          Row(children: [
            const AAvatar(initials: 'AD'), const SizedBox(width: 10),
            const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('User Management', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white)),
              Text('KYC · Billing · Extra Requests', style: TextStyle(fontSize: 11, color: Color(0xFF90CAF9))),
            ])),
            /// 🔄 REFRESH BUTTON
    IconButton(
      onPressed: _loading ? null : _load,
      icon: _loading
          ? const SizedBox(
              height: 18,
              width: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            )
          : const Icon(Icons.refresh_rounded, color: Colors.white),
      tooltip: 'Refresh',
    ),
            if (_pendingKyc.isNotEmpty) Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: kOrange, borderRadius: BorderRadius.circular(20)),
              child: Text('${_pendingKyc.length} KYC', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Colors.white))),
          ]),
          const SizedBox(height: 12),
          // Sub-tabs
          Container(decoration: BoxDecoration(color: Colors.white12, borderRadius: BorderRadius.circular(12)), padding: const EdgeInsets.all(4),
            child: Row(children: [
              _stab('Users', 0), _stab('KYC Pending (${_pendingKyc.length})', 1), _stab('Extra Req', 2),
            ])),
          const SizedBox(height: 12),
          if (_subtab == 0) ...[
            Container(decoration: BoxDecoration(color: kCard, borderRadius: BorderRadius.circular(12)), child: TextField(controller: _searchCtrl,
              style: const TextStyle(fontSize: 12, color: kTextDark, fontFamily: 'Poppins'),
              decoration: const InputDecoration(hintText: 'Search by name or mobile…', hintStyle: TextStyle(fontSize: 12, color: kTextLight), prefixIcon: Icon(Icons.search_rounded, color: kTextLight, size: 20), border: InputBorder.none, contentPadding: EdgeInsets.symmetric(vertical: 11)))),
            const SizedBox(height: 10),
            SingleChildScrollView(scrollDirection: Axis.horizontal, child: Row(children: ['All','Verified','Pending','Rejected'].map((f) => Padding(padding: const EdgeInsets.only(right: 8), child: GestureDetector(onTap: () { setState(() => _filter = f); _applyFilter(); }, child: AnimatedContainer(duration: const Duration(milliseconds: 200), padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5), decoration: BoxDecoration(color: _filter == f ? Colors.white : Colors.white24, borderRadius: BorderRadius.circular(20)), child: Text(f, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: _filter == f ? kPrimary : Colors.white)))))).toList())),
          ],
          const SizedBox(height: 10),
        ]),
      ))),
      if (_loading) const Expanded(child: Center(child: CircularProgressIndicator(color: kPrimary)))
      else Expanded(child: RefreshIndicator(onRefresh: _load, color: kPrimary,
        child: _subtab == 0 ? _usersTab() : _subtab == 1 ? _kycTab() : _extraTab(),
      )),
    ]),
  );

  Widget _stab(String label, int idx) => Expanded(child: GestureDetector(onTap: () => setState(() => _subtab = idx),
    child: AnimatedContainer(duration: const Duration(milliseconds: 200), padding: const EdgeInsets.symmetric(vertical: 7),
      decoration: BoxDecoration(color: _subtab == idx ? Colors.white : Colors.transparent, borderRadius: BorderRadius.circular(9)),
      child: Center(child: Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: _subtab == idx ? kPrimary : Colors.white70), textAlign: TextAlign.center)))));

  Widget _usersTab() => _filtered.isEmpty
      ? const Center(child: Text('No users found', style: TextStyle(color: kTextMid)))
      : ListView.builder(padding: const EdgeInsets.all(14), itemCount: _filtered.length,
          itemBuilder: (ctx, i) => _UserCard(user: _filtered[i],
            onApprove: () => _approveKyc(_filtered[i].id),
            onReject: () => _rejectKyc(_filtered[i].id),
            onGenerateBill: () => _generateBill(_filtered[i].id, _filtered[i].name),onRefresh: _load));

  Widget _kycTab() => _pendingKyc.isEmpty
      ? const Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Text('✅', style: TextStyle(fontSize: 48)), SizedBox(height: 12),
          Text('No pending KYC requests', style: TextStyle(fontSize: 14, color: kTextMid, fontWeight: FontWeight.w600))]))
      : ListView.builder(padding: const EdgeInsets.all(14), itemCount: _pendingKyc.length,
          itemBuilder: (ctx, i) => _KycCard(kyc: _pendingKyc[i],
            onApprove: () => _approveKyc(_pendingKyc[i].userId),
            onReject: () => _rejectKyc(_pendingKyc[i].userId)));

  Widget _extraTab() => _extraRequests.isEmpty
      ? const Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Text('📦', style: TextStyle(fontSize: 48)), SizedBox(height: 12),
          Text('No pending extra requests', style: TextStyle(fontSize: 14, color: kTextMid, fontWeight: FontWeight.w600))]))
      : ListView.builder(padding: const EdgeInsets.all(14), itemCount: _extraRequests.length,
          itemBuilder: (ctx, i) => _ExtraCard(req: _extraRequests[i], onAssign: () => _assignExtra(_extraRequests[i].id)));
}

class _UserCard extends StatefulWidget {
  final Future<void> Function() onRefresh;
  final ManagedUser user; final VoidCallback onApprove, onReject, onGenerateBill;
  const _UserCard({required this.user, required this.onApprove, required this.onReject, required this.onGenerateBill,
  required this.onRefresh });
  @override State<_UserCard> createState() => _UserCardState();
}
class _UserCardState extends State<_UserCard> {
  
Future<List<SubscriptionPlan>> _fetchPlans() async {
  try {
    final res = await ApiClient.get('/admin/plans');


    if (res['data'] == null) {
      throw Exception('Invalid API response');
    }

    return (res['data'] as List)
        .map((e) => SubscriptionPlan.fromJson(e))
        .toList();

  } catch (e) {
    print("FETCH PLAN ERROR: $e"); // 👈 DEBUG
    throw Exception('Failed to load plans');
  }
}
Future<void> _handleEditKyc(ManagedUser user) async {
  Map<String, dynamic>? kycData;

  try {
    final res = await ApiClient.get('/kyc/user/${user.id}');
    kycData = res['data'];
  } catch (e) {
    debugPrint("No existing KYC or error: $e");
  }

  if (!mounted) return;

  _openEditKycSheet(context, user, kycData);
}
void _openEditKycSheet(
  BuildContext context,
  ManagedUser user,
  Map<String, dynamic>? kyc,
) {
  final nameCtrl = TextEditingController(text: kyc?['fullName'] ?? user.name);
  final addrCtrl = TextEditingController(text: kyc?['address'] ?? user.address);
  final cityCtrl = TextEditingController(text: kyc?['city'] ?? '');
  final ZoneCtrl = TextEditingController(text: kyc?['zone'] ?? '');
  final pinCtrl = TextEditingController(text: kyc?['pincode'] ?? '');
  final altCtrl = TextEditingController(text: kyc?['alternateMobile'] ?? '');
  final waCtrl = TextEditingController(text: kyc?['whatsappNumber'] ?? '');
  final landmarkCtrl = TextEditingController(text: kyc?['landmark'] ?? '');
  final notesCtrl = TextEditingController(text: kyc?['notes'] ?? '');

  String freq = kyc?['deliveryFrequency'] ?? 'MORNING';
  String time = kyc?['preferredTime'] ?? '6:00 AM – 7:00 AM';
  double advance = (kyc?['advancePayment'] ?? 500).toDouble();

  bool isLoading = false;
  String? error;


  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => StatefulBuilder(
      builder: (context, setSheetState) {

        Future<void> _submitKyc() async {
          if (nameCtrl.text.trim().isEmpty ||
              addrCtrl.text.trim().isEmpty ||
              cityCtrl.text.trim().isEmpty) {
            setSheetState(() => error = 'Please fill all required fields');
            return;
          }

          setSheetState(() {
            isLoading = true;
            error = null;
          });

          try {
            await ApiClient.post('/kyc/admin/submit', {
              'customerId':user.id,
              'fullName': nameCtrl.text.trim(),
              'alternateMobile': altCtrl.text.trim(),
              'whatsappNumber': waCtrl.text.trim(),
              'address': addrCtrl.text.trim(),
              'landmark': landmarkCtrl.text.trim(),
              'city': cityCtrl.text.trim(),
              'zone':ZoneCtrl.text.trim(),
              'pincode': pinCtrl.text.trim(),
              'deliveryFrequency': freq,
              'preferredTime': time,
              'advancePayment': advance,
              'notes': notesCtrl.text.trim(),
            });
            await widget.onRefresh();

            Navigator.pop(context);

            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('KYC Saved Successfully'),
                backgroundColor: kGreen,
              ),
            );
        
          } catch (e) {
            setSheetState(() {
              error = e.toString().replaceAll('Exception: ', '');
            });
          } finally {
            setSheetState(() => isLoading = false);
          }
        }

     return DraggableScrollableSheet(
  initialChildSize: 0.78,
  minChildSize: 0.55,
  maxChildSize: 0.92,
  expand: false,
  builder: (context, scrollCtrl) {

    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFFF6F8FC), // soft background
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
      ),

      child: Column(
        children: [

          /// 🔷 HEADER
          Container(
            padding: const EdgeInsets.fromLTRB(16, 14, 10, 10),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
              boxShadow: [BoxShadow(color: Color(0x11000000), blurRadius: 6)],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: kPrimaryLt,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.verified_user_rounded, color: kPrimary, size: 18),
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'Edit KYC Details',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                )
              ],
            ),
          ),

          /// 🔷 BODY
          Expanded(
            child: SingleChildScrollView(
              controller: scrollCtrl,
              padding: const EdgeInsets.all(14),
              child: Column(
                children: [

                  /// 🧩 BASIC INFO
                  _sectionCard(
                    title: "Basic Info",
                    icon: Icons.person,
                    children: [
                      _iconField(nameCtrl, "Full Name", Icons.person_outline),
                    ],
                  ),

                  /// 🧩 ADDRESS
                  _sectionCard(
                    title: "Address",
                    icon: Icons.location_on,
                    children: [
                      _iconField(addrCtrl, "Address", Icons.home_outlined),
                      _iconField(
  pinCtrl,
  "Pincode",
  Icons.pin_drop_outlined,
  onChanged: (val) {
    if (val.length == 6) {
      _fetchPincodeDetails(val, (district, zone) {
        print(district);
        setSheetState(() {
          cityCtrl.text = district;
          ZoneCtrl.text = zone;
        });
      });
    }
  },
),
                      _iconField(cityCtrl, "City", Icons.location_city_outlined),
                      _iconField(ZoneCtrl, "Zone", Icons.location_city_outlined),
                      _iconField(landmarkCtrl, "Landmark", Icons.flag_outlined),
                    ],
                  ),

                  /// 🧩 CONTACT
                  _sectionCard(
                    title: "Contact",
                    icon: Icons.phone,
                    children: [
                      _iconField(altCtrl, "Alternate Mobile", Icons.phone_android),
                      _iconField(waCtrl, "WhatsApp", Icons.chat),
                    ],
                  ),

                  /// 🧩 NOTES
                  _sectionCard(
                    title: "Other",
                    icon: Icons.notes,
                    children: [
                      _iconField(notesCtrl, "Notes", Icons.sticky_note_2_outlined),
                    ],
                  ),

                  if (error != null) ...[
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline, color: Colors.red, size: 18),
                          const SizedBox(width: 8),
                          Expanded(child: Text(error!, style: const TextStyle(color: Colors.red))),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 80),
                ],
              ),
            ),
          ),

          /// 🔷 FOOTER
          Container(
            padding: const EdgeInsets.all(14),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: kBorder)),
            ),
            child: Row(
              children: [

                /// CANCEL
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close, size: 16),
                    label: const Text("Cancel"),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),

                const SizedBox(width: 10),

                /// SAVE
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: isLoading ? null : _submitKyc,
                    icon: isLoading
                        ? const SizedBox(
                            height: 16,
                            width: 16,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.check),
                    label: const Text("Save"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kPrimary,
  foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  },
);},
    ),
  );
}

Future<void> _fetchPincodeDetails(
  String pincode,
  Function(String district, String zone) onSuccess,
) async {
  try {
    final res = await ApiClient.getExternal(
      'https://api.postalpincode.in/pincode/$pincode',
    );

    final data = res[0];

    if (data['Status'] == 'Success') {
      final postOffice = data['PostOffice'][0];

      final district = postOffice['District'] ?? '';

      /// 🔥 Zone from UI map
      final zone = postOffice['Block'] ?? '';
      print(district);

      onSuccess(district, zone);
    }
  } catch (e) {
    debugPrint("Pincode fetch error: $e");
  }
}
Widget _sectionCard({
  required String title,
  required IconData icon,
  required List<Widget> children,
}) {
  return Container(
    margin: const EdgeInsets.only(bottom: 12),
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      boxShadow: const [BoxShadow(color: Color(0x08000000), blurRadius: 6)],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: kPrimary),
            const SizedBox(width: 6),
            Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
          ],
        ),
        const SizedBox(height: 10),
        ...children,
      ],
    ),
  );
}

Widget _iconField(
  TextEditingController ctrl,
  String label,
  IconData icon, {
  Function(String)? onChanged,
}) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: TextField(
      controller: ctrl,
      onChanged: onChanged, // ✅ THIS LINE WAS MISSING
      style: const TextStyle(fontSize: 12),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 18, color: kPrimary),
        filled: true,
        fillColor: const Color(0xFFF9FBFF),
        contentPadding: const EdgeInsets.symmetric(vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: kBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: kBorder),
        ),
      ),
    ),
  );
}

void _openSubscriptionSheet(BuildContext context, ManagedUser user) {
  SubscriptionPlan? selectedPlan;
  int selectedQty = 500;
  bool isSubmitting = false;
final plansFuture = _fetchPlans();
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => StatefulBuilder(
      builder: (context, setSheetState) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                20,
                16,
                20,
                MediaQuery.of(context).viewInsets.bottom + 16,
              ),
              child: FutureBuilder<List<SubscriptionPlan>>(
                future: plansFuture,
                builder: (context, snapshot) {

                  /// 🔴 ERROR
                  if (snapshot.hasError) {
                    return const SizedBox(
                      height: 200,
                      child: Center(child: Text('Failed to load plans')),
                    );
                  }

                  /// 🟡 LOADING
                  if (!snapshot.hasData) {
                    return const SizedBox(
                      height: 200,
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }

                  final plans = snapshot.data!;
                  selectedPlan ??= plans.first;

                  return SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [

                        /// 🔹 Drag Handle
                        Center(
                          child: Container(
                            width: 40,
                            height: 4,
                            margin: const EdgeInsets.only(bottom: 16),
                            decoration: BoxDecoration(
                              color: Colors.grey[300],
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),

                        /// 🔹 Title
                        const Text(
                          'New Subscription',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                        ),

                        const SizedBox(height: 4),

                        Text(
                          'Creating plan for ${user.name}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: kTextMid,
                          ),
                        ),

                        const SizedBox(height: 20),

                        /// 🔹 SELECT VARIETY (Dropdown)
                        _label('SELECT VARIETY'),
                        const SizedBox(height: 8),

                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF5F5F5),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: kBorder),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<SubscriptionPlan>(
                              value: selectedPlan,
                              isExpanded: true,
                              icon: const Icon(Icons.keyboard_arrow_down_rounded),
                              items: plans.map((p) {
                                return DropdownMenuItem(
                                  value: p,
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        "${p.name} (₹${p.price.toStringAsFixed(0)})",
                                        style: const TextStyle(fontSize: 13),
                                      ),
                                      if (selectedPlan == p)
                                        const Icon(Icons.check, color: kPrimary, size: 18),
                                    ],
                                  ),
                                );
                              }).toList(),
                              onChanged: (val) {
                                setSheetState(() => selectedPlan = val);
                              },
                            ),
                          ),
                        ),

                        const SizedBox(height: 20),

                        /// 🔹 QUANTITY
                        _label('QUANTITY (ML)'),
                        const SizedBox(height: 8),

                        Wrap(
                          spacing: 10,
                          children: ['500', '1000'].map((q) {
                            final selected = selectedQty.toString() == q;

                            return ChoiceChip(
                              label: Text(
                                q,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: selected ? Colors.white : kTextDark,
                                ),
                              ),
                              selected: selected,
                              selectedColor: kPrimary,
                              checkmarkColor: Colors.white,
                              backgroundColor: const Color(0xFFF5F5F5),
                              onSelected: (_) => setSheetState(
                                () => selectedQty = int.parse(q),
                              ),
                            );
                          }).toList(),
                        ),

                        const SizedBox(height: 20),

                        /// 🔹 DELIVERY TIME (Fixed)
                        _label('DELIVERY TIME'),
                        const SizedBox(height: 8),

                        Container(
                          padding: const EdgeInsets.symmetric(
                            vertical: 12,
                            horizontal: 12,
                          ),
                          decoration: BoxDecoration(
                            color: kPrimaryLt,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            children: const [
                              Icon(Icons.wb_sunny_rounded,
                                  size: 18, color: kPrimary),
                              SizedBox(width: 8),
                              Text(
                                'Morning Delivery',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: kPrimary,
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 30),

                        /// 🔹 BUTTON
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: kPrimary,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            onPressed: isSubmitting
                                ? null
                                : () async {
                                    setSheetState(() => isSubmitting = true);

                                    await _submit(
                                      user.id,
                                      selectedPlan!.name,
                                      selectedQty,
                                      'MORNING', // ✅ fixed
                                    );

                                    setSheetState(() => isSubmitting = false);
                                  },
                            child: isSubmitting
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Text(
                                    'Activate Subscription',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                          ),
                        ),

                        const SizedBox(height: 10),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        );
      },
    ),
  );
}
Future<void> _submit(int uid, String plan, int qty, String freq) async {
  try {
    await ApiClient.post('/admin/subscribe',  {
      'customerId': uid, 'planName': plan, 'quantityMl': qty, 'frequency': freq
    });
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Plan Activated!'), backgroundColor: kGreen));
  } catch (e) {
    _showErrorDialog(e.toString());
  }
}

void _showErrorDialog(String msg) {
  showDialog(context: context, builder: (ctx) => AlertDialog(
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
    title: const Text('Action Required', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
    content: Text(msg.contains('already') ? 'This user has an active plan. End the current plan before starting a new one.' : msg),
    actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('OK'))],
  ));
}

Widget _label(String t) => Padding(padding: const EdgeInsets.only(bottom: 8), child: Text(t, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: kTextLight)));


  bool _expanded = false;
  @override Widget build(BuildContext context) {
    final u = widget.user;
    return Container(margin: const EdgeInsets.only(bottom: 10), decoration: BoxDecoration(color: kCard, borderRadius: BorderRadius.circular(16),
      border: Border.all(color: u.isPending ? const Color(0xFFFFCC80) : kBorder, width: u.isPending ? 1.5 : 1),
      boxShadow: const [BoxShadow(color: Color(0x08000000), blurRadius: 8, offset: Offset(0,2))]),
      child: Column(children: [
        Padding(padding: const EdgeInsets.all(13), child: Column(children: [
          Row(children: [
            Container(width: 42, height: 42, decoration: BoxDecoration(color: u.kycBg, borderRadius: BorderRadius.circular(21)),
              child: Center(child: Text(u.initials, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: u.kycColor)))),
            const SizedBox(width: 10),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Expanded(child: Text(u.name.isNotEmpty ? u.name : 'Unnamed User', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: kTextDark))),
                _badge(u.kycLabel, u.kycColor, u.kycBg),
              ]),
              const SizedBox(height: 3),
              Text('+91 ${u.mobile} · Wallet: ₹${u.walletBalance.toStringAsFixed(0)}', style: const TextStyle(fontSize: 10, color: kTextMid)),
            ])),
            GestureDetector(onTap: () => setState(() => _expanded = !_expanded),
              child: AnimatedRotation(turns: _expanded ? 0.5 : 0, duration: const Duration(milliseconds: 200),
                child: const Icon(Icons.keyboard_arrow_down_rounded, color: kTextLight, size: 22))),
          ]),
          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: Padding(padding: const EdgeInsets.only(top: 10), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Divider(color: kBorder, height: 1), const SizedBox(height: 10),
              if (u.address.isNotEmpty) _det(Icons.location_on_rounded, u.address),
              if (u.zone.isNotEmpty) ...[const SizedBox(height: 5), _det(Icons.map_rounded, 'Zone: ${u.zone}')],
            ])),
            crossFadeState: _expanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 200)),
        ])),
        Container(decoration: const BoxDecoration(border: Border(top: BorderSide(color: kBorder))), padding: const EdgeInsets.all(12),
          child: u.isPending
              ? Row(children: [
                  Expanded(child: ASmallButton(label: '✓ Approve KYC', color: kGreen, bg: kGreenLt, onTap: widget.onApprove)),
                  const SizedBox(width: 8),
                  ASmallButton(label: 'Reject', color: kRed, bg: kRedLt, onTap: widget.onReject),
                ])
              : u.isVerified
                  ? // Inside _UserCardState -> build() -> u.isVerified block
Row(children: [
    Expanded(child: ASmallButton(label: 'Generate Monthly Bill', color: kPrimary, bg: kPrimaryLt, onTap: widget.onGenerateBill)),
    const SizedBox(width: 8),
    // ADD THIS BUTTON:
    ASmallButton(label: '+ Sub', color: kGreen, bg: kGreenLt, onTap: () => _openSubscriptionSheet(context, u)),
    const SizedBox(width: 8),
    ASmallButton(
  label: 'Edit',
  color: kPrimary,
  bg: kPrimaryLt,
  onTap: () => _handleEditKyc(u),
),
])
                  : Container(width: double.infinity, padding: const EdgeInsets.symmetric(vertical: 9), decoration: BoxDecoration(color: kRedLt, borderRadius: BorderRadius.circular(9)),
                      child: const Center(child: Text('KYC Rejected', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: kRed))))),
      ]));
  }
  Widget _badge(String label, Color color, Color bg) => Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3), decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
    child: Text(label, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: color)));
  Widget _det(IconData icon, String text) => Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Icon(icon, size: 13, color: kTextLight), const SizedBox(width: 6),
    Expanded(child: Text(text, style: const TextStyle(fontSize: 10, color: kTextMid, height: 1.4))),
  ]);
}

class _KycCard extends StatelessWidget {
  final KycItem kyc; final VoidCallback onApprove, onReject;
  const _KycCard({required this.kyc, required this.onApprove, required this.onReject});
  @override Widget build(BuildContext context) => ACard(
    borderColor: const Color(0xFFFFCC80), borderWidth: 1.5,
    padding: EdgeInsets.zero,
    child: Column(children: [
      Padding(padding: const EdgeInsets.all(14), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(width: 42, height: 42, decoration: BoxDecoration(color: kOrangeLt, borderRadius: BorderRadius.circular(21)),
            child: Center(child: Text(kyc.fullName.isNotEmpty ? kyc.fullName[0] : '?', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: kOrange)))),
          const SizedBox(width: 10),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(kyc.fullName, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: kTextDark)),
            Text('+91 ${kyc.mobile}', style: const TextStyle(fontSize: 11, color: kTextMid)),
          ])),
          Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3), decoration: BoxDecoration(color: kOrangeLt, borderRadius: BorderRadius.circular(20), border: Border.all(color: const Color(0xFFFFCC80))),
            child: const Text('KYC Pending', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: kOrange))),
        ]),
        const SizedBox(height: 10), const Divider(color: kBorder, height: 1), const SizedBox(height: 10),
        _row(Icons.phone_rounded, 'Mobile', '+91 ${kyc.mobile}'),
        if (kyc.alternateMobile.isNotEmpty) ...[const SizedBox(height: 5), _row(Icons.phone_outlined, 'Alternate', '+91 ${kyc.alternateMobile}')],
        if (kyc.whatsapp.isNotEmpty) ...[const SizedBox(height: 5), _row(Icons.chat_rounded, 'WhatsApp', '+91 ${kyc.whatsapp}')],
        const SizedBox(height: 5),
        _row(Icons.location_on_rounded, 'Address', kyc.address),
        if (kyc.landmark.isNotEmpty) ...[const SizedBox(height: 5), _row(Icons.flag_rounded, 'Landmark', kyc.landmark)],
        if (kyc.city.isNotEmpty) ...[const SizedBox(height: 5), _row(Icons.location_city_rounded, 'City / PIN', '${kyc.city} - ${kyc.pincode}')],
        const SizedBox(height: 5),
        _row(Icons.schedule_rounded, 'Delivery', '${kyc.frequency} · ${kyc.preferredTime}'),
        const SizedBox(height: 5),
        Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: kOrangeLt, borderRadius: BorderRadius.circular(10)), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          const Text('Advance Payment', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: kOrange)),
          Text('₹${kyc.advancePayment.toStringAsFixed(0)} — ${kyc.advancePaid ? "Paid ✓" : "Not paid"}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: kOrange)),
        ])),
        if (kyc.notes.isNotEmpty) ...[const SizedBox(height: 5), _row(Icons.notes_rounded, 'Notes', kyc.notes)],
      ])),
      Container(decoration: const BoxDecoration(border: Border(top: BorderSide(color: kBorder))), padding: const EdgeInsets.all(12),
        child: Row(children: [
          Expanded(child: ASmallButton(label: '✓ Approve Location', color: kGreen, bg: kGreenLt, onTap: onApprove)),
          const SizedBox(width: 8),
          ASmallButton(label: 'Reject', color: kRed, bg: kRedLt, onTap: onReject),
        ])),
    ]),
  );
  Widget _row(IconData icon, String label, String val) => Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Icon(icon, size: 13, color: kTextLight), const SizedBox(width: 6),
    Text('$label: ', style: const TextStyle(fontSize: 10, color: kTextLight)),
    Expanded(child: Text(val, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: kTextDark, height: 1.4))),
  ]);
}

class _ExtraCard extends StatelessWidget {
  final ExtraReq req; final VoidCallback onAssign;
  const _ExtraCard({required this.req, required this.onAssign});
  @override Widget build(BuildContext context) => ACard(
    borderColor: const Color(0xFFFFCC80), borderWidth: 1.5, padding: EdgeInsets.zero,
    child: Column(children: [
      Padding(padding: const EdgeInsets.all(14), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(width: 42, height: 42, decoration: BoxDecoration(color: kOrangeLt, borderRadius: BorderRadius.circular(12)), child: const Center(child: Text('📦', style: TextStyle(fontSize: 22)))),
          const SizedBox(width: 10),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(req.itemDescription, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: kTextDark)),
            Text('Customer: ${req.customerName}', style: const TextStyle(fontSize: 11, color: kTextMid)),
          ])),
          Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3), decoration: BoxDecoration(color: kOrangeLt, borderRadius: BorderRadius.circular(20), border: Border.all(color: const Color(0xFFFFCC80))),
            child: const Text('Pending', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: kOrange))),
        ]),
        const SizedBox(height: 10),
        Row(children: [
          _tag(Icons.shopping_bag_rounded, 'Qty: ${req.quantity}', kPrimary, kPrimaryLt),
          const SizedBox(width: 8),
          _tag(Icons.local_shipping_rounded, '${req.distanceKm.toStringAsFixed(1)}km · ₹${req.deliveryCharge.toStringAsFixed(0)}', kOrange, kOrangeLt),
        ]),
        const SizedBox(height: 5),
        Text('Requested by: ${req.requestedBy}', style: const TextStyle(fontSize: 10, color: kTextLight)),
        Text(req.customerAddress, style: const TextStyle(fontSize: 10, color: kTextMid, height: 1.4)),
      ])),
      Container(decoration: const BoxDecoration(border: Border(top: BorderSide(color: kBorder))), padding: const EdgeInsets.all(12),
        child: ASmallButton(label: '🚚  Assign Driver (Ravi Kumar)', color: kGreen, bg: kGreenLt, onTap: onAssign)),
    ]),
  );
  Widget _tag(IconData icon, String label, Color color, Color bg) => Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
    child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(icon, size: 11, color: color), const SizedBox(width: 4), Text(label, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: color))]));
}
