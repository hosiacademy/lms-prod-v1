import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import '../../../../../core/api/api_client.dart';
import '../../../../../core/config/environment.dart';
import '../modals/instructor_application_modal.dart';

/// Comprehensive Instructors Profiles Overlay
/// Displays a curated list of certified instructors/trainers to market them to learners
/// Instructors are fetched directly from the backend (User table with role_id=2)
class InstructorsProfilesOverlay extends StatefulWidget {
  final bool isModal;
  final VoidCallback? onHide;
  final VoidCallback? onMouseEnter;
  final VoidCallback? onMouseExit;

  const InstructorsProfilesOverlay({
    Key? key,
    this.isModal = true,
    this.onHide,
    this.onMouseEnter,
    this.onMouseExit,
  }) : super(key: key);

  @override
  State<InstructorsProfilesOverlay> createState() =>
      _InstructorsProfilesOverlayState();
}

class _InstructorsProfilesOverlayState
    extends State<InstructorsProfilesOverlay> {
  late Future<List<InstructorProfile>> _instructorsFuture;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _instructorsFuture = _fetchInstructors();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<List<InstructorProfile>> _fetchInstructors() async {
    try {
      final response = await ApiClient.get(
        '/api/v1/instructors/profiles/public_list/',
        queryParameters: {'limit': 12, 'offset': 0},
      );

      if (response.statusCode == 200) {
        final data = response.data;
        final List<dynamic> results =
            (data is Map && data.containsKey('results'))
                ? data['results']
                : (data is List ? data : []);

        return results
            .map((json) =>
                InstructorProfile.fromJson(json as Map<String, dynamic>))
            .toList();
      }
      
      // Handle 403/401 - return empty list (public endpoint shouldn't require auth)
      if (response.statusCode == 403 || response.statusCode == 401) {
        print('⚠️ Instructors endpoint returned ${response.statusCode}, showing empty state');
        return [];
      }
      
      throw Exception('Failed to load instructors: ${response.statusCode}');
    } on DioException catch (e) {
      // Handle network errors gracefully
      final errorCode = e.response?.data?['code'];
      if (errorCode == 'token_not_valid' || e.response?.statusCode == 403) {
        // Token expired but this is a public endpoint - return empty list
        print('⚠️ Auth error on public endpoint, returning empty list');
        return [];
      }
      print('Error fetching instructors: ${e.message}');
      rethrow;
    } catch (e) {
      print('Error fetching instructors: $e');
      rethrow;
    }
  }

  void _showApplicationModal() {
    showDialog(
      context: context,
      builder: (context) => const InstructorApplicationModal(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final content = MouseRegion(
      onEnter: (_) {
        if (mounted) {
          WidgetsBinding.instance
              .addPostFrameCallback((_) => widget.onMouseEnter?.call());
        }
      },
      onExit: (_) {
        if (mounted) {
          WidgetsBinding.instance
              .addPostFrameCallback((_) => widget.onMouseExit?.call());
        }
      },
      child: Material(
        color: theme.scaffoldBackgroundColor,
        borderRadius: BorderRadius.circular(24),
        clipBehavior: Clip.antiAlias,
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(
              color: theme.dividerColor.withValues(alpha: 0.1),
              width: 1,
            ),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Stack(
            children: [
              // Content
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header
                  _buildHeader(context, theme),

                  // Instructors Grid
                  Flexible(
                    child: SingleChildScrollView(
                      controller: _scrollController,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: _buildInstructorsGrid(context, theme),
                    ),
                  ),

                  // Footer CTA
                  _buildFooterCTA(context, theme),
                ],
              ),

              // Close Button
              Positioned(
                top: 20,
                right: 20,
                child: GestureDetector(
                  onTap: () {
                    if (widget.onHide != null) {
                      widget.onHide!();
                    } else if (Navigator.of(context).canPop()) {
                      Navigator.pop(context);
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.close,
                      size: 20,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    if (widget.isModal) {
      return Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        child: content,
      );
    }
    return content;
  }

  Widget _buildHeader(BuildContext context, ThemeData theme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(40, 48, 40, 40),
      decoration: BoxDecoration(
        color: theme.primaryColor.withValues(alpha: 0.95),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
            ),
            child: Text(
              'WORLD-CLASS FACULTY',
              style: theme.textTheme.labelSmall?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Our Expert Instructors',
                      style: theme.textTheme.headlineLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 32,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Learn from certified professionals and global industry leaders who are actively shaping the future of AI and Web3. Our instructors bring massive real-world experience from top-tier organizations directly to your screen.',
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: Colors.white.withValues(alpha: 0.8),
                        height: 1.6,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 40),
              ElevatedButton.icon(
                onPressed: _showApplicationModal,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: theme.primaryColor,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                icon: Icon(Icons.add_task, size: 20, color: theme.primaryColor),
                label: Text(
                  'Apply to Teach',
                  style: TextStyle(
                      color: theme.primaryColor, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInstructorsGrid(BuildContext context, ThemeData theme) {
    return FutureBuilder<List<InstructorProfile>>(
      future: _instructorsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(60),
              child: CircularProgressIndicator(color: theme.primaryColor),
            ),
          );
        }

        if (snapshot.hasError) {
          return Padding(
            padding: const EdgeInsets.all(60),
            child: Column(
              children: [
                Icon(Icons.wifi_off_rounded, size: 64, color: Colors.grey[400]),
                const SizedBox(height: 16),
                const Text(
                  'Failed to sync instructors from the cloud.',
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        final instructors = snapshot.data ?? [];

        if (instructors.isEmpty) {
          return const Padding(
            padding: const EdgeInsets.all(60),
            child: Text(
                'Coming soon: More elite instructors joining Hosi Academy.'),
          );
        }

        final screenWidth = MediaQuery.of(context).size.width;
        int crossAxisCount = 4;
        if (screenWidth < 600) {
          crossAxisCount = 1;
        } else if (screenWidth < 900) {
          crossAxisCount = 2;
        } else if (screenWidth < 1200) {
          crossAxisCount = 3;
        }

        return Container(
          margin: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: theme.primaryColor.withValues(alpha: 0.3),
              width: 1.5,
            ),
          ),
          child: GridView.builder(
            shrinkWrap: true,
            padding: const EdgeInsets.all(32),
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              mainAxisSpacing: 24,
              crossAxisSpacing: 24,
              childAspectRatio: 0.8,
            ),
            itemCount: instructors.length,
            itemBuilder: (context, index) => _buildInstructorCard(
              context,
              instructors[index],
              theme,
            ),
          ),
        );
      },
    );
  }

  Widget _buildInstructorCard(
    BuildContext context,
    InstructorProfile instructor,
    ThemeData theme,
  ) {
    final isDark = theme.brightness == Brightness.dark;

    return GestureDetector(
      onTap: () => _showInstructorDetail(context, instructor),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: theme.dividerColor.withValues(alpha: 0.1),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: _buildProfileImage(instructor),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              instructor.displayName,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              instructor.headline ?? 'Senior Instructor',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.primaryColor,
                fontWeight: FontWeight.bold,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: theme.primaryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'View Profile',
                style: TextStyle(
                  color: theme.primaryColor,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileImage(InstructorProfile instructor) {
    if (instructor.image != null && instructor.image!.isNotEmpty) {
      String imageUrl = instructor.image!;
      if (!imageUrl.startsWith('http')) {
        imageUrl = '${Environment.apiBaseUrl}$imageUrl';
      }

      return Image.network(
        imageUrl,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        errorBuilder: (context, error, stackTrace) =>
            _buildPlaceholderImage(instructor),
      );
    }
    return _buildPlaceholderImage(instructor);
  }

  Widget _buildPlaceholderImage(InstructorProfile instructor) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.grey[800]!,
            Colors.grey[900]!,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Icon(Icons.person,
            color: Colors.white.withValues(alpha: 0.3), size: 40),
      ),
    );
  }

  Widget _buildFooterCTA(BuildContext context, ThemeData theme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 48),
      decoration: BoxDecoration(
        color: theme.cardColor.withValues(alpha: 0.5),
        border: Border(
          top: BorderSide(
            color: theme.dividerColor.withValues(alpha: 0.1),
          ),
        ),
      ),
      child: Column(
        children: [
          Text(
            'Bring Your Expertise to Hosi Academy',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Are you a certified professional or industry expert passionate about teaching? Join our elite global faculty and help shape the next generation of technologists.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _showApplicationModal,
            icon: const Icon(Icons.school),
            label: const Text('Become an Instructor'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showInstructorDetail(
    BuildContext context,
    InstructorProfile instructor,
  ) {
    showDialog(
      context: context,
      builder: (context) => _InstructorDetailDialog(instructor: instructor),
    );
  }
}

class _InstructorDetailDialog extends StatelessWidget {
  final InstructorProfile instructor;

  const _InstructorDetailDialog({required this.instructor});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 800),
        width: MediaQuery.of(context).size.width * 0.9,
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(24),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Stack(
                children: [
                  Container(
                    height: 300,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius:
                          const BorderRadius.vertical(top: Radius.circular(24)),
                      color: Colors.grey[900],
                    ),
                    child: _buildProfileImage(instructor),
                  ),
                  Positioned(
                    top: 16,
                    right: 16,
                    child: IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close, color: Colors.white),
                      style:
                          IconButton.styleFrom(backgroundColor: Colors.black26),
                    ),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.all(40),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      instructor.displayName,
                      style: theme.textTheme.headlineMedium
                          ?.copyWith(fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      instructor.headline ?? 'Instructor',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: theme.primaryColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Divider(),
                    const SizedBox(height: 24),
                    Text(
                      'About',
                      style: theme.textTheme.titleLarge
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      instructor.bio ?? 'Biographical information coming soon.',
                      style: theme.textTheme.bodyLarge
                          ?.copyWith(height: 1.6, color: Colors.grey),
                    ),
                    const SizedBox(height: 32),
                    if (instructor.expertise.isNotEmpty) ...[
                      Text(
                        'Expertise',
                        style: theme.textTheme.titleLarge
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 16),
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: instructor.expertise
                            .map((tag) => Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: theme.primaryColor
                                        .withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                        color: theme.primaryColor
                                            .withValues(alpha: 0.2)),
                                  ),
                                  child: Text(
                                    tag,
                                    style: TextStyle(
                                        color: theme.primaryColor,
                                        fontWeight: FontWeight.bold),
                                  ),
                                ))
                            .toList(),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileImage(InstructorProfile instructor) {
    if (instructor.image != null && instructor.image!.isNotEmpty) {
      String imageUrl = instructor.image!;
      if (!imageUrl.startsWith('http')) {
        imageUrl = '${Environment.apiBaseUrl}$imageUrl';
      }

      return Image.network(
        imageUrl,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        errorBuilder: (context, error, stackTrace) =>
            _buildPlaceholderImage(instructor),
      );
    }
    return _buildPlaceholderImage(instructor);
  }

  Widget _buildPlaceholderImage(InstructorProfile instructor) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.grey[800]!,
            Colors.grey[900]!,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: const Center(
        child: Icon(Icons.person, color: Colors.white, size: 80),
      ),
    );
  }
}

class InstructorProfile {
  final int id;
  final String displayName;
  final String? headline;
  final String? bio;
  final String? image;
  final String? location;
  final List<String> expertise;

  InstructorProfile({
    required this.id,
    required this.displayName,
    this.headline,
    this.bio,
    this.image,
    this.location,
    this.expertise = const [],
  });

  factory InstructorProfile.fromJson(Map<String, dynamic> json) {
    final expertise = <String>[];

    // Mix interests and specialization for expertise tags
    final rawExpertise = [
      json['interests'],
      json['specialization'],
    ].where((e) => e != null && e.toString().isNotEmpty).join(', ');

    if (rawExpertise.isNotEmpty) {
      expertise.addAll(rawExpertise
          .split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toSet()
          .toList());
    }

    // Handle nested user object from PublicFacilitatorSerializer
    final user = json['user'] as Map<String, dynamic>? ?? {};

    return InstructorProfile(
      id: json['id'] ?? 0,
      displayName:
          user['name'] ?? user['username'] ?? json['name'] ?? 'Instructor',
      headline: user['headline'] ?? json['headline'],
      bio: user['about'] ?? user['short_details'] ?? json['bio'],
      image: user['image_url'] ??
          user['image'] ??
          user['avatar'] ??
          user['photo'] ??
          json['image'],
      location: user['location_string'] ??
          json['location'] ??
          (user['city'] != null
              ? "${user['city']}, ${user['country'] ?? ''}"
              : null),
      expertise: expertise,
    );
  }
}
