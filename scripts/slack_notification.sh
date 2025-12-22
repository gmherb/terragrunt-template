#!/usr/bin/env bash

set -exuEo pipefail

#
# This script forwards the build results to a slack channel.
#
# It only checks for environment-specific plan files, and does not check for global plan files.
#

readonly PROJECT_URL="https://github.com/gmherb/terragrunt-template"

readonly SLACK_WEBHOOK_URL=${SLACK_WEBHOOK_URL:-"https://hooks.slack.com/services/ADD_SLACK_WEBHOOK_PARTIAL_URL_HERE"}

readonly BUILD_NUMBER=${BUILD_NUMBER:-"null"}
# Exit if not running in Jenkins
[[ $BUILD_NUMBER == "null" ]] && exit 0
# Uncomment to run tests
#readonly BUILD_TAG="TEST_TAG"
#readonly BUILD_URL="TEST_URL"
#readonly BRANCH_NAME="TEST_BRANCH"

# Obtain abort_on_destroy information if it exists
if [ -f abort_on_destroy ]; then
  TF_ENABLE_DESTROY=$(jq -r '.tf_enable_destroy' abort_on_destroy)
  PLAN_DIR=$(jq -r '.plan_dir' abort_on_destroy)
  DESTROY_COUNT=$(jq -r '.destroy_count' abort_on_destroy)
fi

function failure_notification {
  curl -s -X POST -d "payload={\"text\": \"Slack notification for *terragrunt-template* [$BUILD_URL] *FAILED!*\", \"icon_emoji\": \":warning:\"}" $SLACK_WEBHOOK_URL
}
trap failure_notification ERR

GIT_LOG_JSON=$(jc --pretty git log -1)
AUTHOR=$(jq -r '.[].author_email' <<< $GIT_LOG_JSON)
COMMIT_DATE=$(jq -r '.[].date' <<< $GIT_LOG_JSON)
COMMIT_MESSAGE=$(jq -r '.[].message' <<< $GIT_LOG_JSON)
COMMIT=$(jq -r '.[].commit' <<< $GIT_LOG_JSON)
COMMIT_SHORT=${COMMIT:0:8}
COMMIT_URL=$PROJECT_URL/commits/$COMMIT

declare -A UNIT_COUNT
UNIT_COUNT["dev"]=$(find dev/ -name terragrunt.hcl  -not -path "*/.terragrunt-cache/*" | wc -l | tr -d ' ')
UNIT_COUNT["prod"]=$(find prod/ -name terragrunt.hcl  -not -path "*/.terragrunt-cache/*" | wc -l | tr -d ' ')

declare -A NO_CHANGES
NO_CHANGES["dev"]=$(grep -c '^No changes. Your infrastructure matches the configuration.' plan-dev* || true)
NO_CHANGES["prod"]=$(grep -c '^No changes. Your infrastructure matches the configuration.' plan-prod* || true)

declare -A OUTPUT_CHANGES
OUTPUT_CHANGES["dev"]=$(grep -c '^Changes to Outputs:' plan-dev* || true)
OUTPUT_CHANGES["prod"]=$(grep -c '^Changes to Outputs:' plan-prod* || true)

declare -A PLANS
PLANS["dev"]=$(grep -c '^Plan: ' plan-dev* || true)
PLANS["prod"]=$(grep -c '^Plan: ' plan-prod* || true)

function parse_plan {
   local env=$1
   local plan_file=$2
   local plan_count=$(sed 's/"//g' <<< ${PLANS[$env]})

   [[ "$plan_count" -gt 0 ]] \
       && sed -n '/Terraform will perform the following actions:/, /Saved the plan to: /{ /Saved the plan to: /!p}' $plan_file \
	      | awk 'NF {sub(/\r/, ""); printf "%s\\n",$0;}' \
	      | sed 's/"/\\"/g' \
	   || echo "No Changes."
}

DEV_BUILD_RESULTS=$(parse_plan dev plan-dev*)
PROD_BUILD_RESULTS=$(parse_plan prod plan-prod*)

PAYLOAD=$(cat <<EOF
{
	"icon_emoji": ":announcement:",
	"username": "$BUILD_TAG",
    "text": "Terragrunt (terragrunt-template) build results",
	"blocks": [
		{
			"type": "section",
			"text": {
				"type": "mrkdwn",
				"text": "*Terragrunt (terragrunt-template)*: *<$BUILD_URL|$BUILD_TAG>*"
			}
		},
		{
			"type": "section",
			"fields": [
				{
					"type": "mrkdwn",
					"text": "*Author:* $AUTHOR"
				},
				{
					"type": "mrkdwn",
					"text": "*Branch/PR:* $BRANCH_NAME"
				},
				{
					"type": "mrkdwn",
					"text": "*Commit:* <$COMMIT_URL|$COMMIT_SHORT>"
				},
				{
					"type": "mrkdwn",
					"text": "*Commit Message:* $COMMIT_MESSAGE"
				}
			]
		},
		{
			"type": "rich_text",
			"elements": [
				{
					"type": "rich_text_section",
					"elements": [
						{
							"type": "text",
							"text": "Development:",
							"style": {
								"bold": true
							}
						}
					]
				}
			]
		},
		{
			"type": "rich_text",
			"elements": [
				{
					"type": "rich_text_preformatted",
					"elements": [
						{
							"type": "text",
							"text": "$DEV_BUILD_RESULTS"
						}
					]
				}
			]
		},
		{
			"type": "rich_text",
			"elements": [
				{
					"type": "rich_text_section",
					"elements": [
						{
							"type": "text",
							"text": "No Changes [${NO_CHANGES["dev"]}], Output Changes [${OUTPUT_CHANGES["dev"]}], Changes [${PLANS["dev"]}], Total Units [${UNIT_COUNT["dev"]}] ...",
							"style": {
								"italic": true
							}
						}
					]
				}
			]
		},
		{
			"type": "rich_text",
			"elements": [
				{
					"type": "rich_text_section",
					"elements": [
						{
							"type": "text",
							"text": "Production:",
							"style": {
								"bold": true
							}
						}
					]
				}
			]
		},
		{
			"type": "rich_text",
			"elements": [
				{
					"type": "rich_text_preformatted",
					"elements": [
						{
							"type": "text",
							"text": "$PROD_BUILD_RESULTS"
						}
					]
				}
			]
		},
		{
			"type": "rich_text",
			"elements": [
				{
					"type": "rich_text_section",
					"elements": [
						{
							"type": "text",
							"text": "No Changes [${NO_CHANGES["prod"]}], Output Changes [${OUTPUT_CHANGES["prod"]}], Changes [${PLANS["prod"]}], Total Units [${UNIT_COUNT["prod"]}] ...",
							"style": {
								"italic": true
							}
						}
					]
				}
			]
		}
	]
}
EOF)

CURL_RESPONSE=$(curl -s -X POST -d "$PAYLOAD" $SLACK_WEBHOOK_URL)

[[ "$CURL_RESPONSE" == "ok" ]] || failure_notification

exit 0
