# This machine

A full Teramind stack runs here, legacy and unipipe side by side, fed by a real
Windows agent on a VM. It is where changes get proven before they leave the
laptop. Everything below is live: assume anything you start, stop or write to is
shared with whatever else is running.

## A question is a question

When the user asks *how does X work*, *why does Y happen*, *what would it take*,
*is Z possible* — answer it. Do not edit, restart, deploy, delete or create
anything. Reading the code, querying a database, tailing a topic, inspecting a
container: all fair game, and usually how the answer gets found. Changing the
state of this machine or of a repository is not, until the user asks for it in
so many words.

If the answer is "that needs a change", say what the change would be and stop
there. Offering to make it is fine; making it is not.

## "Test" means on this machine

When the user says *test*, they mean the real thing running here: the change
loaded into a process on this box, against the live stack, with its effect
visible where it would be visible in production. Unit tests and isolated
harnesses are a precondition, not the test — "the unit tests pass" is never an
answer to "did it work".

A test is finished when the effect is confirmed **from more than one angle**: the
row in the store *and* the metric *and* the log line — and where a second
implementation exists to compare against (legacy vs unipipe), both sides. One
green signal is a hypothesis, not a result.

**Assume nothing that can be checked.** Check it: when the binary was built and
whether any source is newer, which process actually holds the port, whether the
record reached the topic, whether the row you are looking at is the one you just
produced or one from last week, whether the component you did not restart also
compiles the code you changed. Where a check turns out to be impossible, say that
plainly rather than reporting the parts that did pass and leaving the gap
implied.

## Every test starts by proving the stack runs the code under test

Not once — every time, before any measurement, and **fix what it finds** as part
of the test rather than reporting around it. A number measured against stale code
is worse than no number, because it looks like evidence.

1. **Binaries.** `find cmd internal -name '*.go' -newer bin/<binary>` for the one
   you expect, then `go list -deps ./cmd/<x> | grep '^tmgoap/'` against your diff
   to find every *other* binary that compiles what you changed. Rebuild and
   restart those too, with the flags they already had — read them off `ps` before
   stopping anything.
2. **Containers.** For every containerised app in the path under test, compare
   what the container imports against the project file:
   `docker exec <c> sha1sum <path in container>` versus `sha1sum <path in project>`.
   Mismatch means the container is answering from stale code: repoint its mount at
   the project directory and re-create it before going further.
3. **Processes.** One process per metrics port, and a component missing from `ps`
   whose consumer group still has lag has died — read its log before restarting.

Then say in the report what was stale and what you restarted. "It works" from a
stack you did not verify is a guess.

**For how to actually run a test — start a consumer, replay a packet, compare
legacy against unipipe, clean up afterwards — load the `tm-local-stack` skill.**
This file is only the map and the rules.

## The map

| What | Where |
|---|---|
| Kafka | `localhost:9094` (host), container `kafka`, UI on `:8081` |
| ClickHouse unipipe | container `clickhouse-unipipe`, native `127.0.0.1:9001`, HTTP `:8124`; DBs `tmgoap`, `tmgoap_1` |
| ClickHouse legacy | container `clickhouse`, native `127.0.0.1:9000`, HTTP `:8123` |
| Postgres | `127.0.0.1:5432`, master DB `teramind`, tenant DB `tm_onsite`, user `teramind` |
| tmsrv (agent endpoint) | container `terasrv`, host network, listens `:10000`/`:10001` |
| tenantsvc | `:8400` (real, master-DB backed) |
| cubeapi via router | `127.0.0.1:18080` (legacy + unipipe), `:18081` (second unipipe) |
| cubeapi direct | `:8000` legacy, `:8010` unipipe (`tmgoap`), `:8011` unipipe (`tmgoap_1`) |
| teraweb | `https://<this host>/tm-api` (see `tmgoap/CLAUDE.md` for the address and test users) |
| Prometheus / Grafana | `:9090` / `:3000` |

The one tenant is **`onsite`** (`instance_id` 1, DB `tm_onsite`). Its agent is the
Windows VM, which reports continuously — the input topic is never idle.

## Rules

