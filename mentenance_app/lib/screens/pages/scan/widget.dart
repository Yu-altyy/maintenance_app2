import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:mentenance_app/screens/pages/reports/report_sheet.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:flutter_nfc_kit/flutter_nfc_kit.dart';
import 'package:mentenance_app/core/constant/constant.dart';

/// 🟢 ويدجيت الكاميرا باستخدام mobile_scanner لقراءة QR
class CameraBox extends StatelessWidget {
  final void Function(String)? onDetect;

  const CameraBox({super.key, this.onDetect});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: MediaQuery.of(context).size.width,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.secondary, width: 2),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: MobileScanner(
          onDetect: (barcodeCapture) {
            final barcodes = barcodeCapture.barcodes;
            if (barcodes.isNotEmpty) {
              final code = barcodes.first.rawValue;
              if (code != null) {
                if (onDetect != null) onDetect!(code);

                // عرض Popup تلقائي عند قراءة QR
                showDialog(
                  context: context,
                  builder:
                      (_) => ScanPopup(
                        icon: Icons.qr_code,
                        title: 'تم مسح QR',
                        message: code,
                        color: AppColors.secondary,
                      ),
                );
              }
            }
          },
        ),
      ),
    );
  }
}

/// 🟢 ويدجيت التعليمات
class ScanInstructions extends StatelessWidget {
  const ScanInstructions({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'كيفية المسح:',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.black87,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 8),
        _buildRow(
          Icons.qr_code_2,
          AppColors.secondary,
          'وجه الكاميرا نحو رمز QR على الجهاز',
        ),
        _buildRow(
          Icons.nfc_sharp,
          AppColors.primary,
          'أو قرب الهاتف من منطقة NFC',
        ),
        _buildRow(
          Icons.usb,
          AppColors.secondary,
          'أو اشبك هاتفك مع الجهاز عبر USB',
        ),
      ],
    );
  }

  Widget _buildRow(IconData icon, Color color, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text, style: const TextStyle(color: Colors.black54)),
          ),
        ],
      ),
    );
  }
}

//
// ======= Helpers for NDEF parsing =======
//

Uint8List _toBytes(dynamic payload) {
  if (payload == null) return Uint8List(0);
  if (payload is Uint8List) return payload;
  if (payload is List<int>) return Uint8List.fromList(payload);
  if (payload is String) {
    // flutter_nfc_kit sometimes returns base64-encoded string or raw string
    // try base64 first, then utf8 bytes
    try {
      return base64.decode(payload);
    } catch (_) {
      return Uint8List.fromList(utf8.encode(payload));
    }
  }
  return Uint8List(0);
}

String _toHex(Uint8List bytes, {String sep = ':'}) =>
    bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join(sep);

bool _looksLikeText(Uint8List bytes) {
  if (bytes.isEmpty) return false;
  // check proportion of printable ascii / utf8
  int nonPrintable = 0;
  for (var b in bytes) {
    if (b == 9 || b == 10 || b == 13) continue;
    if (b < 32 || b > 126) nonPrintable++;
  }
  return nonPrintable < bytes.length * 0.3;
}

/// NDEF URI prefix table (per spec)
String _ndefUriPrefix(int code) {
  const prefixes = [
    "",
    "http://www.",
    "https://www.",
    "http://",
    "https://",
    "tel:",
    "mailto:",
    "ftp://anonymous:anonymous@",
    "ftp://ftp.",
    "ftps://",
    "sftp://",
    "smb://",
    "nfs://",
    "ftp://",
    "dav://",
    "news:",
    "telnet://",
    "imap:",
    "rtsp://",
    "urn:",
    "pop:",
    "sip:",
    "sips:",
    "tftp:",
    "btspp://",
    "btl2cap://",
    "btgoep://",
    "tcpobex://",
    "irdaobex://",
    "file://",
    "urn:epc:id:",
    "urn:epc:tag:",
    "urn:epc:pat:",
    "urn:epc:raw:",
    "urn:epc:",
    "urn:nfc:",
  ];
  if (code >= 0 && code < prefixes.length) return prefixes[code];
  return '';
}

