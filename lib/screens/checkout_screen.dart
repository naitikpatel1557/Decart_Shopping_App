import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';

import 'address_screen.dart';
import 'order_confirmation_screen.dart';

class CheckoutScreen extends StatefulWidget {
  final Map<String, dynamic> deliveryAddress;
  final int totalAmount;

  const CheckoutScreen({
    super.key,
    required this.deliveryAddress,
    required this.totalAmount,
  });

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final Color brandColor = const Color(0xFF0F4C5C);

  late Map<String, dynamic> _currentDeliveryAddress;

  bool _isPaymentConfirmed = false;
  String _selectedPaymentMethod = 'cod';
  String? _selectedBank;

  final Map<String, bool> _giftOptionExpanded = {};
  final Map<String, TextEditingController> _giftMessageControllers = {};
  final Map<String, TextEditingController> _giftFromControllers = {};

  final List<String> _banks = [
    'Airtel Payments Bank', 'Axis Bank', 'HDFC Bank', 'ICICI Bank', 'Kotak Bank', 'State Bank of India',
    'Allahabad Bank', 'Andhra Bank', 'Bank of India', 'Bank of Maharashtra', 'Canara Bank',
    'Catholic Syrian Bank', 'Central Bank of India', 'City Union Bank', 'Corporation Bank',
    'Cosmos Bank', 'DCB Bank Ltd', 'Deutsche Bank', 'Dhanlakshmi Bank', 'Federal Bank',
    'IDBI Bank', 'IDFC FIRST Bank', 'ING Vysya Bank', 'Indian Bank', 'Indian Overseas Bank',
    'IndusInd Bank', 'Jammu & Kashmir Bank', 'Janata Sahakari Bank', 'Karnataka Bank Ltd',
    'Karur Vysya Bank', 'Laxmi Vilas Bank - Corporate', 'Laxmi Vilas Bank - Retail',
    'Oriental Bank of Commerce', 'PNB YUVA Netbanking', 'Punjab National Bank - Corporate Banking',
    'Punjab National Bank - Retail Banking', 'Saraswat Bank', 'Shamrao Vitthal Co-operative Bank',
    'South Indian Bank', 'Standard Chartered Bank', 'State Bank of Bikaner & Jaipur',
    'State Bank of Hyderabad', 'State Bank of Mysore', 'State Bank of Patiala',
    'State Bank of Travancore', 'Syndicate Bank', 'Tamilnad Mercantile Bank Ltd.',
    'Union Bank of India', 'United Bank of India', 'Yes Bank Ltd',
  ];

  @override
  void initState() {
    super.initState();
    _currentDeliveryAddress = widget.deliveryAddress;
  }

  @override
  void dispose() {
    for (var controller in _giftMessageControllers.values) {
      controller.dispose();
    }
    for (var controller in _giftFromControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _updateQuantity(String docId, int currentQty, int change) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final cartRef = FirebaseFirestore.instance.collection('users').doc(user.uid).collection('cart').doc(docId);
    final newQty = currentQty + change;

    if (newQty <= 0) {
      await cartRef.delete();
    } else {
      await cartRef.update({'quantity': newQty});
    }
  }

  Future<void> _saveGiftOptions(String docId, bool isGift, bool includeGiftBox) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final msg = _giftMessageControllers[docId]?.text ?? '';
    final fromName = _giftFromControllers[docId]?.text ?? '';

    await FirebaseFirestore.instance.collection('users').doc(user.uid).collection('cart').doc(docId).update({
      'isGift': isGift,
      'giftMessage': msg,
      'giftFrom': fromName,
      'includeGiftBox': includeGiftBox,
      'giftBoxFee': includeGiftBox ? 30 : 0,
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gift options saved!'), backgroundColor: Colors.green),
      );
      setState(() {
        _giftOptionExpanded[docId] = false;
      });
    }
  }

