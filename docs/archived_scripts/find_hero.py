import glob, re

found_snippets = []
for f in glob.glob('/root/.claude/debug/*.txt'):
    try:
        with open(f, 'r') as file:
            content = file.read()
            if 'class HeroSection' in content or 'hero_section.dart' in content:
                print(f"Found mention in {f}")
                blocks = re.findall(r'```dart(.*?)```', content, re.DOTALL)
                for b in blocks:
                    if 'class HeroSection' in b:
                        found_snippets.append(b.encode('utf-8').decode('unicode_escape'))
                
                cat_commands = re.findall(r'cat >.*?<< \\*[\'"]?EOF\\*[\'"]?.*?(.*?)EOF', content, re.DOTALL)
                for c in cat_commands:
                    if 'class HeroSection' in c:
                        found_snippets.append(c.encode('utf-8').decode('unicode_escape'))
    except Exception as e:
        pass

for idx, snippet in enumerate(found_snippets):
    print(f"\n--- Snippet {idx} ---")
    lines = snippet.split('\n')
    print('\n'.join(lines[:50]))
