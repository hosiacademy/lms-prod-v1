import glob, re, os

print("Searching for AfricaContacts...")
found_snippets = []

for f in glob.glob('/root/.claude/debug/*.txt'):
    try:
        with open(f, 'r') as file:
            content = file.read()
            if 'AfricaContacts' in content:
                print(f"Found mention in {f}")
                
                # Match dart code blocks
                blocks = re.findall(r'```dart(.*?)```', content, re.DOTALL)
                for b in blocks:
                    if 'AfricaContacts' in b:
                        # Unescape if it's JSON encoded
                        b_unescaped = b.encode('utf-8').decode('unicode_escape')
                        found_snippets.append(b_unescaped)
                
                # Match cat << EOF blocks inside the JSON commands
                cat_commands = re.findall(r'cat >.*?<< \\*[\'"]?EOF\\*[\'"]?.*?(.*?)EOF', content, re.DOTALL)
                for c in cat_commands:
                    if 'AfricaContacts' in c:
                        c_unescaped = c.encode('utf-8').decode('unicode_escape')
                        found_snippets.append(c_unescaped)

    except Exception as e:
        print(f"Error reading {f}: {e}")

if not found_snippets:
    print("No snippets found. Let's try raw unescaping the whole file...")
    for f in glob.glob('/root/.claude/debug/*.txt'):
        try:
            with open(f, 'r') as file:
                content = file.read()
                if 'AfricaContacts' in content:
                    # The file might just contain escaped JSON of bash commands or file writes
                    idx = content.find('AfricaContacts')
                    # Extract 4000 chars around it
                    start = max(0, idx - 1000)
                    end = min(len(content), idx + 3000)
                    snippet = content[start:end]
                    # Print raw snippet after unescaping
                    print(f"\n--- Raw context from {f} ---")
                    try:
                        print(snippet.encode('utf-8').decode('unicode_escape'))
                    except:
                        print(snippet)
        except Exception as e:
            pass
else:
    for idx, snippet in enumerate(found_snippets):
        print(f"\n--- Snippet {idx} ---")
        lines = snippet.split('\\n')
        if len(lines) < 2:
             lines = snippet.split('\n')
        print('\n'.join(lines[:100]))
