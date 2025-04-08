import 'package:doxie_dummy_pdf/models/pdf_document.dart';
import 'package:doxie_dummy_pdf/services/api_service.dart';
import 'package:doxie_dummy_pdf/theme/app_theme.dart';
import 'package:doxie_dummy_pdf/screens/dawer/app_dawer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
// Import skeletonizer with a prefix to avoid conflicts
import 'package:skeletonizer/skeletonizer.dart' as skeleton;

import '../services/websocket_service.dart';
import 'pdf_viewer_screen.dart';

class HomeScreen extends StatefulWidget {
  final ApiService apiService;
  final WebSocketService websocketService;

  const HomeScreen({
    Key? key,
    required this.apiService,
    required this.websocketService,
  }) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  late Future<List<PdfDocument>> _documentsFuture;
  List<PdfDocument>? _documents;
  List<PdfDocument>? _filteredDocuments;
  bool _isLoading = false;
  String _searchQuery = '';
  TextEditingController _searchController = TextEditingController();
  late TabController _tabController;
  bool _showStatusPopup = false;
  String _statusMessage = '';
  bool _isStatusSuccess = true;

  // Track document status counts
  int _totalDocuments = 0;
  int _verifiedDocuments = 0;
  int _pendingDocuments = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_handleTabChange);
    _loadDocuments();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _tabController.removeListener(_handleTabChange);
    _tabController.dispose();
    super.dispose();
  }

  void _handleTabChange() {
    if (_tabController.indexIsChanging) {
      setState(() {
        // Reset search when changing tabs
        if (_searchQuery.isNotEmpty) {
          _searchController.clear();
          _searchQuery = '';
          _filteredDocuments = _documents;
        }
      });
    }
  }

  void _loadDocuments() {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
    });

    _documentsFuture = widget.apiService.getAllPdfDocuments();
    _documentsFuture
        .then((docs) {
          if (mounted) {
            setState(() {
              _documents = docs;
              _filteredDocuments = docs;
              _isLoading = false;

              // Calculate document status counts
              _calculateDocumentCounts(docs);
            });

            // Show status popup
            _showStatusPopupMessage('Documents loaded successfully', true);
          }
        })
        .catchError((error) {
          if (mounted) {
            setState(() {
              _isLoading = false;
            });
            _showErrorDialog('Error Loading Documents', error.toString());

            // Show status popup for error
            _showStatusPopupMessage('Failed to load documents', false);
          }
        });
  }

  void _calculateDocumentCounts(List<PdfDocument> documents) {
    _totalDocuments = documents.length;
    _verifiedDocuments =
        documents
            .where(
              (doc) =>
                  doc.metadata.containsKey('status') &&
                  doc.metadata['status'] == 'Verified',
            )
            .length;
    _pendingDocuments = _totalDocuments - _verifiedDocuments;
  }

  void _showStatusPopupMessage(String message, bool isSuccess) {
    setState(() {
      _statusMessage = message;
      _isStatusSuccess = isSuccess;
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

  void _updateDocument(PdfDocument updatedDocument) {
    if (_documents != null && mounted) {
      setState(() {
        final index = _documents!.indexWhere(
          (doc) => doc.fileId == updatedDocument.fileId,
        );
        if (index != -1) {
          _documents![index] = updatedDocument;

          // Update filtered documents if search is active
          if (_searchQuery.isNotEmpty && _filteredDocuments != null) {
            final filteredIndex = _filteredDocuments!.indexWhere(
              (doc) => doc.fileId == updatedDocument.fileId,
            );
            if (filteredIndex != -1) {
              _filteredDocuments![filteredIndex] = updatedDocument;
            }
          }

          // Recalculate document counts
          _calculateDocumentCounts(_documents!);
        }
      });

      // Show status popup for document update
      _showStatusPopupMessage('Document updated successfully', true);
    }
  }

  void _clearSearch() {
    setState(() {
      _searchQuery = '';
      _searchController.clear();
      _filteredDocuments = _documents;
    });
  }

  void _performSearch(String query) {
    if (!mounted || _documents == null) return;

    setState(() {
      _searchQuery = query;
      if (query.isEmpty) {
        _filteredDocuments = _documents;
      } else {
        _filteredDocuments =
            _documents!.where((doc) {
              final title = doc.originalFilename.toLowerCase();
              final id = doc.fileId.toLowerCase();
              final searchLower = query.toLowerCase();

              return title.contains(searchLower) || id.contains(searchLower);
            }).toList();
      }
    });
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

  Future<void> _openPdfDocument(
    PdfDocument document,
    List<PdfDocument> documents,
    int index,
  ) async {
    if (!mounted) return;

    try {
      setState(() {
        _isLoading = true;
      });

      // Show loading indicator
      _showStatusPopupMessage('Downloading PDF...', true);

      debugPrint(
        "Opening document: ${document.originalFilename} with URL: ${document.pdfUrl}",
      );

      // Validate the PDF URL
      if (document.pdfUrl.isEmpty) {
        throw Exception('PDF URL is empty');
      }

      final pdfFile = await widget.apiService.downloadPdf(document.pdfUrl);

      if (!mounted) return;

      // Verify the PDF file
      if (!await pdfFile.exists()) {
        throw Exception('Downloaded PDF file does not exist');
      }

      final fileSize = await pdfFile.length();
      if (fileSize == 0) {
        throw Exception('Downloaded PDF file is empty');
      }

      debugPrint(
        "PDF file downloaded successfully: ${pdfFile.path} (${fileSize} bytes)",
      );

      setState(() {
        _isLoading = false;
      });

      // Navigate to PDF viewer
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder:
              (context) => PdfViewerScreen(
                pdfFile: pdfFile,
                document: document,
                allDocuments: documents,
                currentIndex: index,
                apiService: widget.apiService,
                websocketService: widget.websocketService,
                onDocumentUpdated: _updateDocument,
              ),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      // Show error dialog
      _showErrorDialog('Failed to load PDF', e.toString());

      // Show status popup for error
      _showStatusPopupMessage('Failed to load PDF: ${e.toString()}', false);
    }
  }

  void _verifyDocument(PdfDocument document) {
    // Show loading indicator
    _showStatusPopupMessage('Verifying document...', true);

    // In a real app, you would call an API to update the document status
    // For now, we'll simulate it with a delay
    Future.delayed(const Duration(seconds: 2), () {
      if (!mounted) return;

      // Update the document status directly
      document.metadata['status'] = 'Verified';
      final updatedDocument = document;

      // Update the document in our state
      _updateDocument(updatedDocument);

      // Show success message
      _showStatusPopupMessage('Document verified successfully', true);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      drawer: AppDrawer(
        apiService: widget.apiService,
        documents: _documents,
        onDocumentUpdated: _updateDocument,
      ),
      appBar: AppBar(
        centerTitle: true,
        title: Text(
          'DOXIE',
          style: GoogleFonts.inter(
            textStyle: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 18,
            ),
          ),
        ),
        backgroundColor: AppTheme.primaryColor,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          GestureDetector(
            onTap: _loadDocuments, // Function to call on press
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
              ), // Adjust spacing
              child: Image.asset(
                color: Colors.white,
                "lib/assets/icons/refresh.png", // Replace with your actual PNG path
                width: 24,
                height: 24,
              ),
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          Column(
            children: [
              // Document status summary
              _buildDocumentStatusSummary(),

              // Search Bar
              DocumentSearchBar(
                controller: _searchController,
                onChanged: _performSearch,
                onClear: _clearSearch,
                showClearButton: _searchQuery.isNotEmpty,
              ),
              // Tab Bar
              CustomTabBar(
                controller: _tabController,
                tabs: const ['Inbound', 'Outbound'],
                onTap: (index) {
                  // Handle tab tap if needed
                },
              ),
              // Document List
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    // Inbound Tab - Show all documents
                    _buildDocumentsList(isInbound: true),

                    // Outbound Tab - Show only verified documents
                    _buildDocumentsList(isInbound: false),
                  ],
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
              child: Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color:
                      _isStatusSuccess
                          ? Colors.green.withOpacity(0.9)
                          : Colors.red.withOpacity(0.9),
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
                      _isStatusSuccess ? Icons.check_circle : Icons.error,
                      color: Colors.white,
                      size: 28,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        _statusMessage,
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w500,
                          color: Colors.white,
                          fontSize: 14,
                        ),
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
            ).animate().slideY(
              begin: 1,
              end: 0,
              duration: 300.ms,
              curve: Curves.easeOutCubic,
            ),
        ],
      ),
    );
  }

  Widget _buildDocumentStatusSummary() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 6,
            spreadRadius: 0,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          // Verified documents
          Expanded(
            child: GestureDetector(
              onTap: () {
                // Switch to Outbound tab
                _tabController.animateTo(1);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  vertical: 8,
                  horizontal: 12,
                ),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green.withOpacity(0.3)),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.verified,
                          color: Colors.green,
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          "Verified",
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: Colors.green,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _verifiedDocuments.toString(),
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade800,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Pending documents
          Expanded(
            child: GestureDetector(
              onTap: () {
                // Switch to Inbound tab
                _tabController.animateTo(0);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  vertical: 8,
                  horizontal: 12,
                ),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.withOpacity(0.3)),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.pending, color: Colors.blue, size: 16),
                        const SizedBox(width: 4),
                        Text(
                          "Pending",
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: Colors.blue,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _pendingDocuments.toString(),
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade800,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Total documents
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.description,
                        color: Colors.grey.shade700,
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        "Total",
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _totalDocuments.toString(),
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade800,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentsList({required bool isInbound}) {
    if (_isLoading) {
      // Return skeletonized version of the list
      return _buildSkeletonList(isInbound: isInbound);
    }

    return FutureBuilder<List<PdfDocument>>(
      future: _documentsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting && _isLoading) {
          // Return skeletonized version while loading
          return _buildSkeletonList(isInbound: isInbound);
        } else if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.error_outline,
                  size: 60,
                  color: AppTheme.primaryColor,
                ),
                const SizedBox(height: 16),
                Text(
                  'Error loading documents',
                  style: GoogleFonts.inter(
                    textStyle: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 18,
                      color: Color(0xFF2D3748),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${snapshot.error}',
                  style: GoogleFonts.inter(
                    textStyle: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF718096),
                    ),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _loadDocuments,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        final documents = _filteredDocuments ?? snapshot.data ?? [];

        // Filter documents based on tab
        final filteredByType =
            isInbound
                ? documents // Show all documents in Inbound tab
                : documents
                    .where(
                      (doc) =>
                          doc.metadata.containsKey('status') &&
                          doc.metadata['status'] == 'Verified',
                    )
                    .toList(); // Show only verified documents in Outbound tab

        if (filteredByType.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  isInbound ? Icons.download_rounded : Icons.upload_rounded,
                  size: 64,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                Text(
                  isInbound
                      ? 'No documents available'
                      : 'No verified documents available',
                  style: GoogleFonts.inter(
                    textStyle: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey[600],
                    ),
                  ),
                ),
                if (_searchQuery.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      'Try a different search term',
                      style: GoogleFonts.inter(
                        textStyle: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[500],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () async {
            _loadDocuments();
          },
          color: AppTheme.primaryColor,
          child: ListView.builder(
            itemCount: filteredByType.length,
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemBuilder: (context, index) {
              final document = filteredByType[index];
              return EnhancedPdfListItem(
                    document: document,
                    onTap:
                        () => _openPdfDocument(document, filteredByType, index),
                    onVerify:
                        document.metadata.containsKey('status') &&
                                document.metadata['status'] == 'Verified'
                            ? null
                            : () => _verifyDocument(document),
                  )
                  .animate()
                  .fade(duration: 300.ms, delay: 50.ms * index)
                  .slideY(begin: 0.1, end: 0);
            },
          ),
        );
      },
    );
  }

  Widget _buildSkeletonList({required bool isInbound}) {
    return skeleton.Skeletonizer(
      effect: const skeleton.ShimmerEffect(),
      enabled: true,
      child: ListView.builder(
        itemCount: 5,
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemBuilder: (context, index) {
          // Instead of creating actual PdfDocument objects,
          // create a simplified version of the list item directly
          final isVerified = isInbound ? (index % 2 != 0) : true;

          return Container(
            margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      // PDF Icon with enhanced styling
                      Container(
                        width: 54,
                        height: 64,
                        decoration: BoxDecoration(
                          color:
                              isVerified
                                  ? const Color.fromARGB(255, 227, 236, 228)
                                  : const Color.fromARGB(255, 223, 242, 251),
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.red.withOpacity(0.1),
                              blurRadius: 4,
                              spreadRadius: 0,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Image.asset(
                            isVerified
                                ? "lib/assets/icons/VPDF_icons.png"
                                : "lib/assets/icons/!VPDF_icons.png",
                            width: 50,
                            height: 50,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),

                      // Document Details
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    "Document ${index + 1}.pdf",
                                    style: GoogleFonts.inter(
                                      textStyle: const TextStyle(
                                        fontWeight: FontWeight.w500,
                                        fontSize: 14,
                                        color: Color(0xFF2D3748),
                                      ),
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            const Divider(
                              height: 1,
                              thickness: 1,
                              color: Color(0xFFEDF2F7),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                // Document metadata (ID and Date)
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'ID: doc-$index',
                                      style: GoogleFonts.inter(
                                        textStyle: const TextStyle(
                                          fontSize: 12,
                                          color: Color(0xFF718096),
                                          fontWeight: FontWeight.w400,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'Date: 2023-05-${10 + index}',
                                      style: GoogleFonts.inter(
                                        textStyle: const TextStyle(
                                          fontSize: 12,
                                          color: Color(0xFF718096),
                                          fontWeight: FontWeight.w400,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                if (isVerified)
                                  Container(
                                    margin: const EdgeInsets.only(left: 8),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.green.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(4),
                                      border: Border.all(
                                        color: Colors.green.withOpacity(0.5),
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(
                                          Icons.verified,
                                          color: Colors.green,
                                          size: 12,
                                        ),
                                        const SizedBox(width: 2),
                                        Text(
                                          'Verified',
                                          style: GoogleFonts.inter(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w500,
                                            color: Colors.green,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),

                                // Status indicator for pending (moved to the right)
                                if (!isVerified)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.blue.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(4),
                                      border: Border.all(
                                        color: Colors.blue.withOpacity(0.5),
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(
                                          Icons.pending,
                                          color: Colors.blue,
                                          size: 12,
                                        ),
                                        const SizedBox(width: 2),
                                        Text(
                                          'Pending',
                                          style: GoogleFonts.inter(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w500,
                                            color: Colors.blue,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class DocumentSearchBar extends StatelessWidget {
  final TextEditingController controller;
  final Function(String) onChanged;
  final VoidCallback onClear;
  final bool showClearButton;

  const DocumentSearchBar({
    Key? key,
    required this.controller,
    required this.onChanged,
    required this.onClear,
    this.showClearButton = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 50,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 6,
            spreadRadius: 0,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(color: const Color(0xFFEEF2F6), width: 1),
      ),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        style: GoogleFonts.inter(
          textStyle: const TextStyle(
            fontSize: 14,
            color: Color(0xFF334155),
            fontWeight: FontWeight.w400,
          ),
        ),
        decoration: InputDecoration(
          hintText: 'Search documents...',
          hintStyle: GoogleFonts.inter(
            textStyle: const TextStyle(
              fontSize: 14,
              color: Color(0xFF94A3B8),
              fontWeight: FontWeight.w400,
            ),
          ),
          prefixIcon: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Icon(Icons.search, color: const Color(0xFF94A3B8), size: 20),
          ),
          suffixIcon:
              showClearButton
                  ? Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: IconButton(
                      icon: const Icon(Icons.clear, size: 18),
                      onPressed: onClear,
                      color: const Color(0xFF94A3B8),
                      splashRadius: 20,
                    ),
                  )
                  : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            vertical: 15,
            horizontal: 16,
          ),
          isDense: true,
        ),
      ),
    );
  }
}

class CustomTabBar extends StatelessWidget {
  final TabController controller;
  final List<String> tabs;
  final Function(int) onTap;

  const CustomTabBar({
    Key? key,
    required this.controller,
    required this.tabs,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 6,
            spreadRadius: 0,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(color: const Color(0xFFEEF2F6), width: 1),
      ),
      padding: const EdgeInsets.all(2),
      child: TabBar(
        controller: controller,
        onTap: onTap,
        indicator: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 3,
              spreadRadius: 0,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        labelColor: const Color(0xFF334155),
        unselectedLabelColor: const Color(0xFF64748B),
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        indicatorPadding: const EdgeInsets.symmetric(
          vertical: 2,
          horizontal: 2,
        ),
        labelPadding: EdgeInsets.zero,
        padding: EdgeInsets.zero,
        labelStyle: GoogleFonts.inter(
          textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        ),
        unselectedLabelStyle: GoogleFonts.inter(
          textStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
        ),
        tabs:
            tabs
                .map(
                  (tab) => Tab(
                    child: Container(
                      alignment: Alignment.center,
                      child: Text(tab),
                    ),
                  ),
                )
                .toList(),
      ),
    );
  }
}

class EnhancedPdfListItem extends StatefulWidget {
  final PdfDocument document;
  final VoidCallback onTap;
  final VoidCallback? onVerify;

  const EnhancedPdfListItem({
    Key? key,
    required this.document,
    required this.onTap,
    this.onVerify,
  }) : super(key: key);

  @override
  State<EnhancedPdfListItem> createState() => _EnhancedPdfListItemState();
}

class _EnhancedPdfListItemState extends State<EnhancedPdfListItem>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.02,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _showOptionsMenu() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder:
          (context) => Container(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                ListTile(
                  leading: const Icon(
                    Icons.visibility,
                    color: AppTheme.primaryColor,
                  ),
                  title: Text('View Document', style: GoogleFonts.poppins()),
                  onTap: () {
                    Navigator.pop(context);
                    widget.onTap();
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.edit, color: Colors.blue),
                  title: Text('Edit Details', style: GoogleFonts.poppins()),
                  onTap: () {
                    Navigator.pop(context);
                    // Add edit functionality
                  },
                ),
                if (widget.onVerify != null)
                  ListTile(
                    leading: const Icon(Icons.verified, color: Colors.green),
                    title: Text(
                      'Verify Document',
                      style: GoogleFonts.poppins(),
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      widget.onVerify!();
                    },
                  ),
                ListTile(
                  leading: const Icon(Icons.share, color: Colors.purple),
                  title: Text('Share', style: GoogleFonts.poppins()),
                  onTap: () {
                    Navigator.pop(context);
                    // Add share functionality
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.delete, color: Colors.red),
                  title: Text('Delete', style: GoogleFonts.poppins()),
                  onTap: () {
                    Navigator.pop(context);
                    // Add delete functionality
                  },
                ),
              ],
            ),
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isVerified =
        widget.document.metadata.containsKey('status') &&
        widget.document.metadata['status'] == 'Verified';

    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(scale: _scaleAnimation.value, child: child);
      },
      child: GestureDetector(
        onTap: () {
          _controller.forward().then((_) => _controller.reverse());
          widget.onTap();
        },
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
            // border: Border.all(
            //   color:
            //       isVerified
            //           ? Colors.green.withOpacity(0.3)
            //           : Colors.transparent,
            //   width: isVerified ? 1 : 0,
            // ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    // PDF Icon with enhanced styling
                    if (isVerified)
                      Container(
                        width: 54,
                        height: 64,
                        decoration: BoxDecoration(
                          color: const Color.fromARGB(255, 227, 236, 228),
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.red.withOpacity(0.1),
                              blurRadius: 4,
                              spreadRadius: 0,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Image.asset(
                            "lib/assets/icons/VPDF_icons.png", // Replace with your actual PNG path
                            width: 50, // Adjust size as needed
                            height: 50,
                          ),
                        ),
                      ),
                    if (!isVerified)
                      Container(
                        width: 54,
                        height: 64,
                        decoration: BoxDecoration(
                          color: const Color.fromARGB(255, 223, 242, 251),
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.red.withOpacity(0.1),
                              blurRadius: 4,
                              spreadRadius: 0,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Image.asset(
                            "lib/assets/icons/!VPDF_icons.png", // Replace with your actual PNG path
                            width: 50, // Adjust size as needed
                            height: 50,
                          ),
                        ),
                      ),
                    const SizedBox(width: 16),

                    // Document Details
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  widget.document.originalFilename,
                                  style: GoogleFonts.inter(
                                    textStyle: const TextStyle(
                                      fontWeight: FontWeight.w500,
                                      fontSize: 14,
                                      color: Color(0xFF2D3748),
                                    ),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          const Divider(
                            height: 1,
                            thickness: 1,
                            color: Color(0xFFEDF2F7),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              // Document metadata (ID and Date)
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'ID: ${widget.document.fileId}',
                                    style: GoogleFonts.inter(
                                      textStyle: const TextStyle(
                                        fontSize: 12,
                                        color: Color(0xFF718096),
                                        fontWeight: FontWeight.w400,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Date: ${widget.document.uploadDate}',
                                    style: GoogleFonts.inter(
                                      textStyle: const TextStyle(
                                        fontSize: 12,
                                        color: Color(0xFF718096),
                                        fontWeight: FontWeight.w400,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              if (isVerified)
                                Container(
                                  margin: const EdgeInsets.only(left: 8),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.green.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(4),
                                    border: Border.all(
                                      color: Colors.green.withOpacity(0.5),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(
                                        Icons.verified,
                                        color: Colors.green,
                                        size: 12,
                                      ),
                                      const SizedBox(width: 2),
                                      Text(
                                        'Verified',
                                        style: GoogleFonts.inter(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w500,
                                          color: Colors.green,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                              // Status indicator for pending (moved to the right)
                              if (!isVerified)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.blue.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(4),
                                    border: Border.all(
                                      color: Colors.blue.withOpacity(0.5),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(
                                        Icons.pending,
                                        color: Colors.blue,
                                        size: 12,
                                      ),
                                      const SizedBox(width: 2),
                                      Text(
                                        'Pending',
                                        style: GoogleFonts.inter(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w500,
                                          color: Colors.blue,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
