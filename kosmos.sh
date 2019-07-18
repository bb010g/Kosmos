#!/usr/bin/env bash
#
# Kosmos
# Copyright (C) 2019 Steven Mattera
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#

set -ueo pipefail

func_result=""
user_agent="Kosmos/1.0.0"
temp_template='kosmos.XXXXXXXXXX'
declare -A releases

# =============================================================================
# General Functions
# =============================================================================

# Downloads the latest release JSON.
# Params:
#   - GitHub owner/repo
# Returns:
#   The latest release JSON on ${releases[owner/repo]}.
get_latest_release () {
    releases[${1}]=$(curl -s "https://api.github.com/repos/${1}/releases" \
        -H "Accept: application/json" \
        -H "Content-Type: application/json" \
        -H "User-Agent: ${user_agent}" | jq -r '.[0]')
}

# Finds a specific asset in a release.
# Params:
#   - (stdin) The release JSON
#   - Filename regex
# Returns:
#   The asset JSON on stdout.
find_asset () {
    jq --arg regex "${1}" '.assets | map(select(.name | test($regex; "ip"))) | .[0]'
}

# Gets the download URL from an asset.
# Params:
#   - (stdin) The release asset JSON
# Returns:
#   The download URL on stdout.
get_download_url () {
    jq -r '.browser_download_url'
}

# Downloads a file.
# Params:
#   - The URL
# Returns:
#   The file path on ${func_result}.
download_file () {
    func_result=$(mktemp "${temp_template}")
    curl -L -H "User-Agent: ${user_agent}" -s "${1}" -o "${func_result}"
}

# Gets the version number from an asset.
# Params:
#   - The release asset JSON
# Returns:
#   The version number on ${func_result}.
get_version_number () {
    func_result=$(jq -r ".tag_name" <<< "${1}")
}

# First word of the arguments
# Params:
#   - One or more arguments
# Returns:
#   - The first argument provided on ${func_result}.
first () {
    func_result=${1}
}

# =============================================================================
# Atmosphere Functions
# =============================================================================

# Downloads the latest Atmosphere release and extracts it.
# Params:
#   - Directory to extract to
# Returns:
#   The version number on ${func_result}.
download_atmosphere () {
    repo="Atmosphere-NX/Atmosphere"
    get_latest_release "${repo}"

    func_result=$(find_asset 'atmosphere.*\.zip' <<< "${releases[$repo]}" \
        | get_download_url)
    download_file "${func_result}"

    unzip -qq "${func_result}" -d "${1}"
    rm -f "${1}/switch/reboot_to_payload.nro"
    rm -f "${func_result}"

    func_result=$(find_asset 'fusee.*\.bin' <<< "${releases[$repo]}" \
        | get_download_url)
    download_file "${func_result}"

    mkdir -p "${1}/bootloader/payloads"
    mv "${func_result}" "${1}/bootloader/payloads/fusee-primary.bin"

    get_version_number "${releases[$repo]}"
}

# =============================================================================
# Hekate Functions
# =============================================================================

# Downloads the latest Hekate release and extracts it.
# Params:
#   - Directory to extract to
# Returns:
#   The version number on ${func_result}.
download_hekate () {
    local repo="CTCaer/hekate"
    get_latest_release "${repo}"

    func_result=$(find_asset 'hekate.*\.zip' <<< "${releases[$repo]}" \
        | get_download_url)
    download_file "${func_result}"

    unzip -qq "${func_result}" -d "${1}"
    rm -f "${func_result}"

    get_version_number "${releases[$repo]}"
}

# Copy the payload to where it needs to be.
# Params:
#   - The temp directory
copy_payload () {
    first "${1}"/hekate*.bin
    cp "${func_result}" "${1}/bootloader/update.bin"
    cp "${func_result}" "${1}/atmosphere/reboot_payload.bin"
}

# Builds the hekate files.
# Params:
#   - The temp directory
#   - The Kosmos version number
build_hekate_files () {
    cp "./Modules/hekate/bootlogo.bmp" "${1}/bootloader/bootlogo.bmp"
    sed "s/KOSMOS_VERSION/${2}/g" "./Modules/hekate/hekate_ipl.ini" >> "${1}/bootloader/hekate_ipl.ini"
}

