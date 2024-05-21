NIX_DIRENV_SKIP_VERSION_CHECK=1
# shellcheck shell=bash

NIX_DIRENV_VERSION=3.0.4

# min required versions
BASH_MIN_VERSION=4.4
DIRENV_MIN_VERSION=2.21.3
NIX_MIN_VERSION=2.4

_NIX_DIRENV_LOG_PREFIX="nix-direnv: "

_nix_direnv_info() {
  log_status "${_NIX_DIRENV_LOG_PREFIX}$*"
}

_nix_direnv_warning() {
  if [[ -n $DIRENV_LOG_FORMAT ]]; then
    local msg=$* color_normal='' color_warning=''
    if [[ -t 2 ]]; then
      color_normal="\e[m"
      color_warning="\e[33m"
    fi
    # shellcheck disable=SC2059
    printf "${color_warning}${DIRENV_LOG_FORMAT}${color_normal}\n" \
      "${_NIX_DIRENV_LOG_PREFIX}${msg}" >&2
  fi
}

_nix_direnv_error() { log_error "${_NIX_DIRENV_LOG_PREFIX}$*"; }

_nix() {
  /nix/store/awshr3d8a94v2igyf16jh5p8bw9wf93s-nix-2.18.2/bin/nix --extra-experimental-features "nix-command flakes" "$@"
}

_require_version() {
  local cmd=$1 version=$2 required=$3
  if ! printf "%s\n" "$required" "$version" | LC_ALL=C /nix/store/hq8765g3p1i7qbargnqli5mn0jpsdbfl-coreutils-9.5/bin/sort -c -V 2>/dev/null; then
    _nix_direnv_error \
      "minimum required $(/nix/store/hq8765g3p1i7qbargnqli5mn0jpsdbfl-coreutils-9.5/bin/basename "$cmd") version is $required (installed: $version)"
    return 1
  fi
}

_require_cmd_version() {
  local cmd=$1 required=$2 version
  if ! has "$cmd"; then
    _nix_direnv_error "command not found: $cmd"
    return 1
  fi
  version=$($cmd --version)
  [[ $version =~ ([0-9]+\.[0-9]+\.[0-9]+) ]]
  _require_version "$cmd" "${BASH_REMATCH[1]}" "$required"
}

