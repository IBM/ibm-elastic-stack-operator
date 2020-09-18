#!/bin/bash
#
# Copyright 2020 IBM Corporation
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
ESROOT=/usr/share/elasticsearch/data
ES66=6.x
ES66ROOT=$ESROOT/$ES66
DONEFILE=MIGRATIONCOMPLETE
# free space buffer when importing/retaining old data so the elasticsearch 6.x can run after upgrade
# logging default pv is of 20G in size
FREESPACEAFTERIMPORT=10

IMPORTDATA=false
{{- if .Values.upgrade.elasticsearch.importData }}
IMPORTDATA=true
{{- end }}

RETAINOLDDATA=false
{{- if .Values.upgrade.elasticsearch.retainOldData }}
RETAINOLDDATA=true
{{- end }}

echo "`date` Flags to control migration: importData=${IMPORTDATA} retainOldData=${RETAINOLDDATA}"

# [1] check if we already done with migration
if [ -f $ESROOT/$DONEFILE ]; then
    echo "`date` Migration success flag found at $ESROOT/$DONEFILE, nothing to do."
    exit 0
fi

# [2] create data directory for elasticsearch 6.6
mkdir -p $ES66ROOT

# [3] check if there are elk551 data already on the PV
if [ -d $ESROOT/nodes ]; then
    echo "`date` FOUND data from elk 551 deployment!"

    # calculate free and used (by logging data pod) disk spaces
    free_disk=$(df -lh -BG --output=avail $ESROOT | sed '1d' | grep -oP '\d+')
    used_disk=$(du -sh -BG $ESROOT/nodes | cut -f1 | sed 's/\([0-9]*\)\(.*\)/\1/')
    required_disk=$(($used_disk + $FREESPACEAFTERIMPORT))
    echo "`date` Free disk: ${free_disk}G Logging used disk: ${used_disk}G Required Disk (for importing): ${required_disk}G"

    # need to import data
    if $IMPORTDATA; then
    # check if we need to retain old data or not
    if $RETAINOLDDATA; then
        # retain old data
        if [ $free_disk -gt $required_disk ]; then
        echo "`date` Importing data ... "
        time cp -p -R $ESROOT/nodes $ES66ROOT
        echo "`date` Done importing elk5.5.1 data"
        else
        echo "`date` No enough disk space to import logging data!"
        exit 1
        fi
    else
        # does not need to retain old data
        echo "`date` Delete old data now..."
        rm -rf $ESROOT/nodes
        echo "`date` Done deleting old data!"
    fi
    else
    # no need to import data
    if $RETAINOLDDATA; then
        # retain old data
        if [ $free_disk -gt $required_disk ]; then
        echo "`date` En:enough space for new data!"
        else
        echo "`date` No enough disk space for new data!"
        exit 1
        fi
    else
        # does not need to retain old data
        echo "`date` Delete old data now..."
        rm -rf $ESROOT/nodes
        echo "`date` Done deleting old data!"
    fi
    fi
else
    # this is a new install of elk6
    echo "`date` NEW INSTALL!"
fi

echo "`date` touch $DONEFILE"
touch $ESROOT/$DONEFILE
exit 0
