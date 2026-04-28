#!/usr/bin/env dart
// Daily sync script for AICerts course images
// Run with: dart scripts/sync_course_images.dart

import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:crypto/crypto.dart';

const String aicertsApiUrl = 'https://www.aicerts.ai/wp-json/aicerts-api/v1/courses';
const String jsonMappingPath = 'assets/data/course_images.json';
const String imagesDir = 'assets/images/courses';
const String syncLogPath = 'assets/data/last_sync.json';

void main() async {
  print('═══════════════════════════════════════════════════════');
  print('🔄 AICerts Course Images Daily Sync');
  print('═══════════════════════════════════════════════════════');
  print('');
  print('Started at: ${DateTime.now()}');
  print('');

  try {
    // Step 1: Fetch latest courses from AICerts API
    print('📡 Fetching latest courses from AICerts API...');
    final courses = await fetchAICertsCourses();
    print('   ✓ Fetched ${courses.length} courses\n');

    // Step 2: Load existing mapping
    print('📖 Loading existing image mapping...');
    final mapping = await loadImageMapping();
    print('   ✓ Loaded ${mapping['courses'].length} existing mappings\n');

    // Step 3: Create images directory if needed
    final dir = Directory(imagesDir);
    if (!await dir.exists()) {
      await dir.create(recursive: true);
      print('📁 Created images directory\n');
    }

    // Step 4: Sync each course
    int updated = 0;
    int unchanged = 0;
    int added = 0;
    final syncResults = <Map<String, dynamic>>[];

    for (var course in courses) {
      final title = course['title'] as String;
      final imageUrl = course['certificate_badge_url'] as String?;

      if (imageUrl == null || imageUrl.isEmpty) {
        print('⚠️  Skipping "$title" - no image URL');
        continue;
      }

      print('🔍 Checking "$title"...');

      // Find existing mapping
      final existingMapping = _findExistingMapping(mapping, title);
      final slug = _generateSlug(title);

      // Check if image needs updating
      final needsUpdate = await _checkImageNeedsUpdate(
        imageUrl,
        existingMapping,
        slug,
      );

      if (needsUpdate) {
        print('   📥 Downloading updated image...');
        final result = await _downloadAndSaveImage(imageUrl, slug);

        if (result['success']) {
          if (existingMapping == null) {
            added++;
            print('   ✅ Added new course image');
          } else {
            updated++;
            print('   ✅ Updated image');
          }

          syncResults.add({
            'title': title,
            'slug': slug,
            'source_url': imageUrl,
            'status': existingMapping == null ? 'added' : 'updated',
            'timestamp': DateTime.now().toIso8601String(),
          });
        } else {
          print('   ❌ Download failed: ${result['error']}');
        }
      } else {
        unchanged++;
        print('   ⏭️  No changes needed');
      }

      print('');
    }

    // Step 5: Update mapping file
    print('💾 Updating image mapping file...');
    await _updateMappingFile(mapping, syncResults);
    print('   ✓ Mapping updated\n');

    // Step 6: Save sync log
    print('📝 Saving sync log...');
    await _saveSyncLog(syncResults, added, updated, unchanged);
    print('   ✓ Sync log saved\n');

    // Step 7: Summary
    print('═══════════════════════════════════════════════════════');
    print('✅ Sync Complete!');
    print('═══════════════════════════════════════════════════════');
    print('📊 Summary:');
    print('   • Added: $added new courses');
    print('   • Updated: $updated existing courses');
    print('   • Unchanged: $unchanged courses');
    print('   • Total processed: ${courses.length} courses');
    print('');
    print('Finished at: ${DateTime.now()}');
    print('═══════════════════════════════════════════════════════');

    exit(0);
  } catch (e, stackTrace) {
    print('');
    print('❌ ERROR: $e');
    print('Stack trace: $stackTrace');
    exit(1);
  }
}

/// Fetch courses from AICerts API
Future<List<Map<String, dynamic>>> fetchAICertsCourses() async {
  try {
    final response = await http.get(Uri.parse(aicertsApiUrl));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);

      // Handle both array and object responses
      if (data is List) {
        return data.cast<Map<String, dynamic>>();
      } else if (data is Map && data['data'] is List) {
        return (data['data'] as List).cast<Map<String, dynamic>>();
      } else {
        throw Exception('Unexpected API response format');
      }
    } else {
      throw Exception('API returned status ${response.statusCode}');
    }
  } catch (e) {
    throw Exception('Failed to fetch courses: $e');
  }
}

