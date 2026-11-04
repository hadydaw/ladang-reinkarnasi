#!/usr/bin/env python3
"""
Build browser dari sumber proyek.

  src/game.html   kode + markup game (merujuk aset dengan path: assets/...)
  assets/         aset sumber: images/, ui/, audio/, pancing/ (tambah file baru di sini)

Hasil: dist/web/index.html + dist/web/assets/index.json + dist/web/assets/packs/*.bin

Pemeriksaan build (gagal bila ada masalah):
  - setiap path aset yang dirujuk harus ada di assets/
  - tidak boleh ada data:image tertanam di src/
  - ukuran setiap pack <= PACK_LIMIT
Peringatan (tidak menggagalkan build):
  - aset yang ada tapi tidak dirujuk kode (tidak ikut dipaketkan)
"""
import re, os, sys, json, hashlib, shutil

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), '..'))
SRC = os.path.join(ROOT, 'src', 'game.html')
ASSETS = os.path.join(ROOT, 'assets')
OUT = os.path.join(ROOT, 'dist', 'web')
PACK_LIMIT = 8 * 1024 * 1024
MIME = {'.webp': 'image/webp', '.png': 'image/png', '.jpg': 'image/jpeg', '.wav': 'audio/wav', '.ogg': 'audio/ogg', '.mp3': 'audio/mpeg'}
REF = re.compile(r'assets/[A-Za-z0-9_./-]+\.(?:webp|png|jpg|wav|ogg|mp3)')

BOOT = r'''<script>
(function(){
  var BLOBS = {};
  function fix(t){ return t.replace(/__A_([0-9a-f]{10})__/g, function(m,k){ return BLOBS[k] || m; }); }
  function domReady(){ return document.readyState === 'loading' ? new Promise(function(r){ document.addEventListener('DOMContentLoaded', r); }) : Promise.resolve(); }
  function loadAssets(){
    return fetch('assets/index.json').then(function(r){ if(!r.ok) throw new Error('index'); return r.json(); }).then(function(idx){
      var files = {};
      Object.keys(idx).forEach(function(k){ files[idx[k].f] = true; });
      return Promise.all(Object.keys(files).map(function(f){
        return fetch(f).then(function(r){ if(!r.ok) throw new Error(f); return r.arrayBuffer(); }).then(function(buf){ return [f, buf]; });
      })).then(function(pairs){
        var bufs = {}; pairs.forEach(function(p){ bufs[p[0]] = p[1]; });
        Object.keys(idx).forEach(function(k){
          var e = idx[k];
          BLOBS[k] = URL.createObjectURL(new Blob([new Uint8Array(bufs[e.f], e.o, e.l)], { type: e.m }));
        });
      });
    });
  }
  function run(){
    document.querySelectorAll('style').forEach(function(st){ st.textContent = fix(st.textContent); });
    Array.from(document.querySelectorAll('*')).forEach(function(el){
      Array.from(el.attributes).forEach(function(a){ if (a.value.indexOf('__A_') >= 0) el.setAttribute(a.name, fix(a.value)); });
    });
    document.querySelectorAll('script[type="text/x-game"]').forEach(function(sc){
      var n = document.createElement('script'); n.textContent = fix(sc.textContent); document.body.appendChild(n); sc.remove();
    });
  }
  Promise.all([loadAssets(), domReady()]).then(run, function(err){
    var d = document.createElement('div');
    d.style.cssText = 'position:fixed;inset:0;display:flex;align-items:center;justify-content:center;background:#2b1a0c;color:#fff;font:16px sans-serif;padding:16px;text-align:center;z-index:99999';
    d.textContent = 'Aset game gagal dimuat. Coba muat ulang halaman. (' + (err && err.message || err) + ')';
    document.body.appendChild(d);
  });
})();
</script>'''

def fail(msg):
    print('BUILD GAGAL:', msg); sys.exit(1)

