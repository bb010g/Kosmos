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

# Downloads the latest Atmosphere release and extracts it.
# Params:
#   - Directory to extract to
#   - GitHub Login
# Returns:
#   The version number.
download_atmosphere () {
    mkdir -p "${1}"
    latest_release=$(\
        ./common.sh get_latest_release "${2}" "Atmosphere-NX" "Atmosphere" \
    )

    asset=$(./common.sh find_asset "${latest_release}" "atmosphere*" "*.zip")
    file=$(./common.sh download_file "${asset}")

    unzip -qq "${file}" -d "${1}"
    rm -f "${1}/switch/reboot_to_payload.nro"
    rm -f "${file}"

    asset=$(./common.sh find_asset "${latest_release}" "fusee*" "*.bin")
    file=$(./common.sh download_file "${asset}")

    mkdir -p "${1}/bootloader/payloads"
    mv "${file}" "${1}/bootloader/payloads/fusee-primary.bin"
    rm -f "${1}/atmosphere/system_settings.ini"
    cp "./Modules/atmosphere/system_settings.ini" \
        "${1}/atmosphere/system_settings.ini"

    ./common.sh get_version_number "${latest_release}"
}

# Downloads the latest Hekate release and extracts it.
# Params:
#   - Directory to extract to
#   - The Kosmos version number
#   - GitHub Login
# Returns:
#   The version number.
download_hekate () {
    mkdir -p "${1}"
    latest_release=$(./common.sh get_latest_release "${3}" "CTCaer" "hekate")

    asset=$(./common.sh find_asset "${latest_release}" "hekate*" "*.zip")
    file=$(./common.sh download_file "${asset}")

    unzip -qq "${file}" -d "${1}"
    rm -f "${file}"

    payload=$(./common.sh glob "${1}/hekate*.bin")
    cp "${payload}" "${1}/bootloader/update.bin"
    mkdir -p "${1}/atmosphere"
    cp "${payload}" "${1}/atmosphere/reboot_payload.bin"

    cp "./Modules/hekate/bootlogo.bmp" "${1}/bootloader/bootlogo.bmp"
    sed "s/KOSMOS_VERSION/${2}/g" "./Modules/hekate/hekate_ipl.ini" \
        >> "${1}/bootloader/hekate_ipl.ini"

    ./common.sh get_version_number "${latest_release}"
}

download_appstore () {
    mkdir -p "${1}"
    latest_release=$(./common.sh get_latest_release "${2}" \
        "vgmoose" "hb-appstore")

    asset=$(./common.sh find_asset "${latest_release}" "*.nro")
    file=$(./common.sh download_file "${asset}")

    mkdir -p "${1}/switch/appstore"
    mv "${file}" "${1}/switch/appstore/appstore.nro"

    ./common.sh get_version_number "${latest_release}"
}

download_edizon () {
    mkdir -p "${1}"
    latest_release=$(./common.sh get_latest_release "${2}" "WerWolv" "EdiZon")

    asset=$(./common.sh find_asset "${latest_release}" "*.zip")
    file=$(./common.sh download_file "${asset}")

    unzip -qq "${file}" -d "${1}"
    rm -f "${file}"

    ./common.sh get_version_number "${latest_release}"
}

download_emuiibo () {
    mkdir -p "${1}"
    latest_release=$(./common.sh get_latest_release "${2}" "XorTroll" "emuiibo")

    asset=$(./common.sh find_asset "${latest_release}" "emuiibo*" "*.zip")
    file=$(./common.sh download_file "${asset}")

    unzip -qq "${file}" -d "${1}"
    rm -f "${1}/titles/0100000000000352/flags/boot2.flag"
    rm -f "${file}"
    mkdir -p "${1}/atmosphere/titles"
    mv "${1}/titles/0100000000000352" "${1}/atmosphere/titles/"
    rm -rf "${1}/titles"

    ./common.sh get_version_number "${latest_release}"
}

download_goldleaf () {
    mkdir -p "${1}"
    latest_release=$(./common.sh get_latest_release "${2}" "XorTroll" "Goldleaf")

    asset=$(./common.sh find_asset "${latest_release}" "*.nro")
    file=$(./common.sh download_file "${asset}")

    mkdir -p "${1}/switch/Goldleaf"
    mv "${file}" "${1}/switch/Goldleaf/Goldleaf.nro"

    ./common.sh get_version_number "${latest_release}"
}

download_hid_mitm () {
    mkdir -p "${1}"
    latest_release=$(./common.sh get_latest_release "${2}" "jakibaki" "hid-mitm")

    asset=$(./common.sh find_asset "${latest_release}" "hid*" "*.zip")
    file=$(./common.sh download_file "${asset}")

    unzip -qq "${file}" -d "${1}"
    rm -f "${1}/atmosphere/titles/0100000000000faf/flags/boot2.flag"
    rm -f "${file}"

    ./common.sh get_version_number "${latest_release}"
}

