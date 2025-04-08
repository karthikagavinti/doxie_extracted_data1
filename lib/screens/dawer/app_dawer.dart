import 'package:doxie_dummy_pdf/models/pdf_document.dart';
import 'package:doxie_dummy_pdf/screens/dawer/help_support.dart';
import 'package:doxie_dummy_pdf/screens/dawer/verificcation_queue.dart';
import 'package:doxie_dummy_pdf/theme/app_theme.dart';
import 'package:doxie_dummy_pdf/services/api_service.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import 'package:flutter_animate/flutter_animate.dart';

class AppDrawer extends StatefulWidget {
  final ApiService? apiService;
  final List<PdfDocument>? documents;
  final Function(PdfDocument)? onDocumentUpdated;

  const AppDrawer({
    Key? key,
    this.apiService,
    this.documents,
    this.onDocumentUpdated,
  }) : super(key: key);

  @override
  State<AppDrawer> createState() => _AppDrawerState();
}

class _AppDrawerState extends State<AppDrawer> {
  bool _isLoading = true;
  int _totalDocuments = 0;
  int _verifiedDocuments = 0;
  int _pendingDocuments = 0;

  @override
  void initState() {
    super.initState();
    _loadStorageInfo();
  }

  void _loadStorageInfo() {
    setState(() {
      _isLoading = true;
    });

    if (widget.documents != null && widget.documents!.isNotEmpty) {
      _calculateStorageInfo(widget.documents!);
    } else if (widget.apiService != null) {
      widget.apiService!
          .getAllPdfDocuments()
          .then((docs) {
            if (mounted) {
              _calculateStorageInfo(docs);
            }
          })
          .catchError((error) {
            if (mounted) {
              setState(() {
                _isLoading = false;
              });
            }
          });
    } else {
      // Use default values if no documents or API service
      setState(() {
        _totalDocuments = 0;
        _verifiedDocuments = 0;
        _pendingDocuments = 0;
        _isLoading = false;
      });
    }
  }

