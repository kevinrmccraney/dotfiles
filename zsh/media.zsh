# @cmd tiffconvert - Convert TIFF files to PNG or JPEG
tiffconvert() {
  if [[ "$1" == "--help" || "$1" == "-h" ]]; then
    cat <<'EOF'
Usage: tiffconvert PATH [png|jpg]

Convert one TIFF file, or recursively convert TIFF files in a directory.
Default output format is PNG; use jpg for JPEG output.

Options:
  -h, --help  Show this help

Requires: macOS sips
EOF
    return 0
  fi

  local p="$1"
  local f="${2:-png}"
  local sf="$f"
  [[ "$f" == "jpg" ]] && sf="jpeg"

  if [[ -f "$p" ]]; then
    sips -s format "$sf" "$p" --out "${p%.*}.$f"
  else
    find "$p" -type f \( -iname '*.tif' -o -iname '*.tiff' \) -print0 |
      while IFS= read -r -d '' x; do
        sips -s format "$sf" "$x" --out "${x%.*}.$f"
      done
  fi
}

# @cmd avi2mp4 - Convert AVI files to MP4, remuxing when possible
avi2mp4() {
  if [[ "$1" == "--help" || "$1" == "-h" ]]; then
    cat <<'EOF'
Usage: avi2mp4 [file.avi|directory]

Convert one AVI file, or recursively convert AVI files in a directory.
Defaults to the current directory. First tries lossless remuxing, then
falls back to H.264/AAC encoding. Preserves modification timestamps.
Existing MP4 outputs are skipped; original AVI files are retained.

Options:
  -h, --help  Show this help

Requires: ffmpeg
EOF
    return 0
  fi

  local input="${1:-.}"
  local file output tmp

  if ! command -v ffmpeg >/dev/null 2>&1; then
    echo "Error: ffmpeg is not installed." >&2
    return 1
  fi

  if [[ ! -e "$input" ]]; then
    echo "Error: Path does not exist: $input" >&2
    return 1
  fi

  _avi2mp4_convert() {
    local file="$1"
    local output="${file%.*}.mp4"
    local tmp="${file%.*}.avi2mp4.tmp.mp4"

    if [[ -e "$output" ]]; then
      echo "Skipping (exists): $output"
      return 0
    fi

    echo "Converting: $file"
    if ffmpeg -hide_banner -loglevel error -nostdin \
        -i "$file" \
        -map 0:v -map 0:a? \
        -c copy \
        -map_metadata 0 \
        -map_chapters 0 \
        -y "$tmp"; then
      echo "  Lossless remux successful."
    else
      echo "  Remux failed; re-encoding..."
      rm -f "$tmp"
      if ! ffmpeg -hide_banner -loglevel error -nostdin \
          -i "$file" \
          -map 0:v:0 -map 0:a? \
          -c:v libx264 -crf 18 -preset slow \
          -c:a aac -b:a 192k \
          -pix_fmt yuv420p \
          -map_metadata 0 \
          -map_chapters 0 \
          -y "$tmp"; then
        echo "  ERROR: Conversion failed: $file" >&2
        rm -f "$tmp"
        return 1
      fi
    fi

    touch -r "$file" "$tmp"
    mv "$tmp" "$output"
    echo "  Saved: $output"
  }

  local failures=0
  if [[ -f "$input" ]]; then
    if [[ "${input,,}" != *.avi ]]; then
      echo "Error: Not an AVI file: $input" >&2
      return 1
    fi
    _avi2mp4_convert "$input" || failures=$((failures + 1))
  elif [[ -d "$input" ]]; then
    while IFS= read -r -d '' file; do
      _avi2mp4_convert "$file" || failures=$((failures + 1))
    done < <(find "$input" -type f -iname "*.avi" -print0)
  else
    echo "Error: Not a regular file or directory: $input" >&2
    return 1
  fi

  unset -f _avi2mp4_convert
  if (( failures > 0 )); then
    echo "Completed with $failures failure(s)." >&2
    return 1
  fi
}

# Show the N largest files in a directory.
# Usage: largestfiles [directory] [count]

# @cmd transcribe - Transcribe audio to text with parakeet-mlx
transcribe() {
  if [[ "$1" == "--help" || "$1" == "-h" ]]; then
    cat <<'EOF'
Usage: transcribe <audio-file> [additional files/options ...]

Transcribe audio using parakeet-mlx, forcing plain-text output.
All supplied arguments are forwarded to parakeet-mlx.

Options:
  -h, --help  Show this wrapper help
EOF
    return 0
  fi
  parakeet-mlx "$@" --output-format txt
}

# Effective behavior of the last of the original duplicate 'bud' aliases.

# @cmd vcut - Split a video into fixed-duration segments
vcut() {
  if [[ "$1" == "--help" || "$1" == "-h" ]]; then
    cat <<'EOF'
Usage: vcut <video-file> <segment-duration-seconds>

Split a video into numbered segments with ffmpeg, copying streams
without re-encoding. Output files use <name>_000.<extension>, etc.

Options:
  -h, --help  Show this help

Requires: ffmpeg
EOF
    return 0
  fi
  local f="$1" name="${1:t:r}" ext="${1:e}"
  ffmpeg -i "$f" -c copy -map 0 -f segment -segment_time "$2" -reset_timestamps 1 "${name}_%03d.${ext}"
}

# @cmd ytdl - Resume yt-dlp downloads from the configured batch file
ytdl() {
  if [[ "$1" == "--help" || "$1" == "-h" ]]; then
    cat <<'EOF'
Usage: ytdl [yt-dlp options]

Resume downloads from /Users/kmccraney/youtube.txt using yt-dlp.
Additional options are forwarded to yt-dlp.

Options:
  -h, --help  Show this wrapper help
EOF
    return 0
  fi
  yt-dlp -c --batch-file /Users/kmccraney/youtube.txt "$@"
}

# @cmd append-txt-extension - Replace a path extension with .txt
append-txt-extension() {
  if [[ "$1" == "--help" || "$1" == "-h" ]]; then
    cat <<'EOF'
Usage: append-txt-extension <path>

Replace the input path's extension with .txt and print the result.

Options:
  -h, --help  Show this help
EOF
    return 0
  fi
  local input_file="$1"
  local base_name="${input_file%.*}"
  echo "${base_name}.txt"
}

# @cmd ocr - Run the ocr-text macOS Shortcut and save clipboard output
ocr() {
  if [[ "$1" == "--help" || "$1" == "-h" ]]; then
    cat <<'EOF'
Usage: ocr <input-file> [output-file]

Run the macOS Shortcut named ocr-text for the input file and write
clipboard text to the output file. If omitted, output is input-name.txt.

Options:
  -h, --help  Show this help

Requires: macOS shortcuts, Shortcut "ocr-text"
EOF
    return 0
  fi
  local input_file="$1"
  local output_file="$2"
  [[ -z "$output_file" ]] && output_file=$(append-txt-extension "$input_file")
  shortcuts run ocr-text -i "$input_file" | pbpaste > "$output_file"
}

# @cmd fake-scan - Apply a scanned-document effect with ImageMagick
alias fake-scan='function _fake_scan(){ convert -density 300 "$1" -alpha remove -rotate 0.33 -attenuate 0.15 +noise Multiplicative +repage -monochrome -compress group4 "$2"; }; _fake_scan'
