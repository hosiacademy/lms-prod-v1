#!/usr/bin/env python3
"""
Apply FluidSize transformations to all Dart files in the onboarding directory.
This script handles the transformations carefully, preserving logic and only replacing
hardcoded pixel values with fs. equivalents.
"""
import os
import re

ONBOARDING_DIR = "/home/tk/lms-prod/frontend/lib/src/presentation/pages/onboarding"

def add_fs_to_methods(content):
    """Add `final fs = context.fs;` to Widget build and _build methods."""
    lines = content.split('\n')
    result = []
    i = 0
    while i < len(lines):
        line = lines[i]
        result.append(line)

        # Check if this line declares a Widget build or _build method
        # Patterns:
        #   Widget build(BuildContext context) {
        #   Widget _buildSomething(...) {
        #   Widget _buildSomething(...)
        #   {
        match = re.match(r'^(\s*)(Widget\s+(?:build|_build\w+)\s*\([^)]*\)\s*)\{?\s*$', line)
        if match:
            indent = match.group(1)
            # Check if opening brace is on this line or next
            has_brace_on_this_line = '{' in line

            if not has_brace_on_this_line:
                # Opening brace should be on next line
                i += 1
                if i < len(lines):
                    result.append(lines[i])
                    # Check if next line after brace already has fs
                    next_i = i + 1
                else:
                    next_i = i

                # Check if fs already exists in next few lines
                fs_exists = False
                for j in range(next_i, min(next_i + 5, len(lines))):
                    if 'final fs = context.fs;' in lines[j]:
                        fs_exists = True
                        break
                    # Stop at certain boundaries
                    stripped = lines[j].strip()
                    if stripped.startswith('@override') or stripped.startswith('class ') or (stripped.startswith('Widget ') and '(' in stripped):
                        break

                if not fs_exists:
                    result.append(f'{indent}  final fs = context.fs;')
            else:
                # Brace on this line, check next lines for fs
                fs_exists = False
                for j in range(i + 1, min(i + 5, len(lines))):
                    if 'final fs = context.fs;' in lines[j]:
                        fs_exists = True
                        break
                    stripped = lines[j].strip()
                    if stripped.startswith('@override') or stripped.startswith('class ') or (stripped.startswith('Widget ') and '(' in stripped and '{' not in stripped):
                        break
                    if stripped == '}':
                        break

                if not fs_exists:
                    result.append(f'{indent}  final fs = context.fs;')
        i += 1

    return '\n'.join(result)

