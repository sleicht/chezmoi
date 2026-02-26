# Managed by chezmoi - edit in ~/.local/share/chezmoi/dot_zsh.d/
#!/usr/bin/env zsh

# `sdkmanrc-shim.zsh` bridges .sdkmanrc files with mise for Java version management.
#
# Workaround for https://github.com/jdx/mise/issues/XXXX — mise reads .sdkmanrc
# but drops the SDKMAN vendor suffix (e.g. 21.0.10-tem becomes java@21.0.10
# instead of java@temurin-21.0.10). This hook bypasses mise's broken parser
# by setting MISE_JAVA_VERSION directly.
#
# Remove this file once mise fixes .sdkmanrc vendor mapping.

# Map SDKMAN vendor suffixes to mise vendor names
_sdkmanrc_vendor() {
  case $1 in
    tem)      printf 'temurin' ;;
    amzn)     printf 'corretto' ;;
    albba)    printf 'dragonwell' ;;
    graalce)  printf 'graalvm-community' ;;
    librca)   printf 'liberica' ;;
    ms)       printf 'microsoft' ;;
    open)     printf 'openjdk' ;;
    sapmchn)  printf 'sapmachine' ;;
    sem)      printf 'semeru-openj9' ;;
    zulu)     printf 'zulu' ;;
  esac
}

# Find .sdkmanrc by walking up the directory tree
_sdkmanrc_find() {
  local dir=$PWD
  while [[ $dir != "/" ]]; do
    [[ -f "$dir/.sdkmanrc" ]] && printf '%s' "$dir/.sdkmanrc" && return
    dir=${dir:h}
  done
  return 1
}

# chpwd hook: read .sdkmanrc and set MISE_JAVA_VERSION
_sdkmanrc_chpwd() {
  local rc
  rc=$(_sdkmanrc_find) || { unset MISE_JAVA_VERSION 2>/dev/null; return; }

  local line ver base suffix vendor
  line=$(grep -m1 '^java\s*=' "$rc" 2>/dev/null) || { unset MISE_JAVA_VERSION 2>/dev/null; return; }
  ver=${line#*=}
  ver=${ver// /}

  base=${ver%-*}
  suffix=${ver##*-}
  vendor=$(_sdkmanrc_vendor "$suffix")

  if [[ -n $vendor ]]; then
    export MISE_JAVA_VERSION="${vendor}-${base}"
  else
    export MISE_JAVA_VERSION="$ver"
  fi
}

chpwd_functions+=(_sdkmanrc_chpwd)
# Run once on shell startup for the initial directory
_sdkmanrc_chpwd
