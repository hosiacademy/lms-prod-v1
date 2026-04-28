import os
import re

def fix_dropdown_value(directory):
    count = 0
    for root, dirs, files in os.walk(directory):
        for file in files:
            if file.endswith(".dart"):
                filepath = os.path.join(root, file)
                with open(filepath, "r", encoding="utf-8") as f:
                    content = f.read()
                
                # Check if file has DropdownButtonFormField
                if "DropdownButtonFormField" not in content:
                    continue
                
                # Pattern to find 'value: something,' inside Dropdown context
                # We assume 'value:' is for the dropdown if found near it, but simpler to just replace 'value:' globally in these files if we are careful?
                # No, 'value:' is common.
                # We need to ensure we are inside DropdownButtonFormField.
                # But since we can't parse easily with regex, let's just look for 'value:' preceded by indentation that suggests parameter.
                # Actually, simpler: replace 'value:' with 'initialValue:' and add key ONLY if it looks like a Dropdown param.
                
                # Revised strategy:
                # 1. Capture indentation.
                # 2. Match 'value: <expr>,'
                # 3. Use 'initialValue' rename.
                # 4. Add 'key'.
                
                # We will apply this to ALL 'value:' assignments in files that contain DropdownButtonFormField.
                # This is risky if the file has other widgets using 'value:'.
                # E.g. Radio, Switch, Checkbox, Slider all use 'value'.
                # DropdownMenuItem uses 'value'.
                
                # Wait! DropdownMenuItem usage:
                # DropdownMenuItem(value: 1, child: ...)
                # If we change this to initialValue, we BREAK it. DropdownMenuItem DOES NOT use initialValue.
                
                # CRITCAL: We MUST NOT change DropdownMenuItem value.
                # Usage: DropdownMenuItem<T>(value: ..., ...)
                
                # So we CANNOT do a global replace.
                # We must match DropdownButtonFormField specifically.
                
                # Let's try to find the specific block.
                # Since I can't write a perfect parser in 2 mins, I will fallback to listing the files and manually applying or using a very strict regex that includes "DropdownButtonFormField".
                
                print(f"Skipping automated replace for {filepath} to safe-guard DropdownMenuItem")
                pass

# I'll effectively cancel this script approach and use `grep` to identify files, then check them one by one or grouping them.
