#!/usr/bin/env bash

set -exuo pipefail

# Unless the TF_ENABLE_DESTROY variable is set to true, the script will abort if any destructive operations are found.
#
# Plans are checked via the message: `Plan: # to add, # to change, # to destroy.`
#
# If destructive operations are found, the script will exit with an error and touch `./abort_on_delete` file with the variables from the script.
#
readonly PLAN_DIR=${1:-.tg-plans}
readonly TF_ENABLE_DESTROY=${TF_ENABLE_DESTROY:-false}

# Check for environment variable to override the default behavior.
[[ "${TF_ENABLE_DESTROY}" == "true" ]] && {
    echo "abort_on_destroy: TF_ENABLE_DESTROY is set to true. Destructive operations will be allowed."
    exit 0
}
echo "abort_on_destroy: TF_ENABLE_DESTROY is either unset or false. Destructive operations will be blocked."
echo "abort_on_destroy: To allow destructive operations, set the TF_ENABLE_DESTROY variable to true."

function calculate_destroy_count {
  local plan_dir=$1
  grep 'Plan:' -R $plan_dir | grep 'to destroy' \
    | sed -n "s/^Plan: [0-9]* to add, [0-9]* to change, \([0-9]*\) to destroy./\1/p" \
    | awk 'NF{sum+=$1} END {print sum}' \
    || echo "0"
}

DESTROY_COUNT=$(calculate_destroy_count $PLAN_DIR)
[[ $DESTROY_COUNT -eq 0 ]] || {
  MSG="- tf_enable_destroy: $TF_ENABLE_DESTROY\n  plan_dir: $PLAN_DIR\n  destroy_count: $DESTROY_COUNT"
  echo -e "$MSG" >> abort_on_destroy

  echo "abort_on_destroy: Found [$DESTROY_COUNT] destroy operations in [$PLAN_DIR]! Aborting..."
  exit 1
}
