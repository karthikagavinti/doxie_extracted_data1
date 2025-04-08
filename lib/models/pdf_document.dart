class PdfDocument {
  final Map<String, dynamic> metadata;
  final String pdfUrl;
  final String status;

  PdfDocument({
    required this.metadata,
    required this.pdfUrl,
    required this.status,
  });

  factory PdfDocument.fromJson(Map<String, dynamic> json) {
    // Extract the PDF URL correctly
    String pdfUrl = '';
    if (json.containsKey('pdf')) {
      pdfUrl = json['pdf'];
    } else if (json.containsKey('s3_url')) {
      pdfUrl = json['s3_url'];
    } else if (json.containsKey('metadata') && json['metadata'] is Map) {
      // Try to find S3 URL in metadata
      final metadata = json['metadata'] as Map<String, dynamic>;
      if (metadata.containsKey('s3_url')) {
        pdfUrl = metadata['s3_url'];
      } else if (metadata.containsKey('s3_key') && metadata.containsKey('s3_bucket')) {
        // Construct S3 URL from bucket and key if available
        final bucket = metadata['s3_bucket'];
        final key = metadata['s3_key'];
        pdfUrl = '/download/${metadata['file_id']}.pdf';
      }
    }
    
    // Ensure the URL is properly formatted
    if (!pdfUrl.startsWith('/') && !pdfUrl.startsWith('http')) {
      pdfUrl = '/$pdfUrl';
    }
    
    // Create a default metadata map if not provided
    Map<String, dynamic> metadataMap = json['metadata'] ?? {};
    
    // Add a default 'type' field for inbound/outbound classification if not present
    if (!metadataMap.containsKey('type')) {
      // Randomly assign as inbound or outbound for demo purposes
      metadataMap['type'] = DateTime.now().millisecondsSinceEpoch % 2 == 0 ? 'inbound' : 'outbound';
    }
    
    // Extract original filename from the URL if not present in metadata
    if (!metadataMap.containsKey('original_filename') || metadataMap['original_filename'] == null || metadataMap['original_filename'].toString().isEmpty) {
      String filename = '';
      if (pdfUrl.isNotEmpty) {
        // Extract filename from URL
        filename = pdfUrl.split('/').last;
        // Remove extension if present
        if (filename.toLowerCase().endsWith('.pdf')) {
          filename = filename.substring(0, filename.length - 4);
        }
        // Replace underscores and hyphens with spaces
        filename = filename.replaceAll('_', ' ').replaceAll('-', ' ');
        // Capitalize first letter of each word
        filename = filename.split(' ').map((word) => 
          word.isNotEmpty ? '${word[0].toUpperCase()}${word.substring(1)}' : ''
        ).join(' ');
      }
      
      metadataMap['original_filename'] = filename.isNotEmpty ? filename : 'Untitled Document';
    }
    
    // Set default title to original_filename if not present
    if (!metadataMap.containsKey('title') || metadataMap['title'] == null || metadataMap['title'].toString().isEmpty) {
      metadataMap['title'] = metadataMap['original_filename'] ?? 'Untitled Document';
    }
    
    // Set default upload date if not present
    if (!metadataMap.containsKey('upload_date') || metadataMap['upload_date'] == null || metadataMap['upload_date'].toString().isEmpty) {
      final now = DateTime.now();
      metadataMap['upload_date'] = '${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year}';
    }
    
    return PdfDocument(
      metadata: metadataMap,
      pdfUrl: pdfUrl,
      status: json['status'] ?? '',
    );
  }

  String get title => metadata['title'] ?? 'Untitled Document';
  String get originalFilename => metadata['original_filename'] ?? title;
  String get fileId => metadata['file_id'] ?? 'Unknown ID';
  String get uploadDate => metadata['upload_date'] ?? 'Unknown Date';
  String get s3Url => metadata['s3_url'] ?? '';
  String get type => metadata['type'] ?? 'inbound';

  // Helper method to get any metadata field with a default value
  dynamic getMetadataField(String key, [dynamic defaultValue = '']) {
    return metadata.containsKey(key) ? metadata[key] : defaultValue;
  }

  // Create a copy of the document with updated metadata
  PdfDocument copyWith({Map<String, dynamic>? updatedMetadata}) {
    return PdfDocument(
      metadata: updatedMetadata ?? this.metadata,
      pdfUrl: this.pdfUrl,
      status: this.status,
    );
  }
}

