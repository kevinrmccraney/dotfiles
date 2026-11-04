# @cmd colcp - Extract a named column from CSV/TSV or delimited text
colcp() {
  local include_header=0
  local delimiter=""

  usage() {
    cat <<'EOF'
Usage:
  colcp [options] FILE COLUMN

Extract a column by header name from a delimited text file.

Options:
  -h, --header          Include the header row in output
  -d, --delimiter CHAR  Override the delimiter
      --help            Show this help message

Delimiter inference:
  .csv  comma
  .tsv  tab
  other comma

Examples:
  colcp data.csv title
  colcp -h data.tsv title
  colcp -d '|' data.txt name
  colcp data.csv title > titles.txt
EOF
  }

  while [[ "$1" == -* ]]; do
    case "$1" in
      -h|--header)
        include_header=1
        shift
        ;;
      -d|--delimiter)
        if [[ -z "$2" ]]; then
          echo "Error: --delimiter requires a value" >&2
          return 2
        fi
        delimiter="$2"
        shift 2
        ;;
      --help)
        usage
        return 0
        ;;
      *)
        echo "Error: unknown option: $1" >&2
        usage >&2
        return 2
        ;;
    esac
  done

  local file="$1"
  local column="$2"

  if [[ -z "$file" || -z "$column" ]]; then
    usage >&2
    return 2
  fi

  if [[ -z "$delimiter" ]]; then
    case "$file" in
      *.tsv) delimiter=$'\t' ;;
      *.csv) delimiter=',' ;;
      *)     delimiter=',' ;;
    esac
  fi

  awk -F"$delimiter" -v target="$column" -v header="$include_header" '
    NR == 1 {
      for (i = 1; i <= NF; i++) {
        if ($i == target) {
          col = i
          break
        }
      }

      if (!col) {
        print "Error: column \"" target "\" not found" > "/dev/stderr"
        exit 1
      }

      if (header)
        print $col

      next
    }

    { print $col }
  ' "$file"
}

# @cmd filter_http - Keep blank lines and unique HTTP URLs from a text file
filter_http() {
  if [[ "$1" == "--help" || "$1" == "-h" ]]; then
    cat <<'EOF'
Usage: filter_http <input-file>

Write <input-file-without-extension>-filtered.txt containing blank lines
and unique lines starting with "http". Later duplicate URLs are omitted.

Options:
  -h, --help  Show this help
EOF
    return 0
  fi
  awk '/^\r?$/ || (/^http/ && !seen[$0]++)' "$1" > "${1%.*}-filtered.txt"
}

# @cmd split_buckets - Run the bucket CSV filter/deduplicate/split script
split_buckets() {
  if [[ "$1" == "--help" || "$1" == "-h" ]]; then
    cat <<'EOF'
Usage: split_buckets [script arguments]

Run filter_deduplicate_and_split_bucket_csvs.py using python3.
Pass any supplied arguments directly to the script.

Options:
  -h, --help  Show this wrapper help
EOF
    return 0
  fi
  python3 "/Users/kmccraney/Developer/scripts-and-config/filter_deduplicate_and_split_bucket_csvs.py" "$@"
}

