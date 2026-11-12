#!/usr/bin/env python3
"""Urcă fișa din App Store (texte în 7 limbi, categorie, date pentru review, capturi) prin App Store Connect API.

Citește structura `fastlane/metadata` și `fastlane/screenshots` din repo, fără fastlane.
Variabile de mediu: APP_STORE_CONNECT_KEY_IDENTIFIER, APP_STORE_CONNECT_ISSUER_ID,
APP_STORE_CONNECT_PRIVATE_KEY, BUNDLE_ID. Opțional: ASC_BASE_URL (pentru teste), APP_VERSION.
"""
import base64
import hashlib
import json
import os
import re
import sys
import textwrap
import time
import urllib.error
import urllib.request

import jwt  # PyJWT

BASE = os.environ.get("ASC_BASE_URL", "https://api.appstoreconnect.apple.com")
ROOT = os.environ.get("CM_BUILD_DIR", os.getcwd())
META = os.path.join(ROOT, "fastlane", "metadata")
SHOTS = os.path.join(ROOT, "fastlane", "screenshots")
BUNDLE_ID = os.environ["BUNDLE_ID"]
VERSION = os.environ.get("APP_VERSION", "1.0")
DISPLAY_TYPE = "APP_IPHONE_67"
HAS_RELEASE = False   # slotul 6.9"/6.7" (1320×2868 și 1290×2796)


def env(name: str) -> str:
    """Valoarea unei variabile; Codemagic poate da o referință: @file:/cale sau @env:VARIABILA."""
    raw = os.environ[name].strip()
    for _ in range(3):
        if raw.startswith("@file:"):
            raw = open(os.path.expanduser(raw[len("@file:"):]), encoding="utf-8").read().strip()
        elif raw.startswith("@env:"):
            raw = os.environ[raw[len("@env:"):]].strip()
    return raw


def private_key() -> str:
    raw = env("APP_STORE_CONNECT_PRIVATE_KEY").replace("\\n", "\n")
    if "BEGIN" not in raw:
        try:
            dec = base64.b64decode(raw).decode()
            if "BEGIN" in dec:
                raw = dec
        except Exception:
            pass
    body = re.sub(r"-----(BEGIN|END) [A-Z ]+-----", "", raw)
    body = re.sub(r"\s+", "", body)
    return "-----BEGIN PRIVATE KEY-----\n" + "\n".join(textwrap.wrap(body, 64)) + "\n-----END PRIVATE KEY-----\n"


_token = {"value": None, "exp": 0}


def token() -> str:
    if _token["value"] and time.time() < _token["exp"] - 60:
        return _token["value"]
    exp = int(time.time()) + 15 * 60
    _token["value"] = jwt.encode(
        {"iss": env("APP_STORE_CONNECT_ISSUER_ID"), "exp": exp, "aud": "appstoreconnect-v1"},
        private_key(), algorithm="ES256",
        headers={"kid": env("APP_STORE_CONNECT_KEY_IDENTIFIER"), "typ": "JWT"})
    _token["exp"] = exp
    return _token["value"]


def api(method, path, body=None, ok=(200, 201, 204)):
    url = path if path.startswith("http") else BASE + path
    data = json.dumps(body).encode() if body is not None else None
    req = urllib.request.Request(url, data=data, method=method, headers={
        "Authorization": "Bearer " + token(), "Content-Type": "application/json"})
    try:
        with urllib.request.urlopen(req, timeout=60) as r:
            raw = r.read()
            return json.loads(raw) if raw else {}
    except urllib.error.HTTPError as e:
        detail = e.read().decode(errors="replace")
        if e.code in ok:
            return json.loads(detail) if detail else {}
        raise SystemExit(f"{method} {path} → HTTP {e.code}\n{detail}")


def read(path):
    p = os.path.join(META, path)
    return open(p, encoding="utf-8").read().strip() if os.path.exists(p) else None


def locales():
    return sorted(d for d in os.listdir(META) if os.path.isdir(os.path.join(META, d)) and d != "review_information")


