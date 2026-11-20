# @cmd reset-mac - Generate and apply a random MAC address to en0
reset-mac() {
  if [[ "$1" == "--help" || "$1" == "-h" ]]; then
    cat <<'EOF'
Usage: reset-mac

Generate a random locally administered MAC address for en0,
apply it with sudo ifconfig, and cycle Wi-Fi power.
This changes network configuration and may interrupt connectivity.

Options:
  -h, --help  Show this help without changing anything
EOF
    return 0
  fi
  local new_mac="02:$(openssl rand -hex 5 | sed 's/\(..\)/\1:/g; s/:$//')"
  networksetup -setairportpower en0 on
  sudo ifconfig en0 ether "$new_mac" && echo "New MAC address for en0: $new_mac"
  networksetup -setairportpower en0 off; sleep 2; networksetup -setairportpower en0 on
}

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

