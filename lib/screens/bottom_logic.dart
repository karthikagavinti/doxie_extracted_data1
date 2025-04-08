// import 'dart:convert';
// import 'package:flutter/material.dart';
// import '../theme/app_theme.dart';

// class DocumentBottomSheet {
//   // Show the bottom sheet with extracted data
//   static Future<void> showExtractedDataBottomSheet(
//     BuildContext context, {
//     required String label,
//     required String value,
//     required bool isMetadataVisible,
//     required Function(bool) onMetadataVisibilityChanged,
//     required Map<String, dynamic> metadata,
//     bool isEditable = false,
//     Function(String)? onValueChanged,
//     VoidCallback? onSave,
//   }) {
//     // Create a text editing controller if the sheet is editable
//     final TextEditingController? editController =
//         isEditable ? TextEditingController(text: value) : null;

//     // Store the data and expand the sheet
//     return showModalBottomSheet(
//       context: context,
//       isScrollControlled: true,
//       backgroundColor: Colors.white,
//       shape: const RoundedRectangleBorder(
//         borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
//       ),
//       builder: (context) {
//         return DraggableScrollableSheet(
//           expand: false,
//           initialChildSize: 0.7,
//           minChildSize: 0.5,
//           maxChildSize: 0.95,
//           builder: (context, scrollController) {
//             return Column(
//               children: [
//                 // Handle bar
//                 Column(
//                   children: [
//                     Container(
//                       margin: const EdgeInsets.only(top: 10),
//                       width: 40,
//                       height: 5,
//                       decoration: BoxDecoration(
//                         color: Colors.grey.shade300,
//                         borderRadius: BorderRadius.circular(10),
//                       ),
//                     ),
//                     Container(
//                       margin: const EdgeInsets.symmetric(vertical: 8),
//                       padding: const EdgeInsets.symmetric(
//                         horizontal: 16,
//                         vertical: 4,
//                       ),
//                       decoration: BoxDecoration(
//                         color: Colors.grey.shade100,
//                         borderRadius: BorderRadius.circular(20),
//                         border: Border.all(color: Colors.grey.shade300),
//                       ),
//                       child: Row(
//                         mainAxisSize: MainAxisSize.min,
//                         children: [
//                           Icon(
//                             Icons.drag_handle,
//                             size: 16,
//                             color: Colors.grey.shade600,
//                           ),
//                           const SizedBox(width: 4),
//                           Text(
//                             'Drag to resize',
//                             style: TextStyle(
//                               fontSize: 12,
//                               color: Colors.grey.shade600,
//                             ),
//                           ),
//                         ],
//                       ),
//                     ),
//                   ],
//                 ),
//                 // Header
//                 Padding(
//                   padding: const EdgeInsets.all(16.0),
//                   child: Row(
//                     mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                     children: [
//                       Text(
//                         label,
//                         style: const TextStyle(
//                           fontSize: 20,
//                           fontWeight: FontWeight.bold,
//                         ),
//                       ),
//                       Row(
//                         children: [
//                           if (isEditable && onSave != null)
//                             TextButton.icon(
//                               icon: const Icon(Icons.save),
//                               label: const Text('Save'),
//                               onPressed: () {
//                                 if (editController != null &&
//                                     onValueChanged != null) {
//                                   onValueChanged(editController.text);
//                                 }
//                                 onSave();
//                                 Navigator.of(context).pop();
//                               },
//                             ),
//                           IconButton(
//                             icon: const Icon(Icons.close),
//                             onPressed: () {
//                               Navigator.of(context).pop();
//                             },
//                           ),
//                         ],
//                       ),
//                     ],
//                   ),
//                 ),
//                 const Divider(),
//                 // Content
//                 Expanded(
//                   child: SingleChildScrollView(
//                     controller: scrollController,
//                     padding: const EdgeInsets.all(16.0),
//                     child: _buildExtractedDataContent(
//                       isEditable ? (editController?.text ?? value) : value,
//                       isMetadataVisible,
//                       onMetadataVisibilityChanged,
//                       metadata,
//                       isEditable: isEditable,
//                       editController: editController,
//                     ),
//                   ),
//                 ),
//               ],
//             );
//           },
//         );
//       },
//     );
//   }

//   // Build the content for the extracted data bottom sheet
//   static Widget _buildExtractedDataContent(
//     String text,
//     bool isMetadataVisible,
//     Function(bool) onMetadataVisibilityChanged,
//     Map<String, dynamic> metadata, {
//     bool isEditable = false,
//     TextEditingController? editController,
//   }) {
//     // Extract all key details from the text
//     final details = extractAllKeyDetails(text);

//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         // Document metadata section - MOVED TO TOP
//         Row(
//           mainAxisAlignment: MainAxisAlignment.spaceBetween,
//           children: [
//             const Text(
//               'Document Metadata:',
//               style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
//             ),
//             // Add eye icon to toggle metadata visibility
//             IconButton(
//               icon: Icon(
//                 isMetadataVisible ? Icons.visibility : Icons.visibility_off,
//                 color: Colors.grey.shade700,
//                 size: 20,
//               ),
//               onPressed: () {
//                 onMetadataVisibilityChanged(!isMetadataVisible);
//               },
//               tooltip: isMetadataVisible ? 'Hide Metadata' : 'Show Metadata',
//             ),
//           ],
//         ),
//         const SizedBox(height: 12),

//         // Document metadata cards - conditionally visible
//         if (isMetadataVisible)
//           Container(
//             decoration: BoxDecoration(
//               color: Colors.grey.shade50,
//               borderRadius: BorderRadius.circular(8),
//               border: Border.all(color: Colors.grey.shade200),
//             ),
//             child: Column(
//               children: [
//                 _buildMetadataItem(
//                   'Original Filename',
//                   metadata['original_filename'] ?? '',
//                 ),
//                 _buildMetadataItem('File ID', metadata['file_id'] ?? ''),
//                 _buildMetadataItem(
//                   'Upload Date',
//                   metadata['upload_date'] ?? '',
//                 ),
//                 _buildMetadataItem(
//                   'Type',
//                   metadata['type'] != null
//                       ? metadata['type'].charAt(0).toUpperCase() +
//                           metadata['type'].substring(1)
//                       : '',
//                 ),
//                 if (metadata.containsKey('status'))
//                   _buildMetadataItem('Status', metadata['status'].toString()),

//                 // Additional metadata section
//                 const Padding(
//                   padding: EdgeInsets.all(12),
//                   child: Align(
//                     alignment: Alignment.centerLeft,
//                     child: Text(
//                       'Additional Metadata:',
//                       style: TextStyle(
//                         fontSize: 14,
//                         fontWeight: FontWeight.bold,
//                       ),
//                     ),
//                   ),
//                 ),