**Never start a toxicity service on this machine** — not `toxicity-svc`,
`toxicity-svc-v3`, `speedtoxify-svc` or any other real scorer, and never set a
consumer's `--toxicity-service-url`. It consumes all RAM and CPU: on 2026-09-23
one start crash-looped at 17 GB and 8 cores, load passed 570, and the OOM killer
took down `clickhouse-unipipe` and the shared consumers. Toxicity is out of scope
here; the `toxicity-shim` stub (always scores 0) may stay up.

**Never invent an instance name.** tenantsvc resolves instances from the master
DB, and an unknown one is fatal to the consumer: it dies, and the record stays in
the topic, so it dies again on restart. The only way past is skipping offsets,
which throws away live agent data. Use `onsite`, or run `faketenantsvc`, which
accepts any name.

**Synthetic data uses agent ids 9000+**, never a real agent's id, and gets deleted
from both `tmgoap` and `tmgoap_1` when the test is done. Sessions are keyed by
`instance:agent:computer`; reusing a live agent's id disturbs its real session.

**Don't reset consumer group offsets** to get out of trouble. It is silent data
loss for every group you touch, and the agent's traffic is not replayable.

**Restart everything that compiles what you changed**, not just the obvious
binary. `find cmd internal -name '*.go' -newer bin/<binary>` answers it, and
several processes share this box — check `ps` before assuming yours is the only
one. Two processes cannot share a metrics port; pass `--metrics-port`.

**Legacy mail ingestion is dead here** — `mon_mail` has not been written since
2026-05-29. Mail parity against legacy cannot be tested on this machine; other
event types are fine.

## Containerised apps run the project directory

The dev-facing Python services take their code from a bind mount, so a change is
made in `/home/prod/projects/<project>` and the container is pointed at it —
`tmbi/tma` into the cubeapi containers, `./tma:/app/tma` in tmbi's dev compose.
Never edit code inside a container, and never assume the mount points where you
expect: check that the file the container imports matches the one you edited. The
`tm-local-stack` skill has the commands.

## Go code in these projects

`tmgoap`, `cubeapi-compare` and `cubeapi-router` are Go. Write what a Go reviewer
would expect to read, and match the file you are editing before any general rule.

- **Errors are values, and they carry context.** Wrap with `%w` and a phrase
  naming the operation; compare with `errors.Is`/`errors.As`. Never swallow one.
  In pipeline paths decide explicitly between failing the batch and degrading
  gracefully, and write the reason down — both are correct in different places
  here, and the next reader cannot tell which you meant.
- **Interfaces belong to the consumer, and stay small.** Define them where they
  are used, keep them to the methods that call site needs, accept interfaces and
  return concrete types. One implementation needs no interface; add it when the
  second arrives or when a test genuinely cannot use the real thing.
- **Concurrency has an owner and an exit.** Every goroutine has a defined way to
  stop; the writer closes the channel; `errgroup` for a batch of parallel stages;
  `context` threaded through anything that touches the network or can block. A
  plain mutex beats a clever lock-free scheme.
- **Lifecycles are explicit.** Whatever you open, you close — `defer` next to the
  acquisition. Say in a comment what happens to buffered or in-flight state on
  shutdown, abort and rebalance; on this pipeline that is where the bugs live.
- **Tests are table-driven**, named for the behaviour they pin rather than the
  function they call, and use a fake struct in preference to a mocking framework.
  A test that would have caught the bug beats three that restate the code.
- **No Java in Go.** No factories producing factories, no interface per struct,
  no getters and setters, no package named `utils`, no stutter (`store.Store`).
  Composition over inheritance-shaped hierarchies, zero values that work.
- **The standard library first.** A new dependency has to earn its place and be
  justified in the commit message.
- **`gofmt` and `go vet` clean before you call it done**, and `go test ./...`
  run — with pre-existing failures named as pre-existing, having checked that
  they are.

Comments here explain *why*, often at length, and that is deliberate: this
codebase carries decisions that look arbitrary without their reason. Match that
density. Do not restate what the code says.

## Known long-running processes

Two tmgoap consumers (`test-consumer`, `clean-reprocess`) and two sinkers, all
started by hand, all logging to a session scratchpad rather than a fixed path.
They are not supervised: if you stop one, you own restarting it.
