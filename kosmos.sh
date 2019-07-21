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

# Bash requirements:
# 3.0 (
# 4.2 (2011-02-14)
# 4.3 (2014-02-26)
# 4.4 (2016-09-15): shopt inherit_errexit
if [ "${BASH_VERSINFO-0}" -lt 4 ] || [[ "${BASH_VERSINFO[1]-0}" -lt 4 ]]; then
    printf 'Bash 4.4 or newer is required.\n' >&2
    exit 1
fi

shopt -s -o errexit errtrace nounset pipefail
shopt -s inherit_errexit

declare -A releases
declare -A repos
declare user_agent="Kosmos/1.0.0"

# ============================================================================
# General Functions
# ============================================================================

# Set up GitHub release storage for a resource.
# Params:
#   - Resource identifier
#   - Github owner/repo
declare_release() {
    repos[${1}]=$2
    declare -gA "assets_${1}"
}

# Downloads a release's latest JSON.
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
    declare -gA "assets_${1}=()"
}

# Looks up a stored release's JSON.
# Params:
#   - (optional) -u: update if necessary
#   - Resource identifier
# Returns:
#   The currently stored release JSON on ${REPLY}.
get_release () {
    if [[ "${1}" == '-u' ]]; then shift
        if [[ -z "${releases[${1}]:+s}" ]]; then update_release "${1}"; fi
    fi
    REPLY=${releases[${1}]}
}

# Finds a specific stored release's asset's name with a regex.
# Params:
#   - (optional) -u: update if necessary
#   - Resource identifier
#   - Asset file name regex
# Returns:
#   The asset file name on stdout.
find_asset_name () {
    local u; u=(); if [[ "${1}" == '-u' ]]; then shift; u=(-u); fi
    local asset name
    asset=$(get_release "${u[@]}" "${1}" | jq --arg regex "${2}" \
        '.assets | first(.[] | select(.name | test($regex; "ip")))')
    name=$(jq -r '.name' <<< "${asset}")
    eval "assets_${1}[\${name}]=\${asset}"
    printf '%s\n' "${name}"
}

# Looks up a specific stored release's asset's metadata.
# Params:
#   - (optional) -u: update if necessary
#   - Resource identifier
#   - Asset file name
# Returns:
#   The asset metadata on stdout.
get_asset_meta () {
    local u; u=(); if [[ "${1}" == '-u' ]]; then shift; u=(-u); fi
    local asset="assets_${1}[\${2}]"
    if [[ -z "${!asset:+s}" ]]; then
        eval "${asset}"'=$(get_release "${u[@]}" "${1}" \
            | jq --arg name "${2}" \
                '\''.assets | first(.[] | select(.name == $name))'\'')'
    fi
    printf '%s\n' "${!asset}"
}

# Downloads a file as an asset.
# Params:
#   - Resource identifier
#   - URL
#   - (optional) Asset file name
# Returns:
#   The file path on stdout.
download_file () {
    local filename out_opts
    if [[ -n "${3:+s}" ]]; then out_opts=(-o "${3}"); else out_opts=(-O); fi

    mkdir -p "${bld}/assets/${1}"
    filename=$( (cd "${bld}/assets/${1}" && \
        curl -s -L -H "User-Agent: ${user_agent}" "${out_opts[@]}" "${2}" \
            -w "%{filename_effective}") || return "${?}" )
    printf '%s\n' "${bld}/assets/${1}/${filename}"
}

# Downloads a resource's release asset.
# Params:
#   - Resource identifier
#   - Asset file name
# Returns:
#   The file path on stdout.
update_asset () {
    download_file "${1}" "$(get_asset_meta -u "${1}" "${2}" \
        | jq -r '.browser_download_url')" "${2}"
}

# Looks up a resource's release asset.
# Params:
#   - (optional) -u: update if necessary
#   - Resource identifier
#   - Asset file name
# Returns:
#   The file path on stdout.
get_asset () {
    local u; if [[ "${1}" == '-u' ]]; then shift; u=1; fi
    local file="${bld}/assets/${1}/${2}"
    if [[ "${u}" == '1' && ! -e "${file}" ]]; then
        file=$(update_asset "${1}" "${2}")
    fi
    printf '%s\n' "${file}"
}

# Looks up a resources's release asset with a regex.
# Params:
#   - (optional) -u: update if necessary
#   - Resource identifier
#   - Asset file name regex
# Returns:
#   The asset file name on stdout.
find_asset () {
    local u; u=(); if [[ "${1}" == '-u' ]]; then shift; u=(-u); fi
    local asset
    asset=$(find_asset_name "${u[@]}" "${1}" "${2}")
    get_asset "${u[@]}" "${1}" "${asset}"
}

