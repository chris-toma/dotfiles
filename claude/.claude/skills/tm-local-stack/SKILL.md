---
name: tm-local-stack
description: Cookbook for testing any change against the Teramind stack on this machine — the tmgoap consumer, sinkers, Kafka, ClickHouse (unipipe and legacy), Postgres, cubeapi and the Windows agent VM. Use when asked to test functionality end to end, inject or replay traffic, isolate a test from the shared pipeline, follow an event through the hops, restart a component, compare legacy against unipipe, or clean up test data on this box.
---

# Testing on the local Teramind stack

`/home/prod/projects/CLAUDE.md` has the map, the rules, and what "test" means
here. This is the method and the recipes. Nothing below is specific to one
feature — pick the parts the change in front of you needs.

## 0. Pre-flight: does the stack run the code under test?

Run this before every test, and repair what it finds — the repair is part of the
test. Copy the check, do not remember it.

```bash
cd /home/prod/projects/tmgoap

# a. is the binary you expect current?
find cmd internal -name '*.go' -newer bin/consumer        # any output = rebuild

# b. what else compiles what you changed?
go list -deps ./cmd/sinker | grep '^tmgoap/'              # compare against your diff

# c. do the containers in the path run the project, or a copy of it?
for c in unipipe-cubeapi unipipe-cubeapi-1; do
  docker inspect $c --format '{{range .Mounts}}{{.Source}} -> {{.Destination}}{{println}}{{end}}' | grep site-packages
done
F=cubeapi/core/dims/_common.py                            # any file your change touches
docker exec unipipe-cubeapi sha1sum /opt/venv/lib/python3.13/site-packages/tma/$F
sha1sum /home/prod/projects/tmbi/tma/$F

# d. is anything that should be running, missing or double-bound?
ps -eo pid,lstart,cmd | grep -E "[b]in/consumer|[t]mgoap-sinker" | cut -c1-120
ss -lntp | grep -E ":(2112|2113|2114|2116)"
```

Repairs, in the order they usually apply:

- **Stale binary** → `make build-<cmd>`, `kill -TERM` the old process, start it
  again with the flags `ps` showed. Every binary that compiles a changed package,
  not only the obvious one.
- **Container mounting a copy instead of the project** → capture the definition
  (`docker inspect <name>`: image, `Cmd`, `Env`, `NetworkMode`, every mount),
  then `docker rm -f` and `docker run` with the same arguments and the mount
  source changed to the project directory. Keep the captured definition until the
  container is verified healthy, so it can be put back.
- **Port already bound** → the loser serves nothing silently; give your process
  its own `--metrics-port`.

Record what was stale in the report. A result from an unverified stack is a
guess, however green it looks.

## 1. Pick the smallest loop that can answer the question

| Question | Loop | Cost | Repeatable |
|---|---|---|---|
| Is the logic right? | `go test ./...` | seconds | yes |
| Does it behave inside a running consumer? | your own lane + a synthetic scenario | ~2 min | yes |
| Does it behave on data the agent really sent? | replay a captured record byte for byte | ~1 min | yes |
| Does the agent actually send what we assumed? | do the thing on the Windows VM | minutes | no |

Work down the list only as far as the question needs, but a change that is about
to ship reaches at least row three: real bytes through a running process. Row
four is the only way to learn what the agent itself does — and its data can then
be captured once and replayed forever, which is what makes row three cheap.

The order also isolates failures. If the synthetic scenario works and the real
record does not, the difference is in the data, not the code.

## 2. Run a lane, don't disturb the shared pipeline

Two consumers and two sinkers run on this box and feed the ClickHouse that
comparison runs read. Restarting them to try something is how you lose an
afternoon of agent traffic. Instead give your test its own lane — the same input
topic, everything else separate:

| Shared | Yours |
|---|---|
| `--group=test-consumer` | `--group=<something>-lane` |
| `--node-id=0` | any unused id (snowflake source) |
| `--state-topic=employee-activity-state` | `<lane>-state`, **compacted** |
| `--output-unified-topic=tmgoap-unified-records` | `<lane>-unified` |
| `--metrics-port=2116` | an unused port |
| local store dirs | a directory of your own |

```bash
LANE=mytest
for t in $LANE-state; do
  docker exec kafka /opt/kafka/bin/kafka-topics.sh --bootstrap-server localhost:9092 \
    --create --topic $t --partitions 3 --replication-factor 1 --if-not-exists \
    --config cleanup.policy=compact --config segment.ms=300000
done
docker exec kafka /opt/kafka/bin/kafka-topics.sh --bootstrap-server localhost:9092 \
  --create --topic $LANE-unified --partitions 3 --replication-factor 1 --if-not-exists

cd /home/prod/projects/tmgoap && make build-consumer
nohup ./bin/consumer --brokers=localhost:9094 --topic=employee-activity \
  --state-topic=$LANE-state --group=$LANE-lane --node-id=7 \
  --protocol-workers=8 --session-workers=16 \
  --output-unified-topic=$LANE-unified --output-screen-text-topic=$LANE-text \
  --tenantsvc-url=http://localhost:8400 --metrics-port=2130 \
  > "$SCRATCH/$LANE.log" 2>&1 &
```

**Seed the lane's offsets before you start it.** A consumer group with no
committed offsets starts *at the beginning* of the input topic
(`ConsumeResetOffset(AtStart)`), which on this box is well over a million
records. Committing latest for a group that does not exist yet is allowed and
creates it:

```bash
docker exec kafka /opt/kafka/bin/kafka-consumer-groups.sh --bootstrap-server localhost:9092 \
  --group $LANE-lane --topic employee-activity --reset-offsets --to-latest --execute
```

Do this before the first start, never after the lane has members. If the lane
needs rows in ClickHouse, copy a sinker config, change `consumer_group`, `topic`,
`database` and `metrics_port`, and create the database with
`tmgoap/schema/events_table.sql` (plus the view files if you will query through
cubeapi).

When the change is behind a flag, the cheapest A/B is two lanes off the same
input, one with the flag and one without, compared row for row.

Two things a lane does **not** isolate: the tenant's settings in tenantsvc, and
the agent ids you write. Both are shared — see the rules in `CLAUDE.md`.

## 3. Know what is running before you change it

```bash
ps -eo pid,lstart,cmd | grep -E "[b]in/consumer|[t]mgoap-sinker|[b]in/tenantsvc|[c]ubeapi-router" | cut -c1-140
docker ps --format '{{.Names}}\t{{.Status}}'
for g in test-consumer clean-reprocess sinker-ch-main sinker-ch-second; do
  echo -n "$g lag: "
  docker exec kafka /opt/kafka/bin/kafka-consumer-groups.sh --bootstrap-server localhost:9092 \
    --describe --group $g 2>/dev/null | awk 'NR>1 && $6!="-" {l+=$6} END {print l+0}'
done
cd /home/prod/projects/tmgoap && find cmd internal -name '*.go' -newer bin/consumer   # output = rebuild
```

Before believing a binary is current, check what else compiles the packages you
changed — `go list -deps ./cmd/<x> | grep '^tmgoap/'` against your diff — and
restart those too. A process missing from `ps` whose group still has lag died;
read its log before restarting it.

## 4. Containerised apps: edit in the project, run in the container

The Python and PHP services run from images, but the ones meant for development
take their code from a bind mount. The loop is: edit the file in
`/home/prod/projects/<project>`, make sure the container is mounting that
directory, restart the process inside it.

**tmbi through its dev compose.** `dev.docker-compose.yml` mounts `./tma:/app/tma`,
and some services run gunicorn with `--reload`, so an edit takes effect on the
next request; the rest need that service restarted.

**The hand-run cubeapi containers.** `unipipe-cubeapi` (`tma-cubeapi --bind
127.0.0.1:8010`, `UNIPIPE_DB=tmgoap`) and `unipipe-cubeapi-1` (`:8011`,
`UNIPIPE_DB=tmgoap_1`) run the image's entry point with the `tma` package
bind-mounted read-only over the installed one. Point that mount at the working
tree and the container runs your code:

```
-v /home/prod/projects/tmbi/tma:/opt/venv/lib/python3.13/site-packages/tma:ro
```

A running container's mounts cannot be changed, so this means re-creating it:
capture the current definition first — `docker inspect <name>` for the image,
`Cmd`, `Env`, `NetworkMode` and every mount — then `docker rm -f` and `docker
run` with the same arguments plus the new `-v`. Once the mount is right,
`docker restart <name>` is all an edit needs.

**Legacy `terabi-cubeapi` (`:8000`), `terabi-etl`, `terabi-cat`** carry no code
mount: they run what is baked into the image. Testing a change there means adding
a mount the same way, or rebuilding the image.

**`teraweb`** is PHP-FPM inside the image; only storage, conf, rec and logs come
from the host, so there is no project directory to edit — changes go through the
image.

**Confirm the container is running what you think it is.** A mount source can
drift from the project it was copied from, and nothing will tell you:

