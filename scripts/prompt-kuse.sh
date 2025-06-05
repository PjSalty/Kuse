#!/usr/bin/env bash
#
# prompt-kuse.sh (256-color version)
#
# If sourced, this updates PS1 to include CURRENT_KUBE_FOLDER in a
# hash-derived 256-color. We map each folder name to one of the 216 “color cube”
# entries (indices 16–231).

# 1) Function: compute a color index (16..231) from folder name
get_256color_for_folder() {
  local folder="$1"
  local sum=0
  local i char

  for (( i=0; i<${#folder}; i++ )); do
    # Get ASCII code of each character, add it up
    char=$(printf "%d" "'${folder:i:1}")
    (( sum += char ))
  done

  # There are 216 “cube” colors from index 16 to 231
  local index=$(( 16 + (sum % 216) ))
  echo "$index"
}

# 2) Build an ANSI escape sequence for “foreground = 256-color <n>”
ansi_fg256() {
  local idx="$1"
  printf "\[\e[38;5;%sm\]" "$idx"
}

# 3) Reset colors back to default
ansi_reset() {
  printf "\[\e[0m\]"
}

# 4) update_prompt – invoked before each PS1
update_prompt() {
  local kube_part=""

  if [ -n "${CURRENT_KUBE_FOLDER:-}" ]; then
    local color_idx
    color_idx=$(get_256color_for_folder "$CURRENT_KUBE_FOLDER")

    local color_start
    color_start=$(ansi_fg256 "$color_idx")
    local color_end
    color_end=$(ansi_reset)

    kube_part=" (${color_start}${CURRENT_KUBE_FOLDER}${color_end})"
  fi

  PS1="${debian_chroot:+($debian_chroot)}\[\033[01;32m\]\u@\h\[\033[00m\]:\
\[\033[01;34m\]\w\[\033[00m\]${kube_part}\$ "
}

# 5) Ensure update_prompt runs before each prompt
PROMPT_COMMAND="update_prompt${PROMPT_COMMAND:+; }$PROMPT_COMMAND"
