#!/usr/bin/env python3
"""Afișează starea versiunii și a trimiterilor la App Review (doar citire)."""
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from asc_listing import api, BUNDLE_ID

app_id = api("GET", f"/v1/apps?filter[bundleId]={BUNDLE_ID}")["data"][0]["id"]
for v in api("GET", f"/v1/apps/{app_id}/appStoreVersions?limit=5")["data"]:
    a = v["attributes"]
    print(f"STARE VERSIUNE {a.get('versionString')}: {a.get('appStoreState')} "
          f"(release: {a.get('releaseType')})")
for s in api("GET", f"/v1/reviewSubmissions?filter[app]={app_id}&limit=5")["data"]:
    a = s["attributes"]
    print(f"TRIMITERE {s['id']}: {a.get('state')} (trimisă {a.get('submittedDate')})")