_nix_direnv_preflight() {
  if [[ -z $direnv ]]; then
    # shellcheck disable=2016
    _nix_direnv_error '$direnv environment variable was not defined. Was this script run inside direnv?'
    return 1
  fi

  # check command min versions
  if [[ -z ${NIX_DIRENV_SKIP_VERSION_CHECK:-} ]]; then
    # bash check uses $BASH_VERSION with _require_version instead of
    # _require_cmd_version because _require_cmd_version uses =~ operator which would be
    # a syntax error on bash < 3
    if ! _require_version bash "$BASH_VERSION" "$BASH_MIN_VERSION" ||
      ! _require_cmd_version "$direnv" "$DIRENV_MIN_VERSION" || # direnv stdlib defines $direnv
      ! _require_cmd_version nix "$NIX_MIN_VERSION"; then
      return 1
    fi
  fi

  local layout_dir
  layout_dir=$(direnv_layout_dir)

  if [[ ! -d "$layout_dir/bin" ]]; then
    /nix/store/hq8765g3p1i7qbargnqli5mn0jpsdbfl-coreutils-9.5/bin/mkdir -p "$layout_dir/bin"
  fi
  # N.B. This script relies on variable expansion in *this* shell.
  # (i.e. The written out file will have the variables expanded)
  # If the source path changes, the script becomes broken.
  # Because direnv_layout_dir is user controlled,
  # we can't assume to be able to reverse it to get the source dir
  # So there's little to be done about this.
  /nix/store/hq8765g3p1i7qbargnqli5mn0jpsdbfl-coreutils-9.5/bin/cat >"${layout_dir}/bin/nix-direnv-reload" <<-EOF
#!/usr/bin/env bash
set -e
if [[ ! -d "$PWD" ]]; then
  echo "Cannot find source directory; Did you move it?"
  echo "(Looking for "$PWD")"
  echo 'Cannot force reload with this script - use "direnv reload" manually and then try again'
  exit 1
fi

# rebuild the cache forcefully
_nix_direnv_force_reload=1 direnv exec "$PWD" true

# Update the mtime for .envrc.
# This will cause direnv to reload again - but without re-building.
touch "$PWD/.envrc"

# Also update the timestamp of whatever profile_rc we have.
# This makes sure that we know we are up to date.
touch -r "$PWD/.envrc" "${layout_dir}"/*.rc
EOF

  if [[ ! -x "${layout_dir}/bin/nix-direnv-reload" ]]; then
    /nix/store/hq8765g3p1i7qbargnqli5mn0jpsdbfl-coreutils-9.5/bin/chmod +x "${layout_dir}/bin/nix-direnv-reload"
  fi

  PATH_add "${layout_dir}/bin"
}

# Usage: nix_direnv_version <version_at_least>
#
# Checks that the nix-direnv version is at least as old as <version_at_least>.
nix_direnv_version() {
  _require_version nix-direnv $NIX_DIRENV_VERSION "$1"
}

_nix_export_or_unset() {
  local key=$1 value=$2
  if [[ $value == __UNSET__ ]]; then
    unset "$key"
  else
    export "$key=$value"
  fi
}

_nix_import_env() {
  local profile_rc=$1

  local -A values_to_restore=(
    ["NIX_BUILD_TOP"]=${NIX_BUILD_TOP:-__UNSET__}
    ["TMP"]=${TMP:-__UNSET__}
    ["TMPDIR"]=${TMPDIR:-__UNSET__}
    ["TEMP"]=${TEMP:-__UNSET__}
    ["TEMPDIR"]=${TEMPDIR:-__UNSET__}
    ["terminfo"]=${terminfo:-__UNSET__}
  )
  local old_xdg_data_dirs=${XDG_DATA_DIRS:-}

  # On the first run in manual mode, the profile_rc does not exist.
  if [[ ! -e $profile_rc ]]; then
    return
  fi

  eval "$(<"$profile_rc")"
  # `nix print-dev-env` will create a temporary directory and use it as TMPDIR
  # We cannot rely on this directory being available at all times,
  # as it may be garbage collected.
  # Instead - just remove it immediately.
  # Use recursive & force as it may not be empty.
  if [[ -n ${NIX_BUILD_TOP+x} && $NIX_BUILD_TOP == */nix-shell.* && -d $NIX_BUILD_TOP ]]; then
    /nix/store/hq8765g3p1i7qbargnqli5mn0jpsdbfl-coreutils-9.5/bin/rm -rf "$NIX_BUILD_TOP"
  fi

  for key in "${!values_to_restore[@]}"; do
    _nix_export_or_unset "$key" "${values_to_restore[${key}]}"
  done

  local new_xdg_data_dirs=${XDG_DATA_DIRS:-}
  export XDG_DATA_DIRS=
  local IFS=:
  for dir in $new_xdg_data_dirs${old_xdg_data_dirs:+:}$old_xdg_data_dirs; do
    dir="${dir%/}" # remove trailing slashes
    if [[ :$XDG_DATA_DIRS: == *:$dir:* ]]; then
      continue # already present, skip
    fi
    XDG_DATA_DIRS="$XDG_DATA_DIRS${XDG_DATA_DIRS:+:}$dir"
  done
}

_nix_add_gcroot() {
  local storepath=$1
  local symlink=$2
  _nix build --out-link "$symlink" "$storepath"
}

_nix_clean_old_gcroots() {
  local layout_dir=$1

  /nix/store/hq8765g3p1i7qbargnqli5mn0jpsdbfl-coreutils-9.5/bin/rm -rf "$layout_dir/flake-inputs/"
  /nix/store/hq8765g3p1i7qbargnqli5mn0jpsdbfl-coreutils-9.5/bin/rm -f "$layout_dir"/{nix,flake}-profile*
}

