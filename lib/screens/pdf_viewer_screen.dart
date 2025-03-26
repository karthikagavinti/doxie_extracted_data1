import 'dart:async';
import 'dart:io';
import 'package:doxie_dummy_pdf/models/pdf_document.dart';
import 'package:doxie_dummy_pdf/services/api_service.dart';
import 'package:doxie_dummy_pdf/services/websocket_service.dart';
import 'package:doxie_dummy_pdf/theme/app_theme.dart';
import 'package:doxie_dummy_pdf/widgets/pdf_debug_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';

import 'pdf_edit_screen.dart';

class PdfViewerScreen extends StatefulWidget {
  final File pdfFile;
  final PdfDocument document;
  final List<PdfDocument> allDocuments;
  final int currentIndex;
  final ApiService apiService;
  final WebSocketService websocketService;
  final Function(PdfDocument)? onDocumentUpdated;

  const PdfViewerScreen({
    Key? key,
    required this.pdfFile,
    required this.document,
    required this.allDocuments,
    required this.currentIndex,
    required this.apiService,
    required this.websocketService,
    this.onDocumentUpdated,
  }) : super(key: key);

  @override
  State<PdfViewerScreen> createState() => _PdfViewerScreenState();
}

class _PdfViewerScreenState extends State<PdfViewerScreen> {
  int _totalPages = 0;
  int _currentPage = 0;
  bool _isLoading = true;
  bool _isNavigating = false;
  bool _pdfError = false;
  String _errorMessage = '';
  late PdfDocument _currentDocument;
  late List<PdfDocument> _documents;
  late File _pdfFile;
  StreamSubscription? _documentUpdateSubscription;
  PDFViewController? _pdfViewController; // Add controller reference

  @override
  void initState() {
    super.initState();
    _currentDocument = widget.document;
    _documents = List.from(widget.allDocuments);
    _pdfFile = widget.pdfFile;

    // Verify PDF file exists and has content
    _verifyPdfFile();

    // Connect to WebSocket for real-time updates
    _setupWebSocketListener();
  }

