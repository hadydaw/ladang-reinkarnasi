#!/usr/bin/env python3
"""
Penyesuaian proyek Android hasil `npx cap add android`:
  - minSdkVersion = 26 (Android 8.0)
  - orientasi tidak dikunci (portrait & landscape didukung);
    rotasi tidak me-restart aktivitas (configChanges memuat orientation)
  - penandatanganan rilis memakai kunci dari GitHub Secrets (env ANDROID_KEYSTORE_PATH, dst.)
  - versionCode = nomor run GitHub Actions (naik setiap build, agar pembaruan bisa dipasang di atas)
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

# --- penandatanganan rilis dan nomor versi ---
bg = os.path.join(AND, 'app', 'build.gradle')
if not os.path.isfile(bg):
    fail('android/app/build.gradle tidak ditemukan')
g = open(bg, encoding='utf-8').read()
if 'signingConfigs' not in g:
    signing = """    signingConfigs {
        release {
            def ksPath = System.getenv("ANDROID_KEYSTORE_PATH")
            if (ksPath) {
                storeFile file(ksPath)
                storePassword System.getenv("ANDROID_KEYSTORE_PASSWORD")
                keyAlias System.getenv("ANDROID_KEY_ALIAS")
                keyPassword System.getenv("ANDROID_KEY_PASSWORD")
            }
        }
    }
"""
    if g.count('    buildTypes {') != 1:
        fail('blok buildTypes tidak ditemukan tepat sekali di app/build.gradle')
    g = g.replace('    buildTypes {', signing + '    buildTypes {', 1)
    bt = g.index('    buildTypes {')
    rel = re.compile(r'(\n\s*release\s*\{\n)').search(g, bt)
    if rel is None:
        fail('blok release tidak ditemukan di buildTypes')
    indent = re.match(r'\n(\s*)', rel.group(1)).group(1) + '    '
    g = g[:rel.end()] + indent + 'if (System.getenv("ANDROID_KEYSTORE_PATH")) { signingConfig signingConfigs.release }\n' + g[rel.end():]
    print('blok penandatanganan ditambahkan')
if 'GITHUB_RUN_NUMBER' not in g:
    vc = re.search(r'versionCode\s+\d+', g)
    vn = re.search(r'versionName\s+"[^"]*"', g)
    if vc is None or vn is None:
        fail('versionCode/versionName tidak ditemukan di app/build.gradle')
    g = g.replace(vc.group(0), 'versionCode (System.getenv("GITHUB_RUN_NUMBER") ?: "1").toInteger()', 1)
    g = g.replace(vn.group(0), 'versionName "1.0." + (System.getenv("GITHUB_RUN_NUMBER") ?: "0")', 1)
    print('versionCode/versionName dari nomor run')
open(bg, 'w', encoding='utf-8').write(g)
print('app/build.gradle OK')
