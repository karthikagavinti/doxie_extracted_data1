import 'package:doxie_dummy_pdf/models/pdf_document.dart';
import 'package:doxie_dummy_pdf/services/api_service.dart';
import 'package:doxie_dummy_pdf/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';

class VerificationQueueScreen extends StatefulWidget {
  final ApiService? apiService;
  final List<PdfDocument>? documents;
  final Function(PdfDocument)? onDocumentUpdated;

  const VerificationQueueScreen({
    Key? key,
    this.apiService,
    this.documents,
    this.onDocumentUpdated,
  }) : super(key: key);

  @override
  State<VerificationQueueScreen> createState() =>
      _VerificationQueueScreenState();
}

class _VerificationQueueScreenState extends State<VerificationQueueScreen>
    with SingleTickerProviderStateMixin {
  List<PdfDocument> _documents = [];
  List<PdfDocument> _filteredDocuments = [];
  bool _isLoading = true;
  String _searchQuery = '';
  String _currentFilter = 'all';
  String _currentView = 'all'; // 'all', 'pending', 'verified'

  // Animation controllers
  late AnimationController _animationController;

  // Document counts for statistics
  int _totalDocuments = 0;
  int _verifiedDocuments = 0;
  int _pendingDocuments = 0;

  // Selected document for details
  PdfDocument? _selectedDocument;
  bool _showDetails = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _loadDocuments();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _loadDocuments() {
    setState(() {
      _isLoading = true;
    });

    if (widget.documents != null) {
      // Use documents passed from parent
      setState(() {
        _documents = widget.documents!;
        _calculateDocumentCounts(_documents);
        _filterDocuments();
        _isLoading = false;
      });
    } else if (widget.apiService != null) {
      // Fetch documents from API
      widget.apiService!
          .getAllPdfDocuments()
          .then((docs) {
            if (mounted) {
              setState(() {
                _documents = docs;
                _calculateDocumentCounts(_documents);
                _filterDocuments();
                _isLoading = false;
              });
            }
          })
          .catchError((error) {
            if (mounted) {
              setState(() {
                _isLoading = false;
              });
              _showErrorSnackBar('Failed to load documents: $error');
            }
          });
    } else {
      // Use empty list if no documents or API service
      setState(() {
        _documents = [];
        _filteredDocuments = [];
        _totalDocuments = 0;
        _verifiedDocuments = 0;
        _pendingDocuments = 0;
        _isLoading = false;
      });
    }
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

  void _filterDocuments() {
    if (_documents.isEmpty) {
      setState(() {
        _filteredDocuments = [];
      });
      return;
    }

    // First filter by view type
    var filtered = _documents;

    if (_currentView == 'pending') {
      filtered =
          filtered
              .where(
                (doc) =>
                    !doc.metadata.containsKey('status') ||
                    doc.metadata['status'] != 'Verified',
              )
              .toList();
    } else if (_currentView == 'verified') {
      filtered =
          filtered
              .where(
                (doc) =>
                    doc.metadata.containsKey('status') &&
                    doc.metadata['status'] == 'Verified',
              )
              .toList();
    }

    // Then apply search filter if any
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      filtered =
          filtered.where((doc) {
            final filename = doc.originalFilename.toLowerCase();
            final id = doc.fileId.toLowerCase();
            return filename.contains(query) || id.contains(query);
          }).toList();
    }

    // Then apply status filter if not 'all'
    if (_currentFilter != 'all') {
      filtered =
          filtered.where((doc) {
            if (!doc.metadata.containsKey('status')) return false;

            final status = doc.metadata['status'].toString().toLowerCase();
            switch (_currentFilter) {
              case 'pending':
                return status != 'verified';
              case 'verified':
                return status == 'verified';
              default:
                return true;
            }
          }).toList();
    }

    setState(() {
      _filteredDocuments = filtered;
    });

    // Trigger animation
    _animationController.reset();
    _animationController.forward();
  }

  void _performSearch(String query) {
    setState(() {
      _searchQuery = query;
    });
    _filterDocuments();
  }

  void _applyFilter(String filter) {
    setState(() {
      _currentFilter = filter;
    });
    _filterDocuments();
  }

  void _changeView(String view) {
    if (_currentView != view) {
      setState(() {
        _currentView = view;
        _showDetails = false;
        _selectedDocument = null;
      });
      _filterDocuments();
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: GoogleFonts.poppins()),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _selectDocument(PdfDocument document) {
    setState(() {
      _selectedDocument = document;
      _showDetails = true;
    });
  }

  void _closeDetails() {
    setState(() {
      _showDetails = false;
    });

    // Wait for animation to complete before clearing selection
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        setState(() {
          _selectedDocument = null;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          'Document Verification',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.red,
        elevation: 0,
        actions: [
          GestureDetector(
            onTap: _loadDocuments, // Function to call on press
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 8,
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
          // Main content
          Column(
            children: [
              // Document statistics
              _buildDocumentStatistics(),

              // View selector
              _buildViewSelector(),

              // Search bar
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: TextField(
                  onChanged: _performSearch,
                  decoration: InputDecoration(
                    hintText: 'Search documents...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                    filled: true,
                    fillColor: Colors.grey.shade50,
                    hintStyle: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Colors.grey.shade500,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Colors.red, width: 2),
                    ),
                  ),
                ),
              ),

              // Document list
              Expanded(
                child:
                    _isLoading
                        ? const Center(
                          child: CircularProgressIndicator(color: Colors.red),
                        )
                        : AnimatedSwitcher(
                          duration: const Duration(milliseconds: 500),
                          child: _buildDocumentList(),
                        ),
              ),
            ],
          ),

          // Document details overlay
          AnimatedPositioned(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            bottom: 0,
            left: 0,
            right: 0,
            top: _showDetails ? 0 : MediaQuery.of(context).size.height,
            child:
                _selectedDocument != null
                    ? _buildDocumentDetails(_selectedDocument!)
                    : const SizedBox(),
          ),
        ],
      ),
    );
  }

  Widget _buildViewSelector() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        children: [
          _buildViewOption('all', 'All Documents'),
          _buildViewOption('pending', 'Pending'),
          _buildViewOption('verified', 'Verified'),
        ],
      ),
    );
  }

  Widget _buildViewOption(String view, String label) {
    final isSelected = _currentView == view;

    return Expanded(
      child: GestureDetector(
        onTap: () => _changeView(view),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            boxShadow:
                isSelected
                    ? [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 4,
                        spreadRadius: 0,
                        offset: const Offset(0, 1),
                      ),
                    ]
                    : null,
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              color: isSelected ? Colors.red : Colors.grey.shade600,
            ),
          ),
        ),
        // .animate(target: isSelected ? 1 : 0)
        // .scale(begin: 0.95, end: 1.0)
        // .fadeIn(),
      ),
    );
  }

  Widget _buildDocumentStatistics() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            spreadRadius: 0,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Circular progress indicator
              CircularPercentIndicator(
                radius: 35.0,
                lineWidth: 8.0,
                percent:
                    _totalDocuments > 0
                        ? _verifiedDocuments / _totalDocuments
                        : 0.0,
                center: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "${_totalDocuments > 0 ? ((_verifiedDocuments / _totalDocuments) * 100).toStringAsFixed(0) : 0}%",
                      style: GoogleFonts.poppins(
                        textStyle: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                          color: Colors.red,
                        ),
                      ),
                    ),
                    Text(
                      "Verified",
                      style: GoogleFonts.poppins(
                        textStyle: const TextStyle(
                          fontWeight: FontWeight.w500,
                          fontSize: 10,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                  ],
                ),
                progressColor: Colors.red,
                backgroundColor: Colors.grey.shade200,
                circularStrokeCap: CircularStrokeCap.round,
                animation: true,
                animationDuration: 800,
              ),
              const SizedBox(width: 16),

              // Document counts
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Document Status",
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade800,
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Progress bar
                    Container(
                      height: 8,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(4),
                        color: Colors.grey.shade200,
                      ),
                      child: Row(
                        children: [
                          Container(
                            width:
                                (MediaQuery.of(context).size.width -
                                    32 -
                                    32 -
                                    70 -
                                    16) *
                                (_totalDocuments > 0
                                    ? _verifiedDocuments / _totalDocuments
                                    : 0.0),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(4),
                              gradient: const LinearGradient(
                                colors: [Colors.red, Colors.redAccent],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 8),

                    // Status counts
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildStatusCount("Verified", _verifiedDocuments),
                        _buildStatusCount("Pending", _pendingDocuments),
                        _buildStatusCount("Total", _totalDocuments),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    ).animate().fade(duration: 500.ms).slideY(begin: -0.2, end: 0);
  }

  Widget _buildStatusCount(String label, int count) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey.shade600),
        ),
        Text(
          count.toString(),
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color:
                label == "Verified"
                    ? Colors.green
                    : label == "Pending"
                    ? Colors.blue
                    : Colors.grey.shade700,
          ),
        ),
      ],
    );
  }

  Widget _buildDocumentList() {
    if (_filteredDocuments.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.description_outlined, size: 80, color: Colors.grey[300]),
            const SizedBox(height: 24),
            Text(
              _currentView == 'verified'
                  ? 'No verified documents'
                  : _currentView == 'pending'
                  ? 'No pending documents'
                  : _searchQuery.isNotEmpty
                  ? 'No documents found'
                  : 'No documents available',
              style: GoogleFonts.poppins(
                fontSize: 18,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _searchQuery.isNotEmpty
                  ? 'Try a different search term'
                  : 'Documents will appear here once available',
              style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey[500]),
            ),
            // if (_searchQuery.isNotEmpty)
            // Padding(
            //   padding: const EdgeInsets.only(top: 24.0),
            //   child: TextButton.icon(
            //     onPressed: () {
            //       setState(() {
            //         _searchQuery = '';
            //       });
            //       _filterDocuments();
            //     },
            //     icon: const Icon(Icons.clear, color: Colors.red),
            //     label: Text(
            //       'Clear search',
            //       style: GoogleFonts.poppins(color: Colors.red),
            //     ),
            //   ),
            // ),
          ],
        ),
      ).animate().fade(duration: 500.ms);
    }

    return RefreshIndicator(
      onRefresh: () async {
        _loadDocuments();
      },
      color: Colors.red,
      child: ListView.builder(
        key: ValueKey<String>(_currentView),
        itemCount: _filteredDocuments.length,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemBuilder: (context, index) {
          final document = _filteredDocuments[index];
          return _buildDocumentCard(document, index);
        },
      ),
    );
  }

  Widget _buildDocumentCard(PdfDocument document, int index) {
    final bool isVerified =
        document.metadata.containsKey('status') &&
        document.metadata['status'] == 'Verified';

    // Extract key details if available
    String poNumber = '';
    String date = '';
    String contact = '';

    if (document.metadata.containsKey('extracted_data')) {
      final extractedData = document.metadata['extracted_data'].toString();

      // Simple regex extraction (in a real app, you'd use more robust parsing)
      final poRegex = RegExp(
        r'(?:Purchase\s*Order|PO|P\.O\.|Customer\s+PO#)[:.\s#]*([A-Z0-9\-]+)',
        caseSensitive: false,
      );
      final poMatch = poRegex.firstMatch(extractedData);
      if (poMatch != null && poMatch.groupCount >= 1) {
        poNumber = poMatch.group(1)?.trim() ?? '';
      }

      final dateRegex = RegExp(
        r'(?:Date|Order\s*Date)[:\s]*(\d{1,2}[\/\-\.]\d{1,2}[\/\-\.]\d{2,4})',
        caseSensitive: false,
      );
      final dateMatch = dateRegex.firstMatch(extractedData);
      if (dateMatch != null && dateMatch.groupCount >= 1) {
        date = dateMatch.group(1)?.trim() ?? '';
      }

      final contactRegex = RegExp(
        r'(?:Phone|Tel|Telephone|Contact|User)[:\s]*([^,\n\r]+)',
        caseSensitive: false,
      );
      final contactMatch = contactRegex.firstMatch(extractedData);
      if (contactMatch != null && contactMatch.groupCount >= 1) {
        contact = contactMatch.group(1)?.trim() ?? '';
      }
    }

    return Card(
          color: Colors.white,
          margin: const EdgeInsets.only(bottom: 16),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: Colors.grey.shade200),
          ),
          child: InkWell(
            onTap: () => _selectDocument(document),
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // PDF Icon
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: const Color.fromARGB(255, 208, 234, 241),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Center(
                          child: Image.asset(
                            "lib/assets/icons/google-docs.png", // Replace with your actual PNG path
                            width: 24,
                            height: 24,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),

                      // Document details
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    document.originalFilename,
                                    style: GoogleFonts.poppins(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 15,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color:
                                        isVerified
                                            ? Colors.green.withOpacity(0.3)
                                            : Colors.blue.withOpacity(0.3),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color:
                                          isVerified
                                              ? Colors.green
                                              : Colors.blue,
                                    ),
                                  ),
                                  child: Text(
                                    isVerified ? 'Verified' : 'Pending',
                                    style: GoogleFonts.poppins(
                                      fontSize: 12,
                                      color:
                                          isVerified
                                              ? Colors.green
                                              : Colors.blue,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'ID: ${document.fileId}',
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              'Uploaded: ${document.uploadDate}',
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  // Additional details section
                  if (poNumber.isNotEmpty ||
                      date.isNotEmpty ||
                      contact.isNotEmpty)
                    Container(
                      margin: const EdgeInsets.only(top: 12),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Column(
                        children: [
                          if (poNumber.isNotEmpty)
                            _buildDetailRow('PO Number', poNumber),
                          if (date.isNotEmpty) _buildDetailRow('Date', date),
                          if (contact.isNotEmpty)
                            _buildDetailRow('Contact', contact),
                        ],
                      ),
                    ),

                  // View details button
                  // Align(
                  //   alignment: Alignment.centerRight,
                  //   child: TextButton(
                  //     onPressed: () => _selectDocument(document),
                  //     style: TextButton.styleFrom(
                  //       foregroundColor: Colors.red,
                  //       padding: const EdgeInsets.symmetric(
                  //         horizontal: 16,
                  //         vertical: 8,
                  //       ),
                  //     ),
                  //     child: Text(
                  //       'View Details',
                  //       style: GoogleFonts.poppins(
                  //         fontSize: 13,
                  //         fontWeight: FontWeight.w500,
                  //       ),
                  //     ),
                  //   ),
                  // ),
                ],
              ),
            ),
          ),
        )
        .animate()
        .fadeIn(duration: 400.ms, delay: 50.ms * index)
        .slideY(
          begin: 0.2,
          end: 0,
          duration: 400.ms,
          curve: Curves.easeOutQuad,
        );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade700,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: Colors.grey.shade900,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentDetails(PdfDocument document) {
    final bool isVerified =
        document.metadata.containsKey('status') &&
        document.metadata['status'] == 'Verified';

    // Extract metadata
    final Map<String, dynamic> metadata = Map.from(document.metadata);
    String extractedData = '';

    if (metadata.containsKey('extracted_data')) {
      extractedData = metadata['extracted_data'].toString();
    }

    return Container(
      color: Colors.white,
      child: Column(
        children: [
          // Header with document info
          Container(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(24),
                bottomRight: Radius.circular(24),
              ),
              boxShadow: [
                BoxShadow(
                  color: Color.fromRGBO(0, 0, 0, 0.1),
                  blurRadius: 4,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: SafeArea(
              bottom: false,
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Document Details',
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color:
                              isVerified
                                  ? Colors.green.withOpacity(0.2)
                                  : Colors.blue.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color:
                                isVerified
                                    ? Colors.green.shade300
                                    : Colors.blue.shade300,
                          ),
                        ),
                        child: Text(
                          isVerified ? 'Verified' : 'Pending',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: Colors.white,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Document title
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 8,
                          spreadRadius: 0,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: const Color(0xFFFEECEA),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Center(
                                child: Icon(
                                  Icons.picture_as_pdf,
                                  color: Colors.red,
                                  size: 20,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    document.originalFilename,
                                    style: GoogleFonts.poppins(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.grey.shade800,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    'ID: ${document.fileId}',
                                    style: GoogleFonts.poppins(
                                      fontSize: 12,
                                      color: Colors.grey.shade600,
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
            ),
          ),

          // Document content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Basic information
                  _buildDetailSection('Basic Information', [
                    {'label': 'File Name', 'value': document.originalFilename},
                    {'label': 'File ID', 'value': document.fileId},
                    {'label': 'Upload Date', 'value': document.uploadDate},
                    {
                      'label': 'Status',
                      'value': isVerified ? 'Verified' : 'Pending',
                    },
                  ]),

                  // Metadata section
                  if (metadata.isNotEmpty)
                    _buildDetailSection(
                      'Metadata',
                      metadata.entries
                          .where(
                            (entry) =>
                                ![
                                  '_id',
                                  'file_id',
                                  'original_filename',
                                  'upload_date',
                                  'extracted_data',
                                  's3_url',
                                ].contains(entry.key),
                          )
                          .map(
                            (entry) => {
                              'label': entry.key.replaceFirst(
                                entry.key[0],
                                entry.key[0].toUpperCase(),
                              ),
                              'value': entry.value.toString(),
                            },
                          )
                          .toList(),
                    ),

                  // Extracted data section
                  if (extractedData.isNotEmpty)
                    Container(
                      margin: const EdgeInsets.only(bottom: 20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            spreadRadius: 0,
                            offset: const Offset(0, 2),
                          ),
                        ],
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.text_fields,
                                  size: 20,
                                  color: Colors.red,
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  'Extracted Text',
                                  style: GoogleFonts.poppins(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.grey.shade800,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Divider(height: 1),
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade50,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.grey.shade200),
                              ),
                              child: Text(
                                extractedData,
                                style: GoogleFonts.poppins(
                                  fontSize: 13,
                                  color: Colors.grey.shade800,
                                  height: 1.5,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    ).animate().fade(duration: 300.ms);
  }

  Widget _buildDetailSection(String title, List<Map<String, String>> details) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            spreadRadius: 0,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(Icons.info_outline, size: 20, color: Colors.red),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade800,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children:
                  details.map((detail) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                            width: 120,
                            child: Text(
                              detail['label'] ?? '',
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w500,
                                color: Colors.grey.shade700,
                                fontSize: 13,
                              ),
                            ),
                          ),
                          Expanded(
                            child: Text(
                              detail['value'] ?? '',
                              style: GoogleFonts.poppins(
                                color: Colors.grey.shade800,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}
