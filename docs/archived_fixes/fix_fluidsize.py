#!/usr/bin/env python3
"""
Fix remaining FluidSize issues:
1. Add `final fs = context.fs;` to ALL methods that take BuildContext context as parameter
2. Remove const from widgets using fs. methods
3. Fix helper methods that use fs but don't have context in scope
"""
import os
import re

ONBOARDING_DIR = "/home/tk/lms-prod/frontend/lib/src/presentation/pages/onboarding"

def fix_file(filepath):
    with open(filepath, 'r', encoding='utf-8', errors='replace') as f:
        content = f.read()

    original = content

    # 1. Add `final fs = context.fs;` to methods that take BuildContext but don't have fs
    # Pattern: any method with BuildContext context parameter
    # We need to find method signatures like:
    #   void _showXxx(BuildContext context) {
    #   Widget _buildXxx(BuildContext context, ...) {
    #   Widget _buildXxx(..., BuildContext context, ...) {

    lines = content.split('\n')
    result_lines = []
    i = 0
    while i < len(lines):
        line = lines[i]
        result_lines.append(line)

        # Check if this line is a method declaration with BuildContext context parameter
        # Match patterns like:
        #   void _showComingSoonModal(BuildContext context) {
        #   Widget _buildXxx(BuildContext context, ...) {
        #   Widget _buildXxx(..., BuildContext context) {
        # But NOT Widget build(BuildContext context) { which is already handled
        # And NOT methods that already have `final fs = context.fs;`

        # Check for method with BuildContext context
        ctx_match = re.search(r'\bBuildContext\s+context\b', line)
        if ctx_match and 'Widget build(BuildContext context)' not in line:
            # Check if this looks like a method declaration (has return type or is void)
            method_match = re.match(r'^\s*(?:void|Widget|Future[\w<>\[\],\s]*|String|int|bool|double|List[\w<>\[\],\s]*|StatelessWidget|State<\w+>)\s+', line)
            if method_match:
                indent = re.match(r'^(\s*)', line).group(1)

                # Check if opening brace is on this line
                has_brace = '{' in line

                # Check if fs is already declared in next few lines
                fs_exists = False
                for j in range(i + 1, min(i + 6, len(lines))):
                    if 'final fs = context.fs;' in lines[j]:
                        fs_exists = True
                        break
                    stripped = lines[j].strip()
                    if stripped.startswith('@override') or stripped.startswith('class '):
                        break
                    if stripped == '}':
                        break

                if not fs_exists:
                    result_lines.append(f'{indent}  final fs = context.fs;')

        i += 1

    content = '\n'.join(result_lines)

    # 2. Remove const from single-line widgets that use fs.
    lines = content.split('\n')
    result = []
    for line in lines:
        if 'const' in line and 'fs.' in line:
            # Remove the first 'const ' occurrence
            line = re.sub(r'\bconst\s+', '', line, count=1)
        result.append(line)
    content = '\n'.join(result)

    # 3. Remove const from multi-line widgets that use fs.
    lines = content.split('\n')
    result = []
    i = 0
    while i < len(lines):
        line = lines[i]
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
                widget_lines[0] = widget_lines[0].replace('const ', '', 1)

            result.extend(widget_lines)
            i = j
        else:
            result.append(line)
            i += 1

    content = '\n'.join(result)

    if content != original:
        with open(filepath, 'w', encoding='utf-8') as f:
            f.write(content)
        return True
    return False

def main():
    modified = []
    for root, dirs, files in os.walk(ONBOARDING_DIR):
        for fname in sorted(files):
            if fname.endswith('.dart'):
                fpath = os.path.join(root, fname)
                try:
                    if fix_file(fpath):
                        modified.append(fpath)
                        print(f"Fixed: {fpath}")
                except Exception as e:
                    print(f"ERROR: {fpath}: {e}")

    print(f"\nTotal files fixed: {len(modified)}")

if __name__ == '__main__':
    main()
