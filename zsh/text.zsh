# @cmd combinetext - Combine and deduplicate lines from local .txt files
combinetext() {
  if [[ "$1" == "--help" || "$1" == "-h" ]]; then
    cat <<'EOF'
Usage: combinetext

Combine lines from all *.txt files in the current directory,
sort them, and remove duplicate lines. Write to combined.txt.
The output is overwritten if it already exists.

Options:
  -h, --help  Show this help
EOF
    return 0
  fi
  cat *.txt | sort -u > combined.txt
}