def main():
    # 1. aplicația și versiunea editabilă
    apps = api("GET", f"/v1/apps?filter[bundleId]={BUNDLE_ID}")["data"]
    if not apps:
        raise SystemExit(f"Nu există aplicație în App Store Connect pentru {BUNDLE_ID}")
    app_id = apps[0]["id"]
    versions = api("GET", f"/v1/apps/{app_id}/appStoreVersions?filter[platform]=IOS&limit=50")["data"]
    editable = [v for v in versions if v["attributes"].get("appStoreState") in
                ("PREPARE_FOR_SUBMISSION", "DEVELOPER_REJECTED", "REJECTED", "METADATA_REJECTED")]
    if editable:
        version = editable[0]
        if version["attributes"]["versionString"] != VERSION:
            api("PATCH", f"/v1/appStoreVersions/{version['id']}", {"data": {
                "type": "appStoreVersions", "id": version["id"], "attributes": {"versionString": VERSION}}})
    else:
        version = api("POST", "/v1/appStoreVersions", {"data": {
            "type": "appStoreVersions",
            "attributes": {"platform": "IOS", "versionString": VERSION},
            "relationships": {"app": {"data": {"type": "apps", "id": app_id}}}}})["data"]
    vid = version["id"]
    global HAS_RELEASE
    HAS_RELEASE = any(v["attributes"].get("appStoreState") in
                      ("READY_FOR_SALE", "READY_FOR_DISTRIBUTION", "REPLACED_WITH_NEW_VERSION", "REMOVED_FROM_SALE")
                      for v in versions)
    print(f"Aplicație {app_id}, versiune {VERSION} ({vid}), publicată anterior: {HAS_RELEASE}")

    copyright_ = read("copyright.txt")
    if copyright_:
        api("PATCH", f"/v1/appStoreVersions/{vid}", {"data": {
            "type": "appStoreVersions", "id": vid, "attributes": {"copyright": copyright_}}})

    # 2. App Info: nume, subtitlu, politica de confidențialitate
    infos = api("GET", f"/v1/apps/{app_id}/appInfos")["data"]
    info = next((i for i in infos if i["attributes"].get("appStoreState") != "READY_FOR_SALE"
                 and i["attributes"].get("state") != "READY_FOR_DISTRIBUTION"), infos[0])

    # 2b. Categoria (fișierele primary_category.txt și primary_first_sub_category.txt, dacă există)
    category = read("primary_category.txt")
    if category:
        rels = {"primaryCategory": {"data": {"type": "appCategories", "id": category}}}
        sub = read("primary_first_sub_category.txt")
        if sub:
            rels["primarySubcategoryOne"] = {"data": {"type": "appCategories", "id": sub}}
        sub2 = read("primary_second_sub_category.txt")
        if sub2:
            rels["primarySubcategoryTwo"] = {"data": {"type": "appCategories", "id": sub2}}
        try:
            api("PATCH", f"/v1/appInfos/{info['id']}", {"data": {
                "type": "appInfos", "id": info["id"], "relationships": rels}})
            print(f"Categorie: {category} / {sub} / {sub2}")
        except SystemExit as err:
            print(f"ATENȚIE: categoria nu a putut fi setată prin API, se pune din App Store Connect.\n{err}")
    info_locs = {l["attributes"]["locale"]: l for l in
                 api("GET", f"/v1/appInfos/{info['id']}/appInfoLocalizations")["data"]}
    for loc in locales():
        attrs = {k: v for k, v in {
            "name": read(f"{loc}/name.txt"),
            "subtitle": read(f"{loc}/subtitle.txt"),
            "privacyPolicyUrl": read(f"{loc}/privacy_url.txt"),
        }.items() if v}
        if loc in info_locs:
            lid = info_locs[loc]["id"]
            api("PATCH", f"/v1/appInfoLocalizations/{lid}", {"data": {
                "type": "appInfoLocalizations", "id": lid, "attributes": attrs}})
        else:
            api("POST", "/v1/appInfoLocalizations", {"data": {
                "type": "appInfoLocalizations", "attributes": {"locale": loc, **attrs},
                "relationships": {"appInfo": {"data": {"type": "appInfos", "id": info["id"]}}}}})
        print(f"App Info {loc}: {attrs.get('name')} / {attrs.get('subtitle')}")

    # 3. Texte pe versiune + capturi
    ver_locs = {l["attributes"]["locale"]: l for l in
                api("GET", f"/v1/appStoreVersions/{vid}/appStoreVersionLocalizations")["data"]}
    for loc in locales():
        attrs = {k: v for k, v in {
            "description": read(f"{loc}/description.txt"),
            "keywords": read(f"{loc}/keywords.txt"),
            "promotionalText": read(f"{loc}/promotional_text.txt"),
            "supportUrl": read(f"{loc}/support_url.txt"),
            "marketingUrl": read(f"{loc}/marketing_url.txt"),
            # „Ce e nou” nu se acceptă la prima versiune a aplicației
            "whatsNew": read(f"{loc}/release_notes.txt") if HAS_RELEASE else None,
        }.items() if v}
        if loc in ver_locs:
            lid = ver_locs[loc]["id"]
            api("PATCH", f"/v1/appStoreVersionLocalizations/{lid}", {"data": {
                "type": "appStoreVersionLocalizations", "id": lid, "attributes": attrs}})
        else:
            lid = api("POST", "/v1/appStoreVersionLocalizations", {"data": {
                "type": "appStoreVersionLocalizations", "attributes": {"locale": loc, **attrs},
                "relationships": {"appStoreVersion": {"data": {"type": "appStoreVersions", "id": vid}}}}})["data"]["id"]
        print(f"Texte {loc}: {len(attrs.get('description', ''))} caractere descriere")
        upload_screenshots(loc, lid)

    # 4. Date pentru echipa de review
    review = {k: v for k, v in {
        "contactFirstName": read("review_information/first_name.txt"),
        "contactLastName": read("review_information/last_name.txt"),
        "contactPhone": read("review_information/phone_number.txt"),
        "contactEmail": read("review_information/email_address.txt"),
        "notes": read("review_information/notes.txt"),
        "demoAccountRequired": False,
    }.items() if v is not None}
    existing = api("GET", f"/v1/appStoreVersions/{vid}/appStoreReviewDetail", ok=(200, 404))
    if existing.get("data"):
        rid = existing["data"]["id"]
        api("PATCH", f"/v1/appStoreReviewDetails/{rid}", {"data": {
            "type": "appStoreReviewDetails", "id": rid, "attributes": review}})
    else:
        api("POST", "/v1/appStoreReviewDetails", {"data": {
            "type": "appStoreReviewDetails", "attributes": review,
            "relationships": {"appStoreVersion": {"data": {"type": "appStoreVersions", "id": vid}}}}})
    print("Date pentru review: completate")
    print("Gata.")


