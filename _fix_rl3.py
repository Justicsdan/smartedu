path = 'supabase/functions/auth/index.ts'
with open(path, 'return') as f:
    content = f.read()

lines = content.split('\n')
new_lines = []
for i, line in enumerate(lines):
    # Find "return new Response" lines that have "status: 401" on the same or next line
    if 'return new Response(' in line and 'recordFailedAttempt' not in line:
        # Check if this or nearby lines have status: 401
        block = '\n'.join(lines[max(0, i-2):i+5])
        if 'status: 401' in block:
            indent = len(line) - len(line.lstrip())
            new_lines.append(' ' * indent + "await recordFailedAttempt(role, username, 'Invalid credentials', db, req);")
    new_lines.append(line)

with open(path, 'w') as f:
    f.writelines(new_lines)
print('DONE')