  // --- NEW: INVOICE GENERATOR FUNCTION (CALLED SILENTLY) ---
  Future<void> _sendInvoiceEmailSilently(Map<String, dynamic> orderData) async {
    try {
      final pdf = pw.Document();

      final String orderId = orderData['orderId'] ?? 'Unknown ID';
      final num grandTotal = orderData['totalAmount'] ?? 0;
      final List<dynamic> items = orderData['items'] ?? [];

      final Map<String, dynamic> address = orderData['shippingAddress'] ?? {};
      final String shipName = address['title'] ?? address['name'] ?? 'Customer';

      String rawAddress = address['fullAddress'] ?? address['address'] ?? '';

      if (rawAddress.trim().isEmpty) {
        List<String> parts = [];
        final keysToCheck = ['flat', 'houseNo', 'street', 'area', 'landmark', 'city', 'state', 'pincode', 'zipCode'];
        for (String key in keysToCheck) {
          if (address[key] != null && address[key].toString().trim().isNotEmpty) {
            parts.add(address[key].toString().trim());
          }
        }
        rawAddress = parts.join(', ');
      }

      if (rawAddress.trim().isEmpty) {
        rawAddress = 'Address details not provided in order data.';
      }

      String shipPhone = address['phone'] ?? address['phoneNumber'] ?? address['mobile'] ?? '';
      if (shipPhone.isNotEmpty) {
        shipPhone = shipPhone.replaceAll(RegExp(r'^\+1'), '');
        shipPhone = shipPhone.replaceAll(RegExp(r'^\+91'), '');
        shipPhone = shipPhone.trim();
        shipPhone = '+91 $shipPhone';
      }

      String shipAddress = rawAddress.replaceAll(', ', '\n');
      if (shipPhone.isNotEmpty) {
        shipAddress += '\nPhone: $shipPhone';
      }

      final Timestamp? orderDateStamp = orderData['orderDate'];
      final String placedDate = orderDateStamp != null ? DateFormat('d MMMM yyyy').format(orderDateStamp.toDate()) : '';
      final String userEmail = FirebaseAuth.instance.currentUser?.email ?? '';

      final int codFee = orderData['paymentMethod'] == 'cod' ? 17 : 0;
      final num itemsSubtotal = grandTotal - codFee;

      if (userEmail.isEmpty) return;

      pw.Widget buildPdfTotalRow(String label, String value) {
        return pw.Padding(
            padding: const pw.EdgeInsets.symmetric(vertical: 3),
            child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(label, style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey800)),
                  pw.Text(value, style: const pw.TextStyle(fontSize: 10)),
                ]
            )
        );
      }

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(40),
          build: (pw.Context context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text('DECART', style: pw.TextStyle(fontSize: 36, fontWeight: pw.FontWeight.bold, color: PdfColor.fromHex('#0F4C5C'), letterSpacing: 2)),
                    pw.Text('INVOICE', style: pw.TextStyle(fontSize: 24, color: PdfColors.grey600)),
                  ],
                ),
                pw.SizedBox(height: 8),
                pw.Divider(color: PdfColor.fromHex('#0F4C5C'), thickness: 1.5),
                pw.SizedBox(height: 20),
                pw.Row(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Expanded(
                          child: pw.Column(
                              crossAxisAlignment: pw.CrossAxisAlignment.start,
                              children: [
                                pw.Container(
                                  width: double.infinity,
                                  padding: const pw.EdgeInsets.only(bottom: 4),
                                  decoration: const pw.BoxDecoration(border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey300, width: 1))),
                                  child: pw.Text('BILLED TO / SHIPPED TO', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColor.fromHex('#0F4C5C'), fontSize: 10)),
                                ),
                                pw.SizedBox(height: 8),
                                pw.Text(shipName.toUpperCase(), style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
                                pw.SizedBox(height: 2),
                                pw.Text(shipAddress, style: const pw.TextStyle(fontSize: 10, lineSpacing: 1.5)),
                              ]
                          )
                      ),
                      pw.SizedBox(width: 40),
                      pw.Expanded(
                          child: pw.Column(
                              crossAxisAlignment: pw.CrossAxisAlignment.start,
                              children: [
                                pw.Container(
                                  width: double.infinity,
                                  padding: const pw.EdgeInsets.only(bottom: 4),
                                  decoration: const pw.BoxDecoration(border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey300, width: 1))),
                                  child: pw.Text('ORDER DETAILS', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColor.fromHex('#0F4C5C'), fontSize: 10)),
                                ),
                                pw.SizedBox(height: 8),
                                pw.RichText(text: pw.TextSpan(style: const pw.TextStyle(fontSize: 10, lineSpacing: 1.5), children: [
                                  pw.TextSpan(text: 'Order ID: ', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                                  pw.TextSpan(text: orderId),
                                ])),
                                pw.RichText(text: pw.TextSpan(style: const pw.TextStyle(fontSize: 10, lineSpacing: 1.5), children: [
                                  pw.TextSpan(text: 'Order Date: ', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                                  pw.TextSpan(text: placedDate),
                                ])),
                                pw.RichText(text: pw.TextSpan(style: const pw.TextStyle(fontSize: 10, lineSpacing: 1.5), children: [
                                  pw.TextSpan(text: 'Payment Method: ', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                                  pw.TextSpan(text: orderData['paymentMethod'] == 'cod' ? 'Pay on Delivery' : 'Prepaid Online'),
                                ])),
                              ]
                          )
                      ),
                    ]
                ),
                pw.SizedBox(height: 30),
                pw.Container(
                    color: PdfColor.fromHex('#0F4C5C'),
                    padding: const pw.EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                    child: pw.Row(
                        children: [
                          pw.Expanded(flex: 5, child: pw.Text('Product Description', style: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold, fontSize: 10))),
                          pw.Expanded(flex: 1, child: pw.Text('Qty', textAlign: pw.TextAlign.center, style: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold, fontSize: 10))),
                          pw.Expanded(flex: 2, child: pw.Text('Unit Price', textAlign: pw.TextAlign.right, style: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold, fontSize: 10))),
                          pw.Expanded(flex: 2, child: pw.Text('Amount', textAlign: pw.TextAlign.right, style: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold, fontSize: 10))),
                        ]
                    )
                ),
                ...items.map((item) {
                  final i = item as Map<String, dynamic>;
                  final num price = i['price'] ?? 0;
                  final num qty = i['quantity'] ?? 1;
                  final String name = i['name'] ?? 'Product';
                  return pw.Container(
                      padding: const pw.EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                      decoration: const pw.BoxDecoration(border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey300))),
                      child: pw.Row(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Expanded(flex: 5, child: pw.Column(
                                crossAxisAlignment: pw.CrossAxisAlignment.start,
                                children: [
                                  pw.Text(name, style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
                                  pw.SizedBox(height: 4),
                                  pw.Text('Sold by: Decart Retail', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600)),
                                ]
                            )),
                            pw.Expanded(flex: 1, child: pw.Text('$qty', textAlign: pw.TextAlign.center, style: const pw.TextStyle(fontSize: 10))),
                            pw.Expanded(flex: 2, child: pw.Text('Rs. $price', textAlign: pw.TextAlign.right, style: const pw.TextStyle(fontSize: 10))),
                            pw.Expanded(flex: 2, child: pw.Text('Rs. ${price * qty}', textAlign: pw.TextAlign.right, style: const pw.TextStyle(fontSize: 10))),
                          ]
                      )
                  );
                }),
                pw.SizedBox(height: 20),
                pw.Align(
                    alignment: pw.Alignment.centerRight,
                    child: pw.SizedBox(
                        width: 250,
                        child: pw.Column(
                            children: [
                              buildPdfTotalRow('Item(s) Subtotal:', 'Rs. $itemsSubtotal'),
                              buildPdfTotalRow('Shipping:', 'Rs. 40.00'),
                              buildPdfTotalRow('Promotion Applied:', '-Rs. 40.00'),
                              if (codFee > 0) buildPdfTotalRow('Cash on Delivery Fee:', 'Rs. 17.00'),
                              pw.SizedBox(height: 4),
                              pw.Divider(color: PdfColors.grey300),
                              pw.SizedBox(height: 4),
                              pw.Row(
                                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                                  children: [
                                    pw.Text('Grand Total:', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: PdfColor.fromHex('#0F4C5C'))),
                                    pw.Text('Rs. $grandTotal', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: PdfColor.fromHex('#0F4C5C'))),
                                  ]
                              )
                            ]
                        )
                    )
                ),
                pw.Spacer(),
                pw.Center(child: pw.Text('Thank you for shopping with Decart! If you have any questions, please contact support@decart.com.', style: const pw.TextStyle(color: PdfColors.grey, fontSize: 9))),
              ],
            );
          },
        ),
      );

      final bytes = await pdf.save();
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/Decart_Invoice_$orderId.pdf');
      await file.writeAsBytes(bytes);

      String username = 'decartofficial85@gmail.com';
      String password = 'lxfe jakg mris ypcn'; // <-- Ensure your actual App Password is here

      final smtpServer = gmail(username, password);

      final message = Message()
        ..from = Address(username, 'Decart Official')
        ..recipients.add(userEmail)
        ..subject = 'Order Confirmation - Decart #$orderId'
        ..text = 'Hello $shipName,\n\nWe have successfully received your order!\n\nPlease find your official invoice attached to this email. You can track your package directly inside the Decart app.\n\nBest regards,\nThe Decart Team'
        ..attachments = [FileAttachment(file)];

      await send(message, smtpServer);
      debugPrint("Silent invoice email sent successfully.");

    } catch (e) {
      debugPrint("Failed to send silent invoice email: $e");
    }
  }

  String _getPaymentMethodTitle() {
    switch (_selectedPaymentMethod) {
      case 'cod': return 'Pay on delivery (Cash/Card)';
      case 'netbanking': return 'Net Banking (${_selectedBank ?? ''})';
      case 'card': return 'Credit or Debit Card';
      case 'upi': return 'Scan and Pay with UPI';
      case 'emi': return 'EMI';
      case 'wallet': return 'Decart Pay Balance';
      default: return 'Selected Payment Method';
    }
  }

  void _showAddressSelection(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
        builder: (BuildContext sheetContext) {
          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Select Delivery Address', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance.collection('users').doc(user.uid).collection('addresses').snapshots(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
                        final addresses = snapshot.data?.docs ?? [];
                        if (addresses.isEmpty) return const Text("No saved addresses found.");

                        return Column(
                          children: [
                            ConstrainedBox(
                              constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.4),
                              child: ListView.separated(
                                shrinkWrap: true,
                                itemCount: addresses.length,
                                separatorBuilder: (context, index) => const Divider(),
                                itemBuilder: (context, index) {
                                  final addrData = addresses[index].data() as Map<String, dynamic>;
                                  final String title = addrData['title'] ?? addrData['name'] ?? 'Home';
                                  final String fullAddress = addrData['fullAddress'] ?? addrData['address'] ?? 'Address details...';

                                  return ListTile(
                                    contentPadding: EdgeInsets.zero,
                                    leading: CircleAvatar(backgroundColor: brandColor.withOpacity(0.1), child: Icon(Icons.location_on, color: brandColor)),
                                    title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
                                    subtitle: Text(fullAddress, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                                    trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
                                    onTap: () {
                                      setState(() => _currentDeliveryAddress = addrData);
                                      Navigator.pop(sheetContext);
                                    },
                                  );
                                },
                              ),
                            ),
                            const SizedBox(height: 16),
                            TextButton.icon(
                              onPressed: () {
                                Navigator.pop(sheetContext);
                                Navigator.push(context, MaterialPageRoute(builder: (context) => const AddressScreen()));
                              },
                              icon: Icon(Icons.add, color: brandColor),
                              label: Text("Add Another Address", style: TextStyle(color: brandColor, fontWeight: FontWeight.bold)),
                            )
                          ],
                        );
                      }
                  )
                ],
              ),
            ),
          );
        }
    );
  }

  @override
  Widget build(BuildContext context) {
    final String name = _currentDeliveryAddress['title'] ?? _currentDeliveryAddress['name'] ?? 'Customer';
    final String fullAddress = _currentDeliveryAddress['fullAddress'] ?? _currentDeliveryAddress['address'] ?? 'No address provided';

    final DateTime deliveryDate = DateTime.now().add(const Duration(days: 4));
    final String headerFormatDate = DateFormat('d MMM yyyy').format(deliveryDate);
    final String radioFormatDate = DateFormat('EEEE, d MMM').format(deliveryDate);

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        shadowColor: Colors.black12,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: brandColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Secure checkout',
          style: TextStyle(color: brandColor, fontWeight: FontWeight.bold, fontFamily: 'Times New Roman', fontSize: 20),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // =========================================================
            // 1. DELIVERY ADDRESS SECTION
            // =========================================================
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.white, border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(8)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Delivering to ${name.toUpperCase()}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                            const SizedBox(height: 4),
                            Text(fullAddress, style: TextStyle(color: Colors.grey.shade800, fontSize: 14, height: 1.4)),
                          ],
                        ),
                      ),
                      TextButton(
                        onPressed: () => _showAddressSelection(context),
                        style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: const Size(50, 20), tapTargetSize: MaterialTapTargetSize.shrinkWrap),
                        child: Text('Change', style: TextStyle(color: Colors.blue.shade700, fontWeight: FontWeight.w500)),
                      )
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text('Add delivery instructions', style: TextStyle(color: Colors.blue.shade700, fontSize: 13, fontWeight: FontWeight.w500)),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // =========================================================
            // 2. PAYMENT METHOD SECTION
            // =========================================================
            if (!_isPaymentConfirmed) ...[
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Text('Payment method', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
              Container(
                decoration: BoxDecoration(color: Colors.white, border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(8)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(padding: EdgeInsets.fromLTRB(16, 16, 16, 8), child: Text('Your available balance', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15))),
                    _buildPaymentRadio(value: 'wallet', title: 'Decart Pay Balance ₹0.00 Unavailable', subtitle: 'Insufficient balance. Add money & get rewarded', subtitleColor: Colors.blue.shade700),

                    const Divider(height: 32, thickness: 1),

                    const Padding(padding: EdgeInsets.fromLTRB(16, 0, 16, 8), child: Text('Another payment method', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15))),
                    _buildPaymentRadio(
                      value: 'card', title: 'Credit or debit card',
                      extraWidget: Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Row(children: [Icon(Icons.credit_card, color: Colors.blue.shade800), const SizedBox(width: 8), const Icon(Icons.credit_card, color: Colors.orange)]),
                      ),
                    ),
                    _buildPaymentRadio(
                      value: 'netbanking', title: 'Net Banking',
                      extraWidget: Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade400), borderRadius: BorderRadius.circular(4)),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              isExpanded: true,
                              hint: const Text('Choose an Option', style: TextStyle(fontSize: 14)),
                              value: _selectedBank,
                              icon: const Icon(Icons.keyboard_arrow_down),
                              items: _banks.map((String bank) {
                                return DropdownMenuItem<String>(value: bank, child: Text(bank, style: const TextStyle(fontSize: 14)));
                              }).toList(),
                              onChanged: (String? newValue) {
                                setState(() {
                                  _selectedBank = newValue;
                                  _selectedPaymentMethod = 'netbanking';
                                });
                              },
                            ),
                          ),
                        ),
                      ),
                    ),
                    _buildPaymentRadio(value: 'upi', title: 'Scan and Pay with UPI', subtitle: 'You will need to Scan the QR code on the payment page to complete the payment.'),
                    _buildPaymentRadio(value: 'emi', title: 'EMI'),
                    _buildPaymentRadio(value: 'cod', title: 'Cash on Delivery/Pay on Delivery', subtitle: 'Cash, UPI and Cards accepted.'),

                    Container(
                      color: Colors.grey.shade50,
                      padding: const EdgeInsets.all(16),
                      child: SizedBox(
                        width: double.infinity,
                        height: 45,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFFD814), foregroundColor: Colors.black, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8), side: const BorderSide(color: Color(0xFFFCD200)))),
                          onPressed: () {
                            if (_selectedPaymentMethod == 'netbanking' && _selectedBank == null) {
                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please select a bank from the dropdown.")));
                              return;
                            }
                            setState(() {
                              _isPaymentConfirmed = true;
                            });
                          },
                          child: const Text('Use this payment method', style: TextStyle(fontWeight: FontWeight.normal, fontSize: 14)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              const Text('Review items and shipping', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black54)),
              const Divider(height: 32, thickness: 1),
            ] else ...[
              // --- COLLAPSED PAYMENT VIEW ---
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: Colors.white, border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(8)),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(_getPaymentMethodTitle(), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          const SizedBox(height: 8),
                          Text('Use a gift card, voucher or promo code', style: TextStyle(color: Colors.blue.shade700, fontSize: 13)),
                        ],
                      ),
                    ),
                    TextButton(
                      onPressed: () => setState(() => _isPaymentConfirmed = false),
                      style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: const Size(50, 20), tapTargetSize: MaterialTapTargetSize.shrinkWrap),
                      child: Text('Change', style: TextStyle(color: Colors.blue.shade700, fontWeight: FontWeight.w500)),
                    )
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // =========================================================
              // 3. EXPANDED REVIEW ITEMS & GIFT OPTIONS SECTION
              // =========================================================
              StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance.collection('users').doc(FirebaseAuth.instance.currentUser?.uid).collection('cart').snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
                    final cartItems = snapshot.data?.docs ?? [];

                    // Calculate total dynamically based on Qty & Gift Bag add-ons
                    int totalItemsPrice = 0;
                    int giftFeesTotal = 0;

                    for (var doc in cartItems) {
                      final d = doc.data() as Map<String, dynamic>;
                      final int p = d['price'] ?? 0;
                      final int q = d['quantity'] ?? 1;
                      final bool hasGiftBox = d['includeGiftBox'] ?? false;
                      totalItemsPrice += (p * q);
                      if (hasGiftBox) giftFeesTotal += 30;
                    }

                    final int grandTotal = totalItemsPrice + giftFeesTotal;

                    return Column(
                      children: [
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: cartItems.length,
                          itemBuilder: (context, index) {
                            final doc = cartItems[index];
                            final docId = doc.id;
                            final data = doc.data() as Map<String, dynamic>;

                            final String name = data['name'] ?? 'Product';
                            final int price = data['price'] ?? 0;
                            final int qty = data['quantity'] ?? 1;
                            final String imageUrl = data['imageUrl'] ?? '';
                            final bool isGift = data['isGift'] ?? false;
                            final bool includeGiftBox = data['includeGiftBox'] ?? false;

                            if (!_giftMessageControllers.containsKey(docId)) {
                              _giftMessageControllers[docId] = TextEditingController(text: data['giftMessage'] ?? 'Enjoy your gift!');
                            }
                            if (!_giftFromControllers.containsKey(docId)) {
                              _giftFromControllers[docId] = TextEditingController(text: data['giftFrom'] ?? name);
                            }

                            final bool isGiftExpanded = _giftOptionExpanded[docId] ?? false;

                            return Column(
                              children: [
                                if (isGiftExpanded)
                                  Container(
                                    margin: const EdgeInsets.only(bottom: 16),
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(color: Colors.white, border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(8)),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text('Choose gift options', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                        const SizedBox(height: 12),
                                        Row(
                                          children: [
                                            ClipRRect(
                                              borderRadius: BorderRadius.circular(4),
                                              child: Image.network(
                                                imageUrl, width: 40, height: 40, fit: BoxFit.cover,
                                                errorBuilder: (c,e,s) => Container(width: 40, height: 40, color: Colors.grey.shade200, child: const Icon(Icons.image)),
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: Text(name, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 12),
                                        Row(
                                          children: [
                                            SizedBox(
                                              width: 24, height: 24,
                                              child: Checkbox(
                                                value: isGift,
                                                activeColor: brandColor,
                                                onChanged: (val) {
                                                  FirebaseFirestore.instance.collection('users').doc(FirebaseAuth.instance.currentUser?.uid).collection('cart').doc(docId).update({'isGift': val ?? false});
                                                },
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            const Text('This item is a gift', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                                          ],
                                        ),
                                        const SizedBox(height: 16),
                                        Row(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Expanded(
                                              flex: 3,
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  const Text('Gift message', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                                  const SizedBox(height: 4),
                                                  TextField(
                                                    controller: _giftMessageControllers[docId],
                                                    maxLines: 3,
                                                    style: const TextStyle(fontSize: 12),
                                                    decoration: InputDecoration(
                                                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(4)),
                                                      contentPadding: const EdgeInsets.all(8),
                                                    ),
                                                  ),
                                                  const SizedBox(height: 8),
                                                  TextField(
                                                    controller: _giftFromControllers[docId],
                                                    style: const TextStyle(fontSize: 12),
                                                    decoration: InputDecoration(
                                                      prefixText: 'From ',
                                                      prefixStyle: const TextStyle(color: Colors.black87, fontSize: 12),
                                                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(4)),
                                                      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            const SizedBox(width: 16),
                                            Expanded(
                                              flex: 2,
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  const Text('Add-ons', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                                  const SizedBox(height: 4),
                                                  Row(
                                                    children: [
                                                      SizedBox(
                                                        width: 20, height: 20,
                                                        child: Checkbox(
                                                          value: includeGiftBox,
                                                          activeColor: brandColor,
                                                          onChanged: (val) {
                                                            FirebaseFirestore.instance.collection('users').doc(FirebaseAuth.instance.currentUser?.uid).collection('cart').doc(docId).update({'includeGiftBox': val ?? false});
                                                          },
                                                        ),
                                                      ),
                                                      const SizedBox(width: 6),
                                                      const Expanded(child: Text('Gift Bag/Box - ₹30.00', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500))),
                                                    ],
                                                  ),
                                                  const SizedBox(height: 8),
                                                  Container(
                                                    height: 60, width: 60,
                                                    decoration: BoxDecoration(color: Colors.amber.shade50, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.amber.shade200)),
                                                    child: const Icon(Icons.card_giftcard, color: Colors.orange, size: 32),
                                                  )
                                                ],
                                              ),
                                            )
                                          ],
                                        ),
                                        const SizedBox(height: 16),
                                        SizedBox(
                                          height: 36,
                                          child: ElevatedButton(
                                            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFFD814), foregroundColor: Colors.black, elevation: 0),
                                            onPressed: () => _saveGiftOptions(docId, isGift, includeGiftBox),
                                            child: const Text('Save gift options', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),

                                Container(
                                  margin: const EdgeInsets.only(bottom: 16),
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(color: Colors.white, border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(8)),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('Arriving $headerFormatDate', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                      const SizedBox(height: 16),
                                      Row(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Expanded(
                                            flex: 3,
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Row(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    ClipRRect(
                                                      borderRadius: BorderRadius.circular(8),
                                                      child: Image.network(
                                                        imageUrl, width: 75, height: 75, fit: BoxFit.cover,
                                                        errorBuilder: (c,e,s) => Container(width: 75, height: 75, color: Colors.grey.shade200, child: const Icon(Icons.image)),
                                                      ),
                                                    ),
                                                    const SizedBox(width: 12),
                                                    Expanded(
                                                      child: Column(
                                                        crossAxisAlignment: CrossAxisAlignment.start,
                                                        children: [
                                                          Text(name, maxLines: 3, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, height: 1.3)),
                                                          const SizedBox(height: 6),
                                                          Text('₹${price * qty}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFFB12704))),
                                                          const SizedBox(height: 4),
                                                          Text('Sold by: Decart Retail', style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                                                        ],
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                const SizedBox(height: 12),
                                                Container(
                                                  height: 36,
                                                  padding: const EdgeInsets.symmetric(horizontal: 8),
                                                  decoration: BoxDecoration(
                                                    color: const Color(0xFFFFF8E1),
                                                    borderRadius: BorderRadius.circular(20),
                                                    border: Border.all(color: const Color(0xFFFFD814), width: 1.5),
                                                  ),
                                                  child: Row(
                                                    mainAxisSize: MainAxisSize.min,
                                                    children: [
                                                      InkWell(
                                                        onTap: () => _updateQuantity(docId, qty, -1),
                                                        child: Icon(qty == 1 ? Icons.delete_outline : Icons.remove, size: 18, color: Colors.black87),
                                                      ),
                                                      Padding(
                                                        padding: const EdgeInsets.symmetric(horizontal: 16),
                                                        child: Text('$qty', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                                      ),
                                                      InkWell(
                                                        onTap: () => _updateQuantity(docId, qty, 1),
                                                        child: const Icon(Icons.add, size: 18, color: Colors.black87),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                                const SizedBox(height: 8),
                                                GestureDetector(
                                                  onTap: () {
                                                    setState(() {
                                                      _giftOptionExpanded[docId] = !isGiftExpanded;
                                                    });
                                                  },
                                                  child: Text(
                                                    isGiftExpanded ? 'Hide gift options' : 'Add gift options',
                                                    style: TextStyle(color: Colors.blue.shade700, fontSize: 13, fontWeight: FontWeight.w500),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          Expanded(
                                            flex: 2,
                                            child: Row(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Radio<bool>(
                                                  value: true,
                                                  groupValue: true,
                                                  onChanged: (v){},
                                                  activeColor: brandColor,
                                                  visualDensity: const VisualDensity(horizontal: -4, vertical: -4),
                                                ),
                                                const SizedBox(width: 4),
                                                Expanded(
                                                  child: Column(
                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                    children: [
                                                      Text(radioFormatDate, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.green.shade800)),
                                                      const SizedBox(height: 2),
                                                      const Text('FREE Delivery', style: TextStyle(fontSize: 12, color: Colors.black87)),
                                                    ],
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            );
                          },
                        ),

                        // =========================================================
                        // 4. FINAL ORDER SUMMARY & PLACE ORDER BUTTON
                        // =========================================================
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(color: Colors.white, border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(8)),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(
                                width: double.infinity,
                                height: 48,
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFFFFD814),
                                    foregroundColor: Colors.black,
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8), side: const BorderSide(color: Color(0xFFFCD200))),
                                  ),
                                  // --- UPDATED FIREBASE ORDER PLACEMENT & INVOICE LOGIC ---
                                  onPressed: () async {
                                    final user = FirebaseAuth.instance.currentUser;
                                    if (user == null) return;

                                    showDialog(
                                      context: context,
                                      barrierDismissible: false,
                                      builder: (context) => const Center(child: CircularProgressIndicator(color: Color(0xFFFFD814))),
                                    );

                                    try {
                                      final cartSnapshot = await FirebaseFirestore.instance.collection('users').doc(user.uid).collection('cart').get();
                                      final List<Map<String, dynamic>> itemsToOrder = cartSnapshot.docs.map((doc) => doc.data()).toList();

                                      final orderRef = FirebaseFirestore.instance.collection('users').doc(user.uid).collection('orders').doc();

                                      final Map<String, dynamic> newOrderData = {
                                        'orderId': orderRef.id,
                                        'orderDate': Timestamp.now(),
                                        'deliveryDate': Timestamp.fromDate(DateTime.now().add(const Duration(days: 4))),
                                        'totalAmount': grandTotal,
                                        'paymentMethod': _selectedPaymentMethod,
                                        'bank': _selectedBank,
                                        'shippingAddress': _currentDeliveryAddress,
                                        'status': 'Placed',
                                        'items': itemsToOrder,
                                      };

                                      // 1. Save order to Firebase
                                      await orderRef.set(newOrderData);

                                      // 2. Clear Cart
                                      WriteBatch batch = FirebaseFirestore.instance.batch();
                                      for (var doc in cartSnapshot.docs) {
                                        batch.delete(doc.reference);
                                      }
                                      await batch.commit();

                                      // 3. SILENTLY GENERATE AND SEND THE INVOICE EMAIL!
                                      _sendInvoiceEmailSilently(newOrderData);

                                      if (mounted) {
                                        Navigator.pop(context); // close dialog
                                        Navigator.pushReplacement(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => OrderConfirmationScreen(
                                              deliveryAddress: _currentDeliveryAddress,
                                              orderItems: itemsToOrder,
                                              deliveryDate: DateTime.now().add(const Duration(days: 4)),
                                            ),
                                          ),
                                        );
                                      }
                                    } catch (e) {
                                      Navigator.pop(context); // close dialog
                                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error placing order: $e'), backgroundColor: Colors.red));
                                    }
                                  },
                                  // ---------------------------------------------
                                  child: const Text('Place your order', style: TextStyle(fontWeight: FontWeight.normal, fontSize: 16)),
                                ),
                              ),
                              const SizedBox(height: 16),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text('Order Total:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                                  Text('₹$grandTotal', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: Color(0xFFB12704))),
                                ],
                              ),
                              if (giftFeesTotal > 0) ...[
                                const SizedBox(height: 4),
                                Text('Includes ₹$giftFeesTotal for gift packaging', style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                              ],
                              const SizedBox(height: 8),
                              Text('By placing your order, you agree to Decart\'s privacy notice and conditions of use.', style: TextStyle(fontSize: 11, color: Colors.grey.shade600, height: 1.4)),
                            ],
                          ),
                        ),
                        const SizedBox(height: 32),
                      ],
                    );
                  }
              ),
            ],

            // --- GLOBAL FOOTER ---
            Text('Need help? Check our help pages or contact us 24x7', style: TextStyle(color: Colors.grey.shade700, fontSize: 11)),
            const SizedBox(height: 12),
            Text(
              'When your order is placed, we\'ll send you an e-mail message acknowledging receipt of your order. If you choose to pay using an electronic payment method (credit card, debit card or net banking), you will be directed to your bank\'s website to complete your payment.',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 10, height: 1.4),
            ),
            const SizedBox(height: 60),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentRadio({required String value, required String title, String? subtitle, Color? subtitleColor, Widget? extraWidget}) {
    return InkWell(
      onTap: () => setState(() => _selectedPaymentMethod = value),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Radio<String>(
              value: value,
              groupValue: _selectedPaymentMethod,
              activeColor: brandColor,
              onChanged: (String? val) {
                if (val != null) setState(() => _selectedPaymentMethod = val);
              },
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(top: 12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    if (subtitle != null) ...[
                      const SizedBox(height: 4),
                      Text(subtitle, style: TextStyle(color: subtitleColor ?? Colors.grey.shade700, fontSize: 12)),
                    ],
                    if (extraWidget != null) extraWidget,
                  ],
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}