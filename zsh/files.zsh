# @cmd birthdate - Gets the birthdate of a file or directory
birthdate() {
  [ "$1" = "--help" ] && { echo "Usage: birthdate <file-or-directory>"; return; }

  if [ -f "$1" ]; then
    stat -f "%SB" -t "%Y%m%d%H%M" "$1"
  elif [ -d "$1" ]; then
    for f in "$1"/*; do
      [ -f "$f" ] && printf '%s\t%s\n' "$(stat -f "%SB" -t "%Y%m%d%H%M" "$f")" "$f"
    done
  else
    echo "birthdate: file or directory not found: $1" >&2
    return 1
  fi
}

# @cmd copyfiles - Copy matching files into a named subdirectory
copyfiles() {
  local delete=false
  local search=""

  while [[ $# -gt 0 ]]; do
    case "$1" in
      -h|--help)
        cat <<'EOF'
Usage: copyfiles [-d|--delete] <search-string>

Finds files in the current directory whose filenames contain
the specified string (case-insensitive), then copies them
into a subdirectory named after that string.

Options:
  -d, --delete  Delete originals after successful copying
  -h, --help    Show this help message

Behavior:
  - Searches the current directory only (not recursively)
  - Matches filenames case-insensitively
  - Creates the destination directory if needed
  - Never overwrites existing destination files
  - Preserves originals unless --delete is specified
  - Runs silently unless an error occurs

Examples:
  copyfiles copy
  copyfiles --delete copy
  copyfiles -d "draft"
EOF
        return 0
        ;;
      -d|--delete) delete=true ;;
      -*) echo "Unknown option: $1" >&2; return 1 ;;
      *)
        if [[ -n "$search" ]]; then
          echo "Error: Only one search string is allowed." >&2
          return 1
        fi
        search="$1"
        ;;
    esac
    shift
  done

  if [[ -z "$search" || "$search" == "." || "$search" == ".." || "$search" == */* ]]; then
    echo "Error: Provide a valid search string." >&2
    return 1
  fi

  mkdir -p -- "$search" || return 1

  local file target
  while IFS= read -r -d '' file; do
    target="./$search/${file#./}"
    [[ -e "$target" || -L "$target" ]] && continue
    if cp -n -- "$file" "$target"; then
      [[ "$delete" == true ]] && rm -- "$file"
    fi
  done < <(find . -maxdepth 1 -type f -iname "*$search*" -print0)
}

# @cmd largestfiles - List the largest files recursively
largestfiles() {
  if [[ "$1" == "--help" || "$1" == "-h" ]]; then
    cat <<'EOF'
Usage: largestfiles [directory] [count]

List the largest files recursively by file size, largest first.
Defaults: directory=$HOME, count=20.

Options:
  -h, --help  Show this help
EOF
    return 0
  fi

  local dir="${1:-$HOME}"
  local count="${2:-20}"
  find "$dir" -type f -exec stat -f '%z %N' {} + 2>/dev/null |
    sort -rn |
    head -n "$count" |
    awk '{
      size=$1
      $1=""
      sub(/^ /, "")
      split("B KB MB GB TB", units, " ")
      i=1
      while (size >= 1024 && i < 5) {
        size /= 1024
        i++
      }
      printf "%8.2f %-2s  %s\n", size, units[i], $0
    }'
}

# Show the N largest directories, measured by disk usage.
# Usage: largestdirs [directory] [count]

# @cmd largestdirs - List the largest directories by disk usage
largestdirs() {
  if [[ "$1" == "--help" || "$1" == "-h" ]]; then
    cat <<'EOF'
Usage: largestdirs [directory] [count]

List the largest disk-usage totals for directories within two levels.
Defaults: directory=$HOME, count=20.

Options:
  -h, --help  Show this help
EOF
    return 0
  fi

  local dir="${1:-$HOME}"
  local count="${2:-20}"
  du -k -d 2 "$dir" 2>/dev/null |
    sort -rn |
    head -n "$count" |
    awk '{
      size=$1 * 1024
      $1=""
      sub(/^ /, "")
      split("B KB MB GB TB", units, " ")
      i=1
      while (size >= 1024 && i < 5) {
        size /= 1024
        i++
      }
      printf "%8.2f %-2s  %s\n", size, units[i], $0
    }'
}