def replace_dimensions(content):
    """Replace hardcoded dimensions with fs. methods."""

    # EdgeInsets patterns - order matters (more specific first)
    # EdgeInsets.symmetric(horizontal: H, vertical: V) → fs.eHV(H, V)
    content = re.sub(
        r'const\s+EdgeInsets\.symmetric\(horizontal:\s*(\d+\.?\d*),\s*vertical:\s*(\d+\.?\d*)\)',
        r'fs.eHV(\1, \2)', content)
    content = re.sub(
        r'const\s+EdgeInsets\.symmetric\(vertical:\s*(\d+\.?\d*),\s*horizontal:\s*(\d+\.?\d*)\)',
        r'fs.eHV(\2, \1)', content)
    content = re.sub(
        r'EdgeInsets\.symmetric\(horizontal:\s*(\d+\.?\d*),\s*vertical:\s*(\d+\.?\d*)\)',
        r'fs.eHV(\1, \2)', content)

    # EdgeInsets.symmetric(horizontal: N) → fs.eH(N)
    content = re.sub(
        r'const\s+EdgeInsets\.symmetric\(horizontal:\s*(\d+\.?\d*)\)',
        r'fs.eH(\1)', content)
    content = re.sub(
        r'EdgeInsets\.symmetric\(horizontal:\s*(\d+\.?\d*)\)',
        r'fs.eH(\1)', content)

    # EdgeInsets.symmetric(vertical: N) → fs.eV(N)
    content = re.sub(
        r'const\s+EdgeInsets\.symmetric\(vertical:\s*(\d+\.?\d*)\)',
        r'fs.eV(\1)', content)
    content = re.sub(
        r'EdgeInsets\.symmetric\(vertical:\s*(\d+\.?\d*)\)',
        r'fs.eV(\1)', content)

    # EdgeInsets.fromLTRB(L, T, R, B) → fs.eLTRB(L, T, R, B)
    content = re.sub(
        r'const\s+EdgeInsets\.fromLTRB\((\d+\.?\d*),\s*(\d+\.?\d*),\s*(\d+\.?\d*),\s*(\d+\.?\d*)\)',
        r'fs.eLTRB(\1, \2, \3, \4)', content)
    content = re.sub(
        r'EdgeInsets\.fromLTRB\((\d+\.?\d*),\s*(\d+\.?\d*),\s*(\d+\.?\d*),\s*(\d+\.?\d*)\)',
        r'fs.eLTRB(\1, \2, \3, \4)', content)

    # EdgeInsets.only(bottom: N) → fs.eO(bottom: N)
    content = re.sub(
        r'const\s+EdgeInsets\.only\(bottom:\s*(\d+\.?\d*)\)',
        r'fs.eO(bottom: \1)', content)
    content = re.sub(
        r'EdgeInsets\.only\(bottom:\s*(\d+\.?\d*)\)',
        r'fs.eO(bottom: \1)', content)

    # EdgeInsets.only(top: N) → fs.eO(top: N)
    content = re.sub(
        r'const\s+EdgeInsets\.only\(top:\s*(\d+\.?\d*)\)',
        r'fs.eO(top: \1)', content)

    # EdgeInsets.only(left: N) → fs.eO(left: N)
    content = re.sub(
        r'const\s+EdgeInsets\.only\(left:\s*(\d+\.?\d*)\)',
        r'fs.eO(left: \1)', content)

    # EdgeInsets.only(right: N) → fs.eO(right: N)
    content = re.sub(
        r'const\s+EdgeInsets\.only\(right:\s*(\d+\.?\d*)\)',
        r'fs.eO(right: \1)', content)

    # EdgeInsets.only with multiple values - handle common patterns
    # EdgeInsets.only(left: N, right: N) → fs.eH(N) if same
    content = re.sub(
        r'const\s+EdgeInsets\.only\(left:\s*(\d+\.?\d*),\s*right:\s*\1\)',
        r'fs.eH(\1)', content)
    # EdgeInsets.only(top: N, bottom: N) → fs.eV(N) if same
    content = re.sub(
        r'const\s+EdgeInsets\.only\(top:\s*(\d+\.?\d*),\s*bottom:\s*\1\)',
        r'fs.eV(\1)', content)

    # EdgeInsets.all(N) → fs.e(all: N)
    content = re.sub(
        r'const\s+EdgeInsets\.all\((\d+\.?\d*)\)',
        r'fs.e(all: \1)', content)
    content = re.sub(
        r'EdgeInsets\.all\((\d+\.?\d*)\)',
        r'fs.e(all: \1)', content)

    # BorderRadius.circular(N) → BorderRadius.circular(fs.r(N))
    content = re.sub(
        r'BorderRadius\.circular\((\d+\.?\d*)\)',
        r'BorderRadius.circular(fs.r(\1))', content)

    # Radius.circular(N) → Radius.circular(fs.r(N))
    content = re.sub(
        r'Radius\.circular\((\d+\.?\d*)\)',
        r'Radius.circular(fs.r(\1))', content)

    # fontSize: N → fontSize: fs.f(N)
    content = re.sub(
        r'fontSize:\s*(\d+\.?\d*)(?![\w.])',
        r'fontSize: fs.f(\1)', content)

    # Icon size: N → size: fs.i(N) - only within Icon context
    # This is tricky, we'll handle Icon(..., size: N) patterns
    content = re.sub(
        r'(Icon\([^)]*?)size:\s*(\d+\.?\d*)',
        r'\1size: fs.i(\2)', content)

    # blurRadius: N → blurRadius: fs.b(N)
    content = re.sub(
        r'blurRadius:\s*(\d+\.?\d*)',
        r'blurRadius: fs.b(\1)', content)

    # strokeWidth: N → strokeWidth: fs.s(N)
    content = re.sub(
        r'strokeWidth:\s*(\d+\.?\d*)',
        r'strokeWidth: fs.s(\1)', content)

    # const SizedBox(height: N) → SizedBox(height: fs.h(N))
    content = re.sub(
        r'const\s+SizedBox\(height:\s*(\d+\.?\d*)\)',
        r'SizedBox(height: fs.h(\1))', content)
    content = re.sub(
        r'const\s+SizedBox\(width:\s*(\d+\.?\d*)\)',
        r'SizedBox(width: fs.w(\1))', content)

    # SizedBox(height: N) → SizedBox(height: fs.h(N)) - non-const
    content = re.sub(
        r'(?<!const\s)SizedBox\(height:\s*(\d+\.?\d*)\)',
        r'SizedBox(height: fs.h(\1))', content)
    content = re.sub(
        r'(?<!const\s)SizedBox\(width:\s*(\d+\.?\d*)\)',
        r'SizedBox(width: fs.w(\1))', content)

    # spacing: N → spacing: fs.g(N)
    content = re.sub(
        r'spacing:\s*(\d+\.?\d*)(?![\w.])',
        r'spacing: fs.g(\1)', content)

    # runSpacing: N → runSpacing: fs.g(N)
    content = re.sub(
        r'runSpacing:\s*(\d+\.?\d*)(?![\w.])',
        r'runSpacing: fs.g(\1)', content)

    # width: N → width: fs.w(N) - careful with non-numeric
    content = re.sub(
        r'(?<![.\w])width:\s*(\d+\.?\d*)(?![\w.])',
        r'width: fs.w(\1)', content)

    # height: N → height: fs.h(N) - careful with non-numeric
    content = re.sub(
        r'(?<![.\w])height:\s*(\d+\.?\d*)(?![\w.])',
        r'height: fs.h(\1)', content)

    return content