/// Parse one NDEF record into human-readable string (handles Text, URI, MIME, binary)
String parseNdefRecord(dynamic rec) {
  // rec expected fields: type, payload, id (varies by platform)
  final rawType = rec.type ?? '';
  final typeStr =
      rawType is Uint8List
          ? utf8.decode(rawType, allowMalformed: true)
          : rawType.toString();

  final bytes = _toBytes(rec.payload);

  // Well-known Text (T) and URI (U) types are encoded by one-letter type 'T'/'U' on some libs.
  // But flutter_nfc_kit may return types differently; try heuristics.
  try {
    // Text record (NFC Forum "T")
    if (typeStr == 'T' ||
        typeStr.toLowerCase() == 'text' ||
        typeStr.toLowerCase().contains('text')) {
      if (bytes.isEmpty) return 'Text: <empty>';
      final status = bytes[0];
      final isUtf16 = (status & 0x80) != 0;
      final langLen = status & 0x3f;
      final payload = bytes.sublist(1 + langLen);
      try {
        final text =
            isUtf16
                ? utf8.decode(
                  payload,
                  allowMalformed: true,
                ) // best-effort (often UTF-8)
                : utf8.decode(payload, allowMalformed: true);
        return 'Text: $text';
      } catch (_) {
        return 'Text (raw hex): ${_toHex(payload)}';
      }
    }

    // URI record (NFC Forum "U")
    if (typeStr == 'U' || typeStr.toLowerCase().contains('uri')) {
      if (bytes.isEmpty) return 'URI: <empty>';
      final idCode = bytes[0];
      final uriPayload = bytes.sublist(1);
      final uriStr = utf8.decode(uriPayload, allowMalformed: true);
      final prefix = _ndefUriPrefix(idCode);
      return 'URI: $prefix$uriStr';
    }

    // MIME type (e.g., "text/plain", "application/json", "image/png")
    if (typeStr.contains('/') || (typeStr.toLowerCase().startsWith('mime'))) {
      final mime = typeStr;
      // try to decode as UTF-8 text if looks like text
      if (_looksLikeText(bytes)) {
        final text = utf8.decode(bytes, allowMalformed: true);
        return 'MIME ($mime): $text';
      } else {
        // binary: show base64 and hex
        final b64 = base64.encode(bytes);
        return 'MIME ($mime): (base64) $b64\n(hex) ${_toHex(bytes)}';
      }
    }

    // Smart Poster or other well-known types: try to interpret text inside
    if (typeStr.toLowerCase().contains('sp') ||
        typeStr.toLowerCase().contains('smart')) {
      if (_looksLikeText(bytes)) {
        final text = utf8.decode(bytes, allowMalformed: true);
        return 'SmartPoster: $text';
      }
      return 'SmartPoster (raw hex): ${_toHex(bytes)}';
    }

    // Fallbacks:
    // 1) If looks textual -> decode utf8
    if (_looksLikeText(bytes)) {
      final text = utf8.decode(bytes, allowMalformed: true);
      return 'Text (auto): $text';
    }

    // 2) Try as ASCII / printable
    try {
      final maybe = utf8.decode(bytes, allowMalformed: true);
      if (maybe.trim().isNotEmpty) return 'Text (auto2): $maybe';
    } catch (_) {}

    // 3) else return hex + base64
    final b64 = base64.encode(bytes);
    return 'Raw (base64): $b64\n(hex): ${_toHex(bytes)}';
  } catch (e) {
    final b64 = base64.encode(bytes);
    return 'Parsing error: ${e.toString()}\nRaw (base64): $b64\n(hex): ${_toHex(bytes)}';
  }
}

//
// ======= ActionButtons with NFC reading (NDEF smart parsing) =======
//

class ActionButtons extends StatelessWidget {
  const ActionButtons({super.key});

