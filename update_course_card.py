import sys
import re

file_path = r'c:\lms-prod\frontend\lib\src\presentation\pages\industry_training\industry_training_enrollment_page.dart'

with open(file_path, 'r', encoding='utf-8') as f:
    content = f.read()

content = content.replace(
'''    return Card(
      elevation: 4,
      shadowColor: colors.shadow.withValues(alpha: 0.1),
      color: colors.surface,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(
          color: colors.primary.withValues(alpha: 0.1),
          width: 1.5,
        ),
      ),''',
'''    return Card(
      elevation: 8,
      shadowColor: colors.primary.withValues(alpha: 0.15),
      color: colors.surface,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: colors.primary.withValues(alpha: 0.15),
          width: 1.0,
        ),
      ),'''
)

content = content.replace(
'''                      IconButton(
                        onPressed: _toggleZoom,
                        icon: Icon(
                          _fontScale == 1.0 ? Icons.zoom_in : Icons.zoom_out,
                          size: 20,
                          color: colors.primary,
                        ),''',
'''                      IconButton(
                        onPressed: _toggleZoom,
                        icon: Icon(
                          _fontScale == 1.0 ? Icons.zoom_in_rounded : Icons.zoom_out_rounded,
                          size: 20,
                          color: colors.primary,
                        ),'''
)

content = content.replace(
'''                        child: SingleChildScrollView(
                          controller: _scrollController,
                          child: Text(
                            widget.course.description ?? 'No description available.',
                            style: theme.textTheme.bodySmall?.copyWith(
                              height: 1.4,
                              fontSize: (theme.textTheme.bodySmall?.fontSize ?? 12) * _fontScale,
                              color: colors.onSurfaceVariant,
                            ),
                          ),
                        ),''',
'''                        child: SingleChildScrollView(
                          controller: _scrollController,
                          child: AnimatedDefaultTextStyle(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                            style: theme.textTheme.bodySmall!.copyWith(
                              height: 1.5,
                              fontSize: (theme.textTheme.bodySmall?.fontSize ?? 12) * _fontScale,
                              color: colors.onSurfaceVariant,
                            ),
                            child: Text(
                              widget.course.description ?? 'No description available.',
                            ),
                          ),
                        ),'''
)

with open(file_path, 'w', encoding='utf-8') as f:
    f.write(content)

print('File updated successfully.')