  void _calculateStorageInfo(List<PdfDocument> documents) {
    // Count documents by status
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

    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.of(context).size;

    return Drawer(
      backgroundColor: Colors.white,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildProfileSection(size),
            _buildEnhancedDocumentInfo(size),
            Expanded(child: _buildNavigationItems()),
          ],
        ).animate().fade(duration: 300.ms),
      ),
    );
  }

  Widget _buildProfileSection(Size size) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.primaryColor,
            AppTheme.primaryColor.withOpacity(0.8),
          ],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "D O X I E",
                style: GoogleFonts.poppins(
                  textStyle: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(
                  Icons.arrow_back_ios_new_outlined,
                  color: Colors.white,
                ),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 8,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: const CircleAvatar(
                  backgroundImage: NetworkImage(
                    'https://randomuser.me/api/portraits/men/32.jpg',
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Alex Johnson',
                      style: GoogleFonts.poppins(
                        textStyle: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'alex.johnson@example.com',
                      style: GoogleFonts.poppins(
                        textStyle: const TextStyle(
                          fontSize: 13,
                          color: Colors.white,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEnhancedDocumentInfo(Size size) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Documents",
                style: GoogleFonts.poppins(
                  textStyle: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade800,
                  ),
                ),
              ),
              Text(
                "$_totalDocuments total documents",
                style: GoogleFonts.poppins(
                  textStyle: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              // Circular indicator showing verified/total ratio
              CircularPercentIndicator(
                radius: 30.0,
                lineWidth: 6.0,
                percent:
                    _totalDocuments > 0
                        ? _verifiedDocuments / _totalDocuments
                        : 0.0,
                center: Text(
                  "${_totalDocuments > 0 ? ((_verifiedDocuments / _totalDocuments) * 100).toStringAsFixed(0) : 0}%",
                  style: GoogleFonts.poppins(
                    textStyle: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                      color: Colors.green,
                    ),
                  ),
                ),
                progressColor: Colors.green,
                backgroundColor: Colors.grey.shade200,
                circularStrokeCap: CircularStrokeCap.round,
                animation: true,
                animationDuration: 800,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Linear progress bar showing verified/total ratio
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
                                (size.width - 32 - 32 - 60 - 16) *
                                (_totalDocuments > 0
                                    ? _verifiedDocuments / _totalDocuments
                                    : 0.0),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(4),
                              gradient: LinearGradient(
                                colors: [
                                  Colors.green,
                                  Colors.green.withOpacity(0.8),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Verified: $_verifiedDocuments",
                          style: GoogleFonts.poppins(
                            textStyle: const TextStyle(
                              fontSize: 12,
                              color: Colors.green,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        Text(
                          "Pending: $_pendingDocuments",
                          style: GoogleFonts.poppins(
                            textStyle: const TextStyle(
                              fontSize: 12,
                              color: Colors.blue,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),

          // Document status breakdown
          const SizedBox(height: 20),
          Text(
            "Document Status",
            style: GoogleFonts.poppins(
              textStyle: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade800,
              ),
            ),
          ),
          // const SizedBox(height: 12),

          // // Status cards
          // Row(
          //   children: [
          //     // Verified documents
          //     Expanded(
          //       child: _buildStatusCard(
          //         icon: Icons.verified,
          //         color: Colors.green,
          //         title: "Verified",
          //         count: _verifiedDocuments,
          //         onTap: () {
          //           Navigator.pop(context);
          //           // Navigate to Outbound tab in HomeScreen
          //         },
          //       ),
          //     ),
          //     const SizedBox(width: 8),
          //     // Pending documents
          //     Expanded(
          //       child: _buildStatusCard(
          //         icon: Icons.pending,
          //         color: Colors.blue,
          //         title: "Pending",
          //         count: _pendingDocuments,
          //         onTap: () {
          //           Navigator.pop(context);
          //           // Navigate to Inbound tab in HomeScreen and filter for pending
          //         },
          //       ),
          //     ),
          //   ],
          // ),
        ],
      ),
    );
  }

  Widget _buildStatusCard({
    required IconData icon,
    required Color color,
    required String title,
    required int count,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: color, size: 16),
                const SizedBox(width: 4),
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: color,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              count.toString(),
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade800,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavigationItems() {
    final List<Map<String, dynamic>> documentItems = [
      {
        'icon': Icons.home_rounded,
        'title': 'Home',
        'onTap': () => Navigator.pop(context),
      },
      {
        'icon': Icons.verified_rounded,
        'title': 'Verification Queue',
        'onTap': () {
          Navigator.pop(context);
          Navigator.push(
            context,
            MaterialPageRoute(
              builder:
                  (context) => VerificationQueueScreen(
                    apiService: widget.apiService,
                    documents: widget.documents,
                    onDocumentUpdated: widget.onDocumentUpdated,
                  ),
            ),
          );
        },
      },
      // {
      //   'icon': Icons.access_time_rounded,
      //   'title': 'Recent Files',
      //   'onTap': () {
      //     Navigator.pop(context);
      //     ScaffoldMessenger.of(context).showSnackBar(
      //       const SnackBar(content: Text('Recent files coming soon')),
      //     );
      //   },
      // },
      // {
      //   'icon': Icons.delete_rounded,
      //   'title': 'Trash',
      //   'onTap': () {
      //     Navigator.pop(context);
      //     ScaffoldMessenger.of(
      //       context,
      //     ).showSnackBar(const SnackBar(content: Text('Trash coming soon')));
      //   },
      // },
    ];

    final List<Map<String, dynamic>> settingsItems = [
      {
        'icon': Icons.settings_rounded,
        'title': 'Settings',
        'onTap': () {
          Navigator.pop(context);
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Settings coming soon')));
        },
      },
      {
        'icon': Icons.help_rounded,
        'title': 'Help & Support',
        'onTap': () {
          Navigator.pop(context);
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => HelpSupportScreen()),
          );
        },
      },
      {
        'icon': Icons.exit_to_app_rounded,
        'title': 'Sign Out',
        'onTap': () {
          Navigator.pop(context);
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Sign out coming soon')));
        },
      },
    ];

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 20, top: 16, bottom: 8),
            child: Text(
              "DOCUMENTS",
              style: GoogleFonts.poppins(
                textStyle: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.2,
                ),
              ),
            ),
          ),
          ...documentItems.map((item) => _buildListItem(item, false)).toList(),

          Divider(
            height: 32,
            thickness: 1,
            color: Colors.grey.shade200,
            indent: 20,
            endIndent: 20,
          ),

          Padding(
            padding: const EdgeInsets.only(left: 20, top: 8, bottom: 8),
            child: Text(
              "SETTINGS",
              style: GoogleFonts.poppins(
                textStyle: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.2,
                ),
              ),
            ),
          ),
          ...settingsItems.map((item) {
            final bool isSignOut = item['title'] == 'Sign Out';
            return _buildListItem(item, isSignOut);
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildListItem(Map<String, dynamic> item, bool isSignOut) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color:
                isSignOut
                    ? AppTheme.primaryColor.withOpacity(0.1)
                    : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            item['icon'],
            color: isSignOut ? AppTheme.primaryColor : Colors.grey.shade700,
            size: 20,
          ),
        ),
        title: Text(
          item['title'],
          style: GoogleFonts.poppins(
            textStyle: TextStyle(
              color: isSignOut ? AppTheme.primaryColor : Colors.grey.shade800,
              fontWeight: isSignOut ? FontWeight.w600 : FontWeight.w500,
              fontSize: 14,
            ),
          ),
        ),
        trailing: Icon(
          Icons.arrow_forward_ios,
          color: Colors.grey.shade400,
          size: 16,
        ),
        onTap: item['onTap'],
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        dense: true,
      ),
    );
  }
}
