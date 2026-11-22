#!/usr/bin/env python3
"""يعدّل مشروع أندرويد المُولَّد بواسطة `flutter create` ليناسب التطبيق:
- صلاحيات الإنترنت والميكروفون
- معرّف تطبيق AdMob (من المتغير ADMOB_APP_ID، الافتراضي معرّف الاختبار)
- اسم التطبيق على الهاتف
- الحد الأدنى لإصدار أندرويد 23
- queries لخدمة التعرف على الكلام (أندرويد 11+)
"""
import os
import re
import sys

APP_NAME = os.environ.get("APP_NAME", "لمعة")
ADMOB_APP_ID = os.environ.get(
    "ADMOB_APP_ID", "ca-app-pub-3940256099942544~3347511713"
).strip()

manifest_path = "android/app/src/main/AndroidManifest.xml"
if not os.path.exists(manifest_path):
    sys.exit("لم يتم العثور على AndroidManifest.xml - شغّل flutter create أولاً")

with open(manifest_path, encoding="utf-8") as f:
    m = f.read()

permissions = """    <uses-permission android:name="android.permission.INTERNET"/>
    <uses-permission android:name="android.permission.ACCESS_NETWORK_STATE"/>
    <uses-permission android:name="android.permission.RECORD_AUDIO"/>
    <uses-permission android:name="android.permission.BLUETOOTH"/>
    <uses-permission android:name="android.permission.BLUETOOTH_ADMIN"/>
    <uses-permission android:name="android.permission.BLUETOOTH_CONNECT"/>
"""

if "android.permission.RECORD_AUDIO" not in m:
    m = m.replace("<application", permissions + "    <application", 1)

# اسم التطبيق
m = re.sub(r'android:label="[^"]*"', f'android:label="{APP_NAME}"', m, count=1)

# معرّف AdMob داخل <application>
if "com.google.android.gms.ads.APPLICATION_ID" not in m:
    meta = (
        '\n        <meta-data\n'
        '            android:name="com.google.android.gms.ads.APPLICATION_ID"\n'
        f'            android:value="{ADMOB_APP_ID}"/>'
    )
    m = re.sub(r"(<application[^>]*>)", lambda mo: mo.group(1) + meta, m, count=1)

# خدمة التعرف على الكلام (مطلوبة لأندرويد 11+)
if "android.speech.RecognitionService" not in m:
    queries = """
    <queries>
        <intent>
            <action android:name="android.speech.RecognitionService"/>
        </intent>
    </queries>
"""
    m = m.replace("</manifest>", queries + "</manifest>")

with open(manifest_path, "w", encoding="utf-8") as f:
    f.write(m)

# الحد الأدنى لـ minSdk
patched = False
for gradle in ("android/app/build.gradle.kts", "android/app/build.gradle"):
    if not os.path.exists(gradle):
        continue
    with open(gradle, encoding="utf-8") as f:
        g = f.read()
    new = re.sub(r"minSdk\s*=\s*flutter\.minSdkVersion", "minSdk = 23", g)
    new = re.sub(r"minSdkVersion\s+flutter\.minSdkVersion", "minSdkVersion 23", new)
    if new != g:
        with open(gradle, "w", encoding="utf-8") as f:
            f.write(new)
        patched = True
    print(f"{gradle}: minSdk patched = {patched}")

print("تم تعديل ملفات أندرويد بنجاح")