# Gets the version number from a release.
# Params:
#   - (optional) -u: update if necessary
#   - Resource identifier
# Returns:
#   The version number on stdout.
get_release_version () {
    local u; u=(); if [[ "${1}" == '-u' ]]; then shift; u=(-u); fi
    get_release "${u[@]}" "${1}" | jq -r ".tag_name"
}

# ============================================================================
# Atmosphere Functions
# ============================================================================

declare_release atmosphere "Atmosphere-NX/Atmosphere"

# Downloads the latest Atmosphere release and extracts it.
download_atmosphere () {
    local file res=atmosphere

    file=$(find_asset -u "${res}" 'atmosphere.*\.zip')
    unzip -qq "${file}" -d "${bld}/bundle"
    rm -f "${bld}/bundle/switch/reboot_to_payload.nro"

    file=$(find_asset -u "${res}" 'fusee.*\.bin')
    mkdir -p "${bld}/bundle/bootloader/payloads"
    cp "${file}" "${bld}/bundle/bootloader/payloads/fusee-primary.bin"
}

# ============================================================================
# Hekate Functions
# ============================================================================

declare_release hekate "CTCaer/hekate"

# Downloads the latest Hekate release and extracts it.
download_hekate () {
    local file res=hekate

    file=$(find_asset -u "${res}" 'hekate.*\.zip')
    unzip -qq "${file}" -d "${bld}/bundle"
}

# Copy the payload to where it needs to be.
copy_hekate_payload () {
    for file in "${bld}"/bundle/hekate*.bin; do
        cp "${file}" "${bld}/bundle/bootloader/update.bin"
        cp "${file}" "${bld}/bundle/atmosphere/reboot_payload.bin"
        break
    done
}

# Builds the hekate files.
# Params:
#   - The Kosmos version number
build_hekate_files () {
    cp "./Modules/hekate/bootlogo.bmp" \
        "${bld}/bundle/bootloader/bootlogo.bmp"
    sed "s/KOSMOS_VERSION/${1}/g" "./Modules/hekate/hekate_ipl.ini" \
        >> "${bld}/bundle/bootloader/hekate_ipl.ini"
}

# ============================================================================
# Homebrew Functions
# ============================================================================

declare_release appstore "vgmoose/hb-appstore"
download_appstore () {
    local file res=appstore

    file=$(find_asset -u appstore '.*\.nro')
    mkdir -p "${bld}/bundle/switch/appstore"
    cp "${file}" "${bld}/bundle/switch/appstore/appstore.nro"
}

declare_release edizon "WerWolv/EdiZon"
download_edizon () {
    local file res=edizon

    file=$(find_asset -u edizon '.*\.zip')
    unzip -qq "${file}" -d "${bld}/bundle"
}

declare_release emuiibo "XorTroll/emuiibo"
download_emuiibo () {
    local file res=emuiibo

    file=$(find_asset -u emuiibo 'emuiibo.*\.zip')
    unzip -qq "${file}" -d "${bld}/bundle"
    rm -rf "${bld}/bundle/ReiNX"
    rm -f "${bld}/bundle/atmosphere/titles/0100000000000352/flags/boot2.flag"
}

declare_release goldleaf "XorTroll/Goldleaf"
download_goldleaf () {
    local file res=goldleaf

    file=$(find_asset -u goldleaf '.*\.nro')
    mkdir -p "${bld}/bundle/switch/Goldleaf"
    cp "${file}" "${bld}/bundle/switch/Goldleaf/Goldleaf.nro"
}

declare_release hid_mitm "jakibaki/hid-mitm"
download_hid_mitm () {
    local file res=hid_mitm

    file=$(find_asset -u hid_mitm 'hid.*\.zip')
    unzip -qq "${file}" -d "${bld}/bundle"
    rm -f "${bld}/bundle/atmosphere/titles/0100000000000faf/flags/boot2.flag"
}

declare_release kosmos_toolbox "AtlasNX/Kosmos-Toolbox"
download_kosmos_toolbox () {
    local file res=kosmos_toolbox

    file=$(find_asset -u kosmos_toolbox '.*\.nro')
    mkdir -p "${bld}/bundle/switch/KosmosToolbox"
    cp "${file}" "${bld}/bundle/switch/KosmosToolbox/KosmosToolbox.nro"
    cp "./Modules/kosmos-toolbox/config.json" \
        "${bld}/bundle/switch/KosmosToolbox/config.json"
}

declare_release kosmos_updater "AtlasNX/Kosmos-Updater"
download_kosmos_updater () {
    local file res=kosmos_updater

    file=$(find_asset -u kosmos_updater '.*\.nro')
    mkdir -p "${bld}/bundle/switch/KosmosUpdater"
    cp "${file}" "${bld}/bundle/switch/KosmosUpdater/KosmosUpdater.nro"
    sed "s/KOSMOS_VERSION/${1}/g" "./Modules/kosmos-updater/internal.db" \
        >> "${bld}/bundle/switch/KosmosUpdater/internal.db"
}

declare_release ldn_mitm "spacemeowx2/ldn_mitm"
download_ldn_mitm () {
    local file res=ldn_mitm

    file=$(find_asset -u ldn_mitm 'ldn_mitm.*\.zip')
    unzip -qq "${file}" -d "${bld}/bundle"
    cp -f "${bld}/bundle/atmosphere/titles/4200000000000010/flags/boot2.flag"
}

declare_release lockpick "shchmue/Lockpick"
download_lockpick () {
    local file res=lockpick

    file=$(find_asset -u lockpick '.*\.nro')
    mkdir -p "${bld}/bundle/switch/Lockpick"
    cp "${file}" "${bld}/bundle/switch/Lockpick/Lockpick.nro"
}

declare_release lockpick_rcm "shchmue/Lockpick_RCM"
download_lockpick_rcm () {
    local file res=lockpick_rcm

    file=$(find_asset -u lockpick_rcm ".*\.bin")
    cp "${file}" "${bld}/bundle/bootloader/payloads/Lockpick_RCM.bin"
}

declare_release sys_clk "retronx-team/sys-clk"
download_sys_clk () {
    local file res=sys_clk

    file=$(find_asset -u sys_clk 'sys-clk.*\.zip')
    unzip -qq "${file}" -d "${bld}/bundle"
    rm -f "${bld}/bundle/atmosphere/titles/00FF0000636C6BFF/flags/boot2.flag"
    rm -f "${bld}/bundle/README.html"
}

# TODO version off of Jenkins?
# https://jenkins.lavatech.top/job/sys-ftpd/
download_sys_ftpd () {
    local file
    file=$(download_file sys_ftpd \
        "https://bsnx.lavatech.top/sys-ftpd/sys-ftpd-latest.zip")

    mkdir "${bld}/sys_ftpd"
    unzip -qq "${file}" "sd/*" -d "${bld}/sys_ftpd"
    mv "${bld}"/sys_ftpd/sd/* "${bld}/bundle"
    rmdir "${bld}/sys_ftpd/sd"
    rm -f "${bld}/bundle/atmosphere/titles/420000000000000E/flags/boot2.flag"
    rmdir "${bld}/sys_ftpd"
}

# download_sys_netcheat () {
    # Someone needs to update their release to not be a kip... =/
# }

# ============================================================================
# Main Script
# ============================================================================

if [ "${#}" -le 1 ]
then
    echo "Usage: ./kosmos.sh VERSION-NUMBER OUTPUT [BUILD-DIR]"
    exit 1
fi

kosmos_version=${1}
output=${2}
# build directory
bld=${3}
if [[ -z "${bld}" ]]; then
    bld=$(mktemp -d 'tmp-kosmos.XXXXXXXXXX')
else
    mkdir -p ${bld}
    if [[ "${bld}" == [^/]* ]]; then
        bld=./${3}
    fi
fi

rm -rf "${bld}/bundle"
mkdir "${bld}/bundle"

# Start building!

download_atmosphere
atmosphere_version=$(get_release_version atmosphere)

download_hekate
hekate_version=$(get_release_version hekate)
copy_hekate_payload
build_hekate_files "${kosmos_version}"

download_appstore
appstore_version=$(get_release_version appstore)

download_edizon
edizon_version=$(get_release_version edizon)

download_emuiibo
emuiibo_version=$(get_release_version emuiibo)

download_goldleaf
goldleaf_version=$(get_release_version goldleaf)

download_hid_mitm
hid_mitm_version=$(get_release_version hid_mitm)

download_kosmos_toolbox
kosmos_toolbox_version=$(get_release_version kosmos_toolbox)

download_kosmos_updater "${kosmos_version}"
kosmos_updater_version=$(get_release_version kosmos_updater)

download_ldn_mitm
ldn_mitm_version=$(get_release_version ldn_mitm)

download_lockpick
lockpick_version=$(get_release_version lockpick)

download_lockpick_rcm
lockpick_rcm_version=$(get_release_version lockpick_rcm)

download_sys_clk
sys_clk_version=$(get_release_version sys_clk)

# TODO query versions
download_sys_ftpd
sys_ftpd_version="latest"

# Delete the bundle if it already exists.
dest=$(realpath -s "${output}")
rm -f "${dest}/Kosmos-${kosmos_version}.zip"

# Bundle everything together.
(cd "${bld}/bundle" && zip -q -r "${dest}/Kosmos-${kosmos_version}.zip" .)

# Clean up.
[[ -z "${KOSMOS_KEEP_BUILD:-}" ]] && rm -rf "${bld}"

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
