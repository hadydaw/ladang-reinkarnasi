#!/usr/bin/env python3
"""
Penyesuaian proyek Android hasil `npx cap add android`:
  - minSdkVersion = 26 (Android 8.0)
  - orientasi tidak dikunci (portrait & landscape didukung);
    rotasi tidak me-restart aktivitas (configChanges memuat orientation)
Skrip ini gagal (exit 1) jika struktur template berubah, supaya tidak diam-diam salah.
"""
import re, os, sys
ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), '..'))
AND = os.path.join(ROOT, 'android')
MIN_SDK = 26

def fail(m):
    print('PATCH GAGAL:', m); sys.exit(1)

vg = os.path.join(AND, 'variables.gradle')
if not os.path.isfile(vg):
    fail('android/variables.gradle tidak ada; jalankan `npx cap add android` dulu')
s = open(vg, encoding='utf-8').read()
if re.search(r'minSdkVersion\s*=\s*\d+', s) is None:
    fail('baris minSdkVersion tidak ditemukan di variables.gradle')
s = re.sub(r'minSdkVersion\s*=\s*\d+', 'minSdkVersion = %d' % MIN_SDK, s)
open(vg, 'w', encoding='utf-8').write(s)
print('minSdkVersion ->', MIN_SDK)

mf = os.path.join(AND, 'app', 'src', 'main', 'AndroidManifest.xml')
if not os.path.isfile(mf):
    fail('AndroidManifest.xml tidak ditemukan')
m = open(mf, encoding='utf-8').read()
if 'screenOrientation' in m:
    m = re.sub(r'\s*android:screenOrientation="[^"]*"', '', m)
    print('screenOrientation lama dihapus (orientasi tidak dikunci)')
cc = re.search(r'android:configChanges="([^"]*)"', m)
if cc is None:
    fail('atribut configChanges tidak ditemukan di AndroidManifest')
if 'orientation' not in cc.group(1):
    fail('configChanges tidak memuat orientation')
open(mf, 'w', encoding='utf-8').write(m)
print('AndroidManifest OK (configChanges memuat orientation)')