//                 // Display all other metadata
//                 ...metadata.entries
//                     .where(
//                       (entry) =>
//                           ![
//                             'title',
//                             'file_id',
//                             'upload_date',
//                             'author',
//                             'description',
//                             'category',
//                             'tags',
//                             'status',
//                             's3_url',
//                             '_id',
//                             'original_filename',
//                             'type',
//                             'extracted_data',
//                           ].contains(entry.key),
//                     )
//                     .map(
//                       (entry) => _buildMetadataItem(
//                         entry.key.replaceFirst(
//                           entry.key[0],
//                           entry.key[0].toUpperCase(),
//                         ),
//                         _valueToString(entry.value),
//                       ),
//                     )
//                     .toList(),
//               ],
//             ),
//           ),

//         const SizedBox(height: 20),

//         // Key Details Table with white theme
//         Container(
//           margin: const EdgeInsets.only(bottom: 20),
//           decoration: BoxDecoration(
//             color: Colors.white,
//             borderRadius: BorderRadius.circular(8),
//             border: Border.all(color: Colors.grey.shade300),
//             boxShadow: [
//               BoxShadow(
//                 color: Colors.black.withOpacity(0.1),
//                 blurRadius: 4,
//                 spreadRadius: 0,
//               ),
//             ],
//           ),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               Padding(
//                 padding: const EdgeInsets.all(12),
//                 child: Text(
//                   'Key Details',
//                   style: TextStyle(
//                     fontSize: 18,
//                     fontWeight: FontWeight.bold,
//                     color: Colors.grey.shade800,
//                   ),
//                 ),
//               ),
//               // Table - Show all extracted key values
//               Table(
//                 border: TableBorder(
//                   horizontalInside: BorderSide(
//                     color: Colors.grey.shade200,
//                     width: 1,
//                   ),
//                 ),
//                 columnWidths: const {
//                   0: FlexColumnWidth(1),
//                   1: FlexColumnWidth(2),
//                 },
//                 children: [
//                   // Table header
//                   _buildTableRow('Field', 'Details', isHeader: true),
//                   // Include all extracted key values
//                   ...details.entries
//                       .map((entry) => _buildTableRow(entry.key, entry.value))
//                       .toList(),
//                   // If no values were found, show a message
//                   if (details.isEmpty)
//                     _buildTableRow(
//                       'No Details Found',
//                       'No key information could be extracted from this document',
//                     ),
//                 ],
//               ),
//             ],
//           ),
//         ),

//         const SizedBox(height: 20),
//         const Text(
//           'Full Content:',
//           style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
//         ),
//         const SizedBox(height: 8),

//         // Full text with highlighted keywords or editable field
//         if (isEditable && editController != null)
//           TextField(
//             controller: editController,
//             maxLines: 10,
//             decoration: InputDecoration(
//               border: OutlineInputBorder(
//                 borderRadius: BorderRadius.circular(8),
//               ),
//               hintText: 'Edit extracted data here...',
//             ),
//           )
//         else
//           _buildHighlightedText(text),
//       ],
//     );
//   }

//   // Helper method for metadata items in the bottom sheet
//   static Widget _buildMetadataItem(String label, String value) {
//     return Container(
//       padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
//       decoration: BoxDecoration(
//         border: Border(
//           bottom: BorderSide(color: Colors.grey.shade200, width: 1),
//         ),
//       ),
//       child: Row(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           SizedBox(
//             width: 120,
//             child: Text(
//               label,
//               style: TextStyle(
//                 fontWeight: FontWeight.bold,
//                 color: Colors.grey.shade700,
//                 fontSize: 13,
//               ),
//             ),
//           ),
//           Expanded(
//             child: Text(
//               value,
//               style: TextStyle(color: Colors.grey.shade800, fontSize: 13),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   // Helper method to build table rows
//   static TableRow _buildTableRow(
//     String field,
//     String value, {
//     bool isHeader = false,
//   }) {
//     return TableRow(
//       decoration: BoxDecoration(
//         color: isHeader ? Colors.grey.shade100 : Colors.white,
//       ),
//       children: [
//         Padding(
//           padding: const EdgeInsets.all(12),
//           child: Text(
//             field,
//             style: TextStyle(
//               fontWeight: isHeader ? FontWeight.bold : FontWeight.normal,
//               color: Colors.grey.shade800,
//             ),
//           ),
//         ),
//         Padding(
//           padding: const EdgeInsets.all(12),
//           child: Text(
//             value.isEmpty ? 'Not specified in the provided data' : value,
//             style: TextStyle(
//               color:
//                   value.isEmpty ? Colors.grey.shade500 : Colors.grey.shade800,
//               fontWeight: isHeader ? FontWeight.bold : FontWeight.normal,
//             ),
//           ),
//         ),
//       ],
//     );
//   }

//   // Helper method to highlight specific keywords in text
//   static Widget _buildHighlightedText(String text) {
//     // Keywords to highlight - expanded list
//     final List<String> keywords = [
//       'po',
//       'date',
//       'address',
//       'contact',
//       'phone',
//       'purchase order',
//       'purchase order number',
//       'p.o.',
//       'invoice number',
//       'order date',
//       'customer p.o',
//       'customer po#',
//       'vendor',
//       'ship to',
//       'ship from',
//       'buy from',
//       'promise date',
//       'shipping address',
//       'vendor address',
//       'complete order date',
//       'purchaseordernumber',
//       'orderdate',
//       'zipcode',
//       'city',
//       'state',
//       'country',
//       'fax',
//       'terms',
//       'tax rate',
//       'subtotal',
//       'total',
//       'currency',
//       'document type',
//       'document number',
//       'delivery no',
//       'customer no',
//       'ship-via',
//       'user',
//       'packing slip',
//       'freight',
//     ];

//     // Create a case-insensitive RegExp pattern for all keywords
//     final List<TextSpan> spans = [];
//     int lastIndex = 0;

//     try {
//       // Process each keyword individually to avoid complex regex
//       for (final keyword in keywords) {
//         final pattern = RegExp('\\b$keyword\\b', caseSensitive: false);

//         for (final match in pattern.allMatches(text)) {
//           // Add text before the match if there is any
//           if (match.start > lastIndex) {
//             spans.add(
//               TextSpan(
//                 text: text.substring(lastIndex, match.start),
//                 style: const TextStyle(color: Colors.black),
//               ),
//             );
//           }

//           // Add the matched text with red color
//           spans.add(
//             TextSpan(
//               text: text.substring(match.start, match.end),
//               style: const TextStyle(
//                 color: Colors.red,
//                 fontWeight: FontWeight.bold,
//               ),
//             ),
//           );

//           lastIndex = match.end;
//         }
//       }

//       // Add any remaining text
//       if (lastIndex < text.length) {
//         spans.add(
//           TextSpan(
//             text: text.substring(lastIndex),
//             style: const TextStyle(color: Colors.black),
//           ),
//         );
//       }
//     } catch (e) {
//       // Fallback if highlighting fails
//       debugPrint("Error highlighting text: $e");
//       spans.add(
//         TextSpan(text: text, style: const TextStyle(color: Colors.black)),
//       );
//     }

