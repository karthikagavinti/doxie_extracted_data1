import 'dart:io';
import 'package:doxie_dummy_pdf/widgets/pdf_debug_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
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

class _PdfEditScreenState extends State<PdfEditScreen> {
  int _totalPages = 0;
  int _currentPage = 0;
  bool _isLoading = true;
  bool _isEdited = false;
  bool _isSaving = false;
  bool _pdfError = false;
  String _errorMessage = '';

  // Controllers for editable fields
  late TextEditingController _originalFilenameController;
  late TextEditingController _titleController;
  late TextEditingController _authorController;
  late TextEditingController _descriptionController;
  late TextEditingController _categoryController;
  late TextEditingController _tagsController;
  late TextEditingController _statusController;

  // Map to store additional metadata controllers
  final Map<String, TextEditingController> _additionalControllers = {};

  @override
  void initState() {
    super.initState();
    _initControllers();
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
              ].contains(entry.key),
        )
        .forEach((entry) {
          _additionalControllers[entry.key] = TextEditingController(
            text: entry.value.toString(),
          );
        });
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

    // Dispose additional controllers
    _additionalControllers.values.forEach((controller) => controller.dispose());

    super.dispose();
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
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Changes saved successfully'),
            backgroundColor: Colors.green,
          ),
        );
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
        title: const Text(
          'Edit Document',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        actions: [
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
              icon: const Icon(Icons.save, color: Colors.white),
              onPressed: _saveChanges,
              tooltip: 'Save Changes',
            ),
        ],
      ),
      body: Column(
        children: [
          // Top section - PDF Viewer (60%)
          Expanded(
            flex: 3,
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
                ],
              ),
            ),
          ),

          // Bottom section - Editable Document Details (40%)
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
                      const Text(
                        'Edit Document Details',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
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
                  const SizedBox(height: 8),
                  Expanded(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildEditableField(
                            'Original Filename',
                            _originalFilenameController,
                          ),
                          _buildEditableField('Title', _titleController),
                          _buildEditableField('Author', _authorController),
                          _buildEditableField(
                            'Description',
                            _descriptionController,
                            maxLines: 3,
                          ),
                          _buildEditableField('Category', _categoryController),
                          _buildEditableField('Tags', _tagsController),
                          _buildEditableField('Status', _statusController),

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
                          ..._additionalControllers.entries
                              .map(
                                (entry) => _buildEditableField(
                                  entry.key.replaceFirst(
                                    entry.key[0],
                                    entry.key[0].toUpperCase(),
                                  ),
                                  entry.value,
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
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _saveChanges,
        backgroundColor: AppTheme.primaryColor,
        child:
            _isSaving
                ? const CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                )
                : const Icon(Icons.save, color: Colors.white),
      ),
    );
  }

  Widget _buildEditableField(
    String label,
    TextEditingController controller, {
    int maxLines = 1,
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
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(
            color: AppTheme.primaryColor,
            fontWeight: FontWeight.bold,
          ),
          floatingLabelBehavior: FloatingLabelBehavior.always,
          contentPadding: const EdgeInsets.all(16),
          border: InputBorder.none,
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: AppTheme.primaryColor, width: 2),
          ),
        ),
      ),
    );
  }
}