  void _showPopup(BuildContext context, Widget popup) {
    showDialog(context: context, builder: (_) => popup);
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // QR Button (محاكاة)
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () => _showPopup(context, const QrScanPopup()),
            icon: const Icon(Icons.qr_code, color: Colors.white),
            label: const Text(
              'مسح QR\nمحاكاة',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.secondary,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),

        // NFC Button مع قراءة NFC حقيقي ومحتوى NDEF مفكوك
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () async {
              try {
                // بدء جلسة NFC - ينتظر حتى يمر التاج أمام الهاتف
                final NFCTag tag = await FlutterNfcKit.poll(
                  timeout: const Duration(seconds: 20),
                );

                // اقرأ سجلات NDEF (قد ترمي استثناء إذا غير مدعوم)
                String ndefContent = '';
                try {
                  final records = await FlutterNfcKit.readNDEFRecords();
                  if (records.isEmpty) {
                    ndefContent = 'لا يوجد محتوى NDEF';
                  } else {
                    int idx = 0;
                    for (var rec in records) {
                      idx++;
                      final parsed = parseNdefRecord(rec);
                      ndefContent +=
                          'Record #$idx\nType(raw): ${rec.type}\nParsed: $parsed\n\n';
                    }
                  }
                } catch (_) {
                  ndefContent = 'لا يمكن قراءة محتوى NDEF (غير مدعوم أو خطأ)';
                }

                // جهّز معلومات التاج - best-effort
                final tagInfo = StringBuffer();
                tagInfo.writeln('-- Chip Info --\n');
                // NFCTag provides type/id/standard; include raw toString for extra data
                tagInfo.writeln('Serial Number: ${_formatId(tag.id)}');
                tagInfo.writeln('Type: ${tag.type}');
                tagInfo.writeln('Standard: ${tag.standard ?? 'غير متوفر'}');
                // include raw representation if available
                try {
                  tagInfo.writeln('\nRaw Tag: ${tag.toString()}');
                } catch (_) {}

                final message = '$tagInfo\nNDEF Content:\n$ndefContent';

                // انهي الجلسة
                try {
                  await FlutterNfcKit.finish();
                } catch (_) {}

                // عرض البوب آپ
                if (context.mounted) {
                  showDialog(
                    context: context,
                    builder:
                        (_) => ScanPopup(
                          icon: Icons.nfc,
                          title: 'تم مسح NFC',
                          message: message,
                          color: AppColors.primary,
                        ),
                  );
                }
              } catch (e) {
                try {
                  await FlutterNfcKit.finish();
                } catch (_) {}
                if (context.mounted) {
                  showDialog(
                    context: context,
                    builder:
                        (_) => ScanPopup(
                          icon: Icons.nfc,
                          title: 'حدث خطأ أثناء قراءة NFC',
                          message: e.toString(),
                          color: Colors.red,
                        ),
                  );
                }
              }
            },
            icon: const Icon(Icons.nfc, color: Colors.white),
            label: const Text(
              'مسح NFC\nحقيقي',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),

        const SizedBox(width: 12),

        // USB Button (محاكاة)
        Expanded(
          child: ElevatedButton.icon(
            onPressed:
                () => _showPopup(
                  context,
                  const UsbScanPopup(
                    technician: "Ahmed Mohamed Ali",
                    deviceSerial: "PROSCAN-6P-001247",
                    deviceLocation: "Damascus Main Branch",
                    connectionType: "USB",
                  ),
                ),
            icon: const Icon(Icons.usb, color: Colors.white),
            label: const Text(
              'مسح USB\nمحاكاة',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.secondary,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),
      ],
    );
  }

  String _formatId(String? id) {
    if (id == null || id.isEmpty) return 'غير متوفر';
    // format like 9f:73:ee:00:04:45:03 if hex string length even
    final cleaned = id.replaceAll(RegExp(r'[^0-9a-fA-F]'), '');
    if (cleaned.length % 2 != 0) return id;
    final bytes = [
      for (var i = 0; i < cleaned.length; i += 2) cleaned.substring(i, i + 2),
    ];
    return bytes.map((s) => s.toLowerCase()).join(':');
  }
}