//     return RichText(
//       text: TextSpan(
//         style: const TextStyle(fontSize: 16, color: Colors.black),
//         children: spans,
//       ),
//     );
//   }

//   // Helper method to safely convert any value to a string
//   static String _valueToString(dynamic value) {
//     if (value == null) {
//       return 'null';
//     } else if (value is Map || value is List) {
//       return jsonEncode(value);
//     } else {
//       return value.toString();
//     }
//   }

//   // Helper methods to extract specific information
//   static String _extractPurchaseOrder(String text) {
//     try {
//       // Enhanced regex to handle various purchase order formats including Customer PO#
//       final List<RegExp> regexPatterns = [
//         RegExp(
//           r'(?:Purchase\s*Order|PO|P\.O\.)(?:\s*Number)?[#:\s]*([A-Z0-9\-]+)',
//           caseSensitive: false,
//         ),
//         RegExp(r'Customer\s+PO#:\s*([A-Z0-9\-]+)', caseSensitive: false),
//         RegExp(r'PO#\s*([A-Z0-9\-]+)', caseSensitive: false),
//       ];

//       for (final regex in regexPatterns) {
//         final match = regex.firstMatch(text);
//         if (match != null && match.groupCount >= 1) {
//           final value = match.group(1)?.trim();
//           if (value != null && value.isNotEmpty) {
//             return value;
//           }
//         }
//       }
//     } catch (e) {
//       debugPrint("Error extracting purchase order: $e");
//     }
//     return '';
//   }

//   static String _extractPhone(String text) {
//     try {
//       // Simplified regex to handle phone numbers
//       final RegExp regex = RegExp(
//         r'(?:Phone|Tel|Telephone)[:\s]*(\d{3}\s*\d{3}-\d{4}|\d{3}[\s\-\.]\d{3}[\s\-\.]\d{4})',
//         caseSensitive: false,
//       );

//       final match = regex.firstMatch(text);
//       if (match != null && match.groupCount >= 1) {
//         final value = match.group(1)?.trim();
//         if (value != null && value.isNotEmpty) {
//           return value;
//         }
//       }
//     } catch (e) {
//       debugPrint("Error extracting phone: $e");
//     }
//     return '';
//   }

//   static String _extractDate(String text) {
//     try {
//       // Enhanced regex to handle various date formats including those with time
//       final List<RegExp> regexPatterns = [
//         RegExp(
//           r'(?:Date|Order\s*Date)[:\s]*(\d{1,2}[\/\-\.]\d{1,2}[\/\-\.]\d{2,4})',
//           caseSensitive: false,
//         ),
//         RegExp(
//           r'Date"?:\s*"?(\d{1,2}/\d{1,2}/\d{4}\s+\d{1,2}:\d{2}\s*(?:AM|PM)?)"?',
//           caseSensitive: false,
//         ),
//         RegExp(
//           r'(\d{1,2}[\/\-\.]\d{1,2}[\/\-\.]\d{2,4})',
//           caseSensitive: false,
//         ),
//       ];

//       for (final regex in regexPatterns) {
//         final match = regex.firstMatch(text);
//         if (match != null && match.groupCount >= 1) {
//           final value = match.group(1)?.trim();
//           if (value != null && value.isNotEmpty) {
//             return value;
//           }
//         }
//       }
//     } catch (e) {
//       debugPrint("Error extracting date: $e");
//     }
//     return '';
//   }

//   static String _extractAddress(String text) {
//     try {
//       // Simplified regex to handle addresses
//       final RegExp regex = RegExp(
//         r'(?:Address|Vendor\s*Address)[:\s]*([^,\n\r]*(?:,\s*[^,\n\r]*){1,})',
//         caseSensitive: false,
//       );

//       final match = regex.firstMatch(text);
//       if (match != null && match.groupCount >= 1) {
//         final value = match.group(1)?.trim();
//         if (value != null && value.isNotEmpty) {
//           // Limit address to 100 characters and add ellipsis if needed
//           if (value.length > 100) {
//             return '${value.substring(0, 97)}...';
//           }
//           return value;
//         }
//       }
//     } catch (e) {
//       debugPrint("Error extracting address: $e");
//     }
//     return '';
//   }

//   // Method to extract additional fields from nested JSON structures
//   static Map<String, String> extractAllKeyDetails(String text) {
//     final Map<String, String> details = {};

//     try {
//       // Extract the main fields using simple regex patterns
//       final purchaseOrder = _extractPurchaseOrder(text);
//       final phone = _extractPhone(text);
//       final date = _extractDate(text);
//       final address = _extractAddress(text);

//       if (purchaseOrder.isNotEmpty)
//         details['Purchase Order Number'] = purchaseOrder;
//       if (phone.isNotEmpty) details['Phone'] = phone;
//       if (date.isNotEmpty) details['Date'] = date;
//       if (address.isNotEmpty) details['Address'] = address;

//       // Extract specific fields from JSON-like structures
//       // Look for patterns like "Customer PO#: MAN160546"
//       final customerPoMatch = RegExp(
//         r'Customer\s+PO#:\s*([^,\n\r"]+)',
//       ).firstMatch(text);
//       if (customerPoMatch != null && customerPoMatch.groupCount >= 1) {
//         final value = customerPoMatch.group(1)?.trim();
//         if (value != null && value.isNotEmpty) {
//           details['Customer PO#'] = value;
//         }
//       }

//       // Look for Customer No.
//       final customerNoMatch = RegExp(
//         r'Customer\s+No\.?:\s*([^,\n\r"]+)',
//       ).firstMatch(text);
//       if (customerNoMatch != null && customerNoMatch.groupCount >= 1) {
//         final value = customerNoMatch.group(1)?.trim();
//         if (value != null && value.isNotEmpty) {
//           details['Customer No.'] = value;
//         }
//       }

//       // Look for Document Type
//       final docTypeMatch = RegExp(
//         r'Document\s+Type"?:\s*"?([^,\n\r"]+)"?',
//       ).firstMatch(text);
//       if (docTypeMatch != null && docTypeMatch.groupCount >= 1) {
//         final value = docTypeMatch.group(1)?.trim();
//         if (value != null && value.isNotEmpty) {
//           details['Document Type'] = value;
//         }
//       }

//       // Look for Document Number
//       final docNumberMatch = RegExp(
//         r'Document\s+Number"?:\s*"?([^,\n\r"]+)"?',
//       ).firstMatch(text);
//       if (docNumberMatch != null && docNumberMatch.groupCount >= 1) {
//         final value = docNumberMatch.group(1)?.trim();
//         if (value != null && value.isNotEmpty) {
//           details['Document Number'] = value;
//         }
//       }

