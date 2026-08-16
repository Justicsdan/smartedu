path = 'supabase/functions/auth/index.ts'
with open(path, 'r') as f:
    lines = f.readlines()

new_lines = []
i = 0
while i < len(lines):
    line = lines[i]
    
    # 1. Insert DB rate limit functions after CORS_HEADERS closing brace
    if line.strip() == "};":
        new_lines.append(line)
        new_lines.append('\n')
        new_lines.append('const MAX_ATTEMPTS = 5;\n')
        new_lines.append('const LOCKOUT_SECONDS = 900;\n')
        new_lines.append('\nasync function checkRateLimit(role: string, username: string, db: any): Promise<{ locked: boolean; remainingSeconds: number }> {\n')
        new_lines.append('  const cutoff = new Date(Date.now() - LOCKOUT_SECONDS * 1000).toISOString();\n')
        new_lines.append('  const { data: countRow, error: countErr } = await db\n')
        new_lines.append('    .from(\'login_history\')\n')
        new_lines.append('    .select(\'created_at\', { count: \'exact\', head: false })\n')
        new_lines.append('    .eq(\'user_type\', role)\n')
        new_lines.append('    .eq(\'username\', username)\n')
        new_lines.append('    .eq(\'is_successful\', false)\n')
        new_lines.append('    .gte(\'created_at\', cutoff)\n')
        new_lines.append('    .limit(1);\n')
        new_lines.append('  if (countErr || !countRow) return { locked: false, remainingSeconds: 0 };\n')
        new_lines.append('  const attempts = parseInt((countRow as any).count) || 0;\n')
        new_lines.append('  if (attempts >= MAX_ATTEMPTS) {\n')
        new_lines.append('    const { data: firstRow, error: firstErr } = await db\n')
        new_lines.append('      .from(\'login_history\')\n')
        new_lines.append('      .select(\'created_at\')\n')
        new_lines.append('      .eq(\'user_type\', role)\n')
        new_lines.append('      .eq(\'username\', username)\n')
        new_lines.append('      .eq(\'is_successful\', false)\n')
        new_lines.append('      .order(\'created_at\', { ascending: true })\n')
        new_lines.append('      .limit(1)\n')
        new_lines.append('      .single();\n')
        new_lines.append('    const firstTime = firstRow?.created_at ? new Date(firstRow.created_at).getTime() : Date.now();\n')
        new_lines.append('    const unlockTime = firstTime + LOCKOUT_SECONDS * 1000;\n')
        new_lines.append('    const remaining = Math.ceil((unlockTime - Date.now()) / 1000);\n')
        new_lines.append('    return { locked: remaining > 0, remainingSeconds: Math.max(0, remaining) };\n')
        new_lines.append('  }\n')
        new_lines.append('  return { locked: false, remainingSeconds: 0 };\n')
        new_lines.append('}\n\n')
        new_lines.append('async function recordFailedAttempt(role: string, username: string, reason: string, db: any, req: Request): Promise<void> {\n')
        new_lines.append('  await db.from(\'login_history\').insert({\n')
        new_lines.append('    school_id: null, user_id: null, user_type: role, username: username,\n')
        new_lines.append('    is_successful: false, failure_reason: reason,\n')
        new_lines.append('    ip_address: req.headers.get(\'x-forwarded-for\') || \'unknown\',\n')
        new_lines.append('    user_agent: req.headers.get(\'user-agent\') || \'unknown\',\n')
        new_lines.append('    created_at: new Date().toISOString(),\n')
        new_lines.append('  });\n')
        new_lines.append('}\n\n')
        new_lines.append('function resetRateLimit(): void { /* DB-backed: no-op */ }\n')
        i += 1
        continue

    # 2. Replace the in-memory check with DB check
    if 'const rl = checkRateLimit(rlKey);' in line:
        line = line.replace(
            'const rl = checkRateLimit(rlKey);',
            'const rl = await checkRateLimit(role, username, db);'
        )
    
    # 3. Replace in-memory recordFailedAttempt with DB version
    if 'recordFailedAttempt(rlKey);' in line:
        line = line.replace(
            'recordFailedAttempt(rlKey);',
            "await recordFailedAttempt(role, username, 'Invalid credentials', db, req);"
        )

    new_lines.append(line)
    i += 1

with open(path, 'w') as f:
    f.writelines(new_lines)
print('DONE')
