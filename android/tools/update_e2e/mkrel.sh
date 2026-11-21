#!/bin/bash
# Makes the test release (A -> B patch + update.json) and puts it at https://waaiya.mssid.org/preview/updtest/
set -e
cd "${WORK:?set WORK to a folder holding A.apk (installed version) and B.apk (newer)}"
rm -rf up && mkdir up && zstd -q -19 -f --patch-from=A.apk B.apk -o up/p-A-B.zst && cp B.apk up/B.apk
python3 - <<'EOF'
import hashlib,json,os
def sha(p):
    h=hashlib.sha256()
    with open(p,'rb') as f:
        for b in iter(lambda:f.read(1<<20),b''): h.update(b)
    return h.hexdigest()
base="https://waaiya.mssid.org/preview/updtest/"
a,b,p=sha('A.apk'),sha('B.apk'),sha('up/p-A-B.zst')
m={"schema":1,"android":{"versionCode":17,"versionName":"0.2.13-t17",
 "apks":{"universal":{"url":base+"B.apk","sha256":b,"size":os.path.getsize('B.apk')}},
 "patches":[{"from":a,"variant":"universal","url":base+"p-A-B.zst","sha256":p,"size":os.path.getsize('up/p-A-B.zst')}],
 "known":{a:"universal",b:"universal"}},"notes":{"en":"Test update (patch).","ar":"تحديث تجريبي."}}
json.dump(m,open('up/update.json','w'),indent=1)
m["android"]["patches"][0]["sha256"]="0"*64
json.dump(m,open('up/update-badpatch.json','w'),indent=1)
EOF
ssh o2 'mkdir -p ~/waaiya.mssid.org/preview/updtest' 2>/dev/null
rsync -a --partial up/ o2:waaiya.mssid.org/preview/updtest/ 2>&1 | grep -v "pq.html\|upgraded\|WARNING\|store now" || true