//       // Look for Delivery No.
//       final deliveryNoMatch = RegExp(
//         r'Delivery\s+No\.?:\s*"?([^,\n\r"]+)"?',
//       ).firstMatch(text);
//       if (deliveryNoMatch != null && deliveryNoMatch.groupCount >= 1) {
//         final value = deliveryNoMatch.group(1)?.trim();
//         if (value != null && value.isNotEmpty) {
//           details['Delivery No.'] = value;
//         }
//       }

//       // Look for Ship-Via
//       final shipViaMatch = RegExp(
//         r'Ship-?Via:\s*"?([^,\n\r"]+)"?',
//       ).firstMatch(text);
//       if (shipViaMatch != null && shipViaMatch.groupCount >= 1) {
//         final value = shipViaMatch.group(1)?.trim();
//         if (value != null && value.isNotEmpty) {
//           details['Ship Via'] = value;
//         }
//       }

//       // Look for Vendor
//       final vendorMatch = RegExp(
//         r'Vendor"?:\s*"?([^,\n\r"]+)"?',
//       ).firstMatch(text);
//       if (vendorMatch != null && vendorMatch.groupCount >= 1) {
//         final value = vendorMatch.group(1)?.trim();
//         if (value != null && value.isNotEmpty) {
//           details['Vendor'] = value;
//         }
//       }

//       // Look for User
//       final userMatch = RegExp(r'User"?:\s*"?([^,\n\r"]+)"?').firstMatch(text);
//       if (userMatch != null && userMatch.groupCount >= 1) {
//         final value = userMatch.group(1)?.trim();
//         if (value != null && value.isNotEmpty) {
//           details['User'] = value;
//         }
//       }

//       // Extract date with time if available
//       final dateTimeMatch = RegExp(
//         r'Date"?:\s*"?(\d{1,2}/\d{1,2}/\d{4}\s+\d{1,2}:\d{2}\s*(?:AM|PM)?)"?',
//       ).firstMatch(text);
//       if (dateTimeMatch != null && dateTimeMatch.groupCount >= 1) {
//         final value = dateTimeMatch.group(1)?.trim();
//         if (value != null && value.isNotEmpty) {
//           details['Date'] = value;
//         }
//       }

//       // Extract nested address information
//       final shipFromMatch = RegExp(
//         r'Ship\s+From"?:\s*\{([^}]+)\}',
//       ).firstMatch(text);
//       if (shipFromMatch != null && shipFromMatch.groupCount >= 1) {
//         final shipFromContent = shipFromMatch.group(1);
//         if (shipFromContent != null) {
//           // Extract company from Ship From
//           final companyMatch = RegExp(
//             r'Company"?:\s*"?([^,\n\r"]+)"?',
//           ).firstMatch(shipFromContent);
//           if (companyMatch != null && companyMatch.groupCount >= 1) {
//             final value = companyMatch.group(1)?.trim();
//             if (value != null && value.isNotEmpty) {
//               details['Ship From Company'] = value;
//             }
//           }

//           // Extract address from Ship From
//           final addressMatch = RegExp(
//             r'Address"?:\s*"?([^,\n\r"]+)"?',
//           ).firstMatch(shipFromContent);
//           if (addressMatch != null && addressMatch.groupCount >= 1) {
//             final value = addressMatch.group(1)?.trim();
//             if (value != null && value.isNotEmpty) {
//               details['Ship From Address'] = value;
//             }
//           }
//         }
//       }

//       // Extract Ship To information
//       final shipToMatch = RegExp(
//         r'Ship\s+To"?:\s*\{([^}]+)\}',
//       ).firstMatch(text);
//       if (shipToMatch != null && shipToMatch.groupCount >= 1) {
//         final shipToContent = shipToMatch.group(1);
//         if (shipToContent != null) {
//           // Extract company from Ship To
//           final companyMatch = RegExp(
//             r'Company"?:\s*"?([^,\n\r"]+)"?',
//           ).firstMatch(shipToContent);
//           if (companyMatch != null && companyMatch.groupCount >= 1) {
//             final value = companyMatch.group(1)?.trim();
//             if (value != null && value.isNotEmpty) {
//               details['Ship To Company'] = value;
//             }
//           }

//           // Extract address from Ship To
//           final addressMatch = RegExp(
//             r'Address"?:\s*"?([^,\n\r"]+)"?',
//           ).firstMatch(shipToContent);
//           if (addressMatch != null && addressMatch.groupCount >= 1) {
//             final value = addressMatch.group(1)?.trim();
//             if (value != null && value.isNotEmpty) {
//               details['Ship To Address'] = value;
//             }
//           }
//         }
//       }

//       // Extract any other key-value pairs using a generic pattern
//       final keyValuePattern = RegExp(
//         r'([A-Za-z0-9_\s]+)"?:\s*"?([^,\n\r"{}]+)"?',
//       );
//       for (final match in keyValuePattern.allMatches(text)) {
//         if (match.groupCount >= 2) {
//           final key = match.group(1)?.trim();
//           final value = match.group(2)?.trim();
//           if (key != null &&
//               value != null &&
//               key.isNotEmpty &&
//               value.isNotEmpty) {
//             // Only add if not already present and not a nested object
//             if (!details.containsKey(key) &&
//                 !value.contains('{') &&
//                 !value.contains('[')) {
//               details[key] = value;
//             }
//           }
//         }
//       }
//     } catch (e) {
//       debugPrint("Error extracting all key details: $e");
//     }

//     return details;
//   }
// }

// extension StringExtension on String {
//   String charAt(int index) {
//     if (index < 0 || index >= length) {
//       return '';
//     }
//     return this[index];
//   }
// }

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:skeletonizer/skeletonizer.dart' as skeleton;

