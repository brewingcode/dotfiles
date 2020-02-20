# ----------------------------------------------------------------------------------------------------------------------
# best | Copyright (C) 2020 eth-p | MIT License
#
# Repository: https://github.com/eth-p/best
# Issues:     https://github.com/eth-p/best/issues
# ----------------------------------------------------------------------------------------------------------------------

# Executes a new instance of the test runner.
# The test runner is specified by the `BEST_RUNNER` environment variable.
#
# Environment:
#
#     BEST_BASH [string]            -- The bash executable.
#     BEST_RUNNER [string]          -- The test runner script.
#
#     TEST_PWD [string]             -- The working direcory to run tests in.
#     TEST_ENV_HOME [string]        -- The HOME variable to run tests with.
#     TEST_ENV_PATH [string:string] -- The PATH variable to run tests with.
#     TEST_ENV_TMPDIR [string]      -- The TEMPDIR variable to run tests with.
#     TEST_LIB_DIR                  -- The test library directory. All scripts in this directory are loaded by the runner.
#     TEST_SHIM_DIR                 -- The test shim directory. Scripts in this directory can be included with `use_shim`.
#     SNAPSHOT_DIR                  -- The snapshot directory.
#
runner() {
	({
		cd "${TEST_PWD}" && env -i \
			HOME="$TEST_ENV_HOME" \
			PATH="$TEST_ENV_PATH" \
			TMPDIR="$TEST_ENV_TMPDIR" \
			TEST_LIB_DIR="$TEST_LIB_DIR" \
			TEST_SHIM_DIR="$TEST_SHIM_DIR" \
			BEST_VERSION="$BEST_VERSION" \
			BEST_RUNNER_QUIET="${BEST_RUNNER_QUIET:-false}" \
			"${BEST_BASH}" "${BEST_RUNNER}" "$@"
	})
}

runner:load() {
	printf "LOAD %s\n" "$1" 1>&3
}

runner:run() {
	printf "TEST " 1>&3
	printf "%q " "$@" 1>&3
	printf "\n" 1>&3
}

runner:skip() {
	printf "ECHO IGNORE %s\n" "$1" 1>&3
}

runner:test_setup() {
	printf "EVAL if type -t setup &>/dev/null; then setup; fi\n" 1>&3
}

runner:test_teardown() {
	printf "EVAL if type -t teardown &>/dev/null; then teardown; fi\n" 1>&3
}