# =============================================================================
# Homebrew Functions
# =============================================================================

download_appstore () {
    local repo="vgmoose/hb-appstore"
    get_latest_release "${repo}"

    func_result=$(find_asset '.*\.nro' <<< "${releases[$repo]}" \
        | get_download_url)
    download_file "${func_result}"

    mkdir -p "${1}/switch/appstore"
    mv "${func_result}" "${1}/switch/appstore/appstore.nro"

    get_version_number "${releases[$repo]}"
}

download_edizon () {
    local repo="WerWolv/EdiZon"
    get_latest_release "${repo}"

    func_result=$(find_asset '.*\.zip' <<< "${releases[$repo]}" \
        | get_download_url)
    download_file "${func_result}"

    unzip -qq "${func_result}" -d "${1}"
    rm -f "${func_result}"

    get_version_number "${releases[$repo]}"
}

download_emuiibo () {
    local repo="XorTroll/emuiibo"
    get_latest_release "${repo}"

    func_result=$(find_asset 'emuiibo.*\.zip' <<< "${releases[$repo]}" \
        | get_download_url)
    download_file "${func_result}"

    unzip -qq "${func_result}" -d "${1}"
    rm -rf "${1}/ReiNX"
    rm -f "${1}/atmosphere/titles/0100000000000352/flags/boot2.flag"
    rm -f "${func_result}"

    get_version_number "${releases[$repo]}"
}

download_goldleaf () {
    repo="XorTroll/Goldleaf"
    get_latest_release "${repo}"

    func_result=$(find_asset '.*\.nro' <<< "${releases[$repo]}" \
        | get_download_url)
    download_file "${func_result}"

    mkdir -p "${1}/switch/Goldleaf"
    mv "${func_result}" "${1}/switch/Goldleaf/Goldleaf.nro"

    get_version_number "${releases[$repo]}"
}

download_hid_mitm () {
    repo="jakibaki/hid-mitm"
    get_latest_release "${repo}"

    func_result=$(find_asset 'hid.*\.zip' <<< "${releases[$repo]}" \
        | get_download_url)
    download_file "${func_result}"

    unzip -qq "${func_result}" -d "${1}"
    rm -f "${1}/atmosphere/titles/0100000000000faf/flags/boot2.flag"
    rm -f "${func_result}"

    get_version_number "${releases[$repo]}"
}

download_kosmos_toolbox () {
    repo="AtlasNX/Kosmos-Toolbox"
    get_latest_release "${repo}"

    func_result=$(find_asset '.*\.nro' <<< "${releases[$repo]}" \
        | get_download_url)
    download_file "${func_result}"

    mkdir -p "${1}/switch/KosmosToolbox"
    mv "${func_result}" "${1}/switch/KosmosToolbox/KosmosToolbox.nro"
    cp "./Modules/kosmos-toolbox/config.json" "${1}/switch/KosmosToolbox/config.json"

    get_version_number "${releases[$repo]}"
}

download_kosmos_updater () {
    repo="AtlasNX/Kosmos-Updater"
    get_latest_release "${repo}"

    func_result=$(find_asset '.*\.nro' <<< "${releases[$repo]}" \
        | get_download_url)
    download_file "${func_result}"

    mkdir -p "${1}/switch/KosmosUpdater"
    mv "${func_result}" "${1}/switch/KosmosUpdater/KosmosUpdater.nro"
    sed "s/KOSMOS_VERSION/${2}/g" "./Modules/kosmos-updater/internal.db" >> "${1}/switch/KosmosUpdater/internal.db"

    get_version_number "${releases[$repo]}"
}

download_ldn_mitm () {
    repo="spacemeowx2/ldn_mitm"
    get_latest_release "${repo}"

    func_result=$(find_asset 'ldn_mitm.*\.zip' <<< "${releases[$repo]}" \
        | get_download_url)
    download_file "${func_result}"

    unzip -qq "${func_result}" -d "${1}"
    rm -f "${1}/atmosphere/titles/4200000000000010/flags/boot2.flag"
    rm -f "${func_result}"

    get_version_number "${releases[$repo]}"
}