```bash
docker exec <container> python -c "import tma; print(tma.__file__)"
docker exec <container> sha1sum /opt/venv/lib/python3.13/site-packages/tma/<file you changed>
sha1sum /home/prod/projects/tmbi/tma/<the same file>
```

Matching digests, or it is not your code that is answering.

## 5. Get events in

**Synthetic, for a shape you control.** A YAML scenario becomes a recording,
which the player replays:

```bash
./bin/scengen --scenario=dev-scripts/scenarios/<name>.yaml --output=/tmp/s.gob \
              --users-from=9001 --users-to=9001 --instance-name=onsite --partitions=3
./bin/player --brokers=localhost:9094 --topic=employee-activity --input=/tmp/s.gob \
             --single-pass --no-recompression --metrics-port=2115
```

Scenario events are `SessionStart`, `sleep`, and anything carrying a `template`
(there is no `SessionEnd`). A template is protobuf JSON for one `Packet` field,
so the field names come from the generated structs in `proto/pb/session/` — read
the struct, don't guess the name. `dev-scripts/scenarios/` has worked examples of
several event types. Use agent ids 9000+.

**A real record, replayed byte for byte.** The most faithful repeatable test, and
the only way to reproduce a client resync: the consumer sees the identical
packet, key, value and headers a second time.

```bash
# locate it: the summary column counts what is inside each packet
END=$(docker exec kafka /opt/kafka/bin/kafka-get-offsets.sh --bootstrap-server localhost:9092 \
      --topic employee-activity --partitions 0 | cut -d: -f3)
./bin/topictail --brokers=localhost:9094 --topic=employee-activity --partition=0 \
                --offset=$((END-500)) --max=500 --kind=<kind>
go run ./tmp/replayone --partition=0 --offset=<offset>     # tool lives in tmgoap/tmp (gitignored)
```

`topictail --list-kinds` lists the filters; `--full` dumps protojson for each
event; `--summary` counts by kind. Scanning renders a few hundred records a
minute, so always start from a recent offset, never from the beginning.

**The agent itself,** for anything about what the client produces. Unrepeatable,
so capture while it happens and replay later:

```bash
./bin/recorder --brokers=localhost:9094 --topic=employee-activity --duration=120 --output=/tmp/vm.gob
```

## 6. Follow the event through the hops

When something does not show up, walk the chain in order; the first hop that is
missing it tells you which component to look at.

| Hop | Check |
|---|---|
| Input topic | `./bin/topictail --topic=employee-activity --partition=0 --offset=<recent> --kind=<kind>` |
| Consumer consumed it | group lag → 0, and `OFFSETS_COMMITTED` in its log |
| Consumer processed it | its `/metrics` counters moved; warnings in its log |
| Output topic | `kafka-get-offsets.sh --topic <unified topic>` grew, or `topictail` it |
| Sinker wrote it | sinker group lag, sinker log |
| ClickHouse | query `u_events` filtered on **your** identifier |
| cubeapi | `cubeapi-compare`, or curl the router on `:18080` |
| Legacy | Postgres `tm_onsite`, and the legacy ClickHouse |

A counter that did not move and a lag of zero together mean the event never
reached that stage — it was not dropped there.

## 7. Verify from more than one angle

A single green signal is a hypothesis. Confirm a behaviour in the store *and* in
a counter *and* in the log, and where legacy implements the same thing, on both
sides. Filter every query on the identifier this run produced — a hash, an event
id, an agent id — never on "the most recent row", which is how a stale row gets
read as a pass.

```bash
docker exec clickhouse-unipipe clickhouse-client -q "
SELECT ts, agent_id, event_type, <the fields the change touches>
FROM tmgoap.u_events WHERE <your identifier> ORDER BY ts DESC FORMAT Vertical"

curl -s localhost:<lane metrics port>/metrics | grep tmgoap_consumer_ | grep <the counter>
```

`u_events.agent_id` is composite — `instance_id << 32 | agent_id` — so agent 1 of
instance 1 reads as 4294967297. Filtering on the bare agent id silently returns
nothing.

Against legacy, the entity tables live in Postgres `tm_onsite` (`mon_mail`,
`mon_activity`, …) and the ETL's output in the legacy ClickHouse. Whole-dashboard
parity is `cubeapi-compare`:

```bash
cd /home/prod/projects/cubeapi-compare && go build -o cubeapi-compare .
./cubeapi-compare -config corpus/config.local-router.yaml -day <YYYY-MM-DD> \
                  -tenants onsite -query <substring>
```

`-payload` runs one ad-hoc widget; `config.isolation.yaml` compares two unipipe
stacks instead of legacy against unipipe.

