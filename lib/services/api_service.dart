import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:doxie_dummy_pdf/models/pdf_document.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

class ApiService {
  final String baseUrl;

  ApiService({required this.baseUrl});

  Future<List<PdfDocument>> getAllPdfDocuments() async {
    try {
      debugPrint("Fetching documents from: $baseUrl/get_all_pdf_data");
      final response = await http.get(Uri.parse('$baseUrl/get_all_pdf_data'));
      
      debugPrint("Response status code: ${response.statusCode}");
      if (response.body.isNotEmpty) {
        debugPrint("Response body preview: ${response.body.substring(0, min(100, response.body.length))}...");
      }
      
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        final List<dynamic> documentsData = data['data'] ?? [];
        
        debugPrint("Found ${documentsData.length} documents");
        return documentsData
            .map((doc) => PdfDocument.fromJson(doc))
            .toList();
      } else {
        throw Exception('Failed to load PDF documents: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint("Error in getAllPdfDocuments: $e");
      throw Exception('Error fetching PDF documents: $e');
    }
  }

  Future<File> downloadPdf(String pdfPath) async {
    try {
      // Ensure the path starts with a slash if it doesn't already
      if (!pdfPath.startsWith('/') && !pdfPath.startsWith('http')) {
        pdfPath = '/$pdfPath';
      }
      
      // Construct the full URL
      final String fullUrl;
      if (pdfPath.startsWith('http')) {
        fullUrl = pdfPath; // Already a full URL
      } else {
        fullUrl = '$baseUrl$pdfPath';
      }
      
      debugPrint("Downloading PDF from: $fullUrl");
      
      // Make sure we have a valid path with a filename
      if (pdfPath.isEmpty) {
        throw Exception('Invalid PDF path: empty path');
      }
      
      // Use a client that follows redirects automatically
      final client = http.Client();
      try {
        // Set a timeout for the request
        final request = http.Request('GET', Uri.parse(fullUrl));
        final streamedResponse = await client.send(request).timeout(
          const Duration(seconds: 30),
          onTimeout: () {
            throw Exception('Request timed out');
          },
        );
        
        // Log redirect information
        if (streamedResponse.isRedirect) {
          final redirectUrl = streamedResponse.headers['location'];
          debugPrint("Following redirect to: $redirectUrl");
        }
        
        // Get the final response after all redirects
        final response = await http.Response.fromStream(streamedResponse);
        
        if (response.statusCode == 200) {
          return _savePdfToFile(response, pdfPath);
        } else {
          debugPrint('Failed to download PDF: ${response.statusCode}');
          if (response.body.length < 1000) {
            debugPrint('Response body: ${response.body}');
          }
          throw Exception('Failed to download PDF: ${response.statusCode}');
        }
      } finally {
        client.close();
      }
    } catch (e) {
      debugPrint('Error in downloadPdf: $e');
      throw Exception('Error downloading PDF: $e');
    }
  }

  // Helper method to save PDF response to file
  Future<File> _savePdfToFile(http.Response response, String pdfPath) async {
    // Verify we actually got PDF data
    if (response.contentLength == null || response.contentLength == 0) {
      throw Exception('Received empty PDF file');
    }
    
    final contentType = response.headers['content-type'] ?? '';
    if (!contentType.contains('application/pdf') && 
        !contentType.contains('application/octet-stream') &&
        !contentType.contains('binary/octet-stream')) {
      debugPrint("Warning: Content-Type is not PDF: $contentType");
      // Continue anyway, as some servers might not set the correct content type
    }
    
    // Get temporary directory
    final directory = await getTemporaryDirectory();
    
    // Extract filename from path or use a default if empty
    String filename = pdfPath.split('/').last;
    if (filename.isEmpty || !filename.toLowerCase().endsWith('.pdf')) {
      filename = "document_${DateTime.now().millisecondsSinceEpoch}.pdf";
    }
    
    // Create a proper file path with filename
    final filePath = '${directory.path}/$filename';
    
    debugPrint('Saving PDF to: $filePath');
    
    // Write to file
    final file = File(filePath);
    await file.writeAsBytes(response.bodyBytes);
    
    // Dump the first 100 bytes of the file for debugging
    final fileBytes = await file.readAsBytes();
    final hexDump = fileBytes.take(100).map((b) => b.toRadixString(16).padLeft(2, '0')).join(' ');
    debugPrint('First 100 bytes of PDF: $hexDump');
    
    // Verify file exists and has content
    if (await file.exists()) {
      final fileSize = await file.length();
      debugPrint('PDF saved successfully. File size: $fileSize bytes');
      
      if (fileSize == 0) {
        throw Exception('Downloaded PDF file is empty');
      }
      
      // Try to read the first few bytes to verify it's a PDF
      final bytes = await file.openRead(0, 5).toList();
      if (bytes.isNotEmpty) {
        final firstBytes = bytes.first;
        
        // Check for PDF signature (%PDF-)
        if (firstBytes.length >= 5) {
          final signature = String.fromCharCodes(firstBytes.sublist(0, 5));
          if (signature != '%PDF-') {
            debugPrint('Warning: File does not start with PDF signature: $signature');
            // Continue anyway, as some PDFs might be malformed but still readable
          }
        }
      }
    } else {
      throw Exception('Failed to create PDF file');
    }
    
    return file;
  }

  Future<bool> updateDocumentMetadata(String fileId, Map<String, dynamic> metadata) async {
    try {
      debugPrint("Updating document metadata for: $fileId");
      debugPrint("Metadata: ${json.encode(metadata)}");
      
      // Remove _id field if present to avoid MongoDB errors
      metadata.remove('_id');
      
      final response = await http.post(
        Uri.parse('$baseUrl/update_document'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'file_id': fileId,
          'metadata': metadata,
        }),
      );
      
      debugPrint("Update response status: ${response.statusCode}");
      debugPrint("Update response body: ${response.body}");
      
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        return data['success'] ?? false;
      } else {
        throw Exception('Failed to update document: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint("Error updating document: $e");
      throw Exception('Error updating document: $e');
    }
  }
}

