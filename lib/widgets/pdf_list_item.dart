// import 'package:doxie_dummy_pdf/models/pdf_document.dart';
// import 'package:doxie_dummy_pdf/theme/app_theme.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_animate/flutter_animate.dart';
// import 'package:google_fonts/google_fonts.dart';

// class PdfListItem extends StatefulWidget {
//   final PdfDocument document;
//   final VoidCallback onTap;

//   const PdfListItem({Key? key, required this.document, required this.onTap})
//     : super(key: key);

//   @override
//   State<PdfListItem> createState() => _PdfListItemState();
// }

// class _PdfListItemState extends State<PdfListItem>
//     with SingleTickerProviderStateMixin {
//   late AnimationController _controller;
//   late Animation<double> _scaleAnimation;

//   @override
//   void initState() {
//     super.initState();
//     _controller = AnimationController(
//       duration: const Duration(milliseconds: 200),
//       vsync: this,
//     );
//     _scaleAnimation = Tween<double>(
//       begin: 1.0,
//       end: 1.02,
//     ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
//   }

//   @override
//   void dispose() {
//     _controller.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return AnimatedBuilder(
//       animation: _scaleAnimation,
//       builder: (context, child) {
//         return Transform.scale(scale: _scaleAnimation.value, child: child);
//       },
//       child: GestureDetector(
//         onTap: () {
//           _controller.forward().then((_) => _controller.reverse());
//           widget.onTap();
//         },
//         child: Container(
//           margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
//           decoration: BoxDecoration(
//             color: Colors.white,
//             borderRadius: BorderRadius.circular(12),
//             boxShadow: [
//               BoxShadow(
//                 color: Colors.black.withOpacity(0.03),
//                 blurRadius: 4,
//                 offset: const Offset(0, 2),
//               ),
//             ],
//           ),
//           child: Stack(
//             children: [
//               Padding(
//                 padding: const EdgeInsets.all(16),
//                 child: Row(
//                   children: [
//                     // PDF Icon - keeping it exactly as in the original
//                     Container(
//                       width: 48,
//                       height: 48,
//                       decoration: BoxDecoration(
//                         color: const Color.fromARGB(1, 254, 236, 234),
//                         borderRadius: BorderRadius.circular(8),
//                       ),
//                       child: const Center(
//                         child: Icon(
//                           Icons.picture_as_pdf,
//                           color: Color(0xFFFF6B6B),
//                           size: 24,
//                         ),
//                       ),
//                     ),
//                     const SizedBox(width: 16),

//                     // Document Details
//                     Expanded(
//                       child: Column(
//                         crossAxisAlignment: CrossAxisAlignment.start,
//                         children: [
//                           Text(
//                             widget.document.originalFilename,
//                             style: GoogleFonts.inter(
//                               textStyle: const TextStyle(
//                                 fontWeight: FontWeight.w500,
//                                 fontSize: 14,
//                                 color: Color(0xFF2D3748),
//                               ),
//                             ),
//                             maxLines: 1,
//                             overflow: TextOverflow.ellipsis,
//                           ),
//                           const SizedBox(height: 8),
//                           const Divider(
//                             height: 1,
//                             thickness: 1,
//                             color: Color(0xFFEDF2F7),
//                           ),
//                           const SizedBox(height: 8),
//                           Text(
//                             'ID: ${widget.document.fileId}',
//                             style: GoogleFonts.inter(
//                               textStyle: const TextStyle(
//                                 fontSize: 12,
//                                 color: Color(0xFF718096),
//                                 fontWeight: FontWeight.w400,
//                               ),
//                             ),
//                           ),
//                           const SizedBox(height: 2),
//                           Text(
//                             'Date: ${widget.document.uploadDate}',
//                             style: GoogleFonts.inter(
//                               textStyle: const TextStyle(
//                                 fontSize: 12,
//                                 color: Color(0xFF718096),
//                                 fontWeight: FontWeight.w400,
//                               ),
//                             ),
//                           ),
//                         ],
//                       ),
//                     ),
//                   ],
//                 ),
//               ),

//               // Three dots icon positioned at bottom right
//               Positioned(
//                 right: 12,
//                 bottom: 12,
//                 child: IconButton(
//                   icon: const Icon(
//                     Icons.more_vert,
//                     color: Color(0xFF718096),
//                     size: 20,
//                   ),
//                   onPressed: () {
//                     // Handle more options menu
//                   },
//                   padding: EdgeInsets.zero,
//                   constraints: const BoxConstraints(),
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }
