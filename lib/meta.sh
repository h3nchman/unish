# Copyright 2015-2016 Gu Zhengxiong <rectigu@gmail.com>
#
# This file is part of Unish.
#
# Unish is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License
# as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# Unish is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with Unish.  If not, see <http://www.gnu.org/licenses/>.


unalias verbose 2> /dev/null
verbose() {
    >&2 printf "==> Running '%s'\n" "${*}" && "${@}"
}


count_items() {
    : "
Display item count in the given or current working directory.

Usage: count_items [<direcotry>]
"
    local directory="${1:-${PWD}}"
    local count
    count=$(find "${directory}" -maxdepth 1 | wc -l)
    stdout "$((count - 1))"
}


exists() {
    : "
Usage: exists <command>

Determine whether the command is available or not.

Examples:

$ exists exists
$ exists which
$ exists pygmentize

"
    command which "$1" > /dev/null 2>&1
}


stdout() {
    : "
Usage: stdout <message>

Write a message to STDOUT appending a newline.
"
    local message="${1}"
    printf '%s\n' "${message}"
}


get_distro() {
    : "
Get the name of the distribution as returned by 'lsb_release -si'.

Examples:

$ get_distro
Arch
"
    local name
    if exists lsb_release; then
        debug "Using lsb_release"
        stdout "$(lsb_release --short --id)"
    else
        debug "Using special files"
        if [[ -f /etc/arch-release ]]; then
            name="Arch"
        elif [[ -f /etc/debian_version ]]; then
            name="Debian"
        fi
    fi
    stdout "${name}"
}


source_if_exists() {
    : "
Usage: source_if_exists <name>

Source the file if it exists, used for optional files.
"
    local name="${1}"
    if [[ -f "${name}" ]]; then
        debug "Sourcing ${name}"
        source "${name}"
    else
        debug "No such file: ${name}"
        return 1
    fi
}


unalias_if_exists() {
    : "
Usage: unalias_if_exists <name>

Remove the alias if it exists.
"
    local name="${1}"
    { unalias "${name}" 2>&1; } > /dev/null && \
        warning "Unaliased: ${name}"
}


_is_generic() {
    debug "$*"
    local expected="${1}"
    local real
    real=$(_type_name "$2")
    debug "_type_name returned '${real}' and expecting '${expected}'"
    [[ "${real}" == "${expected}" ]]
}


_type_names=('function' 'builtin' 'reserved')

_make_is_type_name () { stdout "is_${1}"; }

for one in "${_type_names[@]}"; do
    see_also=$(make_see_also "${one}" _make_is_type_name \
                             "${_type_names[@]}")
    eval "
is_$one() {
    : \"
Usage: is_${one} <message> <message> ...

Write $one messages to standard error stream.

See Also: ${see_also}
\"
    _is_generic '$one' \"\$*\"
}
"
done



_get_docs() {
    debug "$1"
    local docs
    docs=$(printf '%s' "$1" | grep -ozP '(?s)(?<=: ").+?(?=")')
    if [[ $(printf '%s' "$docs" | wc -l) -eq 0 ]]; then
        docs=$(printf '%s' "$1" | grep -ozP '(?s)(?<=doc=").+?(?=")')
        if [[ $(printf '%s' "$docs" | wc -l) -eq 0 ]]; then
            docs="doc not found"
        fi
    fi
    printf '%s' "$docs"
}


info 'Starting Help System...'

help() {
    : "
Usage: help <function_name>

Show the documentation of the specified shell functions,
shell builtins or reserved words.

Examples:

$ help help
$ help cd
$ help export
"
    local one
    for one in "$@"; do
        if is_builtin "${one}" || is_reserved "${one}"; then
            debug "${one} is builtin or reserved"
            if [[ ${CURRENT_SHELL} == "zsh" ]]; then
                debug "Running 'run-help' for Zsh"
                run-help "${one}"
            elif [[ ${CURRENT_SHELL} == "bash" ]]; then
                debug "Running 'builtin help' for Bash"
                builtin help "${one}"
            fi
        elif is_function "${one}"; then
            info ">>> Help on function: ${one} <<<"
            printf '%s\n\n' "$(_get_docs "$(_func_decl "${one}")")" \
                   | less -FXR
        else
            error "${one} is not a function"
        fi
    done
}

info 'Started Help System.'
