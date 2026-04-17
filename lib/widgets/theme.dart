import 'package:flutter/material.dart';

// ── Colors ───────────────────────────────────────────────────────────────────
const Color kPrimary   = Color(0xFF1565C0);
const Color kPrimaryLt = Color(0xFFE3F2FD);
const Color kPrimaryDk = Color(0xFF0D47A1);
const Color kGreen     = Color(0xFF2E7D32);
const Color kGreenLt   = Color(0xFFE8F5E9);
const Color kOrange    = Color(0xFFE65100);
const Color kOrangeLt  = Color(0xFFFFF3E0);
const Color kBg        = Color(0xFFEEF3FA);
const Color kCard      = Color(0xFFFFFFFF);
const Color kBorder    = Color(0xFFE3F2FD);
const Color kTextDark  = Color(0xFF1A237E);
const Color kTextMid   = Color(0xFF607D8B);
const Color kTextLight = Color(0xFF90A4AE);
const Color kRed       = Color(0xFFC62828);
const Color kRedLt     = Color(0xFFFCEBEB);

// ── Models ───────────────────────────────────────────────────────────────────
class DashboardData {
  final double totalMrr, oneTimeSales, serviceFees;
  final int totalUsers, pendingKyc, totalDeliveriesToday, deliveredToday, pendingToday;

  DashboardData.fromJson(Map<String, dynamic> j)
      : totalMrr = (j['totalMrr'] as num?)?.toDouble() ?? 0,
        oneTimeSales = (j['oneTimeSales'] as num?)?.toDouble() ?? 0,
        serviceFees = (j['serviceFees'] as num?)?.toDouble() ?? 0,
        totalUsers = (j['totalUsers'] as num?)?.toInt() ?? 0,
        pendingKyc = (j['pendingKyc'] as num?)?.toInt() ?? 0,
        totalDeliveriesToday = (j['totalDeliveriesToday'] as num?)?.toInt() ?? 0,
        deliveredToday = (j['deliveredToday'] as num?)?.toInt() ?? 0,
        pendingToday = (j['pendingToday'] as num?)?.toInt() ?? 0;
}

class ManagedUser {
  final int id;
  final String name, mobile, address, zone;
  double walletBalance;
  String kycStatus;

  ManagedUser.fromJson(Map<String, dynamic> j)
      : id = j['id'] ?? 0,
        name = j['name'] ?? '',
        mobile = j['mobile'] ?? '',
        address = j['address'] ?? '',
        zone = j['zone'] ?? '',
        walletBalance = (j['walletBalance'] as num?)?.toDouble() ?? 0.0,
        kycStatus = j['kycStatus'] ?? 'PENDING';

  String get initials {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    if (name.isNotEmpty && name.length >= 2) return name.substring(0, 2).toUpperCase();
    return mobile.length >= 2 ? mobile.substring(0, 2) : '??';
  }

  bool get isVerified => kycStatus == 'VERIFIED';
  bool get isPending  => kycStatus == 'PENDING';
  bool get isRejected => kycStatus == 'REJECTED';

  Color get kycColor => isVerified ? kGreen : isPending ? kOrange : kRed;
  Color get kycBg    => isVerified ? kGreenLt : isPending ? kOrangeLt : kRedLt;
  String get kycLabel => isVerified ? 'Verified' : isPending ? 'KYC Pending' : 'Rejected';
}

class GeneratedBill {
  final int id, billMonth, billYear;
  final double subscriptionAmount, oneTimeAmount, extraFeeAmount, totalAmount;
  final String status;

  GeneratedBill.fromJson(Map<String, dynamic> j)
      : id = j['id'] ?? 0,
        billMonth = j['billMonth'] ?? 0,
        billYear = j['billYear'] ?? 0,
        subscriptionAmount = (j['subscriptionAmount'] as num?)?.toDouble() ?? 0,
        oneTimeAmount = (j['oneTimeAmount'] as num?)?.toDouble() ?? 0,
        extraFeeAmount = (j['extraFeeAmount'] as num?)?.toDouble() ?? 0,
        totalAmount = (j['totalAmount'] as num?)?.toDouble() ?? 0,
        status = j['status'] ?? 'GENERATED';
}