def upload_screenshots(loc, loc_id):
    folder = os.path.join(SHOTS, loc)
    files = sorted(f for f in os.listdir(folder) if f.lower().endswith(".png")) if os.path.isdir(folder) else []
    if not files:
        print(f"Capturi {loc}: niciuna găsită, sar peste")
        return
    sets = api("GET", f"/v1/appStoreVersionLocalizations/{loc_id}/appScreenshotSets")["data"]
    sset = next((s for s in sets if s["attributes"]["screenshotDisplayType"] == DISPLAY_TYPE), None)
    if sset is None:
        sset = api("POST", "/v1/appScreenshotSets", {"data": {
            "type": "appScreenshotSets", "attributes": {"screenshotDisplayType": DISPLAY_TYPE},
            "relationships": {"appStoreVersionLocalization": {"data": {
                "type": "appStoreVersionLocalizations", "id": loc_id}}}}})["data"]
    for old in api("GET", f"/v1/appScreenshotSets/{sset['id']}/appScreenshots")["data"]:
        api("DELETE", f"/v1/appScreenshots/{old['id']}")
    ids = []
    for name in files:
        path = os.path.join(folder, name)
        blob = open(path, "rb").read()
        shot = api("POST", "/v1/appScreenshots", {"data": {
            "type": "appScreenshots", "attributes": {"fileName": name, "fileSize": len(blob)},
            "relationships": {"appScreenshotSet": {"data": {"type": "appScreenshotSets", "id": sset["id"]}}}}})["data"]
        for op in shot["attributes"]["uploadOperations"]:
            chunk = blob[op["offset"]: op["offset"] + op["length"]]
            headers = {h["name"]: h["value"] for h in op.get("requestHeaders", [])}
            req = urllib.request.Request(op["url"], data=chunk, method=op["method"], headers=headers)
            urllib.request.urlopen(req, timeout=120).read()
        api("PATCH", f"/v1/appScreenshots/{shot['id']}", {"data": {
            "type": "appScreenshots", "id": shot["id"],
            "attributes": {"uploaded": True, "sourceFileChecksum": hashlib.md5(blob).hexdigest()}}})
        ids.append(shot["id"])
    api("PATCH", f"/v1/appScreenshotSets/{sset['id']}/relationships/appScreenshots",
        {"data": [{"type": "appScreenshots", "id": i} for i in ids]})
    print(f"Capturi {loc}: {len(ids)} urcate în {DISPLAY_TYPE}")


if __name__ == "__main__":
    sys.exit(main())
