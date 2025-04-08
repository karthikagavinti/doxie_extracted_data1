import 'dart:async';
import 'dart:io';
import 'package:doxie_dummy_pdf/screens/bottom_logic.dart';
import 'package:doxie_dummy_pdf/screens/pdf_viewer_screen.dart';
import 'package:doxie_dummy_pdf/widgets/pdf_debug_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/pdf_document.dart';
import '../theme/app_theme.dart';
import '../services/api_service.dart';
import '../services/websocket_service.dart';

class PdfEditScreen extends StatefulWidget {
  final File pdfFile;
  final PdfDocument document;
  final ApiService? apiService;
  final WebSocketService? websocketService;
  final Function(PdfDocument)? onDocumentUpdated;

  PdfEditScreen({
    super.key,
    required this.pdfFile,
    required this.document,
    this.apiService,
    this.websocketService,
    this.onDocumentUpdated,
  });

  @override
  State<PdfEditScreen> createState() => _PdfEditScreenState();
}

class _PdfEditScreenState extends State<PdfEditScreen>
    with SingleTickerProviderStateMixin {
  int _totalPages = 0;
  int _currentPage = 0;
  bool _isLoading = true;
  bool _isEdited = false;
  bool _isSaving = false;
  bool _pdfError = false;
  String _errorMessage = '';
  bool _isBottomSheetExpanded = false;
  String? _currentExtractedData;
  String? _currentExtractedDataLabel;
  bool _isMetadataVisible = false; // Controls metadata visibility
  bool _isVerified = false;
  bool _isFullScreen = false;
  bool _showControls = true;
  Timer? _controlsTimer;
  PDFViewController? _pdfViewController;
  double _currentScale = 1.0;
  bool _showStatusPopup = false;

  // Animation controller
  late AnimationController _animationController;

  // Controllers for editable fields
  late TextEditingController _originalFilenameController;
  late TextEditingController _titleController;
  late TextEditingController _authorController;
  late TextEditingController _descriptionController;
  late TextEditingController _categoryController;
  late TextEditingController _tagsController;
  late TextEditingController _statusController;

  // Controllers for key fields
  late TextEditingController _purchaseOrderController;
  late TextEditingController _contactController;
  late TextEditingController _dateController;
  late TextEditingController _addressController;
  late TextEditingController _extractedDataController;

  // Map to store additional metadata controllers
  final Map<String, TextEditingController> _additionalControllers = {};

  @override
  void initState() {
    super.initState();
    _initControllers();

    // Initialize animation controller
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    // Check if document is already verified
    _isVerified =
        widget.document.metadata.containsKey('status') &&
        widget.document.metadata['status'] == 'Verified';

    // Start timer to hide controls
    _resetControlsTimer();

    // Show status popup briefly on load
    _showStatusPopupBriefly();
  }

  void _showStatusPopupBriefly() {
    if (widget.document.metadata.containsKey('status')) {
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
      if (mounted) {
        setState(() {
          _showControls = false;
        });
      }
    });
  }

  void _initControllers() {
    _originalFilenameController = TextEditingController(
      text: widget.document.originalFilename,
    );
    _titleController = TextEditingController(text: widget.document.title);
    _authorController = TextEditingController(
      text: widget.document.getMetadataField('author', ''),
    );
    _descriptionController = TextEditingController(
      text: widget.document.getMetadataField('description', ''),
    );
    _categoryController = TextEditingController(
      text: widget.document.getMetadataField('category', ''),
    );
    _tagsController = TextEditingController(
      text: widget.document.getMetadataField('tags', ''),
    );
    _statusController = TextEditingController(
      text: widget.document.getMetadataField('status', ''),
    );

    // Initialize controllers for key fields
    String extractedData = '';
    Map<String, String> details = {};

    if (widget.document.metadata.containsKey('extracted_data')) {
      extractedData = widget.document.metadata['extracted_data'].toString();

      // Extract key details if possible
      if (extractedData.isNotEmpty) {
        details = _extractKeyDetails(extractedData);
      }
    }

    _purchaseOrderController = TextEditingController(
      text: details['Purchase Order Number'] ?? details['Customer PO#'] ?? '',
    );

    _contactController = TextEditingController(
      text: details['Phone'] ?? details['User'] ?? '',
    );

    _dateController = TextEditingController(text: details['Date'] ?? '');

    _addressController = TextEditingController(
      text:
          details['Address'] ??
          details['Ship From Address'] ??
          details['Ship To Address'] ??
          '',
    );

    _extractedDataController = TextEditingController(text: extractedData);

    // Initialize controllers for additional metadata
    widget.document.metadata.entries
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
                'extracted_data',
              ].contains(entry.key),
        )
        .forEach((entry) {
          _additionalControllers[entry.key] = TextEditingController(
            text: entry.value.toString(),
          );
        });
  }

  // Helper method to extract key details from extracted data
  Map<String, String> _extractKeyDetails(String text) {
    final Map<String, String> details = {};

    try {
      // Extract Purchase Order
      final poRegex = RegExp(
        r'(?:Purchase\s*Order|PO|P\.O\.)(?:\s*Number)?[#:\s]*([A-Z0-9\-]+)',
        caseSensitive: false,
      );
      final poMatch = poRegex.firstMatch(text);
      if (poMatch != null && poMatch.groupCount >= 1) {
        final value = poMatch.group(1)?.trim();
        if (value != null && value.isNotEmpty) {
          details['Purchase Order Number'] = value;
        }
      }

      // Extract Customer PO#
      final customerPoRegex = RegExp(
        r'Customer\s+PO#:\s*([A-Z0-9\-]+)',
        caseSensitive: false,
      );
      final customerPoMatch = customerPoRegex.firstMatch(text);
      if (customerPoMatch != null && customerPoMatch.groupCount >= 1) {
        final value = customerPoMatch.group(1)?.trim();
        if (value != null && value.isNotEmpty) {
          details['Customer PO#'] = value;
        }
      }

      // Extract Phone
      final phoneRegex = RegExp(
        r'(?:Phone|Tel|Telephone)[:\s]*(\d{3}[\s\-\.]\d{3}[\s\-\.]\d{4})',
        caseSensitive: false,
      );
      final phoneMatch = phoneRegex.firstMatch(text);
      if (phoneMatch != null && phoneMatch.groupCount >= 1) {
        final value = phoneMatch.group(1)?.trim();
        if (value != null && value.isNotEmpty) {
          details['Phone'] = value;
        }
      }

      // Extract User
      final userRegex = RegExp(
        r'User"?:\s*"?([^,\n\r"]+)"?',
        caseSensitive: false,
      );
      final userMatch = userRegex.firstMatch(text);
      if (userMatch != null && userMatch.groupCount >= 1) {
        final value = userMatch.group(1)?.trim();
        if (value != null && value.isNotEmpty) {
          details['User'] = value;
        }
      }

      // Extract Date
      final dateRegex = RegExp(
        r'(?:Date|Order\s*Date)[:\s]*(\d{1,2}[\/\-\.]\d{1,2}[\/\-\.]\d{2,4})',
        caseSensitive: false,
      );
      final dateMatch = dateRegex.firstMatch(text);
      if (dateMatch != null && dateMatch.groupCount >= 1) {
        final value = dateMatch.group(1)?.trim();
        if (value != null && value.isNotEmpty) {
          details['Date'] = value;
        }
      }

      // Extract Address
      final addressRegex = RegExp(
        r'(?:Address|Vendor\s*Address)[:\s]*([^,\n\r]*(?:,\s*[^,\n\r]*){1,})',
        caseSensitive: false,
      );
      final addressMatch = addressRegex.firstMatch(text);
      if (addressMatch != null && addressMatch.groupCount >= 1) {
        final value = addressMatch.group(1)?.trim();
        if (value != null && value.isNotEmpty) {
          details['Address'] = value;
        }
      }

      // Extract Ship From Address
      final shipFromAddressRegex = RegExp(
        r'Ship\s+From"?:\s*\{[^}]*Address"?:\s*"?([^,\n\r"]+)"?',
        caseSensitive: false,
      );
      final shipFromAddressMatch = shipFromAddressRegex.firstMatch(text);
      if (shipFromAddressMatch != null &&
          shipFromAddressMatch.groupCount >= 1) {
        final value = shipFromAddressMatch.group(1)?.trim();
        if (value != null && value.isNotEmpty) {
          details['Ship From Address'] = value;
        }
      }

      // Extract Ship To Address
      final shipToAddressRegex = RegExp(
        r'Ship\s+To"?:\s*\{[^}]*Address"?:\s*"?([^,\n\r"]+)"?',
        caseSensitive: false,
      );
      final shipToAddressMatch = shipToAddressRegex.firstMatch(text);
      if (shipToAddressMatch != null && shipToAddressMatch.groupCount >= 1) {
        final value = shipToAddressMatch.group(1)?.trim();
        if (value != null && value.isNotEmpty) {
          details['Ship To Address'] = value;
        }
      }
    } catch (e) {
      print("Error extracting key details: $e");
    }

    return details;
  }

  @override
  void dispose() {
    _originalFilenameController.dispose();
    _titleController.dispose();
    _authorController.dispose();
    _descriptionController.dispose();
    _categoryController.dispose();
    _tagsController.dispose();
    _statusController.dispose();

    // Dispose key field controllers
    _purchaseOrderController.dispose();
    _contactController.dispose();
    _dateController.dispose();
    _addressController.dispose();
    _extractedDataController.dispose();

    // Dispose additional controllers
    _additionalControllers.values.forEach((controller) => controller.dispose());

    // Dispose animation controller
    _animationController.dispose();
    _controlsTimer?.cancel();

    super.dispose();
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

  void _toggleFullScreen() {
    setState(() {
      _isFullScreen = !_isFullScreen;
      _resetControlsTimer();
    });
  }

  // Add date picker function
  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Colors.red,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _dateController.text = "${picked.day}/${picked.month}/${picked.year}";
      });
    }
  }

  Future<void> _saveChanges() async {
    if (widget.apiService == null) {
      _showErrorDialog('Error', 'API service not available');
      return;
    }

    if (!mounted) return;

    setState(() {
      _isSaving = true;
    });

    try {
      // Collect all updated metadata
      final Map<String, dynamic> updatedMetadata = Map.from(
        widget.document.metadata,
      );

      // Update standard fields
      updatedMetadata['original_filename'] = _originalFilenameController.text;
      updatedMetadata['title'] = _titleController.text;
      updatedMetadata['author'] = _authorController.text;
      updatedMetadata['description'] = _descriptionController.text;
      updatedMetadata['category'] = _categoryController.text;
      updatedMetadata['tags'] = _tagsController.text;
      updatedMetadata['status'] = _statusController.text;

      // Update extracted data if it was modified
      if (widget.document.metadata.containsKey('extracted_data') &&
          _extractedDataController.text !=
              widget.document.metadata['extracted_data'].toString()) {
        updatedMetadata['extracted_data'] = _extractedDataController.text;
      }

      // Update additional fields
      _additionalControllers.forEach((key, controller) {
        updatedMetadata[key] = controller.text;
      });

      // Send update to backend
      final success = await widget.apiService!.updateDocumentMetadata(
        widget.document.fileId,
        updatedMetadata,
      );

      if (!mounted) return;

      if (success) {
        // Create updated document
        final updatedDocument = widget.document.copyWith(
          updatedMetadata: updatedMetadata,
        );

        // Notify parent about the update
        if (widget.onDocumentUpdated != null) {
          widget.onDocumentUpdated!(updatedDocument);
        }

        setState(() {
          _isEdited = true;
          _isSaving = false;
          // Update verification status if it was changed
          _isVerified = _statusController.text == 'Verified';
          // Show status popup
          _showStatusPopup = true;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Changes saved successfully',
              style: GoogleFonts.poppins(),
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
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
      } else {
        throw Exception('Failed to update document');
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isSaving = false;
      });

      _showErrorDialog('Error Saving Changes', e.toString());
    }
  }

  // Method to show the bottom sheet with all metadata fields
  void _showExtractedDataBottomSheet() {
    if (!mounted) return;

    // Store the data and expand the sheet
    setState(() {
      _currentExtractedDataLabel = 'Edit All Fields';
      _currentExtractedData = _extractedDataController.text;
      _isBottomSheetExpanded = true;
    });

    // Use the imported DocumentBottomSheet class with editable mode
    DocumentBottomSheet.showExtractedDataBottomSheet(
      context,
      label: 'Edit All Fields',
      value: _extractedDataController.text,
      isMetadataVisible: _isMetadataVisible,
      onMetadataVisibilityChanged: (visible) {
        setState(() {
          _isMetadataVisible = visible;
        });
      },
      metadata: widget.document.metadata,
      isEditable: true,
      onValueChanged: (newValue) {
        _extractedDataController.text = newValue;
      },
      onSave: _saveChanges,
    ).then((_) {
      // When the bottom sheet is closed, update the state
      if (mounted) {
        setState(() {
          _isBottomSheetExpanded = false;
        });
      }
    });
  }

  void _verifyDocument() {
    setState(() {
      _statusController.text = 'Verified';
      _isVerified = true;
      _showStatusPopup = true;
    });

    // Save changes after verification
    _saveChanges();

    // Hide status popup after 3 seconds
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _showStatusPopup = false;
        });
      }
    });
  }

  void _showVerificationDialog() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            backgroundColor: Colors.white,
            title: Text(
              'Verify Document',
              style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Are you sure you want to verify this document?',
                  style: GoogleFonts.poppins(),
                ),
                const SizedBox(height: 16),
                Text(
                  'This action will mark the document as verified and update its status.',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Cancel', style: GoogleFonts.poppins()),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  _verifyDocument();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
                child: Text('Verify', style: GoogleFonts.poppins()),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
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
                // title: Text(
                //   'Edit Document',
                //   style: GoogleFonts.poppins(
                //     fontWeight: FontWeight.bold,
                //     color: Colors.white,
                //   ),
                // ),
                actions: [
                  if (_isVerified)
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8.0,
                        vertical: 8.0,
                      ),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.9),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.green),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.verified,
                              color: Colors.white,
                              size: 16,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Verified',
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                color: Colors.white,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  IconButton(
                    icon: const Icon(Icons.fullscreen, color: Colors.white),
                    onPressed: _toggleFullScreen,
                    tooltip: 'Toggle Fullscreen',
                  ),
                  if (_isSaving)
                    Container(
                      margin: const EdgeInsets.all(8),
                      width: 30,
                      height: 30,
                      child: const CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  else
                    IconButton(
                      icon: const Icon(
                        Icons.save_alt_outlined,
                        color: Colors.white,
                      ),
                      onPressed: _saveChanges,
                      tooltip: 'Save Changes',
                    ),
                ],
              ),
      body: Stack(
        children: [
          Column(
            children: [
              // Add a SizedBox with the height of the app bar to prevent content from being hidden
              if (!_isFullScreen)
                SizedBox(
                  height: MediaQuery.of(context).padding.top + kToolbarHeight,
                ),

              // Add this linear progress indicator at the top
              if (_isSaving || _isEdited)
                AnimatedContainer(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      colors: [
                        Colors.transparent,
                        Colors.grey.shade200,
                        Colors.grey.shade200,
                        Colors.transparent,
                      ],
                      stops: const [0.0, 0.05, 0.95, 1.0],
                    ),
                  ),
                  duration: const Duration(milliseconds: 300),
                  height: 4,
                  width: double.infinity,
                  child:
                      _isSaving
                          ? LinearProgressIndicator(
                            backgroundColor: Colors.grey.shade200,
                            color: AppTheme.primaryColor,
                          )
                          : LinearProgressIndicator(
                            value: 1.0, // Completed state
                            backgroundColor: Colors.grey.shade200,
                            color: Colors.green,
                          ),
                ),

              // Top section - PDF Viewer (60% or full screen)
              Expanded(
                flex: _isFullScreen ? 1 : 3,
                child: GestureDetector(
                  onTap: _resetControlsTimer,
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
                                pdfFile: widget.pdfFile,
                                errorMessage: _errorMessage,
                                onRetry: () {
                                  if (mounted) {
                                    setState(() {
                                      _pdfError = false;
                                      _isLoading = true;
                                    });
                                  }
                                },
                              )
                            else
                              PDFView(
                                filePath: widget.pdfFile.path,
                                enableSwipe: true,
                                swipeHorizontal: true,
                                autoSpacing: true,
                                pageFling: true,
                                pageSnap: true,
                                fitPolicy: FitPolicy.BOTH,
                                onRender: (pages) {
                                  if (mounted) {
                                    setState(() {
                                      _totalPages = pages!;
                                      _isLoading = false;
                                    });
                                  }
                                },
                                onError: (error) {
                                  if (mounted) {
                                    setState(() {
                                      _isLoading = false;
                                      _pdfError = true;
                                      _errorMessage = error.toString();
                                    });
                                  }
                                },
                                onPageChanged: (page, total) {
                                  if (mounted) {
                                    setState(() {
                                      _currentPage = page!;
                                    });
                                  }
                                },
                                onViewCreated: (controller) {
                                  _pdfViewController = controller;
                                },
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
                                    'Edit Document',
                                    style: GoogleFonts.poppins(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Row(
                                    children: [
                                      if (_isVerified)
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 4,
                                          ),
                                          margin: const EdgeInsets.only(
                                            right: 8,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.green.withOpacity(
                                              0.2,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                            border: Border.all(
                                              color: Colors.green,
                                            ),
                                          ),
                                          child: Row(
                                            children: [
                                              const Icon(
                                                Icons.verified,
                                                color: Colors.white,
                                                size: 16,
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                'Verified',
                                                style: GoogleFonts.poppins(
                                                  fontSize: 12,
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            ],
                                          ),
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
                    ],
                  ),
                ),
              ),

              // Bottom section - Document Details (40%) - Only showing key fields
              if (!_isFullScreen)
                Expanded(
                  flex: 2,
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
                            // Container(
                            //   height: 42,
                            //   width: 42,
                            //   decoration: BoxDecoration(
                            //     color: Colors.red,
                            //     borderRadius: BorderRadius.circular(50),
                            //     boxShadow: [
                            //       BoxShadow(
                            //         color: Colors.black.withOpacity(0.05),
                            //         blurRadius: 5,
                            //         spreadRadius: 1,
                            //       ),
                            //     ],
                            //   ),
                            //   child: IconButton(
                            //     color: Colors.white,
                            //     icon: const Icon(
                            //       Icons.arrow_back_ios_new_rounded,
                            //     ),
                            //     onPressed: () {
                            //       Navigator.pop(context);
                            //     },
                            //   ),
                            // ),
                            Text(
                              'Update Document Details',
                              style: GoogleFonts.poppins(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                            Row(
                              children: [
                                if (_isEdited)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.green.shade100,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.check_circle,
                                          color: Colors.green.shade700,
                                          size: 16,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          'Saved',
                                          style: TextStyle(
                                            color: Colors.green.shade700,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
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
                              children: [
                                // Only show the key fields in the main view
                                _buildEditableField(
                                  'Purchase Order',
                                  _purchaseOrderController,
                                ),
                                _buildEditableField(
                                  'Contact',
                                  _contactController,
                                ),
                                _buildEditableField(
                                  'Date',
                                  _dateController,
                                  isDateField: true,
                                ),
                                _buildEditableField(
                                  'Address',
                                  _addressController,
                                ),

                                // Extracted data with "See more" button
                                Container(
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
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Padding(
                                        padding: const EdgeInsets.all(16),
                                        child: Text(
                                          'Extracted Data',
                                          style: GoogleFonts.poppins(
                                            color: AppTheme.primaryColor,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 16,
                                        ),
                                        child: Text(
                                          _extractedDataController.text.isEmpty
                                              ? 'No extracted data available'
                                              : _extractedDataController.text,
                                          maxLines: 3,
                                          overflow: TextOverflow.ellipsis,
                                          style: GoogleFonts.poppins(),
                                        ),
                                      ),
                                      if (_extractedDataController.text.length >
                                          10)
                                        TextButton(
                                          onPressed:
                                              _showExtractedDataBottomSheet,
                                          child: Text(
                                            'See more',
                                            style: GoogleFonts.poppins(
                                              color: AppTheme.primaryColor,
                                            ),
                                          ),
                                          style: TextButton.styleFrom(
                                            padding: const EdgeInsets.only(
                                              left: 16,
                                              bottom: 16,
                                              top: 8,
                                            ),
                                            minimumSize: const Size(50, 20),
                                            tapTargetSize:
                                                MaterialTapTargetSize
                                                    .shrinkWrap,
                                            alignment: Alignment.centerLeft,
                                          ),
                                        )
                                      else
                                        const SizedBox(height: 16),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),

          // Status popup that slides up from bottom
          if (_showStatusPopup)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 1),
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
                        _isVerified
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
                        _isVerified ? Icons.verified : Icons.pending_actions,
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
                              'Status: ${_statusController.text}',
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                fontSize: 16,
                              ),
                            ),
                            Text(
                              _isVerified
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

          // Verify button as floating action button for non-verified documents
          if (!_isVerified && !_isFullScreen)
            Positioned(
              bottom: 16,
              right: 16,
              child: FloatingActionButton.extended(
                onPressed: _showVerificationDialog,
                backgroundColor: Colors.green,
                icon: const Icon(Icons.verified_outlined, color: Colors.white),
                label: Text(
                  'Verify',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
        ],
      ),
      floatingActionButton:
          _isFullScreen
              ? FloatingActionButton(
                onPressed: _saveChanges,
                backgroundColor: AppTheme.primaryColor,
                child:
                    _isSaving
                        ? const CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        )
                        : const Icon(Icons.save, color: Colors.white),
              )
              : null,
    );
  }

  Widget _buildEditableField(
    String label,
    TextEditingController controller, {
    int maxLines = 1,
    bool readOnly = false,
    bool isDateField = false,
  }) {
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
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        readOnly: readOnly || isDateField, // Make date field read-only
        onTap: isDateField ? () => _selectDate(context) : null,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: GoogleFonts.poppins(
            color: AppTheme.primaryColor,
            fontWeight: FontWeight.bold,
          ),
          floatingLabelBehavior: FloatingLabelBehavior.always,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
          border: InputBorder.none,
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: AppTheme.primaryColor, width: 2),
          ),
          // Add calendar icon for date fields
          suffixIcon:
              isDateField
                  ? Padding(
                    padding: const EdgeInsets.all(
                      12,
                    ), // Adjust padding as needed
                    child: Image.asset(
                      "lib/assets/icons/calendar.png", // Replace with your actual PNG path
                      width: 24, // Adjust the icon size
                      height: 24,
                    ),
                  )
                  : null,
        ),
        style: GoogleFonts.poppins(),
      ),
    );
  }
}