def remove_const_from_fs_widgets(content):
    """Remove const from widgets that use fs. methods."""
    lines = content.split('\n')
    result = []

    i = 0
    while i < len(lines):
        line = lines[i]

        # Check if this line has 'const' and a widget constructor
        const_match = re.match(r'^(\s*)const\s+(\w+)\(', line)
        if const_match:
            indent = const_match.group(1)
            widget_name = const_match.group(2)

            # Collect all lines of this widget
            widget_lines = [line]
            j = i + 1
            paren_depth = line.count('(') - line.count(')')
            has_fs = 'fs.' in line

            while j < len(lines) and paren_depth > 0:
                widget_lines.append(lines[j])
                if 'fs.' in lines[j]:
                    has_fs = True
                paren_depth += lines[j].count('(') - lines[j].count(')')
                j += 1

            if has_fs:
                # Remove const from the first line
                widget_lines[0] = widget_lines[0].replace('const ', '', 1)

            result.extend(widget_lines)
            i = j
        else:
            # Also handle single-line const widgets with fs.
            if 'const' in line and 'fs.' in line:
                line = re.sub(r'\bconst\s+', '', line, count=1)
            result.append(line)
            i += 1

    return '\n'.join(result)

def process_file(filepath):
    """Process a single Dart file."""
    with open(filepath, 'r') as f:
        original = f.read()

    content = original

    # Step 1: Add fs declarations to build methods
    content = add_fs_to_methods(content)

    # Step 2: Replace dimensions
    content = replace_dimensions(content)

    # Step 3: Remove const from widgets using fs.
    content = remove_const_from_fs_widgets(content)

    if content != original:
        with open(filepath, 'w') as f:
            f.write(content)
        return True
    return False

def main():
    modified_files = []
    skipped_files = []

    for root, dirs, files in os.walk(ONBOARDING_DIR):
        for fname in sorted(files):
            if fname.endswith('.dart'):
                fpath = os.path.join(root, fname)
                try:
                    if process_file(fpath):
                        modified_files.append(fpath)
                        print(f"Modified: {fpath}")
                    else:
                        skipped_files.append(fpath)
                except Exception as e:
                    print(f"ERROR processing {fpath}: {e}")

    print(f"\n{'='*60}")
    print(f"Total files modified: {len(modified_files)}")
    print(f"Total files skipped (no changes needed): {len(skipped_files)}")
    print(f"{'='*60}")
    for f in modified_files:
        print(f"  ✓ {f}")

if __name__ == '__main__':
    main()