/// Load existing image mapping
Future<Map<String, dynamic>> loadImageMapping() async {
  final file = File(jsonMappingPath);

  if (await file.exists()) {
    final content = await file.readAsString();
    return json.decode(content);
  }

  // Return empty structure if file doesn't exist
  return {'courses': []};
}

/// Find existing mapping for a course title
Map<String, dynamic>? _findExistingMapping(
  Map<String, dynamic> mapping,
  String title,
) {
  final courses = mapping['courses'] as List;
  return courses.firstWhere(
    (c) => c['source_name'] == title,
    orElse: () => null,
  );
}

/// Generate slug from title
String _generateSlug(String title) {
  return title
      .toLowerCase()
      .replaceAll(RegExp(r'[^\w\s-]'), '')
      .replaceAll(RegExp(r'\s+'), '-')
      .replaceAll(RegExp(r'-+'), '-')
      .trim();
}

/// Check if image needs updating
Future<bool> _checkImageNeedsUpdate(
  String imageUrl,
  Map<String, dynamic>? existingMapping,
  String slug,
) async {
  // If no existing mapping, definitely need to download
  if (existingMapping == null) return true;

  // Check if URL changed
  if (existingMapping['source_url'] != imageUrl) {
    print('   📌 URL changed from previous version');
    return true;
  }

  // Check if local file exists
  final svgPath = '$imagesDir/$slug.svg';
  final svgFile = File(svgPath);

  if (!await svgFile.exists()) {
    print('   📌 Local file missing');
    return true;
  }

  // Check if remote file changed (compare content hash)
  try {
    final remoteContent = await http.get(Uri.parse(imageUrl));
    if (remoteContent.statusCode != 200) return true;

    final remoteHash = md5.convert(remoteContent.bodyBytes).toString();
    final localContent = await svgFile.readAsBytes();
    final localHash = md5.convert(localContent).toString();

    if (remoteHash != localHash) {
      print('   📌 Remote file changed (hash mismatch)');
      return true;
    }
  } catch (e) {
    print('   ⚠️  Could not compare hashes: $e');
    // If we can't compare, assume no update needed
    return false;
  }

  return false;
}

/// Download and save image
Future<Map<String, dynamic>> _downloadAndSaveImage(
  String imageUrl,
  String slug,
) async {
  try {
    // Download image
    final response = await http.get(Uri.parse(imageUrl));

    if (response.statusCode != 200) {
      return {
        'success': false,
        'error': 'HTTP ${response.statusCode}',
      };
    }

    // Save SVG
    final svgPath = '$imagesDir/$slug.svg';
    final svgFile = File(svgPath);
    await svgFile.writeAsBytes(response.bodyBytes);

    // Note: PNG conversion would require external tool (ImageMagick, Inkscape)
    // For now, just save SVG. PNG conversion can be done separately.

    return {
      'success': true,
      'svg_path': svgPath,
    };
  } catch (e) {
    return {
      'success': false,
      'error': e.toString(),
    };
  }
}

/// Update mapping file with new data
Future<void> _updateMappingFile(
  Map<String, dynamic> mapping,
  List<Map<String, dynamic>> syncResults,
) async {
  final courses = mapping['courses'] as List;

  // Update or add courses
  for (var result in syncResults) {
    final title = result['title'];
    final slug = result['slug'];
    final sourceUrl = result['source_url'];

    // Remove existing entry if present
    courses.removeWhere((c) => c['source_name'] == title);

    // Add updated entry
    courses.add({
      'source_name': title,
      'source_url': sourceUrl,
      'local_svg': 'assets/images/courses/$slug.svg',
      'local_png': 'assets/images/courses/$slug.png',
      'last_updated': result['timestamp'],
    });
  }

  // Save updated mapping
  mapping['courses'] = courses;
  mapping['last_sync'] = DateTime.now().toIso8601String();

  final file = File(jsonMappingPath);
  final encoder = JsonEncoder.withIndent('  ');
  await file.writeAsString(encoder.convert(mapping));
}

/// Save sync log
Future<void> _saveSyncLog(
  List<Map<String, dynamic>> syncResults,
  int added,
  int updated,
  int unchanged,
) async {
  final log = {
    'last_sync': DateTime.now().toIso8601String(),
    'summary': {
      'added': added,
      'updated': updated,
      'unchanged': unchanged,
      'total': added + updated + unchanged,
    },
    'changes': syncResults,
  };

  final file = File(syncLogPath);
  final encoder = JsonEncoder.withIndent('  ');
  await file.writeAsString(encoder.convert(log));
}