/// 🟢 ويدجيت الكارد
class RecentDeviceCard extends StatelessWidget {
  const RecentDeviceCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text(
                'PROSCAN-6P-001247',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              SizedBox(height: 4),
              Text(
                'فرع الرياض الرئيسي',
                style: TextStyle(color: Colors.black45, fontSize: 13),
              ),
            ],
          ),
          Text(
            'قبل 5 دقائق',
            style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

/// 🟢 ويدجيت البوب اب
class ScanPopup extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final Color color;

  const ScanPopup({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: Colors.white,
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(24),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(height: 24),
                    CircleAvatar(
                      backgroundColor: color.withOpacity(0.1),
                      radius: 36,
                      child: Icon(icon, color: color, size: 40),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      title,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: color,
                        fontSize: 20,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      message,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.black87,
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              top: 8,
              left: 8,
              child: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: const Icon(Icons.close, color: Colors.black54, size: 28),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// بوب اب QR
class QrScanPopup extends StatelessWidget {
  const QrScanPopup({super.key});

  @override
  Widget build(BuildContext context) {
    return const ScanPopup(
      icon: Icons.qr_code,
      title: 'مسح QR',
      message: 'قرب الكاميرا من رمز QR لقراءته...',
      color: AppColors.secondary,
    );
  }
}

/// بوب اب NFC محاكي
class NfcScanPopup extends StatelessWidget {
  const NfcScanPopup({super.key});

  @override
  Widget build(BuildContext context) {
    return const ScanPopup(
      icon: Icons.nfc,
      title: 'مسح NFC',
      message: 'قرب هاتفك من منطقة NFC الخاصة بالجهاز...',
      color: AppColors.primary,
    );
  }
}

class UsbScanPopup extends StatefulWidget {
  final String technician;
  final String deviceSerial;
  final String deviceLocation;
  final String connectionType;

  const UsbScanPopup({
    super.key,
    required this.technician,
    required this.deviceSerial,
    required this.deviceLocation,
    required this.connectionType,
  });

  @override
  State<UsbScanPopup> createState() => _UsbScanPopupState();
}

class _UsbScanPopupState extends State<UsbScanPopup>
    with SingleTickerProviderStateMixin {
  String? selectedTime;
  String? selectedReason;
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  final List<String> times = ["15 دقيقة", "30 دقيقة", "45 دقيقة"];
  final List<String> reasons = ["صيانة دورية", "تحديث نظام", "صيانة عاجلة"];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _scaleAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutBack,
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl, // 🔹 ضروري لأن النص عربي
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          backgroundColor: Colors.white,
          elevation: 10,
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 24,
            vertical: 40,
          ),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: LinearGradient(
                colors: [Colors.white, Colors.blue.shade50],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            padding: const EdgeInsets.all(20),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Center(
                    child: Icon(Icons.usb, color: Colors.blue, size: 52),
                  ),
                  const SizedBox(height: 12),
                  const Center(
                    child: Text(
                      "طلب موافقة المدير",
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // 🧾 معلومات الجهاز
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.grey.shade300),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.15),
                          blurRadius: 6,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildInfoRow("الفني:", widget.technician),
                        _buildInfoRow(
                          "الرقم التسلسلي للجهاز:",
                          widget.deviceSerial,
                        ),
                        _buildInfoRow("موقع الجهاز:", widget.deviceLocation),
                        _buildInfoRow("نوع الاتصال:", widget.connectionType),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // 🕒 اختيار الوقت
                  const Text(
                    "الوقت المتوقع للصيانة:",
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: selectedTime,
                        hint: const Text("اختر الوقت"),
                        icon: const Icon(Icons.keyboard_arrow_down),
                        isExpanded: true,
                        onChanged: (value) {
                          setState(() => selectedTime = value);
                        },
                        items:
                            times.map((time) {
                              return DropdownMenuItem(
                                value: time,
                                child: Text(time),
                              );
                            }).toList(),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // 🧭 سبب الطلب
                  const Text(
                    "سبب الطلب:",
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: selectedReason,
                        hint: const Text("اختر سبب الطلب"),
                        icon: const Icon(Icons.keyboard_arrow_down),
                        isExpanded: true,
                        onChanged: (value) {
                          setState(() => selectedReason = value);
                        },
                        items:
                            reasons.map((reason) {
                              return DropdownMenuItem(
                                value: reason,
                                child: Text(reason),
                              );
                            }).toList(),
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // ⚙️ الأزرار السفلية
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => Navigator.pop(context),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.grey.shade200,
                            foregroundColor: Colors.black,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          child: const Text(
                            "إلغاء",
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            print("الوقت: $selectedTime");
                            print("السبب: $selectedReason");

                            Navigator.pop(context);
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => MaintenanceReportScreen(),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                            elevation: 2,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          child: const Text(
                            "إرسال الطلب",
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
          ),
          Expanded(
            flex: 5,
            child: Text(value, style: const TextStyle(color: Colors.black87)),
          ),
        ],
      ),
    );
  }
}
