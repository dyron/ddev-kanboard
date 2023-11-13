setup() {
  set -eu -o pipefail
  export DIR="$( cd "$( dirname "$BATS_TEST_FILENAME" )" >/dev/null 2>&1 && pwd )/.."
  export TESTDIR=~/tmp/test-kanboard
  mkdir -p $TESTDIR
  export PROJNAME=test-kanboard
  export DDEV_NON_INTERACTIVE=true
  ddev delete -Oy ${PROJNAME} >/dev/null 2>&1 || true
  cd "${TESTDIR}"
  ddev config --project-name=${PROJNAME}
  ddev config --omit-containers=dba >/dev/null 2>&1 || true
  ddev start -y >/dev/null 2>&1
}

health_checks() {
  set +u # bats-assert has unset variables so turn off unset check
  # ddev restart is required because we have done `ddev get` on a new service
  run ddev restart
  assert_success
  # Make sure we can hit the 8053 port successfully
  curl -s -I -f  https://${PROJNAME}.ddev.site:8053 >/tmp/curlout.txt
  # Make sure `ddev kanboard` works
  DDEV_DEBUG=true run ddev kanboard
  assert_success
  assert_output --partial "FULLURL https://${PROJNAME}.ddev.site:8053"
}

teardown() {
  set -eu -o pipefail
  cd ${TESTDIR} || ( printf "unable to cd to ${TESTDIR}\n" && exit 1 )
  ddev delete -Oy ${PROJNAME} >/dev/null 2>&1
  [ "${TESTDIR}" != "" ] && rm -rf ${TESTDIR}
}

@test "install from directory" {
  set -eu -o pipefail
  cd ${TESTDIR}
  echo "# ddev get ${DIR} with project ${PROJNAME} in ${TESTDIR} ($(pwd))" >&3
  ddev get ${DIR} >/dev/null 2>&1
  ddev mutagen sync >/dev/null 2>&1
  health_checks
}

@test "install from release" {
  set -eu -o pipefail
  cd ${TESTDIR} || ( printf "unable to cd to ${TESTDIR}\n" && exit 1 )
  echo "# ddev get dyron/ddev-kanboard with project ${PROJNAME} in ${TESTDIR} ($(pwd))" >&3
  ddev get dyron/ddev-kanboard >/dev/null 2>&1
  ddev restart >/dev/null 2>&1
  health_checks
}