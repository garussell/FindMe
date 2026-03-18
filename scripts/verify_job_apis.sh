#!/bin/zsh
set -euo pipefail

ROOT_DIR=$(cd "$(dirname "$0")/.." && pwd)
CONFIG_DIR="$ROOT_DIR/FindMe/Config"
OUTPUT_DIR="${1:-/tmp/findme-job-api-verification}"
mkdir -p "$OUTPUT_DIR"

resolve_value() {
  local key="$1"

  if [[ -n "${(P)key:-}" ]]; then
    printf '%s' "${(P)key}"
    return 0
  fi

  if [[ -f "$CONFIG_DIR/APIConfig.local.plist" ]]; then
    local local_value
    local_value=$(/usr/libexec/PlistBuddy -c "Print ${key}" "$CONFIG_DIR/APIConfig.local.plist" 2>/dev/null || true)
    if [[ -n "${local_value}" ]]; then
      printf '%s' "$local_value"
      return 0
    fi
  fi

  if [[ -f "$CONFIG_DIR/APIConfig.plist" ]]; then
    local plist_value
    plist_value=$(/usr/libexec/PlistBuddy -c "Print ${key}" "$CONFIG_DIR/APIConfig.plist" 2>/dev/null || true)
    if [[ -n "${plist_value}" ]]; then
      printf '%s' "$plist_value"
      return 0
    fi
  fi

  return 1
}

write_summary() {
  local name="$1"
  local endpoint="$2"
  local auth="$3"
  local http_status="$4"
  local ok="$5"
  local note="$6"

  jq -n \
    --arg api "$name" \
    --arg endpoint "$endpoint" \
    --arg auth "$auth" \
    --arg status "$http_status" \
    --argjson ok "$ok" \
    --arg note "$note" \
    '{api:$api, endpoint:$endpoint, auth:$auth, http_status:$status, ok:$ok, note:$note}' \
    > "$OUTPUT_DIR/${name}.summary.json"
}

echo "Writing sanitized verification output to $OUTPUT_DIR"

ADZUNA_APP_ID=$(resolve_value ADZUNA_APP_ID)
ADZUNA_APP_KEY=$(resolve_value ADZUNA_APP_KEY)
ADZUNA_RAW="$OUTPUT_DIR/adzuna.raw.json"
ADZUNA_STATUS=$(curl -sS -o "$ADZUNA_RAW" -w '%{http_code}' "https://api.adzuna.com/v1/api/jobs/us/search/1?app_id=${ADZUNA_APP_ID}&app_key=${ADZUNA_APP_KEY}&results_per_page=1&what=ios&where=denver")
jq '{root_keys:(keys), result_count:(.results|length), first:(.results[0] | {id,title,created,company:(.company.display_name//null),location:(.location.display_name//null),salary_min,salary_max})}' "$ADZUNA_RAW" > "$OUTPUT_DIR/adzuna.sanitized.json"
write_summary "adzuna" "GET /v1/api/jobs/us/search/{page}" "query app_id + app_key" "$ADZUNA_STATUS" true "Live response returned."

JSEARCH_API_KEY=$(resolve_value JSEARCH_API_KEY)
JSEARCH_RAW="$OUTPUT_DIR/jsearch.raw.json"
JSEARCH_STATUS=$(curl -sS -o "$JSEARCH_RAW" -w '%{http_code}' 'https://jsearch.p.rapidapi.com/search?query=ios%20in%20denver&page=1&num_pages=1&country=us' -H 'x-rapidapi-host: jsearch.p.rapidapi.com' -H "x-rapidapi-key: ${JSEARCH_API_KEY}")
jq '{root_keys:(keys), message:(.message//null), count:(.data|length? // 0), first:(.data[0] | {job_id,job_title,employer_name,job_city,job_state,job_country,job_is_remote,job_posted_at_datetime_utc,job_min_salary,job_max_salary,job_salary_currency,job_employment_type,job_apply_link})}' "$JSEARCH_RAW" > "$OUTPUT_DIR/jsearch.sanitized.json"
if [[ "$JSEARCH_STATUS" == "200" ]]; then
  write_summary "jsearch" "GET /search" "RapidAPI headers" "$JSEARCH_STATUS" true "Live response returned."
else
  write_summary "jsearch" "GET /search" "RapidAPI headers" "$JSEARCH_STATUS" false "$(jq -r '.message // "Request failed."' "$JSEARCH_RAW")"
fi

USAJOBS_API_KEY=$(resolve_value USAJOBS_API_KEY)
USAJOBS_USER_AGENT=$(resolve_value USAJOBS_USER_AGENT)
USAJOBS_RAW="$OUTPUT_DIR/usajobs.raw.json"
USAJOBS_STATUS=$(curl -sS -o "$USAJOBS_RAW" -w '%{http_code}' 'https://data.usajobs.gov/api/search?Keyword=software&LocationName=Denver&Page=1&ResultsPerPage=1' -H "Authorization-Key: ${USAJOBS_API_KEY}" -H "User-Agent: ${USAJOBS_USER_AGENT}" -H 'Host: data.usajobs.gov')
jq '{root_keys:(keys), search_keys:(.SearchResult|keys), result_count:(.SearchResult.SearchResultItems|length), first:(.SearchResult.SearchResultItems[0].MatchedObjectDescriptor | {PositionID,PositionTitle,OrganizationName,PublicationStartDate,PositionLocationDisplay,PositionRemuneration,PositionSchedule,ApplyURI,PositionURI,UserArea:(.UserArea.Details | {JobSummary,RemoteIndicator})})}' "$USAJOBS_RAW" > "$OUTPUT_DIR/usajobs.sanitized.json"
write_summary "usajobs" "GET /api/search" "Authorization-Key + User-Agent headers" "$USAJOBS_STATUS" true "Live response returned."

BLS_API_KEY=$(resolve_value BLS_API_KEY || true)
BLS_RAW="$OUTPUT_DIR/bls.raw.json"
if [[ -n "${BLS_API_KEY}" ]]; then
  BLS_STATUS=$(curl -sS -o "$BLS_RAW" -w '%{http_code}' 'https://api.bls.gov/publicAPI/v2/timeseries/data/' -H 'Content-Type: application/json' -d "{\"seriesid\":[\"LNS14000000\"],\"startyear\":\"2025\",\"endyear\":\"2026\",\"registrationkey\":\"${BLS_API_KEY}\"}")
  write_summary "bls" "POST /publicAPI/v2/timeseries/data/" "registrationkey in JSON body" "$BLS_STATUS" true "Live response returned with configured key."
else
  BLS_STATUS=$(curl -sS -o "$BLS_RAW" -w '%{http_code}' 'https://api.bls.gov/publicAPI/v1/timeseries/data/LNS14000000')
  write_summary "bls" "GET /publicAPI/v1/timeseries/data/{seriesId}" "public unauthenticated request" "$BLS_STATUS" true "Live response returned without key."
fi
jq '{root_keys:(keys), status:(.status//null), responseTime:(.responseTime//null), series_count:(.Results.series|length), first:(.Results.series[0] | {seriesID, sample:(.data[0] | {year,period,periodName,value,latest})})}' "$BLS_RAW" > "$OUTPUT_DIR/bls.sanitized.json"

echo "API summaries:"
for file in "$OUTPUT_DIR"/*.summary.json; do
  jq -c '.' "$file"
done
