#!/usr/bin/env bash
set -euo pipefail
NS="${1:?namespace required}"
kubectl -n "$NS" run scaling-load --restart=Never --image=scaling-api:1.0.0 --image-pull-policy=Never --command -- python -c '
import concurrent.futures, time, urllib.request
end=time.time()+180
def work(_):
    while time.time()<end:
        try: urllib.request.urlopen("http://scaling-api/work",timeout=5).read()
        except Exception: pass
with concurrent.futures.ThreadPoolExecutor(max_workers=16) as pool:
    list(pool.map(work,range(16)))'
echo "Load runs for 180 seconds. Stop early: kubectl -n $NS delete pod scaling-load"