def main():
    src = open(SRC, encoding='utf-8').read()
    if 'data:image' in src:
        fail('ada data:image tertanam di src/game.html; pindahkan ke assets/ dan rujuk dengan path')

    # 1. kumpulkan path aset yang dirujuk
    refs = sorted(set(REF.findall(src)))
    missing = [r for r in refs if not os.path.isfile(os.path.join(ROOT, r))]
    if missing:
        fail('aset dirujuk tapi tidak ada: ' + ', '.join(missing))

    # 1b. registry aset: setiap file yang dirujuk harus tercatat (peringatan bila tidak)
    reg_path = os.path.join(ASSETS, '..', 'assets', 'registry.json')
    reg_path = os.path.join(ROOT, 'assets', 'registry.json')
    if os.path.isfile(reg_path):
        reg = json.load(open(reg_path, encoding='utf-8'))
        listed = {e['baru'] for e in reg.get('aset', [])}
        not_listed = [r for r in refs if r.startswith('assets/images/') and r not in listed]
        for e in reg.get('aset', []):
            if not os.path.isfile(os.path.join(ROOT, e['baru'])):
                fail('registry menunjuk file yang tidak ada: ' + e['baru'])
        if not_listed:
            print('PERINGATAN registry: %d aset gambar belum tercatat, contoh: %s' % (len(not_listed), not_listed[:3]))

    # 2. ganti path dengan token kunci (hash path), lalu kelompokkan per kategori untuk pack
    key_of = {r: hashlib.sha1(r.encode()).hexdigest()[:10] for r in refs}
    html = REF.sub(lambda m: '__A_%s__' % key_of[m.group(0)], src)

    groups = {}
    for r in refs:
        groups.setdefault(r.split('/')[1], []).append(r)

    if os.path.isdir(OUT):
        shutil.rmtree(OUT)
    os.makedirs(os.path.join(OUT, 'assets', 'packs'))

    index = {}
    report = {'packs': []}
    for group in sorted(groups):
        n = 0; cur = bytearray(); cur_name = None
        def open_pack():
            nonlocal n, cur, cur_name
            cur_name = 'assets/packs/%s-%d.bin' % (group, n); n += 1; cur = bytearray()
        open_pack()
        for r in sorted(groups[group]):
            data = open(os.path.join(ROOT, r), 'rb').read()
            if len(cur) + len(data) > PACK_LIMIT and len(cur):
                report['packs'].append((cur_name, len(cur))); write_pack(cur_name, cur); open_pack()
            ext = os.path.splitext(r)[1].lower()
            index[key_of[r]] = {'p': r, 'f': cur_name, 'o': len(cur), 'l': len(data), 'm': MIME.get(ext, 'application/octet-stream')}
            cur.extend(data)
        report['packs'].append((cur_name, len(cur))); write_pack(cur_name, cur)

    json.dump(index, open(os.path.join(OUT, 'assets', 'index.json'), 'w'), separators=(',', ':'))

    # 3. HTML final: boot loader + skrip game sebagai teks inert (dijalankan setelah aset siap)
    html = html.replace('<script>\n', '<script type="text/x-game">\n')
    if html.count('<script type="text/x-game">') != 2:
        fail('struktur <script> berubah; periksa src/game.html')
    marker = '</style>'
    if html.count(marker) != 1:
        fail('struktur </style> berubah; periksa src/game.html')
    html = html.replace(marker, marker + '\n' + BOOT, 1)
    open(os.path.join(OUT, 'index.html'), 'w', encoding='utf-8').write(html)

    # 4. salin file non-aset yang tetap dibutuhkan (path relatif dipakai di kode)
    # (semua aset yang dirujuk sudah masuk pack; tidak ada salinan terpisah)

    # 5. peringatan: aset tidak dirujuk
    unused = []
    for dp, _, fs in os.walk(ASSETS):
        for f in fs:
            rel = os.path.relpath(os.path.join(dp, f), ROOT).replace(os.sep, '/')
            if rel not in refs and os.path.splitext(f)[1].lower() in MIME:
                unused.append(rel)

    total = sum(os.path.getsize(os.path.join(dp, f)) for dp, _, fs in os.walk(OUT) for f in fs)
    print('OK')
    print('html bytes:', os.path.getsize(os.path.join(OUT, 'index.html')))
    print('aset dirujuk:', len(refs), '| kunci index:', len(index))
    for name, size in report['packs']:
        print('  pack', name, size)
    print('total dist bytes:', total)
    print('aset tidak dirujuk (tidak ikut build):', len(unused))
    for u in unused[:40]:
        print('  -', u)
    if total > 256 * 1024 * 1024:
        fail('total dist melewati 256 MB')

def write_pack(name, buf):
    open(os.path.join(OUT, name), 'wb').write(bytes(buf))

if __name__ == '__main__':
    main()
