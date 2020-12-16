#!/bin/sh

# Copyright 2020 Ville Koskela
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# Requirements:
# 1) Exec as user
# * Under Alpine: su-exec (e.g. apk add --no-cache su-exec)
# * Otherwise: gosu (e.g. apt-get install gosu)
# 2) Add user and group
# * Under Alpine: adduser, addgroup
# * Otherwise: useradd, groupadd

# Exit on any command error
set -e

# Whether to log during execution
verbose="true"

# The command and arguments to execute
command_args=

# The configuration for docker entrypoint
dep_configuration=

log_err() {
  l_prefix=$(date  +'%H:%M:%S')
  printf "[%s] %s\\n" "${l_prefix}" "$@" 1>&2;
}

log_out() {
  if [ -n "${verbose}" ]; then
    l_prefix=$(date  +'%H:%M:%S')
    printf "[%s] %s\\n" "${l_prefix}" "$@"
  fi
}

assert_user_group_matches() {
  l_name="$1"
  l_uid="$2"
  l_gid="$3"

  l_existing_uid=$(id -u "${l_name}")
  if [ "${l_existing_uid}" != "${l_uid}" ]; then
    # The user exists but the user id does not match
    log_err "The user ${l_name} already exists but with uid ${l_existing_uid} and not ${l_uid}"
    exit 1
  fi

  l_existing_gid=$(id -g "${l_name}")
  if [ "${l_existing_gid}" != "${l_gid}" ]; then
    # The user exists but the group id does not match
    log_err "The user ${l_name} already exists but with gid ${l_existing_gid} and not ${l_gid}"
    exit 1
  fi
}

linux_create_user_group() {
  l_name="$1"
  l_uid="$2"
  l_gid="$3"

  if id -u "${l_name}" > /dev/null 2>&1; then
    # Check that the existing user's uid and gid match the given ones
    assert_user_group_matches "${l_name}" "${l_uid}" "${l_gid}"

    # The user exists with matching user and group id
    log_out "The user ${l_name} already exists with required ids ${l_existing_uid}:${l_existing_gid}"
    return
  fi

  log_out "Creating user ${l_name} (${l_uid}) as member of group ${l_name} (${l_gid})"
  groupadd -r "${l_name}" "--gid=${l_gid}"
  useradd -r -g "${l_name}" "--uid=${l_uid}" "${l_name}"
}

alpine_create_user_group() {
  l_name="$1"
  l_uid="$2"
  l_gid="$3"

  if id -u "${l_name}" > /dev/null 2>&1; then
    # Check that the existing user's uid and gid match the given ones
    assert_user_group_matches "${l_name}" "${l_uid}" "${l_gid}"

    # The user exists with matching user and group id
    log_out "The user ${l_name} already exists with required ids ${l_existing_uid}:${l_existing_gid}"
    return
  fi

  log_out "Creating user ${l_name} (${l_uid}) as member of group ${l_name} (${l_gid})"
  addgroup -g "${l_gid}" -S "${l_name}"
  adduser -u "${l_uid}" -S -G "${l_name}" "${l_name}"
}

linux_get_su_cmd() {
  printf "gosu"
}

alpine_get_su_cmd() {
  printf "su-exec"
}

# Split the docker entrypoint arguments from the command
in_command=
for arg in "$@"; do
  log_out "Argument: ${arg}"
  eval "processed_arg=\"${arg}\""
  case "${processed_arg}" in
    *\'*)
     processed_arg=$(printf "%s" "${processed_arg}" | sed "s/'/'\"'\"'/g")
     ;;
    *) : ;;
  esac
  log_out "Processed argument: ${processed_arg}"
  if [ -z ${in_command} ]; then
    if [ "${arg}" = "--" ]; then
      in_command=1
    else
      dep_configuration="${dep_configuration} '${processed_arg}'"
    fi
  else
    command_args="${command_args} '${processed_arg}'"
  fi
done
if [ -z ${in_command} ]; then
  command_args="${dep_configuration}"
  dep_configuration=""
fi

# Parse the docker entrypoint configuration
eval "set -- ${dep_configuration}"

cfg_user=root
cfg_uid=0
cfg_gid=0
cfg_directories=
while getopts "n:u:g:d:" opt; do
  case "$opt" in
    n)
      cfg_user="${OPTARG}"
      ;;
    u)
      cfg_uid="${OPTARG}"
      ;;
    g)
      cfg_gid="${OPTARG}"
      ;;
    d)
      cfg_directory="${OPTARG}"
      case "${cfg_directory}" in
        *\'*)
          cfg_directory=$(printf "%s" "${cfg_directory}" | sed "s/'/'\"'\"'/g")
          ;;
        *) : ;;
      esac
      cfg_directories="${cfg_directories} '${cfg_directory}'"
      ;;
  esac
done
log_out "configured user name: ${cfg_user}"
log_out "configured user id: ${cfg_uid}"
log_out "configured group id: ${cfg_gid}"
log_out "configured directories: ${cfg_directories}"

# Determine the operating system
LINUX="linux"
ALPINE="alpine"
os="${LINUX}"
if [ -f "/etc/alpine-release" ]; then
  os="${ALPINE}"
fi
log_out "Container operating system is: ${os}"

# Create the specified user and group
${os}_create_user_group "${cfg_user}" "${cfg_uid}" "${cfg_gid}"

# Modify the ownership of the specified directories
eval "set -- ${cfg_directories}"
# Disable fail on error so that this becomes a best effort step
set +e
for cfg_directory in "$@"; do
  log_out "Setting ownership of: ${cfg_directory}"
  find "${cfg_directory}" \! -user "${cfg_user}" -exec chown "${cfg_user}:${cfg_user}" '{}' +
done
# Re-enable fail on error
set -e

# Execute the provided command as the specified user
eval "set -- ${command_args}"
log_out "Executing as ${cfg_user}: $*"

# Pop the first argument as the command
command="$1"
shift

# Execute with platform specific wrapper and arguments followed by command args
su_exec_cmd=$(${os}_get_su_cmd)
exec "${su_exec_cmd}" "${cfg_user}:${cfg_user}" "${command}" "$@"
