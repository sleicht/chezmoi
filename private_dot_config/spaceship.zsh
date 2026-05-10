# Spaceship prompt configuration - Managed by chezmoi

# Prompt shape
SPACESHIP_PROMPT_ASYNC=true
SPACESHIP_PROMPT_ADD_NEWLINE=false
SPACESHIP_PROMPT_SEPARATE_LINE=false
SPACESHIP_PROMPT_FIRST_PREFIX_SHOW=true
SPACESHIP_PROMPT_PREFIXES_SHOW=true
SPACESHIP_PROMPT_SUFFIXES_SHOW=true
SPACESHIP_PROMPT_DEFAULT_PREFIX=" "
SPACESHIP_PROMPT_DEFAULT_SUFFIX=" "
# Spaceship otherwise moves RPROMPT one row up/down for multi-line prompts.
# This setup is single-line, so keep the right prompt on the active prompt row.
SPACESHIP_RPROMPT_ADD_NEWLINE=true

SPACESHIP_PROMPT_ORDER=(
  session
  root
  dir
  git
  node
  java
  kotlin
  python
  ruby
  gcloud
  terraform
  exec_time
  time
  exit_code
  char
)

# Section styling
SPACESHIP_DIR_COLOR="#56B6C2"
SPACESHIP_DIR_PREFIX=" "
SPACESHIP_DIR_SUFFIX=" "
SPACESHIP_DIR_TRUNC=2
SPACESHIP_DIR_TRUNC_REPO=true

SPACESHIP_GIT_BRANCH_PREFIX=""
SPACESHIP_GIT_BRANCH_SUFFIX=""
SPACESHIP_GIT_STATUS_PREFIX=" "
SPACESHIP_GIT_STATUS_SUFFIX=" "
SPACESHIP_GIT_STATUS_SHOW=true

SPACESHIP_NODE_PREFIX=" "
SPACESHIP_NODE_SYMBOL=" "
SPACESHIP_NODE_COLOR="#62ED8B"

SPACESHIP_JAVA_PREFIX=" "
SPACESHIP_JAVA_SYMBOL=" "
SPACESHIP_JAVA_COLOR="#E36464"

SPACESHIP_KOTLIN_PREFIX=" "
SPACESHIP_KOTLIN_SYMBOL="K "
SPACESHIP_KOTLIN_COLOR="#D4AAFC"

SPACESHIP_PYTHON_PREFIX=" "
SPACESHIP_PYTHON_SYMBOL=" "
SPACESHIP_PYTHON_COLOR="#DDB15F"

SPACESHIP_RUBY_PREFIX=" "
SPACESHIP_RUBY_SYMBOL=" "
SPACESHIP_RUBY_COLOR="#E36464"

SPACESHIP_GCLOUD_PREFIX=" "
SPACESHIP_GCLOUD_SYMBOL=" "
SPACESHIP_GCLOUD_COLOR="#56B6C2"

spaceship_gcloud() {
  [[ "$SPACESHIP_GCLOUD_SHOW" == false ]] && return
  spaceship::exists gcloud || return

  local gcloud_dir=${CLOUDSDK_CONFIG:-"${HOME}/.config/gcloud"}
  [[ -f "$gcloud_dir/active_config" ]] || return

  local gcloud_active_config=${CLOUDSDK_ACTIVE_CONFIG_NAME:-"$(head -n1 "$gcloud_dir/active_config")"}
  local gcloud_active_config_file="$gcloud_dir/configurations/config_$gcloud_active_config"
  [[ -f "$gcloud_active_config_file" ]] || return

  local gcloud_active_project
  gcloud_active_project=$(sed -n 's/project = \(.*\)/\1/p' "$gcloud_active_config_file")

  local gcloud_status="$gcloud_active_project"
  if [[ "$gcloud_active_config" != default ]]; then
    gcloud_status="$gcloud_active_config/$gcloud_active_project"
  fi
  [[ -n "$gcloud_status" ]] || return

  spaceship::section::v4 \
    --color "$SPACESHIP_GCLOUD_COLOR" \
    --prefix "$SPACESHIP_GCLOUD_PREFIX" \
    --suffix "$SPACESHIP_GCLOUD_SUFFIX" \
    --symbol "$SPACESHIP_GCLOUD_SYMBOL" \
    "$gcloud_status"
}

SPACESHIP_TERRAFORM_PREFIX=" "
SPACESHIP_TERRAFORM_SYMBOL=""
SPACESHIP_TERRAFORM_COLOR="#D4AAFC"

SPACESHIP_EXEC_TIME_PREFIX=" "
SPACESHIP_EXEC_TIME_SUFFIX=" "
SPACESHIP_EXEC_TIME_SYMBOL=" "
SPACESHIP_EXEC_TIME_COLOR="#DCB977"

SPACESHIP_TIME_SHOW=true
SPACESHIP_TIME_PREFIX=" "
SPACESHIP_TIME_SUFFIX=" "
SPACESHIP_TIME_SYMBOL=" "
SPACESHIP_TIME_FORMAT="%H:%M"
SPACESHIP_TIME_COLOR="#DCB977"

SPACESHIP_EXIT_CODE_SHOW=true
SPACESHIP_EXIT_CODE_PREFIX=" "
SPACESHIP_EXIT_CODE_SYMBOL=""
SPACESHIP_EXIT_CODE_COLOR="#E36464"

SPACESHIP_CHAR_SYMBOL="❯"
SPACESHIP_CHAR_SUFFIX=" "
SPACESHIP_CHAR_COLOR_SUCCESS="#DCB977"
SPACESHIP_CHAR_COLOR_FAILURE="#E36464"

# Custom sections
SPACESHIP_SESSION_SHOW=true
SPACESHIP_SESSION_PREFIX=" "
SPACESHIP_SESSION_SUFFIX=" "
SPACESHIP_SESSION_COLOR="#D4AAFC"

spaceship_session() {
  [[ "$SPACESHIP_SESSION_SHOW" == false ]] && return

  spaceship::section::v4 \
    --color "$SPACESHIP_SESSION_COLOR" \
    --prefix "$SPACESHIP_SESSION_PREFIX" \
    --suffix "$SPACESHIP_SESSION_SUFFIX" \
    "${SHELL:t}"
}

SPACESHIP_ROOT_SHOW=true
SPACESHIP_ROOT_PREFIX=" "
SPACESHIP_ROOT_SUFFIX=" "
SPACESHIP_ROOT_SYMBOL=""
SPACESHIP_ROOT_COLOR="#E36464"

spaceship_root() {
  [[ "$SPACESHIP_ROOT_SHOW" == false ]] && return
  (( EUID == 0 )) || return

  spaceship::section::v4 \
    --color "$SPACESHIP_ROOT_COLOR" \
    --prefix "$SPACESHIP_ROOT_PREFIX" \
    --suffix "$SPACESHIP_ROOT_SUFFIX" \
    "$SPACESHIP_ROOT_SYMBOL"
}
