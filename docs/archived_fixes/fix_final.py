#!/usr/bin/env python3
"""
Final comprehensive fix for all remaining FluidSize issues.
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

    # Step 1: Find all method declarations with BuildContext context parameter
    # and add `final fs = context.fs;` after the opening brace
    # Handle both single-line and multi-line signatures

    # Strategy: Find patterns like:
    #   Widget _buildXxx(...BuildContext context...) {
    #   void _showXxx(BuildContext context) {
    # etc.

    # Use a state machine approach
    lines = content.split('\n')
    result = []
    i = 0

    while i < len(lines):
        line = lines[i]
        result.append(line)

        # Check if we're starting a method declaration
        # Look for return types followed by method names
        is_method_start = bool(re.match(
            r'^\s*(?:static\s+)?(?:void|Widget|Future[\w<>\[\],\s]*|String|int|bool|double|List[\w<>\[\],\s]*|StatelessWidget|State<\w+>|T)\s+\w+\s*\(',
            line
        ))

        if is_method_start:
            # Accumulate lines until we find opening brace
            method_lines = [line]
            has_build_context = 'BuildContext context' in line
            j = i + 1

            while j < len(lines) and '{' not in lines[j-1]:
                method_lines.append(lines[j])
                if 'BuildContext context' in lines[j]:
                    has_build_context = True
                # Safety: stop if we hit something that's clearly not part of the signature
                if j > i + 10:  # Max 10 lines for signature
                    break
                j += 1

            # Check if this is a method with BuildContext context (but not the main build method)
            if has_build_context:
                full_method = '\n'.join(method_lines)
                if 'Widget build(BuildContext context)' not in full_method:
                    # Find the line with opening brace
                    brace_idx = -1
                    for idx, ml in enumerate(method_lines):
                        if '{' in ml:
                            brace_idx = idx
                            break

                    if brace_idx >= 0:
                        brace_line = method_lines[brace_idx]
                        indent = re.match(r'^(\s*)', brace_line).group(1)

                        # Check if fs already exists after this
                        fs_exists = False
                        check_start = i + brace_idx + 1
                        for k in range(check_start, min(check_start + 5, len(lines))):
                            if 'final fs = context.fs;' in lines[k]:
                                fs_exists = True
                                break
                            if lines[k].strip() == '}':
                                break

                        if not fs_exists:
                            # Add fs declaration after the brace line
                            result.extend(method_lines[1:brace_idx+1])
                            result.append(f'{indent}  final fs = context.fs;')
                            i = i + brace_idx
                        else:
                            result.extend(method_lines[1:])
                            i = i + len(method_lines) - 1
                    else:
                        result.extend(method_lines[1:])
                        i = i + len(method_lines) - 1
                else:
                    result.extend(method_lines[1:])
                    i = i + len(method_lines) - 1
            else:
                result.extend(method_lines[1:])
                i = i + len(method_lines) - 1

        i += 1

    content = '\n'.join(result)

    # Step 2: Remove const from ALL lines that have fs.
    lines = content.split('\n')
    result = []
    for line in lines:
        if re.search(r'\bconst\b', line) and 'fs.' in line:
            line = re.sub(r'\bconst\s+', '', line, count=1)
        result.append(line)
    content = '\n'.join(result)

    # Step 3: Remove const from multi-line widget constructors containing fs.
    lines = content.split('\n')
    result = []
    i = 0
    while i < len(lines):
        line = lines[i]
        const_match = re.match(r'^(\s*)const\s+(\w+)\(', line)
        if const_match:
            indent = const_match.group(1)
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
                    import traceback
                    print(f"ERROR: {fpath}: {e}")
                    traceback.print_exc()

    print(f"\nTotal files fixed: {len(modified)}")

if __name__ == '__main__':
    main()
