import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:path_provider/path_provider.dart';
import 'cancel_order_screen.dart';

// --- NEW IMPORTS FOR BACKGROUND EMAILING ---
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';

// --- IMPORTS FOR TRACKING AND REVIEWS ---
import 'track_package_screen.dart';
import '../models/product_model.dart';
import 'write_review_screen.dart';

class OrderDetailsScreen extends StatelessWidget {
  final Map<String, dynamic> orderData;

  const OrderDetailsScreen({super.key, required this.orderData});

  // --- UPDATED: PDF GENERATION & DIRECT EMAIL LOGIC (MATCHING ORDERS TAB) ---
  Future<void> _generateAndShareInvoice(BuildContext context) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator(color: Color(0xFF0F4C5C))),
    );

    try {
      final pdf = pw.Document();

      // Extract Data
      final String orderId = orderData['orderId'] ?? 'Unknown ID';
      final num grandTotal = orderData['totalAmount'] ?? 0;
      final List<dynamic> items = orderData['items'] ?? [];

      // --- ROBUST ADDRESS & PHONE LOGIC ---
      final Map<String, dynamic> address = orderData['shippingAddress'] ?? {};
      final String shipName = address['title'] ?? address['name'] ?? 'Customer';

      String rawAddress = address['fullAddress'] ?? address['address'] ?? '';

      // If fullAddress is missing, piece together individual fields
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

      // Format Phone Number to strictly use +91
      String shipPhone = address['phone'] ?? address['phoneNumber'] ?? address['mobile'] ?? '';
      if (shipPhone.isNotEmpty) {
        shipPhone = shipPhone.replaceAll(RegExp(r'^\+1'), ''); // Remove +1 if it exists
        shipPhone = shipPhone.replaceAll(RegExp(r'^\+91'), ''); // Remove +91 to prevent duplicates
        shipPhone = shipPhone.trim();
        shipPhone = '+91 $shipPhone'; // Force +91 prefix
      }

      // Format address with line breaks for the PDF
      String shipAddress = rawAddress.replaceAll(', ', '\n');
      if (shipPhone.isNotEmpty) {
        shipAddress += '\nPhone: $shipPhone';
      }
      // ------------------------------------

      final Timestamp? orderDateStamp = orderData['orderDate'];
      final String placedDate = orderDateStamp != null ? DateFormat('d MMMM yyyy').format(orderDateStamp.toDate()) : '';
      final String userEmail = FirebaseAuth.instance.currentUser?.email ?? '';

      // Calculate Breakdown
      final int codFee = orderData['paymentMethod'] == 'cod' ? 17 : 0;
      final num itemsSubtotal = grandTotal - codFee;

      if (userEmail.isEmpty) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No email address linked to your account.')));
        return;
      }

      // Helper function for the totals row inside the PDF
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
                // --- 1. HEADER LOGO & TITLE ---
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

                // --- 2. ADDRESS & ORDER INFO ---
                pw.Row(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      // Left Side: Billed To
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

                      // Right Side: Order Details
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

                // --- 3. TABLE HEADER ---
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

                // --- 4. TABLE ITEMS ---
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

                // --- 5. TOTALS BREAKDOWN (ALIGNED RIGHT) ---
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

                // --- 6. FOOTER ---
                pw.Spacer(),
                pw.Center(child: pw.Text('Thank you for shopping with Decart! If you have any questions, please contact support@decart.com.', style: const pw.TextStyle(color: PdfColors.grey, fontSize: 9))),
              ],
            );
          },
        ),
      );

      // Save PDF
      final bytes = await pdf.save();
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/Decart_Invoice_$orderId.pdf');
      await file.writeAsBytes(bytes);

      // Setup Email Background Sending
      String username = 'decartofficial85@gmail.com';
      String password = 'lxfe jakg mris ypcn'; // <-- Ensure this is your 16-digit App Password!

      final smtpServer = gmail(username, password);

      final message = Message()
        ..from = Address(username, 'Decart Official')
        ..recipients.add(userEmail)
        ..subject = 'Decart Order Invoice - $orderId'
        ..text = 'Hello $shipName,\n\nThank you for shopping with Decart!\n\nPlease find the invoice for your recent order ($orderId) attached to this email.\n\nBest regards,\nThe Decart Team'
        ..attachments = [FileAttachment(file)];

      await send(message, smtpServer);

      if (context.mounted) {
        Navigator.pop(context); // Close loading
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invoice sent to your email successfully!'), backgroundColor: Colors.green),
        );
      }

    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context); // Close loading
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error sending invoice: $e'), backgroundColor: Colors.red)
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final Color brandColor = const Color(0xFF0F4C5C);

    final String orderId = orderData['orderId'] ?? 'Unknown ID';
    final int grandTotal = orderData['totalAmount'] ?? 0;
    final String paymentMethod = orderData['paymentMethod'] ?? 'Unknown';
    final String bank = orderData['bank'] ?? '';
    final List<dynamic> items = orderData['items'] ?? [];
    final Map<String, dynamic> address = orderData['shippingAddress'] ?? {};

    final Timestamp? orderDateStamp = orderData['orderDate'];
    final Timestamp? deliveryDateStamp = orderData['deliveryDate'];
    final String placedDate = orderDateStamp != null ? DateFormat('d MMMM yyyy').format(orderDateStamp.toDate()) : '';
    final String arrivingText = deliveryDateStamp != null ? 'Arriving ${DateFormat('EEEE').format(deliveryDateStamp.toDate())}' : 'Processing';

    final String shipName = address['title'] ?? address['name'] ?? 'Customer';
    final String shipAddress = address['fullAddress'] ?? address['address'] ?? '';

    String displayPayment = 'Pay on Delivery';
    if (paymentMethod == 'netbanking') displayPayment = 'Net Banking ($bank)';
    if (paymentMethod == 'card') displayPayment = 'Credit/Debit Card';
    if (paymentMethod == 'upi') displayPayment = 'UPI';

    int itemsSubtotal = grandTotal;
    int shipping = 40;
    int codFee = paymentMethod == 'cod' ? 17 : 0;

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        leading: IconButton(icon: Icon(Icons.arrow_back, color: brandColor), onPressed: () => Navigator.pop(context)),
        title: Text('Order Details', style: TextStyle(color: brandColor, fontWeight: FontWeight.bold, fontFamily: 'Times New Roman')),
        actions: [
          IconButton(icon: const Icon(Icons.search, color: Colors.black87), onPressed: () {}),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              color: Colors.white,
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  RichText(
                    text: TextSpan(
                      style: TextStyle(color: Colors.blue.shade700, fontSize: 13),
                      children: const [
                        TextSpan(text: 'Your Account'),
                        TextSpan(text: '  ›  ', style: TextStyle(color: Colors.grey)),
                        TextSpan(text: 'Your Orders'),
                        TextSpan(text: '  ›  ', style: TextStyle(color: Colors.grey)),
                        TextSpan(text: 'Order Details', style: TextStyle(color: Colors.red)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text('Order Details', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text('Order placed $placedDate', style: TextStyle(color: Colors.grey.shade700, fontSize: 13)),
                  Text('Order number ${orderId.substring(0, 15)}...', style: TextStyle(color: Colors.grey.shade700, fontSize: 13)),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerRight,
                    child: GestureDetector(
                      // --- CALLS THE NEW EMAIL INVOICE FUNCTION HERE ---
                      onTap: () => _generateAndShareInvoice(context),
                      child: Text('Invoice ∨', style: TextStyle(color: Colors.blue.shade700, fontWeight: FontWeight.w500)),
                    ),
                  )
                ],
              ),
            ),
            const SizedBox(height: 12),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(color: Colors.white, border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(8)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Ship to', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  const SizedBox(height: 4),
                  Text(shipName, style: const TextStyle(fontWeight: FontWeight.w500)),
                  Text(shipAddress, style: TextStyle(color: Colors.grey.shade800, fontSize: 13, height: 1.4)),
                  const Divider(height: 24),

                  const Text('Payment method', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  const SizedBox(height: 4),
                  Text(displayPayment, style: TextStyle(color: Colors.grey.shade800, fontSize: 13)),
                  const Divider(height: 24),

                  const Text('Order Summary', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  const SizedBox(height: 8),
                  _buildSummaryRow('Item(s) Subtotal:', '₹$itemsSubtotal'),
                  _buildSummaryRow('Shipping:', '₹$shipping'),
                  if (codFee > 0) _buildSummaryRow('Cash/Pay on Delivery fee:', '₹$codFee'),
                  _buildSummaryRow('Total:', '₹${itemsSubtotal + shipping + codFee}'),
                  _buildSummaryRow('Promotion Applied:', '-₹40'),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Grand Total:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                      Text('₹$grandTotal', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFFB12704))),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(color: Colors.white, border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(8)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(arrivingText, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
                  const SizedBox(height: 16),

                  ...items.map((item) {
                    final i = item as Map<String, dynamic>;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(6),
                                child: Image.network(
                                    i['imageUrl'] ?? '', width: 70, height: 70, fit: BoxFit.cover,
                                    errorBuilder: (c,e,s) => Container(width: 70, height: 70, color: Colors.grey.shade200)
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(i['name'] ?? 'Product', maxLines: 3, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 13, color: Colors.blue.shade800, fontWeight: FontWeight.w500)),
                                    const SizedBox(height: 4),
                                    Text('Sold by: Decart Retail', style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                                    const SizedBox(height: 4),
                                    Text('₹${i['price'] ?? 0}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                  ],
                                ),
                              )
                            ],
                          ),
                          const SizedBox(height: 16),

                          // --- TRACK PACKAGE BUTTON ---
                          SizedBox(
                            width: double.infinity, height: 36,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFFD814), foregroundColor: Colors.black, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: const BorderSide(color: Color(0xFFFCD200)))),
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => TrackPackageScreen(
                                      orderData: orderData,
                                      item: i, // Passing specific item being tracked
                                    ),
                                  ),
                                );
                              },
                              child: const Text('Track package', style: TextStyle(fontSize: 13)),
                            ),
                          ),
                          const SizedBox(height: 8),

                          // --- CANCEL ITEMS BUTTON ---
                          SizedBox(
                            width: double.infinity, height: 36,
                            child: OutlinedButton(
                              style: OutlinedButton.styleFrom(foregroundColor: Colors.black87, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))),
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => CancelOrderScreen(orderData: orderData),
                                  ),
                                );
                              },
                              child: const Text('Cancel items', style: TextStyle(fontSize: 13)),
                            ),
                          ),
                          const SizedBox(height: 8),

                          // --- WRITE A PRODUCT REVIEW BUTTON ---
                          SizedBox(
                            width: double.infinity, height: 36,
                            child: OutlinedButton(
                              style: OutlinedButton.styleFrom(foregroundColor: Colors.black87, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))),
                              onPressed: () {
                                final reviewProduct = Product(
                                    id: i['productId'] ?? 'unknown_id',
                                    name: i['name'] ?? 'Unknown Product',
                                    price: (i['price'] ?? 0).toDouble(),
                                    imageUrls: [i['imageUrl'] ?? ''],
                                    productId: i['productId'] ?? 'unknown_id',
                                    category: 'Purchased'
                                );

                                Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (context) => WriteReviewScreen(product: reviewProduct))
                                );
                              },
                              child: const Text('Write a product review', style: TextStyle(fontSize: 13)),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
            const SizedBox(height: 24),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Text('Frequently bought together with your items', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey.shade900)),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 220,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                children: [
                  _buildRecommendationCard('Silicone Case Cover Compatible with...', '₹199', Icons.headphones),
                  _buildRecommendationCard('Heavy Duty Carabiner (Black)', '₹249', Icons.shopping_bag),
                  _buildRecommendationCard('Power Bank 4i 20000mAh', '₹1,499', Icons.battery_charging_full),
                ],
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 13, color: Colors.grey.shade800)),
          Text(value, style: const TextStyle(fontSize: 13, color: Colors.black87)),
        ],
      ),
    );
  }

  Widget _buildRecommendationCard(String title, String price, IconData icon) {
    return Container(
      width: 140,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(color: Colors.white, border: Border.all(color: Colors.grey.shade200), borderRadius: BorderRadius.circular(8)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Center(
              child: Icon(icon, size: 60, color: Colors.blueGrey),
            ),
          ),
          const SizedBox(height: 8),
          Text(title, maxLines: 3, overflow: TextOverflow.ellipsis, style: TextStyle(color: Colors.blue.shade700, fontSize: 12)),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(Icons.star, size: 12, color: Colors.orange.shade400),
              Icon(Icons.star, size: 12, color: Colors.orange.shade400),
              Icon(Icons.star, size: 12, color: Colors.orange.shade400),
              Icon(Icons.star, size: 12, color: Colors.orange.shade400),
              Icon(Icons.star_half, size: 12, color: Colors.orange.shade400),
              const SizedBox(width: 4),
              const Text('12k', style: TextStyle(fontSize: 10, color: Colors.grey)),
            ],
          ),
          const SizedBox(height: 4),
          Text(price, style: const TextStyle(color: Color(0xFFB12704), fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}