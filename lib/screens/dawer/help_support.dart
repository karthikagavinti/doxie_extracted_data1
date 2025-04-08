// help_support_screen.dart - Enhanced help and support screen

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
// import 'package:url_launcher/url_launcher.dart';
import 'package:doxie_dummy_pdf/theme/app_theme.dart';

class HelpSupportScreen extends StatefulWidget {
  const HelpSupportScreen({Key? key}) : super(key: key);

  @override
  State<HelpSupportScreen> createState() => _HelpSupportScreenState();
}

class _HelpSupportScreenState extends State<HelpSupportScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _feedbackController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();

  late TabController _tabController;
  bool _isSubmitting = false;
  String _searchQuery = '';

  // Expandable FAQ sections
  final Map<String, bool> _expandedSections = {
    'General Questions': false,
    'PDF Viewing': false,
    'Document Management': false,
    'Annotations': false,
    'Account & Settings': false,
  };

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _feedbackController.dispose();
    _emailController.dispose();
    _searchController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  void _submitFeedback() async {
    if (_feedbackController.text.trim().isEmpty) {
      _showSnackBar('Please enter your feedback');
      return;
    }

    if (_emailController.text.trim().isEmpty ||
        !_isValidEmail(_emailController.text)) {
      _showSnackBar('Please enter a valid email address');
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    // Simulate API call
    await Future.delayed(const Duration(seconds: 2));

    if (mounted) {
      setState(() {
        _isSubmitting = false;
        _feedbackController.clear();
        _emailController.clear();
      });

      _showSnackBar('Thank you for your feedback!', isSuccess: true);
    }
  }

  bool _isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  void _showSnackBar(String message, {bool isSuccess = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: GoogleFonts.poppins()),
        backgroundColor: isSuccess ? Colors.green : Colors.red,
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(10),
      ),
    );
  }

  void _toggleSection(String section) {
    setState(() {
      _expandedSections[section] = !(_expandedSections[section] ?? false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
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
          'Help & Support',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.normal,
            color: Colors.white,
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          labelStyle: GoogleFonts.poppins(
            fontWeight: FontWeight.w500,
            fontSize: 14,
          ),
          unselectedLabelStyle: GoogleFonts.poppins(
            fontWeight: FontWeight.w400,
            fontSize: 14,
          ),
          tabs: const [
            Tab(text: 'FAQs'),
            Tab(text: 'Guides'),
            Tab(text: 'Contact'),
            Tab(text: 'Feedback'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildFAQsTab(),
          _buildGuidesTab(),
          _buildContactTab(),
          _buildFeedbackTab(),
        ],
      ),
    );
  }

  Widget _buildFAQsTab() {
    // Filter FAQs based on search query
    final List<Map<String, dynamic>> allFaqs = _getFAQs();
    final List<Map<String, dynamic>> filteredFaqs =
        _searchQuery.isEmpty
            ? allFaqs
            : allFaqs
                .where(
                  (faq) =>
                      faq['question'].toLowerCase().contains(
                        _searchQuery.toLowerCase(),
                      ) ||
                      faq['answer'].toLowerCase().contains(
                        _searchQuery.toLowerCase(),
                      ),
                )
                .toList();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search FAQs',
              prefixIcon: const Icon(Icons.search),
              suffixIcon:
                  _searchQuery.isNotEmpty
                      ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          setState(() {
                            _searchController.clear();
                            _searchQuery = '';
                          });
                        },
                      )
                      : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppTheme.primaryColor),
              ),
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
            ),
            onChanged: (value) {
              setState(() {
                _searchQuery = value;
              });
            },
          ),
        ),
        Expanded(
          child:
              _searchQuery.isNotEmpty
                  ? _buildSearchResults(filteredFaqs)
                  : _buildFAQSections(),
        ),
      ],
    );
  }

  Widget _buildSearchResults(List<Map<String, dynamic>> filteredFaqs) {
    if (filteredFaqs.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              'No results found',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Try different keywords or browse the categories',
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: filteredFaqs.length,
      itemBuilder: (context, index) {
        final faq = filteredFaqs[index];
        return Card(
          elevation: 2,
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: ExpansionTile(
            title: Text(
              faq['question'],
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
                fontSize: 15,
              ),
            ),
            childrenPadding: const EdgeInsets.all(16),
            expandedCrossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                faq['answer'],
                style: GoogleFonts.poppins(fontSize: 14, height: 1.5),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFAQSections() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children:
          _expandedSections.keys.map((section) {
            final isExpanded = _expandedSections[section] ?? false;
            final sectionFaqs =
                _getFAQs().where((faq) => faq['category'] == section).toList();

            return Card(
              color: Colors.white,
              elevation: 2,
              margin: const EdgeInsets.only(bottom: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  ListTile(
                    title: Text(
                      section,
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                    trailing: Icon(
                      isExpanded
                          ? Icons.keyboard_arrow_up
                          : Icons.keyboard_arrow_down,
                      color: AppTheme.primaryColor,
                    ),
                    onTap: () => _toggleSection(section),
                  ),
                  if (isExpanded)
                    ListView.separated(
                      physics: const NeverScrollableScrollPhysics(),
                      shrinkWrap: true,
                      itemCount: sectionFaqs.length,
                      separatorBuilder:
                          (context, index) =>
                              Divider(height: 1, color: Colors.grey.shade200),
                      itemBuilder: (context, index) {
                        final faq = sectionFaqs[index];
                        return ExpansionTile(
                          title: Text(
                            faq['question'],
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w500,
                              fontSize: 14,
                            ),
                          ),
                          childrenPadding: const EdgeInsets.all(16),
                          expandedCrossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              faq['answer'],
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                height: 1.5,
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                ],
              ),
            );
          }).toList(),
    );
  }

  Widget _buildGuidesTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildGuideSection(
          title: 'Getting Started',
          guides: [
            {
              'title': 'How to upload documents',
              'description': 'Learn how to upload and manage your documents',
              'icon': Icons.upload_file,
              'url': 'https://docs.doxie.com/upload-guide',
            },
            {
              'title': 'Navigating the PDF viewer',
              'description': 'Master the PDF viewer interface and controls',
              'icon': Icons.menu_book,
              'url': 'https://docs.doxie.com/pdf-viewer-guide',
            },
          ],
        ),
        const SizedBox(height: 24),
        _buildGuideSection(
          title: 'Advanced Features',
          guides: [
            {
              'title': 'Working with annotations',
              'description': 'Create and manage annotations on your documents',
              'icon': Icons.edit_note,
              'url': 'https://docs.doxie.com/annotations-guide',
            },
            {
              'title': 'Document extraction',
              'description': 'How to extract and use data from your documents',
              'icon': Icons.data_object,
              'url': 'https://docs.doxie.com/extraction-guide',
            },
          ],
        ),
        const SizedBox(height: 24),
        _buildVideoTutorialsSection(),
        const SizedBox(height: 24),
        _buildTroubleshootingSection(),
      ],
    );
  }

  Widget _buildGuideSection({
    required String title,
    required List<Map<String, dynamic>> guides,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 8, bottom: 12),
          child: Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
        ),
        ...guides.map((guide) => _buildGuideCard(guide)).toList(),
      ],
    );
  }

  Widget _buildGuideCard(Map<String, dynamic> guide) {
    return Card(
      color: Colors.white,
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => {},
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  guide['icon'],
                  color: AppTheme.primaryColor,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      guide['title'],
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      guide['description'],
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: Colors.grey.shade600,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVideoTutorialsSection() {
    final List<Map<String, dynamic>> tutorials = [
      {
        'title': 'Complete App Walkthrough',
        'duration': '5:32',
        'thumbnail': 'https://example.com/thumbnail1.jpg',
        'url': 'https://youtube.com/watch?v=example1',
      },
      {
        'title': 'Advanced Annotation Features',
        'duration': '3:45',
        'thumbnail': 'https://example.com/thumbnail2.jpg',
        'url': 'https://youtube.com/watch?v=example2',
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 8, bottom: 12),
          child: Text(
            'Video Tutorials',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
        ),
        SizedBox(
          height: 180,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: tutorials.length,
            itemBuilder: (context, index) {
              final tutorial = tutorials[index];
              return Container(
                width: 280,
                margin: EdgeInsets.only(
                  left: index == 0 ? 0 : 12,
                  right: index == tutorials.length - 1 ? 0 : 12,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: Colors.grey.shade200,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        color: Colors.grey.shade300,
                        child: Center(
                          child: Icon(
                            Icons.play_circle_fill,
                            size: 48,
                            color: Colors.white.withOpacity(0.8),
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          borderRadius: const BorderRadius.only(
                            bottomLeft: Radius.circular(12),
                            bottomRight: Radius.circular(12),
                          ),
                          gradient: LinearGradient(
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                            colors: [
                              Colors.black.withOpacity(0.8),
                              Colors.transparent,
                            ],
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              tutorial['title'],
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              tutorial['duration'],
                              style: GoogleFonts.poppins(
                                color: Colors.white.withOpacity(0.8),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Positioned.fill(
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () {},
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildTroubleshootingSection() {
    final List<Map<String, dynamic>> issues = [
      {
        'title': 'PDF not loading',
        'solution':
            'Check your internet connection and try redownloading the document.',
      },
      {
        'title': 'Annotations not saving',
        'solution':
            'Make sure you have the latest app version and try restarting the app.',
      },
      {
        'title': 'App crashes when opening large files',
        'solution':
            'Try clearing the app cache or reinstalling the application.',
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 8, bottom: 12),
          child: Text(
            'Troubleshooting',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
        ),
        Card(
          color: Colors.white,
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: ListView.separated(
            physics: const NeverScrollableScrollPhysics(),
            shrinkWrap: true,
            itemCount: issues.length,
            separatorBuilder:
                (context, index) =>
                    Divider(height: 1, color: Colors.grey.shade200),
            itemBuilder: (context, index) {
              final issue = issues[index];
              return ExpansionTile(
                title: Text(
                  issue['title'],
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                  ),
                ),
                childrenPadding: const EdgeInsets.all(16),
                expandedCrossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    issue['solution'],
                    style: GoogleFonts.poppins(fontSize: 14, height: 1.5),
                  ),
                  const SizedBox(height: 12),
                  TextButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.support_agent),
                    label: Text(
                      'Still having issues? Contact support',
                      style: GoogleFonts.poppins(),
                    ),
                    style: TextButton.styleFrom(
                      foregroundColor: AppTheme.primaryColor,
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildContactTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildContactCard(
          title: 'Email Support',
          description: 'Get help from our support team',
          icon: Icons.email,
          onTap: () => {},
        ),
        const SizedBox(height: 16),
        _buildContactCard(
          title: 'Live Chat',
          description: 'Chat with our support agents in real-time',
          icon: Icons.chat,
          onTap: () => {},
        ),
        const SizedBox(height: 16),
        _buildContactCard(
          title: 'Phone Support',
          description: 'Call us at +1 (800) 123-4567',
          icon: Icons.phone,
          onTap: () => {},
        ),
        const SizedBox(height: 16),
        _buildContactCard(
          title: 'Knowledge Base',
          description: 'Browse our comprehensive documentation',
          icon: Icons.menu_book,
          onTap: () => {},
        ),
        const SizedBox(height: 24),
        Card(
          color: Colors.white,
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Business Hours',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 16),
                _buildBusinessHoursRow(
                  'Monday - Friday',
                  '9:00 AM - 6:00 PM EST',
                ),
                _buildBusinessHoursRow('Saturday', '10:00 AM - 4:00 PM EST'),
                _buildBusinessHoursRow('Sunday', 'Closed'),
                const SizedBox(height: 16),
                Text(
                  'Response Times',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'We aim to respond to all inquiries within 24 hours during business days.',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.grey.shade700,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBusinessHoursRow(String day, String hours) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              day,
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w500,
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              hours,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.grey.shade700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactCard({
    required String title,
    required String description,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 2,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: AppTheme.primaryColor, size: 30),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: Colors.grey.shade600,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeedbackTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            color: Colors.white,
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Share Your Feedback',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'We value your input! Let us know how we can improve our app.',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Colors.grey.shade700,
                    ),
                  ),
                  const SizedBox(height: 24),
                  TextField(
                    controller: _emailController,
                    decoration: InputDecoration(
                      labelText: 'Your Email',
                      hintText: 'Enter your email address',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      prefixIcon: const Icon(Icons.email),
                    ),
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _feedbackController,
                    decoration: InputDecoration(
                      labelText: 'Your Feedback',
                      hintText:
                          'Tell us what you think or suggest improvements',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      alignLabelWithHint: true,
                    ),
                    maxLines: 5,
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isSubmitting ? null : _submitFeedback,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child:
                          _isSubmitting
                              ? Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    'Submitting...',
                                    style: GoogleFonts.poppins(),
                                  ),
                                ],
                              )
                              : Text(
                                'Submit Feedback',
                                style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.w500,
                                  fontSize: 16,
                                ),
                              ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          Card(
            color: Colors.white,
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Rate Our App',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Love using our app? Please consider rating us on the app store!',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Colors.grey.shade700,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ElevatedButton.icon(
                        onPressed: () {},
                        icon: const Icon(Icons.star),
                        label: Text(
                          'Rate on Play Store',
                          style: GoogleFonts.poppins(),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Map<String, dynamic>> _getFAQs() {
    return [
      {
        'category': 'General Questions',
        'question': 'What is Doxie PDF Viewer?',
        'answer':
            'Doxie PDF Viewer is a powerful document management application that allows you to view, annotate, and extract data from PDF documents. It provides a seamless experience for working with all your important documents.',
      },
      {
        'category': 'General Questions',
        'question': 'Is my data secure?',
        'answer':
            'Yes, we take security very seriously. All your documents are encrypted both in transit and at rest. We use industry-standard security protocols to ensure your data remains private and secure.',
      },
      {
        'category': 'PDF Viewing',
        'question': 'How do I navigate between pages?',
        'answer':
            'You can navigate between pages using the arrow buttons at the bottom of the PDF viewer. You can also swipe left or right to move between pages, or use the page indicator to jump to a specific page.',
      },
      {
        'category': 'PDF Viewing',
        'question': 'Can I zoom in on a document?',
        'answer':
            'Yes, you can zoom in and out using the zoom controls on the right side of the viewer. You can also use pinch-to-zoom gestures on touch-enabled devices.',
      },
      {
        'category': 'Document Management',
        'question': 'How do I organize my documents?',
        'answer':
            'You can organize your documents by creating folders and subfolders. You can also use tags and labels to categorize your documents for easier searching and filtering.',
      },
      {
        'category': 'Document Management',
        'question': 'Can I share documents with others?',
        'answer':
            'Yes, you can share documents with others via email, messaging apps, or by generating a secure link. You can also control permissions to determine whether recipients can view, edit, or download the shared documents.',
      },
      {
        'category': 'Annotations',
        'question': 'What types of annotations can I add?',
        'answer':
            'You can add various types of annotations including highlights, notes, underlines, and drawings. Each annotation can be customized with different colors and styles.',
      },
      {
        'category': 'Annotations',
        'question': 'Are annotations saved automatically?',
        'answer':
            'Yes, annotations are saved automatically as you create them. You can also manually save your annotations at any time by tapping the save button in the annotation toolbar.',
      },
      {
        'category': 'Account & Settings',
        'question': 'How do I change my password?',
        'answer':
            'You can change your password by going to Settings > Account > Security > Change Password. You will need to enter your current password and then your new password twice to confirm.',
      },
      {
        'category': 'Account & Settings',
        'question': 'Can I use the app offline?',
        'answer':
            'Yes, you can use the app offline for documents that have been previously downloaded. New documents and changes will sync when you reconnect to the internet.',
      },
    ];
  }
}
