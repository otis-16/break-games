#!/bin/zsh
# Bump the build stamp everywhere, commit and push, so open pages / home-screen apps refresh themselves.
set -e
cd "$(dirname "$0")"
V=$(date +%Y%m%d%H%M%S)
echo "{\"v\":\"$V\"}" > version.json
python3 -I - "$V" <<'PY'
import sys, re, glob
V = sys.argv[1]
for f in ['index.html', '404.html'] + glob.glob('*/index.html'):
    s = open(f, encoding='utf-8').read()
    rel = '' if '/' not in f else '../'
    snip = ("<script>/* app freshness: if a newer build is published, reload once (home-screen apps cache hard) */(function(){var B='%s';try{fetch('%sversion.json?t='+Date.now(),{cache:'no-store'}).then(function(r){return r.json()}).then(function(j){if(j&&j.v&&j.v!==B){var k='dgh-reloaded-'+j.v;if(!sessionStorage.getItem(k)){sessionStorage.setItem(k,'1');location.replace(location.pathname+'?v='+j.v+location.hash)}}}).catch(function(){})}catch(e){}})();</script>\n" % (V, rel))
    s = re.sub(r'<script>/\* app freshness:.*?</script>\n', '', s, flags=re.S)
    i = s.find('<title>')
    if i < 0: continue
    s = s[:i] + snip + s[i:]
    open(f, 'w', encoding='utf-8').write(s)
PY
git add -A -- .
# folders still being built can be held back: HOLD='darts pachinko' ./publish.sh
for h in ${=HOLD:-}; do git reset -q -- "$h" 2>/dev/null || true; done
git commit -qm "${1:-Update site}

Co-Authored-By: Claude Opus 5.5 (1M context) <noreply@anthropic.com>"
git push -q
echo "published $V"