_nix_argsum_suffix() {
  local out checksum
  if [ -n "$1" ]; then

    if has sha1sum; then
      out=$(/nix/store/hq8765g3p1i7qbargnqli5mn0jpsdbfl-coreutils-9.5/bin/sha1sum <<<"$1")
    elif has shasum; then
      out=$(shasum <<<"$1")
    else
      # degrade gracefully both tools are not present
      return
    fi
    read -r checksum _ <<<"$out"
    echo "-$checksum"
  fi
}

nix_direnv_watch_file() {
  # shellcheck disable=2016
  log_error '`nix_direnv_watch_file` is deprecated - use `watch_file`'
  watch_file "$@"
}

_nix_direnv_watches() {
  local -n _watches=$1
  if [[ -z ${DIRENV_WATCHES-} ]]; then
    return
  fi
  while IFS= read -r line; do
    local regex='"[Pp]ath": "(.+)"$'
    if [[ $line =~ $regex ]]; then
      local path="${BASH_REMATCH[1]}"
      if [[ $path == "${XDG_DATA_HOME:-${HOME:-/var/empty}/.local/share}/direnv/allow/"* ]]; then
        continue
      fi
      # expand new lines and other json escapes
      # shellcheck disable=2059
      path=$(printf "$path")
      _watches+=("$path")
    fi
  done < <($direnv show_dump "${DIRENV_WATCHES}")
}

_nix_direnv_manual_reload=0
nix_direnv_manual_reload() {
  _nix_direnv_manual_reload=1
}

_nix_direnv_warn_manual_reload() {
  if [[ -e $1 ]]; then
    _nix_direnv_warning 'cache is out of date. use "nix-direnv-reload" to reload'
  else
    _nix_direnv_warning 'cache does not exist. use "nix-direnv-reload" to create it'
  fi
}

