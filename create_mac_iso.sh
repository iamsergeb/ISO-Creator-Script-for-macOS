#!/usr/bin/env bash
#
# Copyright 2022 Sergey Berman
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

read_lines () {
    return_array=()

    while read -r line
    do
        return_array+=( "$line" )
    done < <(echo "$version_lines" | eval "$1")
}

get_versions_info () {
    version_lines=$(softwareupdate --list-full-installers | grep -E "([0-9]+[\.]?)+,")
           
    read_lines 'grep -Eo "([0-9]+[\.]?)+," | grep -Eo "([0-9]+[\.]?)+"'
    versions=( "${return_array[@]}" )
    
    read_lines 'grep -Eo "[0-9]+KiB" | grep -Eo "[0-9]+"'
    sizes=( "${return_array[@]}")

    # parameters are intended to be passed to awk function not be utilized in bash
    # shellcheck disable=SC2016
    read_lines "awk -F ', ' '{print "'$1'"}' | awk -F ': ' '{print "'$2'"}'"
    names=( "${return_array[@]}" )
}

get_latest_version_info () {
    get_versions_info
    version=${versions[1]}
    size=$(( sizes[1] / 1024 + 1024 * 3 ))"m"
    name=${names[1]}
}

#Running 'softwareupdate -d --fetch-full-installer' resulted in Big Sur being downloaded instead of Monterey so:
get_latest_version_info

softwareupdate -d --fetch-full-installer --full-installer-version "$version"

#Get the final app name
appname=$(ls -p /Applications | grep "$name")

sudo hdiutil create -o /tmp/"$name" -size "$size" -volname "$name" -layout SPUD -fs HFS+J
sudo hdiutil attach /tmp/"$name".dmg -noverify -mountpoint /Volumes/"$name"
sudo "/Applications/""$appname""Contents/Resources/createinstallmedia" --volume /Volumes/"$name" --nointeraction
hdiutil eject -force /Volumes/Install\ macOS*
hdiutil convert /tmp/"$name".dmg -format UDTO -o ~/Desktop/"$name"
mv -v ~/Desktop/"$name".cdr ~/Desktop/"$name".iso
sudo rm -fv /tmp/"$name".dmg