# Debugging CI failures

A build runs one pipeline per arch (amd64, arm64, arm) **in parallel**. One arch can pass while another fails — always inspect every pipeline, not just the first.

List failures grouped by arch (prints `<arch> <step> <status>` for any non-success step):
```
curl -s "http://ci.syncloud.org:8080/api/repos/syncloud/plex/builds/{N}" | python3 -c "
import json,sys
b=json.load(sys.stdin)
for stage in b.get('stages',[]):
    arch = stage.get('name')
    for step in stage.get('steps',[]):
        st = step.get('status')
        if st not in ('success','skipped'):
            print(arch, step.get('number'), step.get('name'), '-', st)
"
```

Then get the step log (stage=pipeline number from `stages[].number`, step=step number from above):
```
curl -s "http://ci.syncloud.org:8080/api/repos/syncloud/plex/builds/{N}/logs/{stage}/{step}" | python3 -c "
import json,sys; [print(l.get('out',''), end='') for l in json.load(sys.stdin)]
" | tail -80
```

**Live log tail (SSE, no auth):** while a step is `running`, the JSON `/logs/...` endpoint above only contains what's been flushed so far. To watch a step in real time, use Drone's Server-Sent Events stream:

```
curl -sN "http://ci.syncloud.org:8080/api/stream/syncloud/plex/{N}/{stage}/{step}" \
  | python3 -c "import sys,json
for line in sys.stdin:
    if line.startswith('data: '):
        e=json.loads(line[6:]); sys.stdout.write(e.get('out',''))"
```

Each event is `data: {\"pos\":N,\"out\":\"...\",\"time\":S}`. The stream ends when the step finishes. Useful when artifact upload is broken and you can't read `journalctl.log` after the fact — anything the test prints to stdout is visible immediately.

# CI

http://ci.syncloud.org:8080/syncloud/plex

CI is Drone CI (JS SPA). Check builds via API:
```
curl -s "http://ci.syncloud.org:8080/api/repos/syncloud/plex/builds?limit=5"
```

Each build contains multiple pipelines (one per arch: amd64, arm64, arm). To check status, look inside `stages` for each pipeline:
```
curl -s "http://ci.syncloud.org:8080/api/repos/syncloud/plex/builds/{N}" | python3 -c "
import json,sys
b=json.load(sys.stdin)
for s in b.get('stages',[]):
    print(f\"{s['name']}: {s['status']}\")
"
```

## CI Artifacts

Artifacts are served at `http://ci.syncloud.org:8081` (returns JSON directory listings).

Browse the top level for a build (returns distro subdirs + snap file):
```
curl -s "http://ci.syncloud.org:8081/files/plex/{build}-{arch}/"
```

**For integration test failures, fetch `journalctl.log` directly from the artifact server — do not add stdout dumps to the test teardown.** The teardown already captures the journal and `scp_from_device`s it into the artifact dir; the drone-scp `artifact` step then uploads the whole directory to `ci.syncloud.org:8081`. Only when port 8081 is itself down (rare; the artifact step will be in `failure`) do you need an alternative.

Each distro dir holds the pytest artifacts; each Playwright step writes its own top-level dir named after the artifact subdir it was given:
```
curl -s "http://ci.syncloud.org:8081/files/plex/{build}-{arch}/{distro}/"
curl -s "http://ci.syncloud.org:8081/files/plex/{build}-{arch}/e2e/playwright/desktop/"
```

Directory structure:
```
{build}-{arch}/
  {distro}/
    log/
      journalctl.log          # full journal from integration test teardown
      ps.log, netstat.log     # process/network state at teardown
    platform_log/             # platform logs
    refresh.journalctl.log    # full journal from upgrade test (pre/post-refresh)
  e2e/                        # Playwright, post-install smoke (amd64 only)
  e2e-before-upgrade/         # Playwright, on the previously released version
  e2e-after-upgrade/          # Playwright, after refreshing to this build
    playwright/
      {desktop,mobile}/
        screenshot/           # shoot() PNGs + page HTML
        journalctl.log        # device journal from globalTeardown
      test-results/           # traces and videos
  machine-identifier.txt      # recorded pre-upgrade, asserted post-upgrade
```

Download a file directly:
```
curl -O "http://ci.syncloud.org:8081/files/plex/{build}-amd64/buster/log/journalctl.log"
curl -O "http://ci.syncloud.org:8081/files/plex/{build}-amd64/e2e/playwright/desktop/journalctl.log"
```

# Running Drone builds locally

The `drone` CLI is not on $PATH. It lives at `../drone-cli/drone` (sibling project). Either prefix calls with that path, or add a shell alias.

Generate `.drone.yml` from jsonnet (run from project root):
```
../drone-cli/drone jsonnet --stdout --stream > .drone.yml
```

Run a specific pipeline with selected steps (e.g. amd64 up to `test bookworm`):
```
../drone-cli/drone exec --pipeline amd64 --trusted \
  --include nginx \
  --include plex \
  --include cli \
  --include "nginx test bookworm" \
  --include "plex test bookworm" \
  --include "cli test bookworm" \
  --include package \
  --include "test bookworm" \
  --include "test buster" \
  --include e2e \
  --include test-upgrade-prev \
  --include e2e-before-upgrade \
  --include test-upgrade \
  --include e2e-after-upgrade \
  .drone.yml
```

Every step is a committed script — `./nginx/build.sh`, `./plex/build.sh <version>`, `./cli/build.sh`, `./package.sh plex <build>`, `./ci/test.sh <spec> <distro> plex`, `./test/e2e/run.sh <artifact-subdir> <spec>` — so each reproduces locally with the same command CI runs.

UI tests run under Playwright (`mcr.microsoft.com/playwright:v1.59.1-jammy`). Plex ships no SPA of its own, so the specs live in `test/e2e/specs/` and are driven by `test/e2e/run.sh`, which runs each spec against both the `desktop` and `mobile` projects. Screenshots, videos and the device journal land in `artifact/<subdir>/playwright/<project>/`.

Notes:
- `--trusted` is required for privileged/volume steps
- `--include` selects only listed steps (in pipeline order); omit to run all steps
- `drone jsonnet --stdout --stream` sends stderr to stderr (proto warnings are harmless)
