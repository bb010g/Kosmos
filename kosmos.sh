#!/usr/bin/env bash
#
# Kosmos
# Copyright (C) 2019 Steven Mattera
#
# This program is free software; you can redistribute it and/or modify it
# under the terms of the GNU General Public License as published by the Free
# Software Foundation; either version 2 of the License, or (at your option)
# any later version.
#
# This program is distributed in the hope that it will be useful, but WITHOUT
# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
# FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for
# more details.
#
# You should have received a copy of the GNU General Public License along with
# this program; if not, write to the Free Software Foundation, Inc.,
# 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA. 
#

set -ueo pipefail

func_result=""
user_agent="Kosmos/1.0.0"
temp_template='tmp-kosmos.XXXXXXXXXX'
declare -A \
    releases \
    repos \

# ============================================================================
# General Functions
# ============================================================================

# Finds the currently stored release JSON.
# Params:
#   - Resource identifier
# Returns:
#   The currently stored release JSON on stdout.
get_release () {
    printf '%s\n' "${releases[${1}]}"
}

# Downloads the latest release JSON.
# Params:
#   - Resource identifier
# Returns:
#   The latest release JSON on ${releases[RESOURCE]}.
update_release () {
    local repo
    repo=${repos[${1}]}
    releases[${1}]=$(curl -s "https://api.github.com/repos/${repo}/releases" \
        -H "Accept: application/json" \
        -H "Content-Type: application/json" \
        -H "User-Agent: ${user_agent}" | jq -r '.[0]')
}

# Finds a specific asset in a stored resource's release.
# Params:
#   - Resource identifier
#   - Filename regex
# Returns:
#   The asset JSON on stdout.
find_asset () {
    get_release "${1}" | jq --arg regex "${2}" \
        '.assets | map(select(.name | test($regex; "ip"))) | .[0]'
}

# Gets the download URL from an asset.
# Params:
#   - (stdin) Release asset JSON
# Returns:
#   The download URL on stdout.
get_download_url () {
    jq -r '.browser_download_url'
}

# Downloads a file.
# Params:
#   - The URL
# Returns:
#   The file path on stdout.
download_file () {
    local file
    file=$(mktemp "${temp_template/./.dl.}")
    curl -s -L -H "User-Agent: ${user_agent}" "${1}" -o "${file}"
    printf '%s\n' "${file}"
}

# Download a resource's release asset.
# Params:
#   - Resource identifier
#   - Asset filename regex
# Returns:
#   The file path on stdout.
download_asset () {
    download_file "$(find_asset "${1}" "${2}" | get_download_url)"
}

# Gets the version number from a release.
# Params:
#   - Resource identifier
# Returns:
#   The version number on stdout.
get_release_version () {
    get_release "${1}" | jq -r ".tag_name"
}

# ============================================================================
# Atmosphere Functions
# ============================================================================

repos[atmosphere]="Atmosphere-NX/Atmosphere"

# Downloads the latest Atmosphere release and extracts it.
# Params:
#   - Directory to extract to
# Returns:
#   The version number on ${func_result}.
download_atmosphere () {
    update_release atmosphere

    local file

    file=$(download_asset atmosphere 'atmosphere.*\.zip')
    unzip -qq "${file}" -d "${1}"
    rm -f "${1}/switch/reboot_to_payload.nro"
    [[ -z "${KOSMOS_LEAVE_TMP:-}" ]] && rm -f "${file}"

    file=$(download_asset atmosphere 'fusee.*\.bin')
    mkdir -p "${1}/bootloader/payloads"
    mv "${file}" "${1}/bootloader/payloads/fusee-primary.bin"

    func_result=$(get_release_version atmosphere)
}

# ============================================================================
# Hekate Functions
# ============================================================================

repos[hekate]="CTCaer/hekate"

# Downloads the latest Hekate release and extracts it.
# Params:
#   - Directory to extract to
# Returns:
#   The version number on ${func_result}.
download_hekate () {
    update_release hekate

    local file
    file=$(download_asset hekate 'hekate.*\.zip')
    unzip -qq "${file}" -d "${1}"
    [[ -z "${KOSMOS_LEAVE_TMP:-}" ]] && rm -f "${file}"

    func_result=$(get_release_version hekate)
}

# Copy the payload to where it needs to be.
# Params:
#   - The build directory
copy_hekate_payload () {
    for file in "${1}"/hekate*.bin; do
        cp "${file}" "${1}/bootloader/update.bin"
        cp "${file}" "${1}/atmosphere/reboot_payload.bin"
        break
    done
}

