# Migrasi sekali jalan: dari HTML monolitik v718 ke folder sumber (src/ + assets/).
import re, hashlib, os, shutil, sys
ROOT = sys.argv[1]; WS = '/home/claude'
s = open(os.path.join(ROOT, 'backup/ladang-reinkarnasi-v718.html'), encoding='utf-8').read()
# satu URI terpecah oleh penggabungan string JS: "...base64,"+"UklGR..."
s = s.replace('base64,"+"', 'base64,')
pat = re.compile(r'data:image/(webp|png);base64,([A-Za-z0-9+/=]+)')
import base64
names = {}
def repl(m):
    uri = m.group(0)
    if uri not in names:
        h = hashlib.sha1(uri.encode()).hexdigest()[:10]
        ext = m.group(1)
        rel = 'assets/images/%s.%s' % (h, ext)
        names[uri] = rel
        open(os.path.join(ROOT, rel), 'wb').write(base64.b64decode(m.group(2)))
    return names[uri]
s = pat.sub(repl, s)
# salin aset yang dirujuk (ui/, audio/, pancing/) dan semua file di folder itu
for d in ['ui', 'audio', 'pancing']:
    for f in sorted(os.listdir(os.path.join(WS, d))):
        src = os.path.join(WS, d, f)
        if os.path.isfile(src):
            shutil.copy(src, os.path.join(ROOT, 'assets', d, f))
    s = re.sub(r'(?<![A-Za-z0-9_./-])%s/([A-Za-z0-9_.-]+)' % d,
               lambda m: 'assets/%s/%s' % (d, m.group(1)) if os.path.exists(os.path.join(ROOT, 'assets', d, m.group(1))) else m.group(0), s)
assert 'data:image' not in s
open(os.path.join(ROOT, 'src/game.html'), 'w', encoding='utf-8').write(s)
print('unique embedded images migrated:', len(names))
