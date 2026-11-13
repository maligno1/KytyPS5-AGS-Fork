# Apply a git patch only when it is not already applied, so that re-running CMake
# (ninja's build.ninja regeneration, or a second configure in the same build dir)
# does not fail on a tree that was already patched by an earlier configure.
# Runs with the current working directory set to the patched source tree
# (FetchContent runs patch steps in the source directory).
# Usage: cmake -D GIT_EXECUTABLE=<git> -D PATCH=<patch file> -P apply-idempotent.cmake

if(NOT DEFINED GIT_EXECUTABLE OR NOT DEFINED PATCH)
	message(FATAL_ERROR "apply-idempotent.cmake: GIT_EXECUTABLE and PATCH are required")
endif()

# Not yet applied: "git apply --check" passes, so apply it for real.
execute_process(
	COMMAND "${GIT_EXECUTABLE}" apply --ignore-whitespace --check "${PATCH}"
	RESULT_VARIABLE can_apply
	ERROR_QUIET OUTPUT_QUIET
)
if(can_apply EQUAL 0)
	execute_process(
		COMMAND "${GIT_EXECUTABLE}" apply --ignore-whitespace "${PATCH}"
		COMMAND_ERROR_IS_FATAL ANY
	)
	return()
endif()

# Already applied: the patch no longer applies forward, but it applies in reverse.
execute_process(
	COMMAND "${GIT_EXECUTABLE}" apply --ignore-whitespace --reverse --check "${PATCH}"
	RESULT_VARIABLE already_applied
	ERROR_QUIET OUTPUT_QUIET
)
if(NOT already_applied EQUAL 0)
	message(FATAL_ERROR "apply-idempotent.cmake: ${PATCH} neither applies nor is applied here")
endif()