# Builds the hekate files.
# Params:
#   - The build directory
#   - The Kosmos version number
build_hekate_files () {
    cp "./Modules/hekate/bootlogo.bmp" "${1}/bootloader/bootlogo.bmp"
    sed "s/KOSMOS_VERSION/${2}/g" "./Modules/hekate/hekate_ipl.ini" \
        >> "${1}/bootloader/hekate_ipl.ini"
}

# ============================================================================
# Homebrew Functions
# ============================================================================

repos[appstore]="vgmoose/hb-appstore"
download_appstore () {
    update_release appstore

    local file
    file=$(download_asset appstore '.*\.nro')
    mkdir -p "${1}/switch/appstore"
    mv "${file}" "${1}/switch/appstore/appstore.nro"

    func_result=$(get_release_version appstore)
}

repos[edizon]="WerWolv/EdiZon"
download_edizon () {
    update_release edizon

    local file
    file=$(download_asset edizon '.*\.zip')
    unzip -qq "${file}" -d "${1}"
    [[ -z "${KOSMOS_LEAVE_TMP:-}" ]] && rm -f "${file}"

    func_result=$(get_release_version edizon)
}

repos[emuiibo]="XorTroll/emuiibo"
download_emuiibo () {
    update_release emuiibo

    local file
    file=$(download_asset emuiibo 'emuiibo.*\.zip')
    unzip -qq "${file}" -d "${1}"
    rm -rf "${1}/ReiNX"
    rm -f "${1}/atmosphere/titles/0100000000000352/flags/boot2.flag"
    [[ -z "${KOSMOS_LEAVE_TMP:-}" ]] && rm -f "${file}"

    func_result=$(get_release_version emuiibo)
}

repos[goldleaf]="XorTroll/Goldleaf"
download_goldleaf () {
    update_release goldleaf

    local file
    file=$(download_asset goldleaf '.*\.nro')
    mkdir -p "${1}/switch/Goldleaf"
    mv "${file}" "${1}/switch/Goldleaf/Goldleaf.nro"

    func_result=$(get_release_version goldleaf)
}

repos[hid_mitm]="jakibaki/hid-mitm"
download_hid_mitm () {
    update_release hid_mitm

    local file
    file=$(download_asset hid_mitm 'hid.*\.zip')
    unzip -qq "${file}" -d "${1}"
    rm -f "${1}/atmosphere/titles/0100000000000faf/flags/boot2.flag"
    [[ -z "${KOSMOS_LEAVE_TMP:-}" ]] && rm -f "${file}"

    func_result=$(get_release_version hid_mitm)
}

repos[kosmos_toolbox]="AtlasNX/Kosmos-Toolbox"
download_kosmos_toolbox () {
    update_release kosmos_toolbox

    local file
    file=$(download_asset kosmos_toolbox '.*\.nro')
    mkdir -p "${1}/switch/KosmosToolbox"
    mv "${file}" "${1}/switch/KosmosToolbox/KosmosToolbox.nro"
    cp "./Modules/kosmos-toolbox/config.json" \
        "${1}/switch/KosmosToolbox/config.json"

    func_result=$(get_release_version kosmos_toolbox)
}

repos[kosmos_updater]="AtlasNX/Kosmos-Updater"
download_kosmos_updater () {
    update_release kosmos_updater

    local file
    file=$(download_asset kosmos_updater '.*\.nro')
    mkdir -p "${1}/switch/KosmosUpdater"
    mv "${file}" "${1}/switch/KosmosUpdater/KosmosUpdater.nro"
    sed "s/KOSMOS_VERSION/${2}/g" "./Modules/kosmos-updater/internal.db" \
        >> "${1}/switch/KosmosUpdater/internal.db"

    func_result=$(get_release_version kosmos_updater)
}

repos[ldn_mitm]="spacemeowx2/ldn_mitm"
download_ldn_mitm () {
    update_release ldn_mitm

    local file
    file=$(download_asset ldn_mitm 'ldn_mitm.*\.zip')
    unzip -qq "${file}" -d "${1}"
    rm -f "${1}/atmosphere/titles/4200000000000010/flags/boot2.flag"
    [[ -z "${KOSMOS_LEAVE_TMP:-}" ]] && rm -f "${file}"

    func_result=$(get_release_version ldn_mitm)
}

repos[lockpick]="shchmue/Lockpick"
download_lockpick () {
    update_release lockpick

    local file
    file=$(download_asset lockpick '.*\.nro')
    mkdir -p "${1}/switch/Lockpick"
    mv "${file}" "${1}/switch/Lockpick/Lockpick.nro"

    func_result=$(get_release_version lockpick)
}

