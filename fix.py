import os
p = 'lib/features/dashboard/student/pages/student_results_page.dart'
with open(p, 'r') as f: c = f.read()
c = c.replace('const Expanded(flex: 3,', 'SizedBox(width: 180,')
c = c.replace('const Expanded(flex: 1,', 'SizedBox(width: 60,')
lines = c.split('\n')
hl = None
for i, line in enumerate(lines):
    if "Text('Subject'" in line and "Text('Remark'" in line:
        hl = i; break
if hl is None: print('NF'); exit(1)
cl = None
for i in range(hl + 1, len(lines)):
    if 'isLast ?' in lines[i] and 'Radius.circular(12)' in lines[i]:
        cl = i; break
if cl is None: print('NE'); exit(1)
close_line = cl + 2  # line of the last ')'
insert_open = [
    '            SingleChildScrollView(\n',
    '              scrollDirection: Axis.horizontal,\n',
    '              child: ConstrainedBox(\n',
    '                constraints: BoxConstraints(minWidth: 640),\n',
    '                child:\n',
]
insert_close = [
    '                ),\n',
    '              ),\n',
    '            ),\n',
]
lines = lines[:hl] + insert_open + lines[hl:close_line+1] + insert_close + lines[close_line+1:]
with open(p, 'w') as f: f.write('\n'.join(lines))
# VERIFY
with open(p, 'r') as f: v = f.read()
has_scroll = 'SingleChildScrollView' in v
has_sized = 'SizedBox(width: 180,' in v
has_no_expanded = 'Expanded(flex:' not in v
print(f'SCROLL:{has_scroll} SIZED:{has_sized} NO_EXPANDED:{has_no_expanded}')
if not has_scroll or not has_sized or not has_no_expanded:
    print('VERIFY FAILED'); exit(1)
print('ALL GOOD')