// ── Shared Widgets ────────────────────────────────────────────────────────────
class AAvatar extends StatelessWidget {
  final String initials;
  final double size;
  const AAvatar({super.key, required this.initials, this.size = 40});
  @override
  Widget build(BuildContext context) => Container(
    width: size, height: size,
    decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(size / 2)),
    child: Center(child: Text(initials,
        style: TextStyle(fontSize: size * 0.32, fontWeight: FontWeight.w700, color: Colors.white))),
  );
}

class ACard extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final Color? borderColor;
  final double borderWidth;
  const ACard({super.key, required this.child, this.padding, this.borderColor, this.borderWidth = 1});
  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      color: kCard, borderRadius: BorderRadius.circular(16),
      border: Border.all(color: borderColor ?? kBorder, width: borderWidth),
      boxShadow: const [BoxShadow(color: Color(0x08000000), blurRadius: 8, offset: Offset(0, 2))],
    ),
    padding: padding ?? const EdgeInsets.all(14),
    child: child,
  );
}

class ASmallButton extends StatefulWidget {
  final String label;
  final Color color, bg;
  final VoidCallback? onTap;
  final bool loading;
  const ASmallButton({super.key, required this.label, required this.color, required this.bg, this.onTap, this.loading = false});
  @override State<ASmallButton> createState() => _ASmallButtonState();
}
class _ASmallButtonState extends State<ASmallButton> {
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: widget.loading ? null : widget.onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 12),
      decoration: BoxDecoration(color: widget.bg, borderRadius: BorderRadius.circular(10), border: Border.all(color: widget.color.withOpacity(0.3))),
      child: widget.loading
          ? Center(child: SizedBox(height: 16, width: 16, child: CircularProgressIndicator(color: widget.color, strokeWidth: 2)))
          : Center(child: Text(widget.label, textAlign: TextAlign.center,
              style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: widget.color))),
    ),
  );
}

class ASectionTitle extends StatelessWidget {
  final String title;
  const ASectionTitle({super.key, required this.title});
  @override
  Widget build(BuildContext context) => Text(title,
      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: kTextDark, letterSpacing: 0.3));
}

Widget aHeader(String title, String subtitle) => Container(
  color: kPrimary,
  child: SafeArea(bottom: false, child: Padding(
    padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
    child: Row(children: [
      const AAvatar(initials: 'AD'),
      const SizedBox(width: 10),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white)),
        Text(subtitle, style: const TextStyle(fontSize: 11, color: Color(0xFF90CAF9))),
      ])),
      const Icon(Icons.more_vert_rounded, color: Colors.white, size: 22),
    ]),
  )),
);

class KycItem {
  final int id, userId;
  final String fullName, mobile, alternateMobile, whatsapp;
  final String address, landmark, city, pincode;
  final String frequency, preferredTime, notes;
  final double advancePayment;
  final bool advancePaid;

  KycItem.fromJson(Map<String, dynamic> j)
      : id = j['id'] ?? 0,
        userId = j['userId'] ?? 0,
        fullName = j['fullName'] ?? '',
        mobile = j['mobile'] ?? '',
        alternateMobile = j['alternateMobile'] ?? '',
        whatsapp = j['whatsappNumber'] ?? '',
        address = j['address'] ?? '',
        landmark = j['landmark'] ?? '',
        city = j['city'] ?? '',
        pincode = j['pincode'] ?? '',
        frequency = j['deliveryFrequency'] ?? 'MORNING',
        preferredTime = j['preferredTime'] ?? '',
        notes = j['notes'] ?? '',
        advancePayment = (j['advancePayment'] as num?)?.toDouble() ?? 500.0,
        advancePaid = j['advancePaid'] ?? false;
}

class ExtraReq {
  final int id, customerId;
  final String customerName, customerAddress;
  final String requestedBy, itemDescription, quantity, status;
  final double distanceKm, deliveryCharge;

  ExtraReq.fromJson(Map<String, dynamic> j)
      : id = j['id'] ?? 0,
        customerId = j['customerId'] ?? 0,
        customerName = j['customerName'] ?? '',
        customerAddress = j['customerAddress'] ?? '',
        requestedBy = j['requestedByName'] ?? '',
        itemDescription = j['itemDescription'] ?? '',
        quantity = j['quantity'] ?? '',
        status = j['status'] ?? 'PENDING',
        distanceKm = (j['distanceKm'] as num?)?.toDouble() ?? 0.0,
        deliveryCharge = (j['deliveryCharge'] as num?)?.toDouble() ?? 10.0;
}