repos[lockpick_rcm]="shchmue/Lockpick_RCM"
download_lockpick_rcm () {
    update_release lockpick_rcm

    local file
    file=$(download_asset lockpick_rcm ".*\.bin")
    mv "${file}" "${1}/bootloader/payloads/Lockpick_RCM.bin"

    func_result=$(get_release_version lockpick_rcm)
}

repos[sys_clk]="retronx-team/sys-clk"
download_sys_clk () {
    update_release sys_clk

    local file
    file=$(download_asset sys_clk 'sys-clk.*\.zip')
    unzip -qq "${file}" -d "${1}"
    rm -f "${1}/atmosphere/titles/00FF0000636C6BFF/flags/boot2.flag"
    rm -f "${1}/README.html"
    [[ -z "${KOSMOS_LEAVE_TMP:-}" ]] && rm -f "${file}"

    func_result=$(get_release_version sys_clk)
}

# TODO version off of Jenkins?
# https://jenkins.lavatech.top/job/sys-ftpd/
download_sys_ftpd () {
    local file
    file=$(download_file \
        "https://bsnx.lavatech.top/sys-ftpd/sys-ftpd-latest.zip")

    local temp_sysftpd_directory
    temp_sysftpd_directory=$(mktemp -d "${temp_template/./.sys_ftpd.}")
    unzip -qq "${file}" -d "${temp_sysftpd_directory}"
    cp -r "${temp_sysftpd_directory}/sd"/* "${1}"
    rm -f "${1}/atmosphere/titles/420000000000000E/flags/boot2.flag"
    [[ -z "${KOSMOS_LEAVE_TMP:-}" ]] && rm -f "${file}"
    [[ -z "${KOSMOS_LEAVE_TMP:-}" ]] && rm -rf "${temp_sysftpd_directory}"

    func_result="latest"
}

# download_sys_netcheat () {
    # Someone needs to update their release to not be a kip... =/
# }

# ============================================================================
# Main Script
# ============================================================================

if [ $# -le 1 ]
then
    echo "Usage: ./kosmos.sh [version-number] [output]"
    exit 1
fi

TMPDIR=$(mktemp -d "${temp_template}")
export TMPDIR
# Temporary build directory
build_dir=$(mktemp -d "${temp_template/./.build.}")

# Start building!

download_atmosphere "${build_dir}"
atmosphere_version=${func_result}

download_hekate "${build_dir}"
hekate_version=${func_result}
copy_hekate_payload "${build_dir}"
build_hekate_files "${build_dir}" "${1}"

download_appstore "${build_dir}"
appstore_version=${func_result}

download_edizon "${build_dir}"
edizon_version=${func_result}

download_emuiibo "${build_dir}"
emuiibo_version=${func_result}

download_goldleaf "${build_dir}"
goldleaf_version=${func_result}

download_hid_mitm "${build_dir}"
hid_mitm_version=${func_result}

download_kosmos_toolbox "${build_dir}"
kosmos_toolbox_version=${func_result}

download_kosmos_updater "${build_dir}" "${1}"
kosmos_updater_version=${func_result}

download_ldn_mitm "${build_dir}"
ldn_mitm_version=${func_result}

download_lockpick "${build_dir}"
lockpick_version=${func_result}

download_lockpick_rcm "${build_dir}"
lockpick_rcm_version=${func_result}

download_sys_clk "${build_dir}"
sys_clk_version=${func_result}

download_sys_ftpd "${build_dir}"
sys_ftpd_version=${func_result}

# Delete the bundle if it already exists.
dest=$(realpath -s "${2}")
rm -f "${dest}/Kosmos-${1}.zip"

# Bundle everything together.
(cd "${build_dir}" && zip -q -r "${dest}/Kosmos-${1}.zip" .)

# Clean up.
[[ -z "${KOSMOS_LEAVE_TMP:-}" ]] && rm -rf "${TMPDIR}"

# Output some useful information.
echo "Kosmos ${1} built with:"
echo "  Atmosphere - ${atmosphere_version}"
echo "  Hekate - ${hekate_version}"
echo "  EdiZon - ${edizon_version}"
echo "  Emuiibo - ${emuiibo_version}"
echo "  Goldleaf - ${goldleaf_version}"
echo "  hid-mitm - ${hid_mitm_version}"
echo "  Homebrew App Store - ${appstore_version}"
echo "  Kosmos Toolbox - ${kosmos_toolbox_version}"
echo "  Kosmos Updater - ${kosmos_updater_version}"
echo "  ldn_mitm - ${ldn_mitm_version}"
echo "  Lockpick - ${lockpick_version}"
echo "  Lockpick RCM - ${lockpick_rcm_version}"
echo "  sys-clk - ${sys_clk_version}"
echo "  sys-ftpd - ${sys_ftpd_version}"

# vim:et:sw=4:tw=78
