# @cmd simclean - Delete unused Xcode simulator runtimes
simclean() {
  if [[ "$1" == "--help" || "$1" == "-h" ]]; then
    cat <<'EOF'
Usage: simclean [DAYS] [--dry-run]

Delete unused Xcode simulator runtimes.

Options:
  DAYS        Days since last use (default: 90)
  --dry-run   Preview without deleting
  -h, --help  Show this help
EOF
    return 0
  fi

  local days="${1:-90}"
  if [[ "$1" =~ ^[0-9]+$ ]]; then
    shift
  elif [[ -n "$1" && "$1" != "--dry-run" ]]; then
    echo "Unknown argument: $1" >&2
    return 2
  fi

  xcrun simctl runtime delete --notUsedSinceDays "$days" "$@"
}

# @cmd bud - Run Homebrew update and upgrade
bud() {
  if [[ "$1" == "--help" || "$1" == "-h" ]]; then
    cat <<'EOF'
Usage: bud

Run Homebrew update followed by upgrade.
Does not run brew cleanup.

Options:
  -h, --help  Show this help
EOF
    return 0
  fi
  brew update && brew upgrade
}

# Get the current year
current_year=$(date +%Y)

# @cmd django - Run the current Django development server
django() {
  if [[ "$1" == "--help" || "$1" == "-h" ]]; then
    cat <<'EOF'
Usage: django [runserver options]

Run the current Django project's development server via
python3 manage.py runserver. Arguments are forwarded to runserver.

Options:
  -h, --help  Show this wrapper help
EOF
    return 0
  fi
  python3 manage.py runserver "$@"
}

# @cmd serve - Serve a local directory over HTTP on an available port
serve() {
  if [[ "$1" == "--help" || "$1" == "-h" ]]; then
    cat <<'EOF'
Usage: serve [port] [-d|--directory <path>] [http.server options]

Serve a directory using Python's HTTP server, bound to 127.0.0.1.
Default port: 8000. Default directory: current working directory.
If the requested port is in use, choose a free port automatically.
Remaining arguments are forwarded to python3 -m http.server.

Options:
  -d, --directory <path>  Directory to serve
  -h, --help              Show this help
EOF
    return 0
  fi
  local port=8000 dir="$PWD"
  if [[ "$1" =~ '^[0-9]+$' ]]; then port="$1"; shift; fi
  while (( $# )); do
    case "$1" in
      -h|--help)
        serve --help
        return 0
        ;;
      -d|--directory) dir="${2:?serve: $1 requires a directory}"; shift 2 ;;
      *) break ;;
    esac
  done
  if lsof -nP -iTCP:"$port" -sTCP:LISTEN >/dev/null 2>&1; then
    local new_port
    new_port=$(python3 -c 'import socket; s=socket.socket(); s.bind(("127.0.0.1",0)); print(s.getsockname()[1])')
    echo "Port $port is in use; using $new_port instead."
    port=$new_port
  fi
  echo "Serving $dir at http://localhost:$port/"
  python3 -m http.server "$port" --bind 127.0.0.1 --directory "$dir" "$@"
}

export PATH="$HOME/.local/bin:$PATH"

# @cmd toolserve - Serve the configured html-tools directory
toolserve() {
  if [[ "$1" == "--help" || "$1" == "-h" ]]; then
    cat <<'EOF'
Usage: toolserve

Serve /Users/kmccraney/Developer/html-tools on localhost,
starting at port 6969 (or a free port if 6969 is occupied).

Options:
  -h, --help  Show this help
EOF
    return 0
  fi
  serve 6969 -d /Users/kmccraney/Developer/html-tools
}

# @cmd btools - Start toolserve and open it in Chrome
btools() {
  if [[ "$1" == "--help" || "$1" == "-h" ]]; then
    cat <<'EOF'
Usage: btools

Start toolserve in the background, open Chrome at
http://localhost:6969/, and bring the server job to the foreground.

Options:
  -h, --help  Show this help

Note: If port 6969 is occupied, serve may choose another port,
but this function still opens 6969.
EOF
    return 0
  fi
  toolserve &
  sleep 1 && open -a "Google Chrome" "http://localhost:6969/"
  fg
}

