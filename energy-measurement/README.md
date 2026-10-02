# Energy measurement

Per-stage energy measurement of this project's CI commands, on controlled hardware,
at release v2.54.0 (`94f057755b7941b321fd11fec1b2e3ca5313a4e0`). Branch `release-2.54.0` is that tag plus this
directory and the workflow; the measurement of the HEAD campaign lives on `master`.
Part of a study comparing the energy cost of CI pipelines across ML and non-ML projects.

## No upstream file is modified

This fork adds exactly five files and changes nothing else:

```
.github/workflows/energy-measurement.yml
energy-measurement/README.md
energy-measurement/Dockerfile
energy-measurement/run_pipeline.sh
energy-measurement/commands.sh
```

Verifiable with:

```sh
git fetch upstream
git diff --name-only v2.54.0...release-2.54.0
```

## Reference cell

The measured configuration is one cell of `.github/workflows/main.yml`: job
`dockerized`, `jobname: debian-11`, `image: debian:11`. It is the Linux cell that runs
the suite with the project's reference toolchain and no configuration variant (no
alternative hash, ref backend, sanitizer or build system). That cell already runs in a
container upstream, so the measurement reproduces an existing containerisation.

The base image is pinned by digest rather than by tag, because Debian 11 leaves
support on 2026-08-31.

## Stages

| stage | command |
|---|---|
| `build` | `make` |
| `test` | `make test` |

`commands.sh` exports the variables of the dispatch and then sources the upstream
`ci/lib.sh`, which derives the rest of the environment: `MAKEFLAGS`, `GIT_PROVE_OPTS`,
`GIT_TEST_OPTS`, `DEVELOPER` and `DEFAULT_TEST_TARGET`; `ci/run-build-and-tests.sh` at
v2.54.0 adds `TEST_CONTRIB_TOO=yes`.
Nothing that `ci/lib.sh` derives is set by hand. Each stage prints its effective
environment so the derivation is auditable from the run log.

The build stage compiles into a Docker volume shared with the test stage, so the test
stage exercises the binary that the build stage produced.

## Deviations from the upstream runner

- **Parallelism 8.** `ci/lib.sh` hardcodes `JOBS=10` for GitHub-hosted runners; this
  bench has 8 cores. `commands.sh` rewrites the two derived flags and asserts the
  rewrite took effect.
- **No network at run time.** Both stages run with `--network none`. The suite is
  hermetic (verified on the HEAD campaign: the same 35115 tests with and without a network).
- **Package temperature sidecar.** `temp_run_NN_<stage>.txt` records the CPU package
  temperature read by the host immediately before and after each stage's RAPL window.

## Running it

```sh
docker build -t git-measurement-2.54.0 -f energy-measurement/Dockerfile .
gh workflow run energy-measurement.yml -f campaign=validation
```

`campaign=validation` executes a single smoke run; `campaign=full` executes a discarded
warm-up followed by ten measured runs and aggregates the medians.