download_kosmos_toolbox () {
    mkdir -p "${1}"
    latest_release=$(./common.sh get_latest_release "${2}" \
        "AtlasNX" "Kosmos-Toolbox")

    asset=$(./common.sh find_asset "${latest_release}" "*.nro")
    file=$(./common.sh download_file "${asset}")

    mkdir -p "${1}/switch/KosmosToolbox"
    mv "${file}" "${1}/switch/KosmosToolbox/KosmosToolbox.nro"
    cp "./Modules/kosmos-toolbox/config.json" \
        "${1}/switch/KosmosToolbox/config.json"

    ./common.sh get_version_number "${latest_release}"
}

download_kosmos_updater () {
    mkdir -p "${1}"
    latest_release=$(./common.sh get_latest_release "${3}" \
        "AtlasNX" "Kosmos-Updater")

    asset=$(./common.sh find_asset "${latest_release}" "*.nro")
    file=$(./common.sh download_file "${asset}")

    mkdir -p "${1}/switch/KosmosUpdater"
    mv "${file}" "${1}/switch/KosmosUpdater/KosmosUpdater.nro"
    sed "s/KOSMOS_VERSION/${2}/g" "./Modules/kosmos-updater/internal.db" \
        >> "${1}/switch/KosmosUpdater/internal.db"

    ./common.sh get_version_number "${latest_release}"
}

download_ldn_mitm () {
    mkdir -p "${1}"
    latest_release=$(./common.sh get_latest_release "${2}" \
        "spacemeowx2" "ldn_mitm")

    asset=$(./common.sh find_asset "${latest_release}" "ldn_mitm*" "*.zip")
    file=$(./common.sh download_file "${asset}")

    unzip -qq "${file}" -d "${1}"
    rm -f "${1}/atmosphere/titles/4200000000000010/flags/boot2.flag"
    rm -f "${file}"

    ./common.sh get_version_number "${latest_release}"
}

download_lockpick () {
    mkdir -p "${1}"
    latest_release=$(./common.sh get_latest_release "${2}" "shchmue" "Lockpick")

    asset=$(./common.sh find_asset "${latest_release}" "*.nro")
    file=$(./common.sh download_file "${asset}")

    mkdir -p "${1}/switch/Lockpick"
    mv "${file}" "${1}/switch/Lockpick/Lockpick.nro"

    ./common.sh get_version_number "${latest_release}"
}

download_lockpick_rcm () {
    mkdir -p "${1}"
    latest_release=$(./common.sh get_latest_release "${2}" \
        "shchmue" "Lockpick_RCM")

    asset=$(./common.sh find_asset "${latest_release}" "*.bin")
    file=$(./common.sh download_file "${asset}")

    mkdir -p "${1}/bootloader/payloads"
    mv "${file}" "${1}/bootloader/payloads/Lockpick_RCM.bin"

    ./common.sh get_version_number "${latest_release}"
}

download_sys_clk () {
    mkdir -p "${1}"
    latest_release=$(./common.sh get_latest_release "${2}" \
        "retronx-team" "sys-clk")

    asset=$(./common.sh find_asset "${latest_release}" "sys-clk*" "*.zip")
    file=$(./common.sh download_file "${asset}")

    unzip -qq "${file}" -d "${1}"
    rm -f "${1}/atmosphere/titles/00FF0000636C6BFF/flags/boot2.flag"
    rm -f "${1}/README.html"
    rm -f "${file}"

    ./common.sh get_version_number "${latest_release}"
}

download_sys_ftpd () {
    releases=$( \
        curl -s -H "User-Agent: Kosmos/1.0.0" \
            -X POST \
            -H 'Content-Type: application/json' \
            -d '{"action":"get","items":{"href":"/sys-ftpd/","what":1}}' \
            http://bsnx.lavatech.top/sys-ftpd/\? \
    )
    latest_release=$( \
        echo "${releases}" | \
        jq -r '.items | map(select(has("fetched") | not)) |
            sort_by(.time) | reverse | .[1].href' \
    )
    latest_release_url="http://bsnx.lavatech.top${latest_release}"

    mkdir -p "${1}"
    file=$(./common.sh download_file_url "${latest_release_url}")

    temp_sysftpd_directory="/tmp/$(uuidgen)"
    mkdir -p "${temp_sysftpd_directory}"
    unzip -qq "${file}" -d "${temp_sysftpd_directory}"
    cp -r "${temp_sysftpd_directory}/sd"/* "${1}"
    rm -f "${1}/atmosphere/titles/420000000000000E/flags/boot2.flag"
    rm -f "${file}"
    rm -rf "${temp_sysftpd_directory}"

    expr substr "${latest_release}" 20 7
}

# ============================================================================
# Main Script
# ============================================================================

if [ $# -le 1 ]
then
    printf '%s\n' "\
This is not meant to be called by end users, \
but instead by the kosmos.sh and sdsetup.sh scripts."
    exit 1
fi

# Check if the function exists (bash specific)
if declare -f "$1" > /dev/null
then
  # call arguments verbatim
  "$@"
else
  # Show a helpful error
  echo "'$1' is not a known function name" >&2
  exit 1
fi

# Local Variables:
# mode: bash
# indent-tabs-mode: nil
# tab-width: 4
# sh-basic-offset: 4
# fill-column: 78
# End:
# vim:et:sw=4:tw=78
