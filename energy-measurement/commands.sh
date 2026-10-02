#!/usr/bin/env bash

set -eo pipefail
STAGE="${1:?stage required: check | build | test}"

# The build stage compiles into a volume shared with the test stage, so the test
# stage exercises the binary this run produced instead of one baked at image time.
cd /work/git

# Variables of the dispatch that runs the measurement. ci/lib.sh derives the whole
# test environment from them; nothing it derives is set here.
export GITHUB_ACTIONS=true
export GITHUB_EVENT_NAME="${GITHUB_EVENT_NAME:-workflow_dispatch}"
export GITHUB_REF="${GITHUB_REF:-refs/heads/master}"
export GITHUB_SHA="${GITHUB_SHA:-$(git rev-parse HEAD)}"
export GITHUB_RUN_ID="${GITHUB_RUN_ID:-0}"
export GITHUB_REPOSITORY="${GITHUB_REPOSITORY:-energy-consumption-cicd/git}"
export GITHUB_ENV="${GITHUB_ENV:-/tmp/github_env}"
export RUNNER_OS=Linux
export CI_JOB_IMAGE=debian:11
export jobname=debian-11
export CUSTOM_PATH=/custom

. ci/lib.sh

# ci/run-build-and-tests.sh at v2.53.0 exports nothing that applies to jobname=debian-11
# (TEST_CONTRIB_TOO and GIT_TEST_USE_SET_E arrived in later releases).

# ci/lib.sh at v2.53.0 never derives GIT_TEST_LONG; the guard of the HEAD instrumentation
# is kept so that EXPENSIVE tests (over 10 GiB, OOM-killed under the 12 GiB cap) can never run.
if [ -n "${GIT_TEST_LONG:-}" ]; then
	echo "GIT_TEST_LONG=$GIT_TEST_LONG derived from CI_EVENT=$CI_EVENT,CI_BRANCH=$CI_BRANCH" >&2
	echo "the pre-registered test scope does not hold; refusing to measure" >&2
	exit 1
fi

# ci/lib.sh hardcodes JOBS=10 for GitHub-hosted runners; this bench has 8 cores.
MAKEFLAGS="${MAKEFLAGS/--jobs=10/--jobs=8}"
GIT_PROVE_OPTS="${GIT_PROVE_OPTS/--jobs 10/--jobs 8}"
export MAKEFLAGS GIT_PROVE_OPTS
case "$MAKEFLAGS" in
*--jobs=8*) ;;
*) echo "parallelism override missed MAKEFLAGS: $MAKEFLAGS" >&2; exit 1 ;;
esac
case "$GIT_PROVE_OPTS" in
*"--jobs 8"*) ;;
*) echo "parallelism override missed GIT_PROVE_OPTS: $GIT_PROVE_OPTS" >&2; exit 1 ;;
esac

# Auditable evidence that the measured configuration was derived by ci/lib.sh and
# not imposed by this script.
echo "::group::effective environment after ci/lib.sh"
env | sort
echo "::endgroup::"

case "$STAGE" in

  check)
    # Pre-flight for run_pipeline.sh: the derivation and the assertions above are
    # the check itself, so reaching this point is the pass condition.
    echo "environment check passed"
    ;;

  build)
    group Build make
    ;;

  test)
    group "Run tests" make test
    ;;

  *)
    echo "Unknown stage: $STAGE" >&2
    exit 1
    ;;
esac
