import 'dart:async';
import 'dart:convert';
import 'package:doxie_dummy_pdf/models/pdf_document.dart';
import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/io.dart';


class WebSocketService {
  WebSocketChannel? _channel;
  final String baseUrl;
  final Map<String, StreamController<PdfDocument>> _documentControllers = {};
  bool _isConnected = false;
  String? _currentDocumentId;

  WebSocketService({required this.baseUrl});

  // Connect to WebSocket for a specific document
  Future<void> connectToDocument(String documentId) async {
    // Close existing connection if any
    await disconnect();
    
    try {
      // Convert http:// to ws:// or https:// to wss://
      String wsUrl = baseUrl.replaceFirst(RegExp(r'^http://'), 'ws://');
      wsUrl = wsUrl.replaceFirst(RegExp(r'^https://'), 'wss://');
      
      // Connect to WebSocket endpoint
      _channel = IOWebSocketChannel.connect('$wsUrl/ws/$documentId');
      _currentDocumentId = documentId;
      _isConnected = true;
      
      // Listen for messages
      _channel!.stream.listen(
        (message) {
          _handleMessage(message);
        },
        onError: (error) {
          debugPrint('WebSocket error: $error');
          _isConnected = false;
        },
        onDone: () {
          debugPrint('WebSocket connection closed');
          _isConnected = false;
        },
      );
      
      debugPrint('Connected to WebSocket for document: $documentId');
    } catch (e) {
      debugPrint('Failed to connect to WebSocket: $e');
      _isConnected = false;
    }
  }

  // Disconnect from WebSocket
  Future<void> disconnect() async {
    if (_channel != null) {
      await _channel!.sink.close();
      _channel = null;
      _isConnected = false;
      _currentDocumentId = null;
      debugPrint('Disconnected from WebSocket');
    }
  }

  // Handle incoming WebSocket messages
  void _handleMessage(dynamic message) {
    try {
      final data = jsonDecode(message);
      
      if (data['type'] == 'document_updated' && data['data'] != null) {
        final documentData = data['data'];
        final updatedDocument = PdfDocument.fromJson(documentData);
        
        // Notify listeners for this document
        if (_documentControllers.containsKey(updatedDocument.fileId)) {
          _documentControllers[updatedDocument.fileId]!.add(updatedDocument);
        }
        
        debugPrint('Received document update: ${updatedDocument.title}');
      }
    } catch (e) {
      debugPrint('Error processing WebSocket message: $e');
    }
  }

  // Get stream for a specific document's updates
  Stream<PdfDocument> getDocumentUpdates(String documentId) {
    if (!_documentControllers.containsKey(documentId)) {
      _documentControllers[documentId] = StreamController<PdfDocument>.broadcast();
    }
    
    // Connect to this document if not already connected
    if (_currentDocumentId != documentId) {
      connectToDocument(documentId);
    }
    
    return _documentControllers[documentId]!.stream;
  }

  // Dispose resources
  void dispose() {
    disconnect();
    for (var controller in _documentControllers.values) {
      controller.close();
    }
    _documentControllers.clear();
  }

  bool get isConnected => _isConnected;
}