class DocumentBottomSheet {
  // Show the bottom sheet with extracted data
  static Future<void> showExtractedDataBottomSheet(
    BuildContext context, {
    required String label,
    required String value,
    required bool isMetadataVisible,
    required Function(bool) onMetadataVisibilityChanged,
    required Map<String, dynamic> metadata,
    bool isEditable = false,
    Function(String)? onValueChanged,
    VoidCallback? onSave,
    bool isLoading = false, // Added isLoading parameter
  }) {
    // Create a text editing controller if the sheet is editable
    final TextEditingController? editController =
        isEditable ? TextEditingController(text: value) : null;

    // Store the data and expand the sheet
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.7,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          builder: (context, scrollController) {
            return Column(
              children: [
                // Handle bar
                Column(
                  children: [
                    Container(
                      margin: const EdgeInsets.only(top: 10),
                      width: 40,
                      height: 5,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    Container(
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.drag_handle,
                            size: 16,
                            color: Colors.grey.shade600,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Drag to resize',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                // Header
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        label,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Row(
                        children: [
                          if (isEditable && onSave != null && !isLoading)
                            TextButton.icon(
                              icon: const Icon(Icons.save),
                              label: const Text('Save'),
                              onPressed: () {
                                if (editController != null &&
                                    onValueChanged != null) {
                                  onValueChanged(editController.text);
                                }
                                onSave();
                                Navigator.of(context).pop();
                              },
                            ),
                          IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () {
                              Navigator.of(context).pop();
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const Divider(),
                // Content
                Expanded(
                  child: SingleChildScrollView(
                    controller: scrollController,
                    padding: const EdgeInsets.all(16.0),
                    child:
                        isLoading
                            ? _buildSkeletonContent() // Show skeleton when loading
                            : _buildExtractedDataContent(
                              isEditable
                                  ? (editController?.text ?? value)
                                  : value,
                              isMetadataVisible,
                              onMetadataVisibilityChanged,
                              metadata,
                              isEditable: isEditable,
                              editController: editController,
                            ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // New method to build skeleton loading UI for the bottom sheet
  static Widget _buildSkeletonContent() {
    return skeleton.Skeletonizer(
      effect: const skeleton.ShimmerEffect(),
      enabled: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Document metadata section skeleton
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Document Metadata:',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              IconButton(
                icon: Icon(
                  Icons.visibility,
                  color: Colors.grey.shade700,
                  size: 20,
                ),
                onPressed: null,
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Document metadata cards skeleton
          Container(
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              children: [
                _buildSkeletonMetadataItem(
                  'Original Filename',
                  'Document_123.pdf',
                ),
                _buildSkeletonMetadataItem('File ID', 'file-123456789'),
                _buildSkeletonMetadataItem('Upload Date', '2024-03-28'),
                _buildSkeletonMetadataItem('Type', 'PDF'),
                _buildSkeletonMetadataItem('Status', 'Verified'),

                // Additional metadata section
                const Padding(
                  padding: EdgeInsets.all(12),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Additional Metadata:',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),

                // Additional metadata items
                _buildSkeletonMetadataItem('Created By', 'John Doe'),
                _buildSkeletonMetadataItem('Department', 'Finance'),
                _buildSkeletonMetadataItem('Category', 'Invoice'),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Key Details Table skeleton
          Container(
            margin: const EdgeInsets.only(bottom: 20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade300),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  spreadRadius: 0,
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(
                    'Key Details',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade800,
                    ),
                  ),
                ),
                // Table skeleton
                Table(
                  border: TableBorder(
                    horizontalInside: BorderSide(
                      color: Colors.grey.shade200,
                      width: 1,
                    ),
                  ),
                  columnWidths: const {
                    0: FlexColumnWidth(1),
                    1: FlexColumnWidth(2),
                  },
                  children: [
                    // Table header
                    _buildSkeletonTableRow('Field', 'Details', isHeader: true),
                    // Skeleton rows
                    _buildSkeletonTableRow('Purchase Order', 'PO-123456'),
                    _buildSkeletonTableRow('Date', '2024-03-28'),
                    _buildSkeletonTableRow('Customer', 'ACME Corporation'),
                    _buildSkeletonTableRow('Amount', '\$1,234.56'),
                    _buildSkeletonTableRow('Status', 'Approved'),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),
          const Text(
            'Full Content:',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),

          // Full text skeleton
          Container(
            height: 200,
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: List.generate(
                8,
                (index) => Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Container(
                    height: 16,
                    width: double.infinity,
                    color: Colors.grey.shade300,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Helper method for skeleton metadata items
  static Widget _buildSkeletonMetadataItem(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade200, width: 1),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade700,
                fontSize: 13,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(color: Colors.grey.shade800, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  // Helper method to build skeleton table rows
  static TableRow _buildSkeletonTableRow(
    String field,
    String value, {
    bool isHeader = false,
  }) {
    return TableRow(
      decoration: BoxDecoration(
        color: isHeader ? Colors.grey.shade100 : Colors.white,
      ),
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: Text(
            field,
            style: TextStyle(
              fontWeight: isHeader ? FontWeight.bold : FontWeight.normal,
              color: Colors.grey.shade800,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(12),
          child: Text(
            value,
            style: TextStyle(
              color: Colors.grey.shade800,
              fontWeight: isHeader ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ],
    );
  }

  // Build the content for the extracted data bottom sheet
  static Widget _buildExtractedDataContent(
    String text,
    bool isMetadataVisible,
    Function(bool) onMetadataVisibilityChanged,
    Map<String, dynamic> metadata, {
    bool isEditable = false,
    TextEditingController? editController,
  }) {
    // Extract all key details from the text
    final details = extractAllKeyDetails(text);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Document metadata section - MOVED TO TOP
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Document Metadata:',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            // Add eye icon to toggle metadata visibility
            IconButton(
              icon: Icon(
                isMetadataVisible ? Icons.visibility : Icons.visibility_off,
                color: Colors.grey.shade700,
                size: 20,
              ),
              onPressed: () {
                onMetadataVisibilityChanged(!isMetadataVisible);
              },
              tooltip: isMetadataVisible ? 'Hide Metadata' : 'Show Metadata',
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Document metadata cards - conditionally visible
        if (isMetadataVisible)
          Container(
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              children: [
                _buildMetadataItem(
                  'Original Filename',
                  metadata['original_filename'] ?? '',
                ),
                _buildMetadataItem('File ID', metadata['file_id'] ?? ''),
                _buildMetadataItem(
                  'Upload Date',
                  metadata['upload_date'] ?? '',
                ),
                _buildMetadataItem(
                  'Type',
                  metadata['type'] != null
                      ? _capitalizeFirstLetter(metadata['type'].toString())
                      : '',
                ),
                if (metadata.containsKey('status'))
                  _buildMetadataItem('Status', metadata['status'].toString()),

                // Additional metadata section
                const Padding(
                  padding: EdgeInsets.all(12),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Additional Metadata:',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),

                // Display all other metadata
                ...metadata.entries
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
                            'extracted_data',
                          ].contains(entry.key),
                    )
                    .map(
                      (entry) => _buildMetadataItem(
                        _capitalizeFirstLetter(entry.key),
                        _valueToString(entry.value),
                      ),
                    )
                    .toList(),
              ],
            ),
          ),

        const SizedBox(height: 20),

        // Key Details Table with white theme
        Container(
          margin: const EdgeInsets.only(bottom: 20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade300),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 4,
                spreadRadius: 0,
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(12),
                child: Text(
                  'Key Details',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade800,
                  ),
                ),
              ),
              // Table - Show all extracted key values
              Table(
                border: TableBorder(
                  horizontalInside: BorderSide(
                    color: Colors.grey.shade200,
                    width: 1,
                  ),
                ),
                columnWidths: const {
                  0: FlexColumnWidth(1),
                  1: FlexColumnWidth(2),
                },
                children: [
                  // Table header
                  _buildTableRow('Field', 'Details', isHeader: true),
                  // Include all extracted key values
                  ...details.entries
                      .map((entry) => _buildTableRow(entry.key, entry.value))
                      .toList(),
                  // If no values were found, show a message
                  if (details.isEmpty)
                    _buildTableRow(
                      'No Details Found',
                      'No key information could be extracted from this document',
                    ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),
        const Text(
          'Full Content:',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),

        // Full text with highlighted keywords or editable field
        if (isEditable && editController != null)
          TextField(
            controller: editController,
            maxLines: 10,
            decoration: InputDecoration(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              hintText: 'Edit extracted data here...',
            ),
          )
        else
          _buildHighlightedText(text),
      ],
    );
  }

  // Helper method for metadata items in the bottom sheet
  static Widget _buildMetadataItem(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade200, width: 1),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade700,
                fontSize: 13,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(color: Colors.grey.shade800, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  // Helper method to build table rows
  static TableRow _buildTableRow(
    String field,
    String value, {
    bool isHeader = false,
  }) {
    return TableRow(
      decoration: BoxDecoration(
        color: isHeader ? Colors.grey.shade100 : Colors.white,
      ),
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: Text(
            field,
            style: TextStyle(
              fontWeight: isHeader ? FontWeight.bold : FontWeight.normal,
              color: Colors.grey.shade800,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(12),
          child: Text(
            value.isEmpty ? 'Not specified in the provided data' : value,
            style: TextStyle(
              color:
                  value.isEmpty ? Colors.grey.shade500 : Colors.grey.shade800,
              fontWeight: isHeader ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ],
    );
  }

  // Helper method to highlight specific keywords in text
  static Widget _buildHighlightedText(String text) {
    // Keywords to highlight - expanded list
    final List<String> keywords = [
      'po',
      'date',
      'address',
      'contact',
      'phone',
      'purchase order',
      'purchase order number',
      'p.o.',
      'invoice number',
      'order date',
      'customer p.o',
      'customer po#',
      'vendor',
      'ship to',
      'ship from',
      'buy from',
      'promise date',
      'shipping address',
      'vendor address',
      'complete order date',
      'purchaseordernumber',
      'orderdate',
      'zipcode',
      'city',
      'state',
      'country',
      'fax',
      'terms',
      'tax rate',
      'subtotal',
      'total',
      'currency',
      'document type',
      'document number',
      'delivery no',
      'customer no',
      'ship-via',
      'user',
      'packing slip',
      'freight',
    ];

    // Create a case-insensitive RegExp pattern for all keywords
    final List<TextSpan> spans = [];
    int lastIndex = 0;

    try {
      // Process each keyword individually to avoid complex regex
      for (final keyword in keywords) {
        final pattern = RegExp('\\b$keyword\\b', caseSensitive: false);

        for (final match in pattern.allMatches(text)) {
          // Add text before the match if there is any
          if (match.start > lastIndex) {
            spans.add(
              TextSpan(
                text: text.substring(lastIndex, match.start),
                style: const TextStyle(color: Colors.black),
              ),
            );
          }

          // Add the matched text with red color
          spans.add(
            TextSpan(
              text: text.substring(match.start, match.end),
              style: const TextStyle(
                color: Colors.red,
                fontWeight: FontWeight.bold,
              ),
            ),
          );

          lastIndex = match.end;
        }
      }

      // Add any remaining text
      if (lastIndex < text.length) {
        spans.add(
          TextSpan(
            text: text.substring(lastIndex),
            style: const TextStyle(color: Colors.black),
          ),
        );
      }
    } catch (e) {
      // Fallback if highlighting fails
      debugPrint("Error highlighting text: $e");
      spans.add(
        TextSpan(text: text, style: const TextStyle(color: Colors.black)),
      );
    }

    return RichText(
      text: TextSpan(
        style: const TextStyle(fontSize: 16, color: Colors.black),
        children: spans,
      ),
    );
  }

  // Helper method to safely convert any value to a string
  static String _valueToString(dynamic value) {
    if (value == null) {
      return 'null';
    } else if (value is Map || value is List) {
      return jsonEncode(value);
    } else {
      return value.toString();
    }
  }

  // Helper method to capitalize first letter of a string
  static String _capitalizeFirstLetter(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1);
  }

  // Helper methods to extract specific information
  static String _extractPurchaseOrder(String text) {
    try {
      // Enhanced regex to handle various purchase order formats including Customer PO#
      final List<RegExp> regexPatterns = [
        RegExp(
          r'(?:Purchase\s*Order|PO|P\.O\.)(?:\s*Number)?[#:\s]*([A-Z0-9\-]+)',
          caseSensitive: false,
        ),
        RegExp(r'Customer\s+PO#:\s*([A-Z0-9\-]+)', caseSensitive: false),
        RegExp(r'PO#\s*([A-Z0-9\-]+)', caseSensitive: false),
      ];

      for (final regex in regexPatterns) {
        final match = regex.firstMatch(text);
        if (match != null && match.groupCount >= 1) {
          final value = match.group(1)?.trim();
          if (value != null && value.isNotEmpty) {
            return value;
          }
        }
      }
    } catch (e) {
      debugPrint("Error extracting purchase order: $e");
    }
    return '';
  }

  static String _extractPhone(String text) {
    try {
      // Simplified regex to handle phone numbers
      final RegExp regex = RegExp(
        r'(?:Phone|Tel|Telephone)[:\s]*(\d{3}\s*\d{3}-\d{4}|\d{3}[\s\-\.]\d{3}[\s\-\.]\d{4})',
        caseSensitive: false,
      );

      final match = regex.firstMatch(text);
      if (match != null && match.groupCount >= 1) {
        final value = match.group(1)?.trim();
        if (value != null && value.isNotEmpty) {
          return value;
        }
      }
    } catch (e) {
      debugPrint("Error extracting phone: $e");
    }
    return '';
  }

  static String _extractDate(String text) {
    try {
      // Enhanced regex to handle various date formats including those with time
      final List<RegExp> regexPatterns = [
        RegExp(
          r'(?:Date|Order\s*Date)[:\s]*(\d{1,2}[\/\-\.]\d{1,2}[\/\-\.]\d{2,4})',
          caseSensitive: false,
        ),
        RegExp(
          r'Date"?:\s*"?(\d{1,2}/\d{1,2}/\d{4}\s+\d{1,2}:\d{2}\s*(?:AM|PM)?)"?',
          caseSensitive: false,
        ),
        RegExp(
          r'(\d{1,2}[\/\-\.]\d{1,2}[\/\-\.]\d{2,4})',
          caseSensitive: false,
        ),
      ];

      for (final regex in regexPatterns) {
        final match = regex.firstMatch(text);
        if (match != null && match.groupCount >= 1) {
          final value = match.group(1)?.trim();
          if (value != null && value.isNotEmpty) {
            return value;
          }
        }
      }
    } catch (e) {
      debugPrint("Error extracting date: $e");
    }
    return '';
  }

  static String _extractAddress(String text) {
    try {
      // Simplified regex to handle addresses
      final RegExp regex = RegExp(
        r'(?:Address|Vendor\s*Address)[:\s]*([^,\n\r]*(?:,\s*[^,\n\r]*){1,})',
        caseSensitive: false,
      );

      final match = regex.firstMatch(text);
      if (match != null && match.groupCount >= 1) {
        final value = match.group(1)?.trim();
        if (value != null && value.isNotEmpty) {
          // Limit address to 100 characters and add ellipsis if needed
          if (value.length > 100) {
            return '${value.substring(0, 97)}...';
          }
          return value;
        }
      }
    } catch (e) {
      debugPrint("Error extracting address: $e");
    }
    return '';
  }

  // Method to extract additional fields from nested JSON structures
  static Map<String, String> extractAllKeyDetails(String text) {
    final Map<String, String> details = {};

    try {
      // Extract the main fields using simple regex patterns
      final purchaseOrder = _extractPurchaseOrder(text);
      final phone = _extractPhone(text);
      final date = _extractDate(text);
      final address = _extractAddress(text);

      if (purchaseOrder.isNotEmpty)
        details['Purchase Order Number'] = purchaseOrder;
      if (phone.isNotEmpty) details['Phone'] = phone;
      if (date.isNotEmpty) details['Date'] = date;
      if (address.isNotEmpty) details['Address'] = address;

      // Extract specific fields from JSON-like structures
      // Look for patterns like "Customer PO#: MAN160546"
      final customerPoMatch = RegExp(
        r'Customer\s+PO#:\s*([^,\n\r"]+)',
      ).firstMatch(text);
      if (customerPoMatch != null && customerPoMatch.groupCount >= 1) {
        final value = customerPoMatch.group(1)?.trim();
        if (value != null && value.isNotEmpty) {
          details['Customer PO#'] = value;
        }
      }

      // Look for Customer No.
      final customerNoMatch = RegExp(
        r'Customer\s+No\.?:\s*([^,\n\r"]+)',
      ).firstMatch(text);
      if (customerNoMatch != null && customerNoMatch.groupCount >= 1) {
        final value = customerNoMatch.group(1)?.trim();
        if (value != null && value.isNotEmpty) {
          details['Customer No.'] = value;
        }
      }

      // Look for Document Type
      final docTypeMatch = RegExp(
        r'Document\s+Type"?:\s*"?([^,\n\r"]+)"?',
      ).firstMatch(text);
      if (docTypeMatch != null && docTypeMatch.groupCount >= 1) {
        final value = docTypeMatch.group(1)?.trim();
        if (value != null && value.isNotEmpty) {
          details['Document Type'] = value;
        }
      }

      // Look for Document Number
      final docNumberMatch = RegExp(
        r'Document\s+Number"?:\s*"?([^,\n\r"]+)"?',
      ).firstMatch(text);
      if (docNumberMatch != null && docNumberMatch.groupCount >= 1) {
        final value = docNumberMatch.group(1)?.trim();
        if (value != null && value.isNotEmpty) {
          details['Document Number'] = value;
        }
      }

      // Look for Delivery No.
      final deliveryNoMatch = RegExp(
        r'Delivery\s+No\.?:\s*"?([^,\n\r"]+)"?',
      ).firstMatch(text);
      if (deliveryNoMatch != null && deliveryNoMatch.groupCount >= 1) {
        final value = deliveryNoMatch.group(1)?.trim();
        if (value != null && value.isNotEmpty) {
          details['Delivery No.'] = value;
        }
      }

      // Look for Ship-Via
      final shipViaMatch = RegExp(
        r'Ship-?Via:\s*"?([^,\n\r"]+)"?',
      ).firstMatch(text);
      if (shipViaMatch != null && shipViaMatch.groupCount >= 1) {
        final value = shipViaMatch.group(1)?.trim();
        if (value != null && value.isNotEmpty) {
          details['Ship Via'] = value;
        }
      }

      // Look for Vendor
      final vendorMatch = RegExp(
        r'Vendor"?:\s*"?([^,\n\r"]+)"?',
      ).firstMatch(text);
      if (vendorMatch != null && vendorMatch.groupCount >= 1) {
        final value = vendorMatch.group(1)?.trim();
        if (value != null && value.isNotEmpty) {
          details['Vendor'] = value;
        }
      }

      // Look for User
      final userMatch = RegExp(r'User"?:\s*"?([^,\n\r"]+)"?').firstMatch(text);
      if (userMatch != null && userMatch.groupCount >= 1) {
        final value = userMatch.group(1)?.trim();
        if (value != null && value.isNotEmpty) {
          details['User'] = value;
        }
      }

      // Extract date with time if available
      final dateTimeMatch = RegExp(
        r'Date"?:\s*"?(\d{1,2}/\d{1,2}/\d{4}\s+\d{1,2}:\d{2}\s*(?:AM|PM)?)"?',
      ).firstMatch(text);
      if (dateTimeMatch != null && dateTimeMatch.groupCount >= 1) {
        final value = dateTimeMatch.group(1)?.trim();
        if (value != null && value.isNotEmpty) {
          details['Date'] = value;
        }
      }

      // Extract nested address information
      final shipFromMatch = RegExp(
        r'Ship\s+From"?:\s*\{([^}]+)\}',
      ).firstMatch(text);
      if (shipFromMatch != null && shipFromMatch.groupCount >= 1) {
        final shipFromContent = shipFromMatch.group(1);
        if (shipFromContent != null) {
          // Extract company from Ship From
          final companyMatch = RegExp(
            r'Company"?:\s*"?([^,\n\r"]+)"?',
          ).firstMatch(shipFromContent);
          if (companyMatch != null && companyMatch.groupCount >= 1) {
            final value = companyMatch.group(1)?.trim();
            if (value != null && value.isNotEmpty) {
              details['Ship From Company'] = value;
            }
          }

          // Extract address from Ship From
          final addressMatch = RegExp(
            r'Address"?:\s*"?([^,\n\r"]+)"?',
          ).firstMatch(shipFromContent);
          if (addressMatch != null && addressMatch.groupCount >= 1) {
            final value = addressMatch.group(1)?.trim();
            if (value != null && value.isNotEmpty) {
              details['Ship From Address'] = value;
            }
          }
        }
      }

      // Extract Ship To information
      final shipToMatch = RegExp(
        r'Ship\s+To"?:\s*\{([^}]+)\}',
      ).firstMatch(text);
      if (shipToMatch != null && shipToMatch.groupCount >= 1) {
        final shipToContent = shipToMatch.group(1);
        if (shipToContent != null) {
          // Extract company from Ship To
          final companyMatch = RegExp(
            r'Company"?:\s*"?([^,\n\r"]+)"?',
          ).firstMatch(shipToContent);
          if (companyMatch != null && companyMatch.groupCount >= 1) {
            final value = companyMatch.group(1)?.trim();
            if (value != null && value.isNotEmpty) {
              details['Ship To Company'] = value;
            }
          }

          // Extract address from Ship To
          final addressMatch = RegExp(
            r'Address"?:\s*"?([^,\n\r"]+)"?',
          ).firstMatch(shipToContent);
          if (addressMatch != null && addressMatch.groupCount >= 1) {
            final value = addressMatch.group(1)?.trim();
            if (value != null && value.isNotEmpty) {
              details['Ship To Address'] = value;
            }
          }
        }
      }

      // Extract any other key-value pairs using a generic pattern
      final keyValuePattern = RegExp(
        r'([A-Za-z0-9_\s]+)"?:\s*"?([^,\n\r"{}]+)"?',
      );
      for (final match in keyValuePattern.allMatches(text)) {
        if (match.groupCount >= 2) {
          final key = match.group(1)?.trim();
          final value = match.group(2)?.trim();
          if (key != null &&
              value != null &&
              key.isNotEmpty &&
              value.isNotEmpty) {
            // Only add if not already present and not a nested object
            if (!details.containsKey(key) &&
                !value.contains('{') &&
                !value.contains('[')) {
              details[key] = value;
            }
          }
        }
      }
    } catch (e) {
      debugPrint("Error extracting all key details: $e");
    }

    return details;
  }

  // Convert extracted data to JSON
  static String extractedDataToJson(String text) {
    final Map<String, dynamic> jsonData = {};

    try {
      // Get all extracted key details
      final details = extractAllKeyDetails(text);

      // Add details to JSON
      jsonData['extracted_details'] = details;

      // Add original text
      jsonData['original_text'] = text;

      // Add timestamp
      jsonData['extraction_timestamp'] = DateTime.now().toIso8601String();

      return jsonEncode(jsonData);
    } catch (e) {
      debugPrint("Error converting to JSON: $e");
      return jsonEncode({'error': e.toString(), 'original_text': text});
    }
  }

  // Show transaction details with skeleton loading
  static Future<void> showTransactionDetails(
    BuildContext context,
    String transactionId,
    Map<String, dynamic> metadata,
  ) async {
    // First show the bottom sheet with skeleton loading
    showExtractedDataBottomSheet(
      context,
      label: "Transaction Details",
      value: "",
      isMetadataVisible: true,
      onMetadataVisibilityChanged: (_) {},
      metadata: metadata,
      isLoading: true, // Show skeleton loading
    );

    try {
      // Simulate fetching transaction details
      await Future.delayed(const Duration(milliseconds: 1500));

      // Mock transaction data - in a real app, this would come from an API
      final String transactionData = '''
      {
        "transaction_id": "$transactionId",
        "status": "completed",
        "date": "2024-03-28",
        "amount": "1,250.00",
        "currency": "USD",
        "vendor": "Acme Supplies",
        "purchase_order": "PO-${transactionId.substring(0, 6)}",
        "items": [
          {"name": "Office Supplies", "quantity": 5, "price": "150.00"},
          {"name": "Furniture", "quantity": 2, "price": "500.00"},
          {"name": "Electronics", "quantity": 1, "price": "600.00"}
        ]
      }''';

      // Close the skeleton loading bottom sheet
      Navigator.of(context).pop();

      // Show the transaction details in the bottom sheet with actual data
      showExtractedDataBottomSheet(
        context,
        label: "Transaction Details",
        value: transactionData,
        isMetadataVisible: true,
        onMetadataVisibilityChanged: (_) {},
        metadata: {
          ...metadata,
          'transaction_id': transactionId,
          'view_timestamp': DateTime.now().toString(),
        },
        isLoading: false, // No longer loading
      );
    } catch (e) {
      // Close loading bottom sheet if still showing
      Navigator.of(context).pop();

      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading transaction: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}

// Skeletonized version of the TransactionCard
class SkeletonTransactionCard extends StatelessWidget {
  const SkeletonTransactionCard({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return skeleton.Skeletonizer(
      effect: const skeleton.ShimmerEffect(),
      enabled: true,
      child: Card(
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      'Transaction Title',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.visibility, color: Colors.blue),
                    onPressed: null,
                    tooltip: 'View Transaction Details',
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '2024-03-28',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                  ),
                  Text(
                    '\$1,250.00',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Completed',
                  style: TextStyle(
                    color: Colors.green,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class TransactionCard extends StatelessWidget {
  final String transactionId;
  final String title;
  final String date;
  final String amount;
  final String status;
  final Map<String, dynamic> metadata;

  const TransactionCard({
    Key? key,
    required this.transactionId,
    required this.title,
    required this.date,
    required this.amount,
    required this.status,
    required this.metadata,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.visibility, color: Colors.blue),
                  onPressed: () {
                    // Show transaction details with skeleton loading
                    DocumentBottomSheet.showTransactionDetails(
                      context,
                      transactionId,
                      metadata,
                    );
                  },
                  tooltip: 'View Transaction Details',
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  date,
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                ),
                Text(
                  amount,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _getStatusColor(status).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                status,
                style: TextStyle(
                  color: _getStatusColor(status),
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'failed':
        return Colors.red;
      default:
        return Colors.blue;
    }
  }
}

class JsonUtils {
  // Improve JSON extraction from text
  static Map<String, dynamic> extractJsonFromText(String text) {
    try {
      // Try to parse the entire text as JSON first
      try {
        return jsonDecode(text);
      } catch (_) {
        // If that fails, look for JSON-like structures
      }

      // Look for JSON objects in the text
      final RegExp jsonPattern = RegExp(r'\{(?:[^{}]|(?:\{[^{}]*\}))*\}');
      final matches = jsonPattern.allMatches(text);

      if (matches.isNotEmpty) {
        // Try each match until we find valid JSON
        for (final match in matches) {
          try {
            final jsonStr = match.group(0);
            if (jsonStr != null) {
              return jsonDecode(jsonStr);
            }
          } catch (_) {
            // Continue to the next match
          }
        }
      }

      // If no valid JSON found, create a structured representation
      return _createStructuredJson(text);
    } catch (e) {
      print('Error extracting JSON: $e');
      return {'error': 'Failed to extract JSON', 'raw_text': text};
    }
  }

  // Create structured JSON from unstructured text
  static Map<String, dynamic> _createStructuredJson(String text) {
    final Map<String, dynamic> result = {
      'raw_text': text,
      'extracted_fields': <String, dynamic>{},
    };

    // Extract key-value pairs using regex
    final RegExp keyValuePattern = RegExp(
      r'([A-Za-z0-9_\s]+)[:\s]+([^,\n\r]+)',
    );
    final matches = keyValuePattern.allMatches(text);

    for (final match in matches) {
      if (match.groupCount >= 2) {
        final key = match.group(1)?.trim();
        final value = match.group(2)?.trim();

        if (key != null &&
            value != null &&
            key.isNotEmpty &&
            value.isNotEmpty) {
          result['extracted_fields'][key] = value;
        }
      }
    }

    return result;
  }

  // Format JSON for display
  static String prettyPrintJson(Map<String, dynamic> json) {
    const encoder = JsonEncoder.withIndent('  ');
    return encoder.convert(json);
  }
}
