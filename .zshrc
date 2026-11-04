# Minimal Zsh bootstrap. Command implementations live in ~/dotfiles/zsh/.

export PATH="$HOME/.local/bin:$PATH"

# >>> conda initialize >>>
# !! Contents within this block are managed by 'conda init' !!
__conda_setup="$('/opt/miniconda3/bin/conda' 'shell.zsh' 'hook' 2> /dev/null)"
if [ $? -eq 0 ]; then
    eval "$__conda_setup"
else
    if [ -f "/opt/miniconda3/etc/profile.d/conda.sh" ]; then
        . "/opt/miniconda3/etc/profile.d/conda.sh"
    else
        export PATH="/opt/miniconda3/bin:$PATH"
    fi
fi
unset __conda_setup
# <<< conda initialize <<<

# Source command modules.
for file in "$HOME/dotfiles/zsh/"*.zsh(N); do
  source "$file"
done

zhelp() {
  if [[ "$1" == "--help" || "$1" == "-h" ]]; then
    cat <<'EOF'
Usage: zhelp [QUERY]

List or search commands documented in ~/dotfiles/zsh/*.zsh.
Commands are discovered from comments of the form:
  # @cmd command-name - Description

Examples:
  zhelp
  zhelp csv
  zhelp backup
EOF
    return 0
  fi

  local dir="$HOME/dotfiles/zsh"
  local query="$1"
  local records

  records=$(grep -hE '^# @cmd ' "$dir"/*.zsh 2>/dev/null | sed 's/^# @cmd //') || return 1

  if [[ -n "$query" ]]; then
    print -r -- "$records" | grep -i -- "$query" | sort
  else
    print -r -- "$records" | sort
  fi
}