# Show disk usage and available space.

# @cmd diskspace - Show root filesystem disk usage
diskspace() {
  if [[ "$1" == "--help" || "$1" == "-h" ]]; then
    cat <<'EOF'
Usage: diskspace

Show filesystem capacity, used space, and available space for /.

Options:
  -h, --help  Show this help
EOF
    return 0
  fi
  df -h /
}

# @cmd makeproj - Create the standard year-prefixed project directory structure
makeproj() {
  if [[ "$1" == "--help" || "$1" == "-h" ]]; then
    cat <<'EOF'
Usage: makeproj <project_name>

Create a directory named YEAR_project_name with subdirectories:
admin, final_deliverables, highlights, highlights_edited,
from_source, and unedited_rest.

Options:
  -h, --help  Show this help
EOF
    return 0
  fi
  [[ -z "$1" ]] && { echo "Usage: makeproj <project_name>"; return 1; }
  local project_name="$(date +%Y)_$1"
  mkdir -p "$project_name"/{admin,final_deliverables,highlights,highlights_edited,from_source,unedited_rest}
  echo "Created $project_name"
}

# @cmd sortfiles - Sort files into folders based on filename suffixes
sortfiles() {
  if [[ "$1" == "--help" || "$1" == "-h" ]]; then
    cat <<'EOF'
Usage: sortfiles [separator] [extension]

Move files in the current directory into folders named after the
text following the final separator in each filename (minus extension).
Defaults: separator=" - ", extension=pdf.
Does not overwrite destination files.

Options:
  -h, --help  Show this help

Example:
  sortfiles " - " pdf
EOF
    return 0
  fi
  emulate -L zsh
  setopt null_glob

  local sep="${1:- - }"
  local ext="${2:-pdf}"
  ext="${ext#.}"
  ext="${ext:l}"

  local f base category
  for f in *(N); do
    [[ -f "$f" ]] || continue
    [[ "${f:e:l}" == "$ext" ]] || continue

    base="${f%.*}"
    [[ "$base" == *"$sep"* ]] || continue

    category="${base##*"$sep"}"
    [[ -n "$category" ]] || continue

    mkdir -p -- "$category" && mv -n -- "$f" "$category/"
  done
}

# Filter, deduplicate, and split bucket CSV exports.

# @cmd copy-matching-photos - Copy files named in a text list into keep/
copy-matching-photos() {
  if [[ "$1" == "--help" || "$1" == "-h" ]]; then
    cat <<'EOF'
Usage: copy-matching-photos <text-file> <source-directory>

Read filenames from the text file and copy matching files from the source
directory into a keep/ subdirectory.

Options:
  -h, --help  Show this help
EOF
    return 0
  fi

  local TEXT_FILE="$1"
  local SOURCE_DIR="$2"
  local DEST_DIR="keep"

  if [[ ! -f "$TEXT_FILE" ]]; then
    echo "Text file not found: $TEXT_FILE"
    return 1
  fi
  if [[ ! -d "$SOURCE_DIR" ]]; then
    echo "Source directory not found: $SOURCE_DIR"
    return 1
  fi

  mkdir -p "$SOURCE_DIR/$DEST_DIR"
  while IFS= read -r line; do
    if [[ -f "$SOURCE_DIR/$line" ]]; then
      echo "Copying $line to $DEST_DIR"
      cp "$SOURCE_DIR/$line" "$SOURCE_DIR/$DEST_DIR/"
    else
      echo "File $line not found in $SOURCE_DIR"
    fi
  done < "$TEXT_FILE"
  echo "Finished processing."
}

