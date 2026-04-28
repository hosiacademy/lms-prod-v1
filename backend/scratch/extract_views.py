import json

log_line_file = r'C:\lms-prod\backend\scratch\full_views_restore.txt'
output_file = r'C:\lms-prod\backend\scratch\views_restoration_code.txt'

with open(log_line_file, 'r', encoding='utf-8-sig') as f:
    log_data = json.load(f)

# The args might be a string or a dict depending on how it was logged
args = log_data['tool_calls'][0]['args']
if isinstance(args, str):
    args = json.loads(args)

chunks = args['ReplacementChunks']
# Print type for debugging
print(f"Type of chunks: {type(chunks)}")
if isinstance(chunks, str):
    print(f"Chunks starts with: {chunks[:50]}")
    try:
        chunks = json.loads(chunks)
    except Exception as e:
        print(f"Failed to load chunks as JSON: {e}")
        # If it's a string representation of a list, maybe eval? (Safe since it's our log)
        # But let's try to fix the string first.
        import ast
        chunks = ast.literal_eval(chunks)

with open(output_file, 'w', encoding='utf-8') as f:
    for i, chunk in enumerate(chunks):
        f.write(f"--- CHUNK {i} ---\n")
        f.write(chunk['ReplacementContent'])
        f.write("\n")
