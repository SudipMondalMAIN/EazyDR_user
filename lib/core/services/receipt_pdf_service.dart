import 'dart:convert';
import 'dart:typed_data';

import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../models/booking.dart';

/// Builds and shares/saves a one-page PDF receipt for a booking. Kept
/// separate from any screen so both the ticket sheet and a future booking
/// detail page can call it the same way.
class ReceiptPdfService {
  static Future<void> shareReceipt(Booking booking) async {
    final bytes = await _build(booking);
    await Printing.sharePdf(
      bytes: bytes,
      filename: 'EazyDoctor_Receipt_${booking.tokenNumber}_${booking.appointmentDate}.pdf',
    );
  }

  static Future<Uint8List> _build(Booking booking) async {
    final doc = pw.Document();
    final dateLabel = _formatDate(booking.appointmentDate);

    pw.MemoryImage? qrImage;
    if (booking.qrCodeBase64 != null && booking.qrCodeBase64!.isNotEmpty) {
      try {
        qrImage = pw.MemoryImage(base64Decode(_stripDataUrl(booking.qrCodeBase64!)));
      } catch (_) {
        qrImage = null;
      }
    }

    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a5,
        margin: const pw.EdgeInsets.all(28),
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('EazyDoctor', style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold)),
              pw.Text('Booking Receipt', style: const pw.TextStyle(fontSize: 12, color: PdfColors.grey700)),
              pw.SizedBox(height: 16),
              pw.Divider(),
              pw.SizedBox(height: 8),
              _row('Token Number', '#${booking.tokenNumber}'),
              _row('Status', bookingStatusLabel(booking.status)),
              _row('Doctor', booking.doctorName.isNotEmpty ? booking.doctorName : '-'),
              _row('Facility', booking.facilityName.isNotEmpty ? booking.facilityName : '-'),
              if (booking.facilityAddress.isNotEmpty) _row('Address', booking.facilityAddress),
              _row('Patient', booking.patientName),
              _row('Appointment Date', dateLabel),
              _row('Expected Time', booking.expectedTime),
              _row('Booking Fee', '\u20b9${booking.bookingFee.toStringAsFixed(0)} (${booking.paymentMode})'),
              _row('Booking ID', booking.id),
              pw.SizedBox(height: 16),
              pw.Divider(),
              pw.SizedBox(height: 12),
              if (qrImage != null)
                pw.Center(
                  child: pw.Column(
                    children: [
                      pw.Image(qrImage, width: 140, height: 140),
                      pw.SizedBox(height: 6),
                      pw.Text('Show this QR at the reception desk', style: const pw.TextStyle(fontSize: 10)),
                    ],
                  ),
                ),
              pw.Spacer(),
              pw.Center(
                child: pw.Text(
                  'Generated on ${DateFormat('d MMM yyyy, h:mm a').format(DateTime.now())}',
                  style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
                ),
              ),
            ],
          );
        },
      ),
    );

    return doc.save();
  }

  static pw.Widget _row(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 3),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(
            width: 120,
            child: pw.Text(label, style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
          ),
          pw.Expanded(child: pw.Text(value, style: const pw.TextStyle(fontSize: 11))),
        ],
      ),
    );
  }

  static String _formatDate(String iso) {
    final d = DateTime.tryParse(iso);
    if (d == null) return iso;
    return DateFormat('d MMM yyyy, EEE').format(d);
  }

  static String _stripDataUrl(String value) {
    final idx = value.indexOf(',');
    return idx != -1 && value.startsWith('data:') ? value.substring(idx + 1) : value;
  }
}