## 8. Clean up, every time

Synthetic rows left behind corrupt the next comparison run, which is what this
machine exists for.

```bash
for db in tmgoap tmgoap_1; do
  docker exec clickhouse-unipipe clickhouse-client -q "
    ALTER TABLE $db.u_events DELETE WHERE agent_id IN (<composite ids>) SETTINGS mutations_sync=1"
done
```

Count before and after. Then kill the lane consumer, delete its topics, remove
its store directories, and restart anything shared that you stopped — with the
flags it had, which you noted from `ps` before stopping it.

## 9. Traps on this box

- **An instance name tenantsvc does not know is fatal** to the consumer, and the
  record stays in the topic, so it dies again on restart. Use `onsite`, or run
  `./bin/faketenantsvc serve -config <settings.json> -addr :8401`, which accepts
  any name (minimal config:
  `{"instance_id":1,"instance_name":"fake","default_productivity_profile_id":1,"productivity_profiles":{"1":{}}}`).
  A consumer pointed at the fake stamps synthetic instance ids on everything it
  reads, real tenants included — never leave it there while real traffic flows.
- **Resetting a shared group's offsets** is silent data loss: the agent's
  traffic is not replayable, and every group you touch skips whatever it had not
  read. Last resort, and say so when you do it. Seeding your *own* new lane group
  to latest before it starts is a different thing and is fine.
- **Two processes cannot share a metrics port.** The loser serves nothing and
  looks healthy. Always pass `--metrics-port`.
- **Sessions are keyed `instance:agent:computer`.** Synthetic events under a live
  agent's id disturb that agent's real session state.
- **Changelog topics are co-partitioned** with the input topic: one per consumer
  group, never shared, and produced to the partition the consumer owns.
- **Legacy mail ingestion is dead here** (`mon_mail` unchanged since 2026-05-29),
  so mail parity cannot be measured on this machine. Other entities are fine.

## 10. Per-project tests

| Project | Command |
|---|---|
| `tmgoap` | `go test ./...` — `cmd/cattool` and a `dev-scripts` vet warning fail on main already |
| `cubeapi-compare` | `go test ./...` |
| `cubeapi-router` | `go test ./...` |
| `tmbi` | `task test`, `task test:unit`, `task test:integration` |
| `tmserver` | CMake build; no local test harness wired up here |

---

# Appendix A — the shared pipeline as it runs today

Two consumers and two sinkers, all started by hand, none supervised. Note the
flags from `ps` before stopping anything; these are what they were last started
with.

**`test-consumer`** — the real path: its output reaches ClickHouse through the
sinkers. Metrics on `:2116`.

```bash
cd /home/prod/projects/tmgoap && make build-consumer
nohup ./bin/consumer --brokers=localhost:9094 --topic=employee-activity \
  --state-topic=employee-activity-state --group=test-consumer --node-id=0 \
  --protocol-workers=8 --session-workers=16 \
  --output-unified-topic=tmgoap-unified-records --output-screen-text-topic=tmgoap-screen-text \
  --tenantsvc-url=http://localhost:8400 \
  --mail-dedup-topic=employee-activity-mail-dedup \
  --mail-dedup-dir=/home/prod/projects/tmgoap/data/mail-dedup \
  --metrics-port=2116 > "$SCRATCH/consumer-main.log" 2>&1 &
```

The dedup store's memory ceiling is configurable and defaults to 16 MB × 2
memtables plus a 64 MB block cache: `-mail-dedup-memtable-mb`,
`-mail-dedup-memtables`, `-mail-dedup-block-cache-mb`. It is a ceiling, not
growth per key. A block cache of 0 disables compression with it and leaves reads
to the OS page cache — less RSS, more disk. The store logs what it opened with:
`[MAIL-DEDUP] store open: dir=… memtable=16MB x2 block-cache=64MB compression=…`.

**`clean-reprocess`** — a second reader of the same input whose output topics no
sinker consumes, so nothing it emits reaches ClickHouse. Free A/B lane for a
flagged change. Metrics on `:2112`.

```bash
nohup ./bin/consumer --brokers=localhost:9094 --topic=employee-activity \
  --state-topic=tmgoap-clean-state --group=clean-reprocess --node-id=1 \
  --protocol-workers=8 --session-workers=16 \
  --output-unified-topic=tmgoap-unified-records-clean \
  --output-screen-text-topic=tmgoap-screen-text-clean \
  --tenantsvc-url=http://localhost:8400 --metrics-port=2112 > "$SCRATCH/consumer-clean.log" 2>&1 &
```