  Future<void> _verifyPdfFile() async {
    try {
      if (!await _pdfFile.exists()) {
        debugPrint("PDF file doesn't exist: ${_pdfFile.path}");
        if (mounted) {
          setState(() {
            _pdfError = true;
            _errorMessage = "PDF file not found";
            _isLoading = false;
          });
        }
        return;
      }

      final fileSize = await _pdfFile.length();
      debugPrint("PDF file size: $fileSize bytes");

      if (fileSize == 0) {
        debugPrint("PDF file is empty");
        if (mounted) {
          setState(() {
            _pdfError = true;
            _errorMessage = "PDF file is empty";
            _isLoading = false;
          });
        }
        return;
      }

      // Try to read the first few bytes to verify it's a PDF
      final bytes = await _pdfFile.openRead(0, 5).toList();
      if (bytes.isNotEmpty) {
        final firstBytes = bytes.first;

        // Check for PDF signature (%PDF-)
        if (firstBytes.length >= 5) {
          final signature = String.fromCharCodes(firstBytes.sublist(0, 5));
          if (signature != '%PDF-') {
            debugPrint(
              'Warning: File does not start with PDF signature: $signature',
            );
            // Continue anyway, as some PDFs might be malformed but still readable
          }
        }
      }
    } catch (e) {
      debugPrint("Error verifying PDF file: $e");
      if (mounted) {
        setState(() {
          _pdfError = true;
          _errorMessage = "Error verifying PDF file: $e";
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _redownloadPdf() async {
    try {
      debugPrint("Redownloading PDF from: ${_currentDocument.pdfUrl}");

      // Show loading state
      if (mounted) {
        setState(() {
          _isLoading = true;
          _pdfError = false;
        });
      }

      // Download the PDF again
      final newPdfFile = await widget.apiService.downloadPdf(
        _currentDocument.pdfUrl,
      );

      // Update the file reference
      if (mounted) {
        setState(() {
          _pdfFile = newPdfFile;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error redownloading PDF: $e");
      if (mounted) {
        setState(() {
          _pdfError = true;
          _errorMessage = "Error redownloading PDF: $e";
          _isLoading = false;
        });
      }
    }
  }

  void _setupWebSocketListener() {
    try {
      // Subscribe to document updates
      _documentUpdateSubscription = widget.websocketService
          .getDocumentUpdates(_currentDocument.fileId)
          .listen(_handleDocumentUpdate);
    } catch (e) {
      debugPrint("Error setting up WebSocket listener: $e");
      // Don't show error to user - WebSocket is optional
    }
  }

  void _handleDocumentUpdate(PdfDocument updatedDocument) {
    if (!mounted) return;

    setState(() {
      // Update the current document
      _currentDocument = updatedDocument;

      // Update the document in the list
      final index = _documents.indexWhere(
        (doc) => doc.fileId == updatedDocument.fileId,
      );
      if (index != -1) {
        _documents[index] = updatedDocument;
      }
    });

    // Notify parent about the update
    if (widget.onDocumentUpdated != null) {
      widget.onDocumentUpdated!(_currentDocument);
    }

    // Show a snackbar to notify the user
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Document has been updated'),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  void dispose() {
    _documentUpdateSubscription?.cancel();
    super.dispose();
  }

  void _navigateToEditScreen() {
    if (!mounted) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => PdfEditScreen(
              pdfFile: _pdfFile,
              document: _currentDocument,
              apiService: widget.apiService,
              websocketService: widget.websocketService,
              onDocumentUpdated: _handleDocumentUpdated,
            ),
      ),
    );
  }

  void _handleDocumentUpdated(PdfDocument updatedDocument) {
    if (!mounted) return;

    setState(() {
      // Update the current document
      _currentDocument = updatedDocument;

      // Update the document in the list
      final index = _documents.indexWhere(
        (doc) => doc.fileId == updatedDocument.fileId,
      );
      if (index != -1) {
        _documents[index] = updatedDocument;
      }
    });

    // Notify parent about the update
    if (widget.onDocumentUpdated != null) {
      widget.onDocumentUpdated!(_currentDocument);
    }
  }

  Future<void> _navigateToNextDocument() async {
    if (widget.currentIndex < _documents.length - 1 &&
        !_isNavigating &&
        mounted) {
      setState(() {
        _isNavigating = true;
      });

      try {
        final nextDocument = _documents[widget.currentIndex + 1];
        final nextPdfFile = await widget.apiService.downloadPdf(
          nextDocument.pdfUrl,
        );

        if (!mounted) return;

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder:
                (context) => PdfViewerScreen(
                  pdfFile: nextPdfFile,
                  document: nextDocument,
                  allDocuments: _documents,
                  currentIndex: widget.currentIndex + 1,
                  apiService: widget.apiService,
                  websocketService: widget.websocketService,
                  onDocumentUpdated: widget.onDocumentUpdated,
                ),
          ),
        );
      } catch (e) {
        if (!mounted) return;

        setState(() {
          _isNavigating = false;
        });

        _showErrorDialog('Failed to load next document', e.toString());
      }
    }
  }

  Future<void> _navigateToPreviousDocument() async {
    if (widget.currentIndex > 0 && !_isNavigating && mounted) {
      setState(() {
        _isNavigating = true;
      });

      try {
        final prevDocument = _documents[widget.currentIndex - 1];
        final prevPdfFile = await widget.apiService.downloadPdf(
          prevDocument.pdfUrl,
        );

        if (!mounted) return;

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder:
                (context) => PdfViewerScreen(
                  pdfFile: prevPdfFile,
                  document: prevDocument,
                  allDocuments: _documents,
                  currentIndex: widget.currentIndex - 1,
                  apiService: widget.apiService,
                  websocketService: widget.websocketService,
                  onDocumentUpdated: widget.onDocumentUpdated,
                ),
          ),
        );
      } catch (e) {
        if (!mounted) return;

        setState(() {
          _isNavigating = false;
        });

        _showErrorDialog('Failed to load previous document', e.toString());
      }
    }
  }

  void _showErrorDialog(String title, String message) {
    if (!mounted) return;

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(title),
            content: Text(message),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('OK'),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppTheme.primaryColor, AppTheme.secondaryColor],
            ),
          ),
        ),
        title: Text(
          _currentDocument.originalFilename,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit, color: Colors.white),
            onPressed: _navigateToEditScreen,
            tooltip: 'Edit Document Details',
          ),
          IconButton(
            icon: const Icon(Icons.share, color: Colors.white),
            onPressed: () {
              // Implement share functionality
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Share functionality coming soon'),
                ),
              );
            },
            tooltip: 'Share Document',
          ),
        ],
      ),
      body: Column(
        children: [
          // Top section - PDF Viewer (60%)
          Expanded(
            flex: 3,
            child: GestureDetector(
              onHorizontalDragEnd: (details) {
                if (details.primaryVelocity! < 0) {
                  // Swipe right to left - go to edit page
                  _navigateToEditScreen();
                }
              },
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: Stack(
                  children: [
                    if (_pdfError)
                      PdfDebugWidget(
                        pdfFile: _pdfFile,
                        errorMessage: _errorMessage,
                        onRetry: _redownloadPdf,
                      )
                    else
                      // Always show PDFView, but control visibility with loading state
                      PDFView(
                        filePath: _pdfFile.path,
                        enableSwipe: true,
                        swipeHorizontal: true,
                        autoSpacing: true,
                        pageFling: true,
                        pageSnap: true,
                        fitPolicy: FitPolicy.BOTH,
                        defaultPage: 0,
                        preventLinkNavigation: false,
                        onRender: (pages) {
                          if (mounted) {
                            setState(() {
                              _totalPages = pages!;
                              _isLoading = false;
                            });
                          }
                          debugPrint("PDF rendered with $_totalPages pages");
                        },
                        onError: (error) {
                          debugPrint("Error rendering PDF: $error");
                          if (mounted) {
                            setState(() {
                              _isLoading = false;
                              _pdfError = true;
                              _errorMessage = error.toString();
                            });
                            _showErrorDialog(
                              'Error loading PDF',
                              error.toString(),
                            );
                          }
                        },
                        onPageChanged: (page, total) {
                          if (mounted) {
                            setState(() {
                              _currentPage = page!;
                            });
                          }
                          debugPrint("Page changed: $_currentPage of $total");
                        },
                        onViewCreated: (controller) {
                          _pdfViewController =
                              controller; // Store the controller
                          debugPrint("PDF view created");
                        },
                        onPageError: (page, error) {
                          debugPrint("Error on page $page: $error");
                        },
                      ),
                    if (_isLoading)
                      Container(
                        color: Colors.white.withOpacity(0.8),
                        child: const Center(
                          child: CircularProgressIndicator(
                            color: AppTheme.primaryColor,
                          ),
                        ),
                      ),

                    // Page indicator overlay
                    if (!_pdfError && !_isLoading && _totalPages > 0)
                      Positioned(
                        bottom: 20,
                        left: 0,
                        right: 0,
                        child: Center(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.7),
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.2),
                                  blurRadius: 5,
                                  spreadRadius: 1,
                                ),
                              ],
                            ),
                            child: Text(
                              'Page ${_currentPage + 1} of $_totalPages',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),

                    // Swipe hint overlay
                    if (!_pdfError && !_isLoading)
                      Positioned(
                        top: 80,
                        right: 10,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryColor.withOpacity(0.8),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.swipe_left,
                                color: Colors.white,
                                size: 16,
                              ),
                              SizedBox(width: 4),
                              Text(
                                'Swipe to edit',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                    // Loading overlay for navigation
                    if (_isNavigating)
                      Container(
                        color: Colors.black.withOpacity(0.3),
                        child: const Center(
                          child: CircularProgressIndicator(color: Colors.white),
                        ),
                      ),

                    // Add PDF navigation controls
                    if (!_pdfError && !_isLoading && _totalPages > 1)
                      Positioned(
                        bottom: 60,
                        left: 0,
                        right: 0,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Previous page button
                            if (_currentPage > 0)
                              FloatingActionButton.small(
                                heroTag: "prevPage",
                                backgroundColor: AppTheme.primaryColor,
                                onPressed: () {
                                  _pdfViewController?.setPage(_currentPage - 1);
                                },
                                child: const Icon(
                                  Icons.arrow_back,
                                  color: Colors.white,
                                ),
                              ),
                            const SizedBox(width: 20),
                            // Next page button
                            if (_currentPage < _totalPages - 1)
                              FloatingActionButton.small(
                                heroTag: "nextPage",
                                backgroundColor: AppTheme.primaryColor,
                                onPressed: () {
                                  _pdfViewController?.setPage(_currentPage + 1);
                                },
                                child: const Icon(
                                  Icons.arrow_forward,
                                  color: Colors.white,
                                ),
                              ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),

          // Bottom section - Document Details (40%)
          Expanded(
            flex: 2,
            child: GestureDetector(
              onHorizontalDragEnd: (details) {
                if (details.primaryVelocity! < 0) {
                  // Swipe right to left - go to next document
                  _navigateToNextDocument();
                } else if (details.primaryVelocity! > 0) {
                  // Swipe left to right - go to previous document
                  _navigateToPreviousDocument();
                }
              },
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(24),
                    topRight: Radius.circular(24),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Document Details',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        Row(
                          children: [
                            if (widget.currentIndex > 0)
                              IconButton(
                                icon: const Icon(
                                  Icons.arrow_back_ios,
                                  size: 18,
                                ),
                                onPressed: _navigateToPreviousDocument,
                                tooltip: 'Previous Document',
                              ),
                            if (widget.currentIndex < _documents.length - 1)
                              IconButton(
                                icon: const Icon(
                                  Icons.arrow_forward_ios,
                                  size: 18,
                                ),
                                onPressed: _navigateToNextDocument,
                                tooltip: 'Next Document',
                              ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildDetailCard(
                              'Original Filename',
                              _currentDocument.originalFilename,
                            ),
                            _buildDetailCard(
                              'File ID',
                              _currentDocument.fileId,
                            ),
                            _buildDetailCard(
                              'Upload Date',
                              _currentDocument.uploadDate,
                            ),
                            _buildDetailCard(
                              'Type',
                              _currentDocument.type.charAt(0).toUpperCase() +
                                  _currentDocument.type.substring(1),
                            ),

                            // Add more fields based on your metadata
                            if (_currentDocument.metadata.containsKey('author'))
                              _buildDetailCard(
                                'Author',
                                _currentDocument.metadata['author'],
                              ),
                            if (_currentDocument.metadata.containsKey(
                              'description',
                            ))
                              _buildDetailCard(
                                'Description',
                                _currentDocument.metadata['description'],
                                maxLines: 3,
                              ),
                            if (_currentDocument.metadata.containsKey(
                              'category',
                            ))
                              _buildDetailCard(
                                'Category',
                                _currentDocument.metadata['category'],
                              ),
                            if (_currentDocument.metadata.containsKey('tags'))
                              _buildDetailCard(
                                'Tags',
                                _currentDocument.metadata['tags'],
                              ),
                            if (_currentDocument.metadata.containsKey('status'))
                              _buildDetailCard(
                                'Status',
                                _currentDocument.metadata['status'],
                              ),

                            // Display all other metadata
                            const SizedBox(height: 16),
                            const Text(
                              'Additional Metadata',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 8),
                            ..._currentDocument.metadata.entries
                                .where(
                                  (entry) =>
                                      ![
                                        'title',
                                        'file_id',
                                        'upload_date',
                                        'author',
                                        'description',
                                        'category',
                                        'tags',
                                        'status',
                                        's3_url',
                                        '_id',
                                        'original_filename',
                                        'type',
                                      ].contains(entry.key),
                                )
                                .map(
                                  (entry) => _buildDetailCard(
                                    entry.key.replaceFirst(
                                      entry.key[0],
                                      entry.key[0].toUpperCase(),
                                    ),
                                    entry.value.toString(),
                                  ),
                                )
                                .toList(),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      // Add a floating action button to reload the PDF if needed
      floatingActionButton:
          _pdfError
              ? FloatingActionButton(
                onPressed: _redownloadPdf,
                backgroundColor: AppTheme.primaryColor,
                child: const Icon(Icons.refresh),
              )
              : null,
    );
  }

  Widget _buildDetailCard(String label, String value, {int maxLines = 1}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 5,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryColor,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(fontSize: 16, color: Colors.black87),
              maxLines: maxLines,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

extension StringExtensions on String {
  String charAt(int index) {
    if (index < 0 || index >= length) {
      return '';
    }
    return this[index];
  }
}
