import 'package:doxie_dummy_pdf/models/pdf_document.dart';
import 'package:doxie_dummy_pdf/services/api_service.dart';
import 'package:doxie_dummy_pdf/theme/app_theme.dart';
import 'package:doxie_dummy_pdf/screens/dawer/app_dawer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';

import '../services/websocket_service.dart';
import 'pdf_viewer_screen.dart';
import '../widgets/pdf_list_item.dart';

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
            });
          }
        })
        .catchError((error) {
          if (mounted) {
            setState(() {
              _isLoading = false;
            });
            _showErrorDialog('Error Loading Documents', error.toString());
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
        }
      });
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Downloading PDF...'),
          duration: Duration(seconds: 2),
        ),
      );

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
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      drawer: AppDrawer(),
      appBar: AppBar(
        centerTitle: true,
        title: Text(
          'DOXIE',
          style: GoogleFonts.inter(
            textStyle: TextStyle(
              color: Colors.red,
              fontWeight: FontWeight.w600,
              fontSize: 18,
            ),
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppTheme.primaryColor),
        actions: [
          IconButton(
            icon: const Icon(Icons.remove_from_queue_sharp),
            onPressed: _loadDocuments,
            color: AppTheme.primaryColor,
          ),
        ],
      ),
      body: Column(
        children: [
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
                // Inbound Tab
                _buildDocumentsList(isInbound: true),

                // Outbound Tab
                _buildDocumentsList(isInbound: false),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentsList({required bool isInbound}) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppTheme.primaryColor),
      );
    }

    return FutureBuilder<List<PdfDocument>>(
      future: _documentsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting && _isLoading) {
          return const Center(
            child: CircularProgressIndicator(color: AppTheme.primaryColor),
          );
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

        // Filter documents based on tab (inbound/outbound)
        final filteredByType =
            isInbound
                ? documents
                    .where(
                      (doc) =>
                          doc.getMetadataField('type', 'inbound') == 'inbound',
                    )
                    .toList()
                : documents
                    .where(
                      (doc) =>
                          doc.getMetadataField('type', 'outbound') ==
                          'outbound',
                    )
                    .toList();

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
                      ? 'No inbound documents available'
                      : 'No outbound documents available',
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

        return ListView.builder(
          itemCount: filteredByType.length,
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemBuilder: (context, index) {
            final document = filteredByType[index];
            return PdfListItem(
                  document: document,
                  onTap:
                      () => _openPdfDocument(document, filteredByType, index),
                )
                .animate()
                .fade(duration: 300.ms, delay: 50.ms * index)
                .slideY(begin: 0.1, end: 0);
          },
        );
      },
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
