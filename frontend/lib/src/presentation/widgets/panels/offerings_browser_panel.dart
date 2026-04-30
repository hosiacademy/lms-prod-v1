import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/api/api_client.dart';
import '../../../data/models/course.dart';
import '../../../data/models/masterclass.dart';
import '../../../data/models/learnership.dart';
import 'package:provider/provider.dart';
import '../../../core/providers/cart_provider.dart';
import '../../../core/services/currency_service.dart';
import '../modals/marketing/wishlist_lead_modal.dart';
import '../../blocs/student_portal/wishlist_bloc.dart';

/// A premium browser for the 4 enrollment pathways and their offerings.
/// Designed for use within SlideInPanels.
class OfferingsBrowserPanel extends StatefulWidget {
  final String? initialPathway;

  const OfferingsBrowserPanel({
    super.key,
    this.initialPathway,
  });

  @override
  State<OfferingsBrowserPanel> createState() => _OfferingsBrowserPanelState();
}

class _OfferingsBrowserPanelState extends State<OfferingsBrowserPanel> {
  String? _selectedPathway; // 'corporate', 'learnerships', 'industry', 'custom'
  bool _isLoading = false;
  List<dynamic> _offerings = [];
  String? _error;

  @override
  void initState() {
    super.initState();
    if (widget.initialPathway != null) {
      _selectPathway(widget.initialPathway!);
    }
  }

