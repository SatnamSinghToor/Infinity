import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';

import '../models/order.dart';

/// Builds an order's bill as a PDF and hands it to the phone's share sheet,
/// so the customer can save it, print it or send it on.
///
/// Amounts are written "Rs." rather than with the rupee sign: the PDF's
/// built-in fonts have no ₹ glyph, and a bill with boxes for its currency
/// is worse than one that spells it out.
class InvoiceService {
  const InvoiceService._();

  static String _rs(num v) => 'Rs. ${v.toStringAsFixed(2)}';

  static Future<void> share(Order order, {String? orderLabel}) async {
    final bytes = await build(order, orderLabel: orderLabel);
    final dir = await getTemporaryDirectory();
    final shortId = order.id.length > 8 ? order.id.substring(0, 8) : order.id;
    final file = File('${dir.path}/infinity-invoice-$shortId.pdf');
    await file.writeAsBytes(bytes);
    await Share.shareXFiles(
      [XFile(file.path, mimeType: 'application/pdf')],
      subject: 'Infinity invoice $shortId',
    );
  }

  /// The bill itself, as PDF bytes.
  static Future<List<int>> build(Order order, {String? orderLabel}) async {
    final doc =
        pw.Document(title: 'Invoice ${order.id}', author: 'Infinity');
    final discount = (order.itemsSubtotal +
            order.deliveryFee +
            order.tip -
            order.walletUsed -
            order.totalAmount)
        .clamp(0, double.infinity);
    const muted = PdfColor.fromInt(0xFF6E6E6E);
    const brand = PdfColor.fromInt(0xFFFF6A00);

    pw.Widget row(String label, String value, {bool bold = false}) =>
        pw.Padding(
          padding: const pw.EdgeInsets.symmetric(vertical: 3),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(label,
                  style: pw.TextStyle(
                      fontWeight:
                          bold ? pw.FontWeight.bold : pw.FontWeight.normal)),
              pw.Text(value,
                  style: pw.TextStyle(
                      fontWeight:
                          bold ? pw.FontWeight.bold : pw.FontWeight.normal)),
            ],
          ),
        );

    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(36),
        build: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('Infinity',
                    style: const pw.TextStyle(
                        fontSize: 24,
                        fontWeight: pw.FontWeight.bold,
                        color: brand)),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text('ORDER INVOICE',
                        style: const pw.TextStyle(
                            fontSize: 12, fontWeight: pw.FontWeight.bold)),
                    pw.SizedBox(height: 4),
                    pw.Text('Order: ${orderLabel ?? order.id}',
                        style: const pw.TextStyle(fontSize: 10, color: muted)),
                    pw.Text('Date: ${order.formattedDate}',
                        style: const pw.TextStyle(fontSize: 10, color: muted)),
                    pw.Text('Status: ${order.statusLabel}',
                        style: const pw.TextStyle(fontSize: 10, color: muted)),
                  ],
                ),
              ],
            ),
            pw.SizedBox(height: 20),
            pw.Text('Billed to',
                style: const pw.TextStyle(fontSize: 10, color: muted)),
            pw.Text(order.name,
                style: const pw.TextStyle(fontWeight: pw.FontWeight.bold)),
            pw.Text(order.phone),
            pw.Text(order.address),
            pw.SizedBox(height: 20),
            pw.TableHelper.fromTextArray(
              headers: ['Item', 'Qty', 'Rate', 'Amount'],
              data: [
                for (final item in order.items)
                  [
                    item.variantName == null || item.variantName!.isEmpty
                        ? item.product.name
                        : '${item.product.name} (${item.variantName})',
                    '${item.quantity}',
                    _rs(item.unitPrice),
                    _rs(item.totalPrice),
                  ],
              ],
              headerStyle: const pw.TextStyle(
                  fontWeight: pw.FontWeight.bold, color: PdfColors.white),
              headerDecoration: const pw.BoxDecoration(color: brand),
              cellAlignments: {
                1: pw.Alignment.center,
                2: pw.Alignment.centerRight,
                3: pw.Alignment.centerRight,
              },
              cellPadding:
                  const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 5),
            ),
            pw.SizedBox(height: 16),
            pw.Align(
              alignment: pw.Alignment.centerRight,
              child: pw.SizedBox(
                width: 240,
                child: pw.Column(
                  children: [
                    row('Items total', _rs(order.itemsSubtotal)),
                    row(
                        'Delivery fee',
                        order.deliveryFee > 0
                            ? _rs(order.deliveryFee)
                            : 'FREE'),
                    if (discount >= 0.01) row('Discount', '- ${_rs(discount)}'),
                    if (order.tip > 0)
                      row('Delivery partner tip', _rs(order.tip)),
                    if (order.walletUsed > 0)
                      row('Wallet', '- ${_rs(order.walletUsed)}'),
                    pw.Divider(),
                    row('Total', _rs(order.totalAmount), bold: true),
                  ],
                ),
              ),
            ),
            pw.Spacer(),
            pw.Divider(color: muted),
            pw.Text(
              'Thank you for shopping with Infinity. '
              'This is a computer-generated bill and needs no signature.',
              style: const pw.TextStyle(fontSize: 9, color: muted),
            ),
          ],
        ),
      ),
    );

    return doc.save();
  }
}