use_flake() {
  if ! _nix_direnv_preflight; then
    return 1
  fi

  flake_expr="${1:-.}"
  flake_uri="${flake_expr%#*}"
  flake_dir=${flake_uri#"path:"}

  if [[ $flake_expr == -* ]]; then
    local message="the first argument must be a flake expression"
    if [[ -n $2 ]]; then
      _nix_direnv_error "$message"
      return 1
    else
      _nix_direnv_error "$message. did you mean 'use flake . $1'?"
      return 1
    fi
  fi

  local files_to_watch
  files_to_watch=("$HOME/.direnvrc" "$HOME/.config/direnv/direnvrc")

  if [[ -d $flake_dir ]]; then
    files_to_watch+=("$flake_dir/flake.nix" "$flake_dir/flake.lock" "$flake_dir/devshell.toml")
  fi

  watch_file "${files_to_watch[@]}"

  local layout_dir profile
  layout_dir=$(direnv_layout_dir)
  profile="${layout_dir}/flake-profile$(_nix_argsum_suffix "$flake_expr")"
  local profile_rc="${profile}.rc"
  local flake_inputs="${layout_dir}/flake-inputs/"

  local need_update=0
  local watches
  _nix_direnv_watches watches
  local file=
  for file in "${watches[@]}"; do
    if [[ $file -nt $profile_rc ]]; then
      need_update=1
      break
    fi
  done

  if [[ ! -e $profile ||
    ! -e $profile_rc ||
    $need_update -eq 1 ]] \
    ; then
    if [[ $_nix_direnv_manual_reload -eq 1 && -z ${_nix_direnv_force_reload-} ]]; then
      _nix_direnv_warn_manual_reload "$profile_rc"

    else
      local tmp_profile_rc
      local tmp_profile="${layout_dir}/flake-tmp-profile.$$"
      if tmp_profile_rc=$(_nix print-dev-env --profile "$tmp_profile" "$@"); then
        # If we've gotten here, the user's current devShell is valid and we should cache it
        _nix_clean_old_gcroots "$layout_dir"

        # We need to update our cache
        echo "$tmp_profile_rc" >"$profile_rc"
        _nix_add_gcroot "$tmp_profile" "$profile"
        /nix/store/hq8765g3p1i7qbargnqli5mn0jpsdbfl-coreutils-9.5/bin/rm -f "$tmp_profile" "$tmp_profile"*

        # also add garbage collection root for source
        local flake_input_paths
        /nix/store/hq8765g3p1i7qbargnqli5mn0jpsdbfl-coreutils-9.5/bin/mkdir -p "$flake_inputs"
        flake_input_paths=$(_nix flake archive \
          --json --no-write-lock-file \
          -- "$flake_uri")

        while [[ $flake_input_paths =~ /nix/store/[^\"]+ ]]; do
          local store_path="${BASH_REMATCH[0]}"
          _nix_add_gcroot "${store_path}" "${flake_inputs}/${store_path##*/}"
          flake_input_paths="${flake_input_paths/${store_path}/}"
        done

        _nix_direnv_info "Renewed cache"
      else
        # The user's current flake failed to evaluate,
        # but there is already a prior profile_rc,
        # which is probably more useful than nothing.
        # Fallback to use that (which means just leaving profile_rc alone!)
        _nix_direnv_warning "Evaluating current devShell failed. Falling back to previous environment!"
        export NIX_DIRENV_DID_FALLBACK=1
      fi
    fi
  else
    if [[ -e ${profile_rc} ]]; then
      # Our cache is valid, use that
      _nix_direnv_info "Using cached dev shell"
    else
      # We don't have a profile_rc to use!
      _nix_direnv_error "use_flake failed - Is your flake's devShell working?"
      return 1
    fi
  fi

  _nix_import_env "$profile_rc"
}

use_nix() {
  if ! _nix_direnv_preflight; then
    return 1
  fi

  local layout_dir path version
  layout_dir=$(direnv_layout_dir)
  if path=$(_nix eval --impure --expr "<nixpkgs>" 2>/dev/null); then
    if [[ -f "${path}/.version-suffix" ]]; then
      version=$(<"${path}/.version-suffix")
    elif [[ -f "${path}/.git/HEAD" ]]; then
      local head
      read -r head <"${path}/.git/HEAD"
      local regex="ref: (.*)"
      if [[ $head =~ $regex ]]; then
        read -r version <"${path}/.git/${BASH_REMATCH[1]}"
      else
        version="$head"
      fi
    elif [[ -f "${path}/.version" && ${path} == "/nix/store/"* ]]; then
      # borrow some bits from the store path
      local version_prefix
      read -r version_prefix < <(
        /nix/store/hq8765g3p1i7qbargnqli5mn0jpsdbfl-coreutils-9.5/bin/cat "${path}/.version"
        echo
      )
      version="${version_prefix}-${path:11:16}"
    fi
  fi

  local profile
  profile="${layout_dir}/nix-profile-${version:-unknown}$(_nix_argsum_suffix "$*")"
  local profile_rc="${profile}.rc"

  local in_packages=0
  local attribute=
  local packages=""
  local extra_args=()

  local nixfile=
  if [[ -e "shell.nix" ]]; then
    nixfile="./shell.nix"
  elif [[ -e "default.nix" ]]; then
    nixfile="./default.nix"
  fi

  while [[ $# -gt 0 ]]; do
    i="$1"
    shift

    case $i in
    -p | --packages)
      in_packages=1
      ;;
    --command | --run | --exclude)
      # These commands are unsupported
      # ignore them
      shift
      ;;
    --pure | -i | --keep)
      # These commands are unsupported (but take no argument)
      # ignore them
      ;;
    --include | -I)
      extra_args+=("$i" "$1")
      shift
      ;;
    --attr | -A)
      attribute="$1"
      shift
      ;;
    --option | -o | --arg | --argstr)
      extra_args+=("$i" "$1" "$2")
      shift
      shift
      ;;
    -*)
      # Other arguments are assumed to be of a single arg form
      # (--foo=bar or -j4)
      extra_args+=("$i")
      ;;
    *)
      if [[ $in_packages -eq 1 ]]; then
        packages+=" $i"
      else
        nixfile=$i
      fi
      ;;
    esac
  done

  watch_file "$HOME/.direnvrc" "$HOME/.config/direnv/direnvrc" "shell.nix" "default.nix"

  local need_update=0
  local watches
  _nix_direnv_watches watches
  local file=
  for file in "${watches[@]}"; do
    if [[ $file -nt $profile_rc ]]; then
      need_update=1
      break
    fi
  done

  if [[ ! -e $profile ||
    ! -e $profile_rc ||
    $need_update -eq 1 ]] \
    ; then
    if [[ $_nix_direnv_manual_reload -eq 1 && -z ${_nix_direnv_force_reload-} ]]; then
      _nix_direnv_warn_manual_reload "$profile_rc"
    else
      local tmp_profile="${layout_dir}/nix-tmp-profile.$$"
      local tmp_profile_rc
      if [[ -n $packages ]]; then
        extra_args+=("--expr" "with import <nixpkgs> {}; mkShell { buildInputs = [ $packages ]; }")
      else
        # figure out what attribute we should build
        if [[ -z $attribute ]]; then
          extra_args+=("--file" "$nixfile")
        else
          extra_args+=("--expr" "(import ${nixfile} {}).${attribute}")
        fi
      fi

      if tmp_profile_rc=$(_nix \
        print-dev-env \
        --profile "$tmp_profile" \
        --impure \
        "${extra_args[@]}"); then
        _nix_clean_old_gcroots "$layout_dir"

        echo "$tmp_profile_rc" >"$profile_rc"
        _nix_add_gcroot "$tmp_profile" "$profile"
        /nix/store/hq8765g3p1i7qbargnqli5mn0jpsdbfl-coreutils-9.5/bin/rm -f "$tmp_profile" "$tmp_profile"*
        _nix_direnv_info "Renewed cache"
      else
        _nix_direnv_warning "Evaluating current nix shell failed. Falling back to previous environment!"
        export NIX_DIRENV_DID_FALLBACK=1
      fi
    fi
  else
    if [[ -e ${profile_rc} ]]; then
      _nix_direnv_info "Using cached dev shell"
    else
      _nix_direnv_error "use_nix failed - Is your nix shell working?"
      return 1
    fi
  fi

  _nix_import_env "$profile_rc"

}

