#!/usr/bin/env python3
"""
Comprehensive fix for all remaining FluidSize issues.
Handles multi-line method signatures, const removal, etc.
"""
import os
import re

ONBOARDING_DIR = "/home/tk/lms-prod/frontend/lib/src/presentation/pages/onboarding"

def fix_file(filepath):
    try:
        with open(filepath, 'r', encoding='utf-8', errors='replace') as f:
            content = f.read()
    except:
        return False

    original = content

    # Step 1: Add `final fs = context.fs;` to ALL methods that use `context` and have BuildContext parameter
    # This handles multi-line method signatures
    lines = content.split('\n')
    result = []
    i = 0
    while i < len(lines):
        line = lines[i]
        result.append(line)

        # Look for method declarations that have BuildContext context parameter
        # Could be single-line or multi-line
        # Check if this line or accumulated lines contain a method with BuildContext context

        # Accumulate lines until we find the opening brace
        if re.match(r'^\s*(?:void|Widget|Future|String|int|bool|double|List|StatelessWidget|State<\w+>|static\s+\w+)\s+', line) or \
           (i > 0 and result and re.match(r'^\s*(?:void|Widget|Future|String|int|bool|double|List|State<\w+>|static\s+\w+|\))', line)):

            # Check if we have BuildContext context in accumulated lines
            accumulated = '\n'.join(result[-10:])  # Look at last 10 lines
            if 'BuildContext context' in accumulated and 'Widget build(BuildContext context)' not in accumulated:
                # Check if this line has the opening brace
                if '{' in line:
                    indent = re.match(r'^(\s*)', line).group(1)

                    # Check if fs is already declared
                    fs_exists = False
                    for j in range(i + 1, min(i + 6, len(lines))):
                        if 'final fs = context.fs;' in lines[j]:
                            fs_exists = True
                            break
                        if lines[j].strip().startswith('}') and '(' not in lines[j]:
                            break

                    if not fs_exists:
                        result.append(f'{indent}  final fs = context.fs;')

        i += 1

    content = '\n'.join(result)

    # Step 2: Remove const from lines that have both const and fs.
    lines = content.split('\n')
    result = []
    for line in lines:
        if re.search(r'\bconst\b', line) and 'fs.' in line:
            line = re.sub(r'\bconst\s+', '', line, count=1)
        result.append(line)
    content = '\n'.join(result)

    # Step 3: Remove const from multi-line widget constructors that use fs.
    lines = content.split('\n')
    result = []
    i = 0
    while i < len(lines):
        line = lines[i]
        # Check for const widget constructor
        const_match = re.match(r'^(\s*)const\s+(\w+)\(', line)
        if const_match:
            indent = const_match.group(1)
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
                widget_lines[0] = re.sub(r'\bconst\s+', '', widget_lines[0], count=1)

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