download_lockpick () {
    repo="shchmue/Lockpick"
    get_latest_release "${repo}"

    func_result=$(find_asset '.*\.nro' <<< "${releases[$repo]}" \
        | get_download_url)
    download_file "${func_result}"

    mkdir -p "${1}/switch/Lockpick"
    mv "${func_result}" "${1}/switch/Lockpick/Lockpick.nro"

    get_version_number "${releases[$repo]}"
}

download_lockpick_rcm () {
    repo="shchmue/Lockpick_RCM"
    get_latest_release "${repo}"

    func_result=$(find_asset ".*\.bin" <<< "${releases[$repo]}" \
        | get_download_url)
    download_file "${func_result}"

    mv "${func_result}" "${1}/bootloader/payloads/Lockpick_RCM.bin"

    get_version_number "${releases[$repo]}"
}

download_sys_clk () {
    repo="retronx-team/sys-clk"
    get_latest_release "${repo}"

    func_result=$(find_asset 'sys-clk.*\.zip' <<< "${releases[$repo]}" \
        | get_download_url)
    download_file "${func_result}"

    unzip -qq "${func_result}" -d "${1}"
    rm -f "${1}/atmosphere/titles/00FF0000636C6BFF/flags/boot2.flag"
    rm -f "${1}/README.html"
    rm -f "${func_result}"

    get_version_number "${releases[$repo]}"
}

download_sys_ftpd () {
    download_file "http://bsnx.lavatech.top/sys-ftpd/sys-ftpd-latest.zip"

    temp_sysftpd_directory=$(mktemp -d "${temp_template}")
    mkdir -p "${temp_sysftpd_directory}"
    unzip -qq "${func_result}" -d "${temp_sysftpd_directory}"
    cp -r "${temp_sysftpd_directory}/sd"/* "${1}"
    rm -f "${1}/atmosphere/titles/420000000000000E/flags/boot2.flag"
    rm -f "${func_result}"
    rm -rf "${temp_sysftpd_directory}"

    func_result="latest"
}

# download_sys_netcheat () {
    # Someone needs to update their release to not be a kip... =/
# }

# =============================================================================
# Main Script
# =============================================================================

if [ $# -le 1 ]
then
    echo "Usage: ./kosmos.sh [version-number] [output]"
    exit 1
fi

# Build temp directory
temp_directory=$(mktemp -d "${temp_template}")
mkdir -p "${temp_directory}"

# Start building!

download_atmosphere "${temp_directory}"
atmosphere_version=${func_result}

download_hekate "${temp_directory}"
hekate_version=${func_result}
copy_payload "${temp_directory}"
build_hekate_files "${temp_directory}" "${1}"

download_appstore "${temp_directory}"
appstore_version=${func_result}

download_edizon "${temp_directory}"
edizon_version=${func_result}

download_emuiibo "${temp_directory}"
emuiibo_version=${func_result}

download_goldleaf "${temp_directory}"
goldleaf_version=${func_result}

download_hid_mitm "${temp_directory}"
hid_mitm_version=${func_result}

download_kosmos_toolbox "${temp_directory}"
kosmos_toolbox_version=${func_result}

download_kosmos_updater "${temp_directory}" "${1}"
kosmos_updater_version=${func_result}

download_ldn_mitm "${temp_directory}"
ldn_mitm_version=${func_result}

download_lockpick "${temp_directory}"
lockpick_version=${func_result}

download_lockpick_rcm "${temp_directory}"
lockpick_rcm_version=${func_result}

download_sys_clk "${temp_directory}"
sys_clk_version=${func_result}

download_sys_ftpd "${temp_directory}"
sys_ftpd_version=${func_result}

# Delete the bundle if it already exists.
dest=$(realpath -s "${2}")
rm -f "${dest}/Kosmos-${1}.zip"

# Bundle everything together.
(cd "${temp_directory}" && zip -q -r "${dest}/Kosmos-${1}.zip" .)

# Clean up.
rm -rf "${temp_directory}"

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