Stop either with `kill -TERM` and wait for the process to exit — it saves state
on the way out.

**Sinkers** run from `/tmp/tmgoap-sinker` with configs under a session
scratchpad: `sinker-main.yaml` reads `tmgoap-unified-records` as group
`sinker-ch-main` into `tmgoap.u_events` (metrics `:2113`), `sinker-second.yaml`
the same topic as `sinker-ch-second` into `tmgoap_1.u_events` (metrics `:2114`).
Rebuild and replace when a package they compile changes:

```bash
make build-sinker && kill -TERM <pids> && cp bin/sinker /tmp/tmgoap-sinker
nohup /tmp/tmgoap-sinker --config <config>.yaml >> <log> 2>&1 &
```

Kafka topics in play: `employee-activity` (input, 3 partitions, live agent
traffic on partition 0), `employee-activity-state` (compacted),
`employee-activity-mail-dedup` (delete, 30d retention), `tmgoap-unified-records`,
`tmgoap-screen-text`, and the `-clean` variants.

# Appendix B — worked example: mail deduplication

The whole method applied to one change, as a template for the next one. The
change: suppress a mail the agent has already reported, keyed
`(instance, agent_id, mail_hash)`, which is what tmserver keys on.

**1. Unit loop.** `go test ./internal/store/ ./internal/kafka/pktproc/`.

**2. Synthetic, in a running consumer.** `dev-scripts/scenarios/mail-dedup.yaml`
reports one mail three times, a second mail once, and two mails with no hash:

```bash
./bin/scengen --scenario=dev-scripts/scenarios/mail-dedup.yaml --output=/tmp/s.gob \
              --users-from=9001 --users-to=9001 --instance-name=onsite --partitions=3
./bin/player --brokers=localhost:9094 --topic=employee-activity --input=/tmp/s.gob \
             --single-pass --no-recompression --metrics-port=2115
```

Expect 4 rows from 6 reports: the repeated mail once, the second mail once, and
both hashless mails, which are never suppressed because tmserver does not
suppress them either.

**3. Restart persistence.** Stop the consumer, start it again, replay the same
recording: the log shows `[MAIL-DEDUP] Partition 0: loaded N mails from N
records` and no new rows appear — the local store was rebuilt from the changelog.

**4. Real bytes.** Find the packet carrying a mail (the summary column counts
what is inside each packet) and replay it byte for byte:

```bash
./bin/topictail --brokers=localhost:9094 --topic=employee-activity --partition=0 \
                --offset=<recent> --max=400 --kind=http_monitor_report | grep "mails=[1-9]"
go run ./tmp/replayone --partition=0 --offset=<offset>
```

**5. Verify from three angles.**

```bash
# the store
docker exec clickhouse-unipipe clickhouse-client -q "
SELECT eml_hash, eml_subject, count() AS rows, any(eml_num_attachments) AS att
FROM tmgoap.u_events WHERE event_type='mail' AND ts > today()
GROUP BY eml_hash, eml_subject FORMAT PrettyCompactMonoBlock"

# the counters
curl -s localhost:2116/metrics | grep -E "mail_duplicates_suppressed|mail_dedup_errors|mail_dedup_latency_seconds_count"

# the changelog landed on the partition the consumer owns
docker exec kafka /opt/kafka/bin/kafka-get-offsets.sh --bootstrap-server localhost:9092 \
  --topic employee-activity-mail-dedup
```

A replay must leave the row count unchanged while
`mail_duplicates_suppressed_total` increases. Both moving together is the proof;
either alone is not.

**6. Legacy comparison** — how it would be done where legacy still ingests mail
(not on this box, see the traps):

```bash
PGPASSWORD="$TM_PG_PASSWORD" psql -h 127.0.0.1 -U teramind -d tm_onsite -c "
SELECT mon_mail_id, agent_id, mail_hash, mail_subject,
       (SELECT count(*) FROM mon_mail_attachment a
         WHERE a.mon_mail_id = m.mon_mail_id AND a.name <> '') AS attachments
FROM mon_mail m WHERE m.timestamp > now() - interval '30 minutes' ORDER BY m.timestamp DESC"
```

`$TM_PG_PASSWORD` is not set for you: this file is versioned, so the credential
stays out of it. The value is in `tmgoap/CLAUDE.md`, which is gitignored and
local to this machine.

The `name <> ''` is not incidental: the legacy ETL counts only named
attachments, so any parity check on attachment counts has to apply the same rule.

**7. Clean up.** Delete the synthetic rows from both `tmgoap` and `tmgoap_1` by
composite agent id, and confirm the count is zero afterwards.
