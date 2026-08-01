import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:path_provider/path_provider.dart';
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';
import 'order_details_screen.dart';

// --- IMPORTS FOR PRODUCT REDIRECTION & REVIEWS ---
import '../models/product_model.dart';
import 'write_review_screen.dart';
import 'product_details_screen.dart'; // <-- IMPORTED PRODUCT DETAILS SCREEN
import 'track_package_screen.dart';

class OrdersTab extends StatefulWidget {
  final VoidCallback onNavigateToHome;

  const OrdersTab({super.key, required this.onNavigateToHome});

  @override
  State<OrdersTab> createState() => _OrdersTabState();
}

class _OrdersTabState extends State<OrdersTab> with SingleTickerProviderStateMixin {
  final Color brandColor = const Color(0xFF0F4C5C);
  late TabController _tabController;
  String _selectedFilter = 'past 3 months';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // --- FULLY INTEGRATED PDF INVOICE GENERATOR ---
  Future<void> _generateAndShareInvoice(BuildContext context, Map<String, dynamic> orderData) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator(color: Color(0xFF0F4C5C))),
    );

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

      if (userEmail.isEmpty) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No email address linked to your account.')));
        return;
      }

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
      String password = 'lxfe jakg mris ypcn'; // Ensure your app password is here

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
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return Scaffold(
        appBar: AppBar(backgroundColor: Colors.white, elevation: 1, title: Text('Your Orders', style: TextStyle(color: brandColor, fontWeight: FontWeight.bold))),
        body: const Center(child: Text("Please sign in to view your orders.")),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text('Your Orders', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 20)),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(110),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 40,
                        child: TextField(
                          decoration: InputDecoration(
                            hintText: 'Search all orders',
                            prefixIcon: const Icon(Icons.search, color: Colors.grey),
                            contentPadding: const EdgeInsets.symmetric(vertical: 0),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: BorderSide(color: Colors.grey.shade400)),
                            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: BorderSide(color: Colors.grey.shade400)),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black87,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                      ),
                      onPressed: () {},
                      child: const Text('Search Orders', style: TextStyle(color: Colors.white)),
                    )
                  ],
                ),
              ),
              TabBar(
                controller: _tabController,
                labelColor: Colors.black,
                unselectedLabelColor: Colors.teal.shade700,
                indicatorColor: Colors.orange,
                indicatorWeight: 3,
                tabs: const [
                  Tab(text: 'Orders'),
                  Tab(text: 'Buy Again'),
                  Tab(text: 'Not Yet Shipped'),
                ],
              ),
            ],
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildOrdersList(user.uid),
          const Center(child: Text("Buy Again Items Will Appear Here")),
          const Center(child: Text("Not Yet Shipped Items Will Appear Here")),
        ],
      ),
    );
  }

  Widget _buildOrdersList(String uid) {
    final int currentYear = DateTime.now().year;
    final List<String> filterOptions = [
      'past 3 months',
      'past 6 months',
      for (int i = 0; i < 5; i++) (currentYear - i).toString(),
    ];

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('orders')
          .orderBy('orderDate', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final orders = snapshot.data?.docs ?? [];

        if (orders.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.shopping_bag_outlined, size: 80, color: Colors.grey.shade300),
                const SizedBox(height: 16),
                const Text('No orders found', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: brandColor),
                  onPressed: widget.onNavigateToHome,
                  child: const Text('Start Shopping', style: TextStyle(color: Colors.white)),
                )
              ],
            ),
          );
        }

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Row(
              children: [
                Text('${orders.length} orders placed in ', style: const TextStyle(fontWeight: FontWeight.w500)),
                Container(
                  height: 30,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(6), border: Border.all(color: Colors.grey.shade400)),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedFilter,
                      icon: const Icon(Icons.keyboard_arrow_down, size: 16),
                      style: const TextStyle(fontSize: 13, color: Colors.black87, fontWeight: FontWeight.w500),
                      items: filterOptions.map((String value) {
                        return DropdownMenuItem<String>(value: value, child: Text(value));
                      }).toList(),
                      onChanged: (newValue) {
                        if (newValue != null) setState(() => _selectedFilter = newValue);
                      },
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...orders.map((doc) => _buildOrderCard(doc)),
          ],
        );
      },
    );
  }

  Widget _buildOrderCard(DocumentSnapshot doc) {
    final orderData = doc.data() as Map<String, dynamic>;
    final String orderId = orderData['orderId'] ?? 'Unknown ID';
    final num totalAmount = orderData['totalAmount'] ?? 0;
    final String status = orderData['status'] ?? 'Placed';
    final List<dynamic> items = orderData['items'] ?? [];

    final Map<String, dynamic> address = orderData['shippingAddress'] ?? {};
    final String shipToName = address['title'] ?? address['name'] ?? 'Customer';

    final Timestamp? orderDateStamp = orderData['orderDate'];
    final Timestamp? deliveryDateStamp = orderData['deliveryDate'];

    final String placedDate = orderDateStamp != null ? DateFormat('d MMMM yyyy').format(orderDateStamp.toDate()) : '';

    bool isDelivered = status.toLowerCase() == 'delivered';
    String statusTitle = '';
    Color statusColor = Colors.black;

    if (deliveryDateStamp != null) {
      if (isDelivered) {
        statusTitle = 'Delivered ${DateFormat('d MMMM').format(deliveryDateStamp.toDate())}';
        statusColor = Colors.black87;
      } else {
        statusTitle = 'Arriving ${DateFormat('EEEE').format(deliveryDateStamp.toDate())}';
        statusColor = Colors.teal.shade700;
      }
    } else {
      statusTitle = status;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
              border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _headerItem('ORDER PLACED', placedDate),
                          _headerItem('TOTAL', '₹$totalAmount'),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('SHIP TO', style: TextStyle(fontSize: 10, color: Colors.grey.shade700)),
                              const SizedBox(height: 2),
                              Row(
                                children: [
                                  Text(shipToName.toUpperCase(), style: const TextStyle(fontSize: 12, color: Colors.blue)),
                                  const Icon(Icons.keyboard_arrow_down, size: 14, color: Colors.blue),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('ORDER # ${orderId.substring(0, 15)}...', style: TextStyle(fontSize: 10, color: Colors.grey.shade700)),
                    Row(
                      children: [
                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => OrderDetailsScreen(orderData: orderData))
                            );
                          },
                          child: Text('View order details', style: TextStyle(fontSize: 12, color: Colors.blue.shade700)),
                        ),
                        const SizedBox(width: 8),
                        Text('|', style: TextStyle(color: Colors.grey.shade400)),
                        const SizedBox(width: 8),

                        GestureDetector(
                          onTap: () => _generateAndShareInvoice(context, orderData),
                          child: Row(
                            children: [
                              Text('Invoice', style: TextStyle(fontSize: 12, color: Colors.blue.shade700)),
                              const Icon(Icons.keyboard_arrow_down, size: 14, color: Colors.blue),
                            ],
                          ),
                        ),
                      ],
                    )
                  ],
                )
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(statusTitle, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: statusColor)),
                if (isDelivered) ...[
                  const SizedBox(height: 4),
                  const Text('Package was handed to resident', style: TextStyle(fontSize: 12)),
                ],
                const SizedBox(height: 16),

                ...items.map((item) {
                  final i = item as Map<String, dynamic>;

                  // --- REDIRECTION FUNCTION ---
                  void _goToProductDetails() {
                    final productDetails = Product(
                        id: i['productId'] ?? 'unknown_id',
                        name: i['name'] ?? 'Unknown Product',
                        price: (i['price'] ?? 0).toDouble(),
                        imageUrls: [i['imageUrl'] ?? ''],
                        productId: i['productId'] ?? 'unknown_id',
                        category: 'Purchased'
                    );
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => ProductDetailsScreen(
                              product: productDetails,
                              wishlistIds: const {},
                              onToggleWishlist: (id, name) {},
                            )
                        )
                    );
                  }

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16.0),
                    child: Column(
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            GestureDetector(
                              onTap: _goToProductDetails,
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: Image.network(
                                    i['imageUrl'] ?? '', width: 70, height: 70, fit: BoxFit.cover,
                                    errorBuilder: (c,e,s) => Container(width: 70, height: 70, color: Colors.grey.shade200)
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  GestureDetector(
                                    onTap: _goToProductDetails,
                                    child: Text(i['name'] ?? 'Product', maxLines: 3, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 13, color: Colors.blue.shade800, fontWeight: FontWeight.w500)),
                                  ),
                                  const SizedBox(height: 8),
                                  if (isDelivered)
                                    Text('Return window closed', style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),

                                  const SizedBox(height: 12),
                                  _buildActionButton(
                                    text: isDelivered ? 'Get product support' : 'Track package',
                                    isYellow: true,
                                    onTap: () {
                                      if (!isDelivered) {
                                        // Navigate to Track Package Screen
                                        Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                                builder: (context) => TrackPackageScreen(
                                                  orderData: orderData,
                                                  item: i, // Passing the specific item being tracked
                                                )
                                            )
                                        );
                                      } else {
                                        // Logic for product support can go here in the future
                                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Product support opening...')));
                                      }
                                    },
                                  ),
                                  if (!isDelivered)
                                    _buildActionButton(
                                        text: 'View or edit order',
                                        onTap: () {
                                          Navigator.push(
                                              context,
                                              MaterialPageRoute(builder: (context) => OrderDetailsScreen(orderData: orderData))
                                          );
                                        }
                                    ),
                                  if (isDelivered) ...[
                                    _buildActionButton(text: 'Leave seller feedback', onTap: () {}),
                                    _buildActionButton(text: 'Leave delivery feedback', onTap: () {}),
                                  ],

                                  _buildActionButton(
                                      text: 'Write a product review',
                                      onTap: () {
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
                                      }
                                  ),

                                  if (isDelivered)
                                    Row(
                                      children: [
                                        Expanded(
                                          child: ElevatedButton.icon(
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: const Color(0xFFFFD814),
                                              foregroundColor: Colors.black,
                                              elevation: 0,
                                              padding: const EdgeInsets.symmetric(vertical: 0),
                                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: const BorderSide(color: Color(0xFFFCD200))),
                                            ),
                                            icon: const Icon(Icons.refresh, size: 16),
                                            label: const Text('Buy it again', style: TextStyle(fontSize: 12)),
                                            onPressed: () {},
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: OutlinedButton(
                                            style: OutlinedButton.styleFrom(
                                              foregroundColor: Colors.black87,
                                              padding: const EdgeInsets.symmetric(vertical: 0),
                                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                            ),
                                            onPressed: () {},
                                            child: const Text('View your item', style: TextStyle(fontSize: 12)),
                                          ),
                                        ),
                                      ],
                                    ),
                                ],
                              ),
                            )
                          ],
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _headerItem(String title, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: TextStyle(fontSize: 10, color: Colors.grey.shade700)),
        const SizedBox(height: 2),
        Text(value, style: const TextStyle(fontSize: 12, color: Colors.black87)),
      ],
    );
  }

  Widget _buildActionButton({required String text, bool isYellow = false, required VoidCallback onTap}) {
    return Container(
      width: double.infinity,
      height: 36,
      margin: const EdgeInsets.only(bottom: 8),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: isYellow ? const Color(0xFFFFD814) : Colors.white,
          foregroundColor: Colors.black87,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(color: isYellow ? const Color(0xFFFCD200) : Colors.grey.shade400),
          ),
        ),
        onPressed: onTap,
        child: Text(text, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.normal)),
      ),
    );
  }
}