### resholve directives (auto-generated) ## format_version: 3
# resholve: fake builtin:PATH_add
# resholve: fake builtin:direnv_layout_dir
# resholve: fake builtin:has
# resholve: fake builtin:log_error
# resholve: fake builtin:log_status
# resholve: fake builtin:watch_file
# resholve: fake function:shasum
# resholve: keep $cmd
# resholve: keep $direnv
# resholve: keep /nix/store/awshr3d8a94v2igyf16jh5p8bw9wf93s-nix-2.18.2/bin/nix
# resholve: keep /nix/store/hq8765g3p1i7qbargnqli5mn0jpsdbfl-coreutils-9.5/bin/basename
# resholve: keep /nix/store/hq8765g3p1i7qbargnqli5mn0jpsdbfl-coreutils-9.5/bin/cat
# resholve: keep /nix/store/hq8765g3p1i7qbargnqli5mn0jpsdbfl-coreutils-9.5/bin/chmod
# resholve: keep /nix/store/hq8765g3p1i7qbargnqli5mn0jpsdbfl-coreutils-9.5/bin/mkdir
# resholve: keep /nix/store/hq8765g3p1i7qbargnqli5mn0jpsdbfl-coreutils-9.5/bin/rm
# resholve: keep /nix/store/hq8765g3p1i7qbargnqli5mn0jpsdbfl-coreutils-9.5/bin/sha1sum
# resholve: keep /nix/store/hq8765g3p1i7qbargnqli5mn0jpsdbfl-coreutils-9.5/bin/sort