  Future<void> _selectPathway(String pathway) async {
    setState(() {
      _selectedPathway = pathway;
      _isLoading = true;
      _error = null;
      _offerings = [];
    });

    try {
      switch (pathway) {
        case 'corporate':
          final masterclasses = await ApiClient.getMasterclasses();
          _offerings = masterclasses;
          break;
        case 'learnerships':
          final learnerships = await ApiClient.getLearnerships();
          _offerings = learnerships;
          break;
        case 'industry':
          final courses = await ApiClient.getIndustryTraining();
          _offerings = courses;
          break;
        case 'custom':
          // For custom, we'll fetch general courses or use another method
          final courses =
              await ApiClient.getIndustryTraining(); // Fallback for now
          _offerings = courses;
          break;
        case 'trainers':
          final instructors = await ApiClient.getPublicInstructors();
          _offerings = instructors;
          break;
      }
    } catch (e) {
      _error = "Failed to load offerings. Please try again.";
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(theme, colors),
          const SizedBox(height: 24),
          Expanded(
            child: _selectedPathway == null
                ? _buildPathwaySelection(theme, colors)
                : _buildOfferingsView(theme, colors),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(ThemeData theme, ColorScheme colors) {
    if (_selectedPathway == null) {
      return Text(
        'Choose Enrollment Pathway',
        style: theme.textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.bold,
          color: colors.onSurface,
        ),
      );
    }

    return Row(
      children: [
        IconButton(
          onPressed: () => setState(() => _selectedPathway = null),
          icon:
              const Text('Back', style: TextStyle(fontWeight: FontWeight.bold)),
          style: IconButton.styleFrom(
            backgroundColor:
                colors.surfaceContainerHighest.withValues(alpha: 0.5),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          _getPathwayTitle(_selectedPathway!),
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: colors.onSurface,
          ),
        ),
      ],
    );
  }

  String _getPathwayTitle(String pathway) {
    switch (pathway) {
      case 'corporate':
        return 'Corporate Training';
      case 'learnerships':
        return 'Learnerships';
      case 'industry':
        return 'Industry & Role Based';
      case 'custom':
        return 'Custom Selection';
      case 'trainers':
        return 'Expert Trainers';
      default:
        return 'Offerings';
    }
  }

  Widget _buildPathwaySelection(ThemeData theme, ColorScheme colors) {
    final pathways = [
      _PathwayData(
        id: 'corporate',
        title: 'Corporate Training',
        subtitle: 'AI Masterclasses & Executive Programs',
        icon: Icons.business_rounded,
        color: const Color(0xFF7B5A42), // hosiBrown
      ),
      _PathwayData(
        id: 'learnerships',
        title: 'Learnerships',
        subtitle: 'Accredited Programs & Career Pathways',
        icon: Icons.school_rounded,
        color: const Color(0xFF4CAF50), // successGreen
      ),
      _PathwayData(
        id: 'industry',
        title: 'Industry & Role Based',
        subtitle: 'Technical Skills & Certifications',
        icon: Icons.engineering_rounded,
        color: const Color(0xFF172E3D), // hosiMidnight
      ),
      _PathwayData(
        id: 'custom',
        title: 'Custom Selection',
        subtitle: 'Build Your Own Learning Journey',
        icon: Icons.dashboard_customize_rounded,
        color: const Color(0xFFF79150), // hosiPeach
      ),
      _PathwayData(
        id: 'trainers',
        title: 'Expert Trainers',
        subtitle: 'Work with World-Class Instructors',
        icon: Icons.person_rounded,
        color: const Color(0xFFF79150),
      ),
    ];

    return ListView.builder(
      itemCount: pathways.length,
      itemBuilder: (context, index) {
        final path = pathways[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          clipBehavior: Clip.antiAlias,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: InkWell(
            onTap: () => _selectPathway(path.id),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    path.color.withValues(alpha: 0.05),
                    path.color.withValues(alpha: 0.1),
                  ],
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: path.color,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(path.icon, color: Colors.white, size: 32),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          path.title,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: colors.onSurface,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          path.subtitle,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colors.onSurface.withValues(alpha: 0.6),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.chevron_right_rounded, color: colors.primary),
                ],
              ),
            ),
          ),
        ).animate().fadeIn(delay: (index * 100).ms).slideX(begin: 0.1, end: 0);
      },
    );
  }

  Widget _buildOfferingsView(ThemeData theme, ColorScheme colors) {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Loading world-class offerings...'),
          ],
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text(_error!),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => _selectPathway(_selectedPathway!),
              child: const Text('Try Again'),
            ),
          ],
        ),
      );
    }

    if (_offerings.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.sentiment_dissatisfied,
                size: 64, color: colors.onSurface.withValues(alpha: 0.3)),
            const SizedBox(height: 16),
            const Text('No offerings found for this pathway yet.'),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: _offerings.length,
      itemBuilder: (context, index) {
        final item = _offerings[index];

        if (_selectedPathway == 'trainers') {
          return _buildInstructorCard(
              item as Map<String, dynamic>, theme, colors);
        }

        final course = _convertToCourse(item);

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                _buildCourseImage(course, colors),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        course.displayTitle,
                        style: theme.textTheme.titleSmall
                            ?.copyWith(fontWeight: FontWeight.bold),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        course.price != null
                            ? CurrencyService.instance
                                .formatUSDAmount(course.price!)
                            : 'TBD',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colors.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                _buildActionButtons(course, context),
              ],
            ),
          ),
        ).animate().fadeIn(delay: (index * 50).ms);
      },
    );
  }

  Widget _buildInstructorCard(
      Map<String, dynamic> item, ThemeData theme, ColorScheme colors) {
    // Handle nested user object from backend serializer
    final user = item['user'] as Map<String, dynamic>? ?? {};
    final name = user['name'] ?? user['username'] ?? 'Instructor';
    final headline = user['headline'] ?? 'Senior Trainer';
    final specialization = item['specialization'] ?? headline;
    final imageUrl = user['image_url'] ?? user['image'] ?? user['avatar'];

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            _buildCircularImage(imageUrl, colors),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: theme.textTheme.titleSmall
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    specialization,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.chat_bubble_outline),
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Chat with $name coming soon')),
                );
              },
              tooltip: 'Message Instructor',
            ),
          ],
        ),
      ),
    ).animate().fadeIn();
  }

  Widget _buildCircularImage(String? imageUrl, ColorScheme colors) {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        color: colors.surfaceContainerHighest,
        shape: BoxShape.circle,
        border: Border.all(color: colors.outline.withValues(alpha: 0.1)),
      ),
      child: ClipOval(
        child: imageUrl != null && imageUrl.isNotEmpty
            ? Image.network(
                imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) =>
                    const Icon(Icons.person, size: 30),
              )
            : const Icon(Icons.person, size: 30),
      ),
    );
  }

  Widget _buildCourseImage(Course course, ColorScheme colors) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 80,
        height: 60,
        color: colors.surfaceContainerHighest,
        child: course.featureImageUrl != null
            ? Image.network(
                course.featureImageUrl!,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) =>
                    const Icon(Icons.school, size: 24),
              )
            : const Icon(Icons.school, size: 24),
      ),
    );
  }

  Widget _buildActionButtons(Course course, BuildContext context) {
    return Column(
      children: [
        IconButton(
          icon: const Icon(Icons.favorite_border),
          onPressed: () {
            showDialog(
              context: context,
              barrierDismissible: false,
              builder: (context) => WishlistLeadModal(
                course: course,
                onComplete: (interest, timing, notes) {
                  // Add to local wishlist state via bloc if available, or just notify provider
                  try {
                    context.read<WishlistBloc>().add(
                          AddToWishlistEvent(
                            contentTypeId: 1, // Default to course
                            objectId: int.parse(course.id),
                            trainingType: course.courseType ?? 'course',
                            interestLevel: interest,
                            intendedStart: timing,
                            notes: notes,
                          ),
                        );
                  } catch (e) {
                    // Fallback to provider if bloc not in context
                    context.read<CartProvider>().toggleWishlist(course);
                  }
                },
              ),
            );
          },
          tooltip: 'Wishlist',
        ),
        IconButton(
          icon: const Icon(Icons.add_shopping_cart),
          onPressed: () {
            context.read<CartProvider>().addToCart(course);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Added ${course.displayTitle} to cart')),
            );
          },
          tooltip: 'Add to Cart',
        ),
      ],
    );
  }

  Course _convertToCourse(dynamic item) {
    if (item is Course) return item;
    if (item is Masterclass) return item.toCourse();
    if (item is Learnership) return item.toCourse();
    return Course(id: '0', title: 'Unknown');
  }
}

class _PathwayData {
  final String id;
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;

  _PathwayData({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
  });
}
