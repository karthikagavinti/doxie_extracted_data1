// pdf_viewer_screen.dart - Updated with bottom edit transition and top status popup

import 'dart:convert';
import 'dart:async';
import 'dart:io';
import 'package:doxie_dummy_pdf/models/pdf_document.dart';
import 'package:doxie_dummy_pdf/screens/bottom_logic.dart';
import 'package:doxie_dummy_pdf/services/api_service.dart';
import 'package:doxie_dummy_pdf/services/websocket_service.dart';
import 'package:doxie_dummy_pdf/theme/app_theme.dart';
import 'package:doxie_dummy_pdf/widgets/pdf_debug_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:google_fonts/google_fonts.dart';
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

class _PdfViewerScreenState extends State<PdfViewerScreen>
    with SingleTickerProviderStateMixin {
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
  PDFViewController? _pdfViewController;
  double _currentScale = 1.0;
  bool _isFullScreen = false;
  bool _showControls = true;
  Timer? _controlsTimer;
  bool _showStatusPopup = false;

  // Animation controller for transitions
  late AnimationController _animationController;

  // Bottom sheet state
  bool _isBottomSheetExpanded = false;
  String? _currentExtractedData;
  String? _currentExtractedDataLabel;
  bool _isMetadataVisible = false;

  // Annotations
  List<Annotation> _annotations = [];
  bool _isAnnotationMode = false;
  Color _currentAnnotationColor = Colors.yellow.withOpacity(0.3);

  @override
  void initState() {
    super.initState();
    _currentDocument = widget.document;
    _documents = List.from(widget.allDocuments);
    _pdfFile = widget.pdfFile;

    // Initialize animation controller
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    // Print extracted_data to terminal if it exists
    if (_currentDocument.metadata.containsKey('extracted_data')) {
      final extractedData = _currentDocument.metadata['extracted_data'];
      if (extractedData is Map) {
        debugPrint("Extracted Data: ${jsonEncode(extractedData)}");
      } else {
        debugPrint("Extracted Data: $extractedData");
      }
    } else {
      debugPrint("No extracted_data field found in metadata");
    }

    // Verify PDF file exists and has content
    _verifyPdfFile();

    // Connect to WebSocket for real-time updates
    _setupWebSocketListener();

    // Start timer to hide controls
    _resetControlsTimer();

    // Show status popup briefly on load
    _showStatusPopupBriefly();
  }

  void _showStatusPopupBriefly() {
    if (_currentDocument.metadata.containsKey('status')) {
      setState(() {
        _showStatusPopup = true;
      });

      // Hide after 3 seconds
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) {
          setState(() {
            _showStatusPopup = false;
          });
        }
      });
    }
  }

  void _resetControlsTimer() {
    _controlsTimer?.cancel();
    setState(() {
      _showControls = true;
    });
    _controlsTimer = Timer(const Duration(seconds: 3), () {
      if (mounted && !_isAnnotationMode) {
        setState(() {
          _showControls = false;
        });
      }
    });
  }

  // Helper method to safely convert any value to a string
  String _valueToString(dynamic value) {
    if (value == null) {
      return 'null';
    } else if (value is Map || value is List) {
      return jsonEncode(value);
    } else {
      return value.toString();
    }
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

      // Show status popup
      _showStatusPopup = true;
    });

    // Print updated extracted_data if it exists
    if (_currentDocument.metadata.containsKey('extracted_data')) {
      final extractedData = _currentDocument.metadata['extracted_data'];
      if (extractedData is Map) {
        debugPrint("Updated Extracted Data: ${jsonEncode(extractedData)}");
      } else {
        debugPrint("Updated Extracted Data: $extractedData");
      }
    }

    // Notify parent about the update
    if (widget.onDocumentUpdated != null) {
      widget.onDocumentUpdated!(_currentDocument);
    }

    // Show a snackbar to notify the user with animation
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Document has been updated',
          style: GoogleFonts.poppins(),
        ),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(10),
      ),
    );

    // Hide status popup after 3 seconds
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _showStatusPopup = false;
        });
      }
    });
  }

  @override
  void dispose() {
    _documentUpdateSubscription?.cancel();
    _animationController.dispose();
    _controlsTimer?.cancel();
    super.dispose();
  }

  void _navigateToEditScreen() {
    if (!mounted) return;

    // Start animation
    _animationController.forward();

    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder:
            (context, animation, secondaryAnimation) => PdfEditScreen(
              pdfFile: _pdfFile,
              document: _currentDocument,
              apiService: widget.apiService,
              websocketService: widget.websocketService,
              onDocumentUpdated: _handleDocumentUpdated,
            ),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          // Changed: Animation now comes from bottom
          const begin = Offset(0.0, 1.0);
          const end = Offset.zero;
          const curve = Curves.easeInOutCubic;

          var tween = Tween(
            begin: begin,
            end: end,
          ).chain(CurveTween(curve: curve));
          var offsetAnimation = animation.drive(tween);

          return SlideTransition(position: offsetAnimation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 400),
      ),
    ).then((_) {
      // Reset animation when returning
      _animationController.reset();
    });
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

      // Show status popup
      _showStatusPopup = true;
    });

    // Print updated extracted_data if it exists
    if (_currentDocument.metadata.containsKey('extracted_data')) {
      final extractedData = _currentDocument.metadata['extracted_data'];
      if (extractedData is Map) {
        debugPrint(
          "Document Updated - Extracted Data: ${jsonEncode(extractedData)}",
        );
      } else {
        debugPrint("Document Updated - Extracted Data: $extractedData");
      }
    }

    // Notify parent about the update
    if (widget.onDocumentUpdated != null) {
      widget.onDocumentUpdated!(_currentDocument);
    }

    // Hide status popup after 3 seconds
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _showStatusPopup = false;
        });
      }
    });
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
          PageRouteBuilder(
            pageBuilder:
                (context, animation, secondaryAnimation) => PdfViewerScreen(
                  pdfFile: nextPdfFile,
                  document: nextDocument,
                  allDocuments: _documents,
                  currentIndex: widget.currentIndex + 1,
                  apiService: widget.apiService,
                  websocketService: widget.websocketService,
                  onDocumentUpdated: widget.onDocumentUpdated,
                ),
            transitionsBuilder: (
              context,
              animation,
              secondaryAnimation,
              child,
            ) {
              const begin = Offset(1.0, 0.0);
              const end = Offset.zero;
              const curve = Curves.easeInOutCubic;

              var tween = Tween(
                begin: begin,
                end: end,
              ).chain(CurveTween(curve: curve));
              var offsetAnimation = animation.drive(tween);

              return SlideTransition(position: offsetAnimation, child: child);
            },
            transitionDuration: const Duration(milliseconds: 400),
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
          PageRouteBuilder(
            pageBuilder:
                (context, animation, secondaryAnimation) => PdfViewerScreen(
                  pdfFile: prevPdfFile,
                  document: prevDocument,
                  allDocuments: _documents,
                  currentIndex: widget.currentIndex - 1,
                  apiService: widget.apiService,
                  websocketService: widget.websocketService,
                  onDocumentUpdated: widget.onDocumentUpdated,
                ),
            transitionsBuilder: (
              context,
              animation,
              secondaryAnimation,
              child,
            ) {
              const begin = Offset(-1.0, 0.0);
              const end = Offset.zero;
              const curve = Curves.easeInOutCubic;

              var tween = Tween(
                begin: begin,
                end: end,
              ).chain(CurveTween(curve: curve));
              var offsetAnimation = animation.drive(tween);

              return SlideTransition(position: offsetAnimation, child: child);
            },
            transitionDuration: const Duration(milliseconds: 400),
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
            title: Text(
              title,
              style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
            ),
            content: Text(message, style: GoogleFonts.poppins()),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text('OK', style: GoogleFonts.poppins()),
              ),
            ],
          ),
    );
  }

  // New method to show extracted data in bottom sheet
  void _showExtractedDataBottomSheet(String label, String value) {
    if (!mounted) return;

    // Store the data and expand the sheet
    setState(() {
      _currentExtractedDataLabel = label;
      _currentExtractedData = value;
      _isBottomSheetExpanded = true;
    });

    // Use the imported DocumentBottomSheet class
    DocumentBottomSheet.showExtractedDataBottomSheet(
      context,
      label: label,
      value: value,
      isMetadataVisible: _isMetadataVisible,
      onMetadataVisibilityChanged: (visible) {
        setState(() {
          _isMetadataVisible = visible;
        });
      },
      metadata: _currentDocument.metadata,
    ).then((_) {
      // When the bottom sheet is closed, update the state
      if (mounted) {
        setState(() {
          _isBottomSheetExpanded = false;
        });
      }
    });
  }

  void _toggleFullScreen() {
    setState(() {
      _isFullScreen = !_isFullScreen;
      _resetControlsTimer();
    });
  }

  void _toggleAnnotationMode() {
    setState(() {
      _isAnnotationMode = !_isAnnotationMode;
      if (_isAnnotationMode) {
        _showControls = true; // Always show controls in annotation mode
      } else {
        _resetControlsTimer();
      }
    });
  }

  void _addAnnotation(Offset position) {
    if (!_isAnnotationMode) return;

    setState(() {
      _annotations.add(
        Annotation(
          page: _currentPage,
          position: position,
          color: _currentAnnotationColor,
          text: '',
          timestamp: DateTime.now(),
        ),
      );
    });

    // Show annotation dialog
    _showAnnotationDialog(_annotations.last);
  }

  void _showAnnotationDialog(Annotation annotation) {
    final TextEditingController textController = TextEditingController();

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(
              'Add Note',
              style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: textController,
                  decoration: InputDecoration(
                    hintText: 'Enter your note here...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Color:', style: GoogleFonts.poppins()),
                    Row(
                      children: [
                        _buildColorOption(Colors.yellow.withOpacity(0.3)),
                        _buildColorOption(Colors.green.withOpacity(0.3)),
                        _buildColorOption(Colors.blue.withOpacity(0.3)),
                        _buildColorOption(Colors.red.withOpacity(0.3)),
                      ],
                    ),
                  ],
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  // Remove the annotation if canceled
                  setState(() {
                    _annotations.remove(annotation);
                  });
                },
                child: Text('Cancel', style: GoogleFonts.poppins()),
              ),
              ElevatedButton(
                onPressed: () {
                  // Update the annotation
                  setState(() {
                    final index = _annotations.indexOf(annotation);
                    if (index != -1) {
                      _annotations[index] = annotation.copyWith(
                        text: textController.text,
                        color: _currentAnnotationColor,
                      );
                    }
                  });
                  Navigator.pop(context);
                },
                child: Text('Save', style: GoogleFonts.poppins()),
              ),
            ],
          ),
    );
  }

  Widget _buildColorOption(Color color) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _currentAnnotationColor = color;
        });
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          color: color,
          border: Border.all(
            color:
                _currentAnnotationColor == color
                    ? Colors.black
                    : Colors.grey.shade300,
            width: _currentAnnotationColor == color ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar:
          _isFullScreen
              ? null
              : AppBar(
                elevation: 4,
                backgroundColor: Colors.transparent,
                flexibleSpace: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [AppTheme.primaryColor, AppTheme.secondaryColor],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                ),
                title: Text(
                  _currentDocument.originalFilename,
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.normal,
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
                    icon: const Icon(Icons.fullscreen, color: Colors.white),
                    onPressed: _toggleFullScreen,
                    tooltip: 'Toggle Fullscreen',
                  ),
                ],
              ),
      body: GestureDetector(
        onTap: () => _resetControlsTimer(),
        child: Stack(
          children: [
            Column(
              children: [
                // Top section - PDF Viewer (60% or full screen)
                Expanded(
                  flex: _isFullScreen ? 1 : 3,
                  child: GestureDetector(
                    onHorizontalDragEnd: (details) {
                      if (details.primaryVelocity! < 0) {
                        // Swipe right to left - go to edit page
                        _navigateToEditScreen();
                      }
                    },
                    onTapUp: (details) {
                      if (_isAnnotationMode) {
                        // Get the tap position
                        final RenderBox box =
                            context.findRenderObject() as RenderBox;
                        final position = box.globalToLocal(
                          details.globalPosition,
                        );
                        _addAnnotation(position);
                      } else {
                        _resetControlsTimer();
                      }
                    },
                    child: Stack(
                      children: [
                        Container(
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
                                  enableSwipe: !_isAnnotationMode,
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
                                    debugPrint(
                                      "PDF rendered with $_totalPages pages",
                                    );
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
                                    debugPrint(
                                      "Page changed: $_currentPage of $total",
                                    );
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

                              // Annotations layer
                              if (!_pdfError &&
                                  !_isLoading &&
                                  _annotations.isNotEmpty)
                                Positioned.fill(
                                  child: IgnorePointer(
                                    ignoring: !_isAnnotationMode,
                                    child: CustomPaint(
                                      painter: AnnotationPainter(
                                        annotations:
                                            _annotations
                                                .where(
                                                  (a) => a.page == _currentPage,
                                                )
                                                .toList(),
                                        onTap: (annotation) {
                                          if (_isAnnotationMode) {
                                            _showAnnotationDialog(annotation);
                                          }
                                        },
                                      ),
                                    ),
                                  ),
                                ),

                              if (_isLoading)
                                Container(
                                  color: Colors.white.withOpacity(0.8),
                                  child: Center(
                                    child: CircularProgressIndicator(
                                      color: AppTheme.primaryColor,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),

                        // Fullscreen controls overlay
                        if (_isFullScreen && _showControls)
                          Positioned(
                            top: 0,
                            left: 0,
                            right: 0,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    Colors.black.withOpacity(0.7),
                                    Colors.transparent,
                                  ],
                                ),
                              ),
                              child: SafeArea(
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    IconButton(
                                      icon: const Icon(
                                        Icons.arrow_back,
                                        color: Colors.white,
                                      ),
                                      onPressed: () => Navigator.pop(context),
                                    ),
                                    Text(
                                      _currentDocument.originalFilename,
                                      style: GoogleFonts.poppins(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Row(
                                      children: [
                                        IconButton(
                                          icon: const Icon(
                                            Icons.edit,
                                            color: Colors.white,
                                          ),
                                          onPressed: _navigateToEditScreen,
                                          tooltip: 'Edit Document',
                                        ),
                                        IconButton(
                                          icon: const Icon(
                                            Icons.fullscreen_exit,
                                            color: Colors.white,
                                          ),
                                          onPressed: _toggleFullScreen,
                                          tooltip: 'Exit Fullscreen',
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),

                        // Page indicator overlay
                        if (!_pdfError &&
                            !_isLoading &&
                            _totalPages > 0 &&
                            _showControls)
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
                                  style: GoogleFonts.poppins(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ),

                        // Swipe hint overlay
                        if (!_pdfError &&
                            !_isLoading &&
                            _showControls &&
                            !_isAnnotationMode)
                          Positioned(
                            top: 10,
                            right: 10,
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppTheme.primaryColor.withOpacity(0.8),
                                borderRadius: BorderRadius.circular(8),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.2),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Row(
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
                                    style: GoogleFonts.poppins(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
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
                            child: Center(
                              child: CircularProgressIndicator(
                                color: Colors.white,
                              ),
                            ),
                          ),

                        // Add PDF navigation controls
                        if (!_pdfError &&
                            !_isLoading &&
                            _totalPages > 1 &&
                            _showControls)
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
                                    elevation: 4,
                                    onPressed: () {
                                      _pdfViewController?.setPage(
                                        _currentPage - 1,
                                      );
                                      _resetControlsTimer();
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
                                    elevation: 4,
                                    onPressed: () {
                                      _pdfViewController?.setPage(
                                        _currentPage + 1,
                                      );
                                      _resetControlsTimer();
                                    },
                                    child: const Icon(
                                      Icons.arrow_forward,
                                      color: Colors.white,
                                    ),
                                  ),
                              ],
                            ),
                          ),

                        // Zoom controls
                        if (!_pdfError && !_isLoading && _showControls)
                          Positioned(
                            top: 60,
                            right: 10,
                            child: Column(
                              children: [
                                FloatingActionButton.small(
                                  heroTag: "zoomIn",
                                  backgroundColor: Colors.white,
                                  elevation: 4,
                                  onPressed: () {
                                    setState(() {
                                      _currentScale = (_currentScale + 0.25)
                                          .clamp(0.5, 3.0);
                                    });
                                    // Instead of setZoom, use scale parameter
                                    _pdfViewController?.setPage(_currentPage);
                                    _resetControlsTimer();
                                  },
                                  child: const Icon(
                                    Icons.zoom_in,
                                    color: Colors.black87,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.1),
                                        blurRadius: 4,
                                        spreadRadius: 1,
                                      ),
                                    ],
                                  ),
                                  child: Text(
                                    '${(_currentScale * 100).toInt()}%',
                                    style: GoogleFonts.poppins(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                FloatingActionButton.small(
                                  heroTag: "zoomOut",
                                  backgroundColor: Colors.white,
                                  elevation: 4,
                                  onPressed: () {
                                    setState(() {
                                      _currentScale = (_currentScale - 0.25)
                                          .clamp(0.5, 3.0);
                                    });
                                    // Instead of setZoom, use scale parameter
                                    _pdfViewController?.setPage(_currentPage);
                                    _resetControlsTimer();
                                  },
                                  child: const Icon(
                                    Icons.zoom_out,
                                    color: Colors.black87,
                                  ),
                                ),
                              ],
                            ),
                          ),

                        // Annotation tools
                        if (!_pdfError && !_isLoading && _showControls)
                          Positioned(
                            top: 60,
                            left: 10,
                            child: Column(
                              children: [
                                FloatingActionButton.small(
                                  heroTag: "annotate",
                                  backgroundColor:
                                      _isAnnotationMode
                                          ? AppTheme.primaryColor
                                          : Colors.white,
                                  elevation: 4,
                                  onPressed: _toggleAnnotationMode,
                                  child: Icon(
                                    Icons.edit_note,
                                    color:
                                        _isAnnotationMode
                                            ? Colors.white
                                            : Colors.black87,
                                  ),
                                ),
                                if (_isAnnotationMode) ...[
                                  const SizedBox(height: 8),
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(12),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.1),
                                          blurRadius: 4,
                                          spreadRadius: 1,
                                        ),
                                      ],
                                    ),
                                    child: Column(
                                      children: [
                                        _buildColorOption(
                                          Colors.yellow.withOpacity(0.3),
                                        ),
                                        const SizedBox(height: 8),
                                        _buildColorOption(
                                          Colors.green.withOpacity(0.3),
                                        ),
                                        const SizedBox(height: 8),
                                        _buildColorOption(
                                          Colors.blue.withOpacity(0.3),
                                        ),
                                        const SizedBox(height: 8),
                                        _buildColorOption(
                                          Colors.red.withOpacity(0.3),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ),

                // Bottom section - Document Details (40%)
                if (!_isFullScreen)
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
                                Text(
                                  'Document Details',
                                  style: GoogleFonts.poppins(
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

                                    if (widget.currentIndex <
                                        _documents.length - 1)
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
                            Expanded(
                              child: SingleChildScrollView(
                                physics: const BouncingScrollPhysics(),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: _buildDocumentDetailWidgets(),
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

            // Status popup that slides down from top (changed from bottom)
            if (_showStatusPopup &&
                _currentDocument.metadata.containsKey('status'))
              Positioned(
                top:
                    _isFullScreen
                        ? 0
                        : kToolbarHeight, // Position below app bar
                left: 0,
                right: 0,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, -1), // Changed: Comes from top
                    end: Offset.zero,
                  ).animate(
                    CurvedAnimation(
                      parent: _animationController..forward(),
                      curve: Curves.easeOutCubic,
                    ),
                  ),
                  child: Container(
                    margin: const EdgeInsets.all(16),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color:
                          _currentDocument.metadata['status'] == 'Verified'
                              ? Colors.green.withOpacity(0.9)
                              : Colors.blue.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 10,
                          spreadRadius: 1,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Icon(
                          _currentDocument.metadata['status'] == 'Verified'
                              ? Icons.verified
                              : Icons.pending_actions,
                          color: Colors.white,
                          size: 28,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Status: ${_currentDocument.metadata['status']}',
                                style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  fontSize: 16,
                                ),
                              ),
                              Text(
                                _currentDocument.metadata['status'] ==
                                        'Verified'
                                    ? 'This document has been verified and processed.'
                                    : 'This document is awaiting verification.',
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  color: Colors.white.withOpacity(0.9),
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.white),
                          onPressed: () {
                            setState(() {
                              _showStatusPopup = false;
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildDocumentDetailWidgets() {
    List<Widget> widgets = [];
    String emptyValue = 'Not available';

    // Get extracted data if available
    String extractedDataText = '';
    Map<String, String> details = {};

    if (_currentDocument.metadata.containsKey('extracted_data')) {
      final extractedData = _currentDocument.metadata['extracted_data'];
      extractedDataText = _valueToString(extractedData);
      details = DocumentBottomSheet.extractAllKeyDetails(extractedDataText);
    }

    // 1. Purchase Order
    widgets.add(
      _buildDetailCard(
        'Purchase Order',
        (details.containsKey('Purchase Order Number') ||
                details.containsKey('Customer PO#'))
            ? (details['Purchase Order Number'] ??
                details['Customer PO#'] ??
                '')
            : emptyValue,
      ),
    );

    // 2. Contact information
    widgets.add(
      _buildDetailCard(
        'Contact',
        (details.containsKey('Phone') || details.containsKey('User'))
            ? (details['Phone'] ?? details['User'] ?? '')
            : emptyValue,
      ),
    );

    // 3. Date
    widgets.add(
      _buildDetailCard(
        'Date',
        details.containsKey('Date') ? details['Date']! : emptyValue,
      ),
    );

    // 4. Address
    widgets.add(
      _buildDetailCard(
        'Address',
        (details.containsKey('Address') ||
                details.containsKey('Ship From Address') ||
                details.containsKey('Ship To Address'))
            ? (details['Address'] ??
                details['Ship From Address'] ??
                details['Ship To Address'] ??
                '')
            : emptyValue,
      ),
    );

    // 5. Always show extracted data field
    widgets.add(
      _buildDetailCard(
        'Extracted Data',
        extractedDataText.isEmpty ? emptyValue : extractedDataText,
        maxLines: 3,
        isExtractedData: true,
      ),
    );

    // 6. Annotations count
    final pageAnnotations =
        _annotations.where((a) => a.page == _currentPage).length;
    final totalAnnotations = _annotations.length;

    if (totalAnnotations > 0) {
      widgets.add(
        _buildDetailCard(
          'Annotations',
          '$pageAnnotations on current page, $totalAnnotations total',
          maxLines: 1,
          isExtractedData: false,
        ),
      );
    }

    return widgets;
  }

  Widget _buildDetailCard(
    String label,
    String value, {
    int maxLines = 1,
    bool isExtractedData = false,
  }) {
    // Print the label and value if it's "Extracted Data"
    if (label == 'Extracted Data') {
      debugPrint("$label: $value");
    }

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 4,
            spreadRadius: 0,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppTheme.primaryColor,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.poppins(fontSize: 16, color: Colors.black87),
            maxLines: maxLines,
            overflow: maxLines > 1 ? TextOverflow.ellipsis : TextOverflow.fade,
          ),
          // Add "See more" button for long text
          if (value.length > 100 && maxLines > 1)
            TextButton(
              onPressed: () {
                if (isExtractedData) {
                  _showExtractedDataBottomSheet(label, value);
                } else {
                  // Show regular dialog for non-extracted data
                  showDialog(
                    context: context,
                    builder:
                        (context) => AlertDialog(
                          title: Text(
                            label,
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          content: SingleChildScrollView(
                            child: Text(value, style: GoogleFonts.poppins()),
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(),
                              child: Text(
                                'Close',
                                style: GoogleFonts.poppins(),
                              ),
                            ),
                          ],
                        ),
                  );
                }
              },
              child: Text(
                'See more',
                style: GoogleFonts.poppins(
                  color: Colors.blueAccent,
                  fontWeight: FontWeight.w500,
                ),
              ),
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                minimumSize: const Size(50, 20),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                alignment: Alignment.centerLeft,
              ),
            ),
        ],
      ),
    );
  }
}

// Annotation model
class Annotation {
  final int page;
  final Offset position;
  final Color color;
  final String text;
  final DateTime timestamp;

  Annotation({
    required this.page,
    required this.position,
    required this.color,
    required this.text,
    required this.timestamp,
  });

  Annotation copyWith({
    int? page,
    Offset? position,
    Color? color,
    String? text,
    DateTime? timestamp,
  }) {
    return Annotation(
      page: page ?? this.page,
      position: position ?? this.position,
      color: color ?? this.color,
      text: text ?? this.text,
      timestamp: timestamp ?? this.timestamp,
    );
  }
}

// Custom painter for annotations
class AnnotationPainter extends CustomPainter {
  final List<Annotation> annotations;
  final Function(Annotation) onTap;

  AnnotationPainter({required this.annotations, required this.onTap});

  @override
  void paint(Canvas canvas, Size size) {
    for (final annotation in annotations) {
      final paint =
          Paint()
            ..color = annotation.color
            ..style = PaintingStyle.fill;

      // Draw a circle at the annotation position
      canvas.drawCircle(
        annotation.position,
        30.0, // Radius
        paint,
      );

      // Draw text if available
      if (annotation.text.isNotEmpty) {
        final textSpan = TextSpan(
          text:
              annotation.text.length > 10
                  ? '${annotation.text.substring(0, 10)}...'
                  : annotation.text,
          style: TextStyle(
            color: Colors.black87,
            fontSize: 10,
            fontWeight: FontWeight.w500,
          ),
        );

        final textPainter = TextPainter(
          text: textSpan,
          textDirection: TextDirection.ltr,
        );

        textPainter.layout(maxWidth: 60);

        textPainter.paint(
          canvas,
          Offset(
            annotation.position.dx - textPainter.width / 2,
            annotation.position.dy - textPainter.height / 2,
          ),
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;

  @override
  bool hitTest(Offset position) {
    for (final annotation in annotations) {
      final distance = (position - annotation.position).distance;
      if (distance <= 30.0) {
        onTap(annotation);
        return true;
      }
    }
    return false;
  }
}
