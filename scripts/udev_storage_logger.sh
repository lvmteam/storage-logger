#!/bin/bash

# Copyright (C) 2019 Red Hat, Inc. All rights reserved.
#
# This copyrighted material is made available to anyone wishing to use,
# modify, copy, or redistribute it subject to the terms and conditions
# of the GNU General Public License v.2.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software Foundation,
# Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA

#########################################################################
# INSTALLATION INSTRUCTIONS
#########################################################################

# This script is designed to be called from a udev rules file that runs 
# after all the other ones that relate to block devices.
# It will log block device information into the system journal after each 
# relevant uevent.

# Save this script as /sbin/udev_storage_logger.sh
# Make it executable.
# Have it invoked by creating:
#   /etc/udev/rules.d/99-zzz-udev-storage-logger.rules
# with the following contents (removing the first # on each line):

###########################################################
# UDEV RULES FILE
###########################################################
#   # Copyright (C) 2019 Red Hat, Inc. All rights reserved.
#
#   # This rule must run after all rules able to change any block device state
#   # so that the environment variables hold a correct and complete record.
#
#   # Only perform this for block devices.
#   SUBSYSTEM!="block", GOTO="skip_udev_storage_logger"
#
#   # Run script to log udev environment variables into the system journal.
#   TEST{111}=="/sbin/udev_storage_logger.sh", RUN+="/sbin/udev_storage_logger.sh"
#
#   LABEL="skip_udev_storage_logger"

#########################################################################
# SCRIPT DEPENDENCIES
#########################################################################

# Firstly, this script relies upon some features of bash and some utilities.

# Secondly, it uses the --journald option of 'logger', which needs
# version 2.25 or higher of the util-linux package.
# This is not present on older systems such as RHEL7 so there is a
# fallback mode that writes the data to syslog as a single line of text.

#########################################################################
# USAGE INSTRUCTIONS
#########################################################################

# Use journalctl to query the data.
# Here's a quick guide.
#
# You can filter by using exact matches on persistent identifiers in the
# format used in the /dev/disk/by-* directories.
#   PERSISTENT_STORAGE_ID
#   PERSISTENT_STORAGE_LABEL
#   PERSISTENT_STORAGE_PARTLABEL
#   PERSISTENT_STORAGE_PARTUUID
#   PERSISTENT_STORAGE_PATH
#   PERSISTENT_STORAGE_UUID
#
# The following patterns are used:
#   PERSISTENT_STORAGE_ID:
#	ata-${ID_SERIAL}
#	ata-${ID_SERIAL}-part%n
#	ata-${ID_SERIAL_SHORT}
#	ata-${ID_SERIAL_SHORT}-part%n
#	dm-name-${DM_NAME}
#	dm-uuid-${DM_UUID}
#	${DM_TYPE}-${DM_SERIAL}
#	${DM_TYPE}-${DM_SERIAL}-part${DM_PART}
#	edd-${ID_EDD}
#	edd-${ID_EDD}-part%n
#	${ID_BUS}-${ID_SERIAL}
#	${ID_BUS}-${ID_SERIAL}-${ID_USB_INTERFACE_NUM}
#	${ID_BUS}-${ID_SERIAL}-${.INPUT_CLASS}
#	${ID_BUS}-${ID_SERIAL}-event-${.INPUT_CLASS}
#	${ID_BUS}-${ID_SERIAL}-event-if$attr{bInterfaceNumber}
#	${ID_BUS}-${ID_SERIAL}-if$attr{bInterfaceNumber}-${.INPUT_CLASS}
#	${ID_BUS}-${ID_SERIAL}-if$attr{bInterfaceNumber}-event-${.INPUT_CLASS}
#	${ID_BUS}-${ID_SERIAL}-if${ID_USB_INTERFACE_NUM}
#	${ID_BUS}-${ID_SERIAL}-if${ID_USB_INTERFACE_NUM}-port${.ID_PORT}
#	${ID_BUS}-${ID_SERIAL}-nst
#	${ID_BUS}-${ID_SERIAL}-part%n
#	${ID_BUS}-${ID_SERIAL}-video-index$attr{index}
#	${ID_BUS}-${ID_SERIAL}
#	${ID_BUS}-${ID_SERIAL}-part%n
#	ieee1394-$attr{ieee1394_id}
#	ieee1394-$attr{ieee1394_id}-part%n
#	ieee1394-${ieee1394_id}
#	ieee1394-${ieee1394_id}-part%n
#	lvm-pv-uuid-${ID_FS_UUID_ENC}
#	lvm-pv-uuid-<PV_UUID> symlink for each PV
#	md-name-${MD_NAME}
#	md-name-${MD_NAME}, OPTIONS+="string_escape=replace"
#	md-name-${MD_NAME}-part%n
#	md-name-${MD_NAME}-part%n, OPTIONS+="string_escape=replace"
#	md-uuid-${MD_UUID}
#	md-uuid-${MD_UUID}-part%n
#	memstick-${ID_NAME}_${ID_SERIAL}
#	memstick-${ID_NAME}_${ID_SERIAL}-part%n
#	memstick-${ID_NAME}_${ID_SERIAL}
#	memstick-${ID_NAME}_${ID_SERIAL}-part%n
#	mmc-${ID_NAME}_${ID_SERIAL}
#	mmc-${ID_NAME}_${ID_SERIAL}-part%n
#	mmc-${ID_NAME}_${ID_SERIAL}
#	mmc-${ID_NAME}_${ID_SERIAL}-part%n
#	nvme-$attr{wwid}
#	nvme-$attr{wwid}-part%n
#	nvme-${ID_SERIAL}
#	nvme-${ID_SERIAL}-part%n
#	scsi-${ID_SCSI_COMPAT}
#	scsi-${ID_SCSI_COMPAT}-part%n
#	scsi-${ID_SERIAL}
#	virtio-${ID_SERIAL}
#	virtio-${ID_SERIAL}-part%n
#	wwn-${DM_WWN}
#	wwn-${DM_WWN}-part${DM_PART}
#	wwn-${ID_WWN_WITH_EXTENSION}
#	wwn-${ID_WWN_WITH_EXTENSION}-part%n
#
#   PERSISTENT_STORAGE_LABEL:
#	${CACHED_LABEL}
#	${ID_FS_LABEL_ENC}
#
#   PERSISTENT_STORAGE_PARTLABEL:
#	${ID_PART_ENTRY_NAME}
#
#   PERSISTENT_STORAGE_PARTUUID:
#	${ID_PART_ENTRY_UUID}
#
#   PERSISTENT_STORAGE_PATH:
#	${ID_PATH}
#	${ID_PATH}-audio-index$attr{index}
#	${ID_PATH}-boot%n
#	${ID_PATH}-card
#	${ID_PATH}-control
#	${ID_PATH}-${.INPUT_CLASS}
#	${ID_PATH}-event
#	${ID_PATH}-event-${.INPUT_CLASS}
#	${ID_PATH}-nst
#	${ID_PATH}-part%n
#	${ID_PATH}-port${.ID_PORT}
#	${ID_PATH}-render
#	${ID_PATH}-video-index$attr{index}
#	${ID_SAS_PATH}
#	${ID_SAS_PATH}-part%n
#	virtio-${ID_PATH}
#	virtio-${ID_PATH}-part%n
#
#   PERSISTENT_STORAGE_UUID:
#	${CACHED_UUID}
#	${ID_FS_UUID_ENC}
#
# For example, to look up the major and minor number used by vg1-lvol0 you can use:
#   journalctl -t UDEVLOG --output verbose --output-fields=PERSISTENT_STORAGE_ID,MAJOR,MINOR PERSISTENT_STORAGE_ID=dm-name-vg1-lvol0 
#
# Useful command line arguments:
#
#   Only show the data logged by this script, with matching SYSLOG_IDENTIFIER:
#	-t UDEVLOG	
#
#   We do not log a message, so nothing appears in the basic syslog-style output.
#   To view the structured data that was logged you can use:
#	--output verbose
#
#   All the fields from the udev database are logged.
#   Choose the ones you want to see and eliminate the rest like this:
#       --output-fields=PERSISTENT_STORAGE_ID,MAJOR,MINOR
#
#  To restrict the output to a particular time range, use -S (since) and
#  -U (until)
#	-S "2019-05-01 12:00:00"  -U "2019-05-01 13:00:00"
#
#  Specify which matches you want to see using FIELD=VALUE notation.
#  Note that journalctl does not accept wildcards here, but only matches
#  on the exact complete string.
#
#  To see data for the LVM2 logical volume lvol0 in volume group vg1:
#	PERSISTENT_STORAGE_ID=dm-name-vg1-lvol0
#
#  To see data for the disk that forms the LVM Physical Volume with a 
#  particular UUID:
#       PERSISTENT_STORAGE_ID=lvm-pv-uuid-UWDjz8-wdEB-Y3k5-O7wr-YiTL-UmX6-zv6Las
#  perhaps with 
#       --output-fields=PERSISTENT_STORAGE_ID,PERSISTENT_STORAGE_PATH,DEVNAME

#########################################################################
# THE SCRIPT
#########################################################################

# Enable bash extended and null globbing so we can easily match a range 
# of sysfs filenames that might not be present.
shopt -s extglob nullglob

# Default binary locations
UDEVLOG_DMSETUP="${UDEVLOG_DMSETUP:-/sbin/dmsetup}"
UDEVLOG_HEAD="${UDEVLOG_HEAD:-/usr/bin/head}"
UDEVLOG_LSBLK="${UDEVLOG_LSBLK:-/bin/lsblk}"
UDEVLOG_LOGGER="${UDEVLOG_LOGGER:-/bin/logger}"
UDEVLOG_XARGS="${UDEVLOG_XARGS:-/usr/bin/xargs}"

# FIXME Check all these binaries exist

# FIXME need a fallback for head eg in initrd!

# Exit if logger isn't installed so we can't send data to syslog
if [[ ! -x $UDEVLOG_LOGGER ]]; then
	exit 0
fi

# Whether or not we have a sufficiently new version that supports
# logging of structured data.
# If you know you have this support, you can set this to 1 to
# improve efficiency.
UDEVLOG_LOGGER_HAS_JOURNALD="${UDEVLOG_LOGGER_HAS_JOURNALD:-}"

# Are we using systemd and does the logger binary support the --journald option?
if [[ ! $UDEVLOG_LOGGER_HAS_JOURNALD && -d /run/systemd/system/ ]] && \
   $UDEVLOG_LOGGER --journald --no-act < /dev/null > /dev/null 2>&1; then
	UDEVLOG_LOGGER_HAS_JOURNALD=1
fi

# Only store the first 512 bytes of device-mapper tables
UDEVLOG_LOGGER_DM_TABLE_LIMIT="${UDEVLOG_LOGGER_DM_TABLE_LIMIT:-512}"

# Use syslog priority 6 by default
UDEVLOG_LOGGER_PRIORITY="${UDEVLOG_LOGGER_PRIORITY:-6}"

# Index syslog messages with the identifier UDEVLOG
UDEVLOG_LOGGER_IDENTIFIER="${UDEVLOG_LOGGER_IDENTIFIER:-UDEVLOG}"

# Earlier udev rules may set up DEVLINKS entries.  Read them into an array.
read -ra devlinks <<< "$DEVLINKS"

# Only process add, change and remove uevents.
if [[ "$ACTION" != "add" && "$ACTION" != "change" && "$ACTION" != "remove" ]]; then
	exit 0;
fi

# Use an internal subshell to produce all the output so we can redirect it easily.
{
	echo PRIORITY="$UDEVLOG_LOGGER_PRIORITY"
	echo SYSLOG_IDENTIFIER="$UDEVLOG_LOGGER_IDENTIFIER"

	# Obtain the list of environment variables by using bash completion logic.
	compgen -e | \
		# Write out each environment variable with its value.
		while read -r envvar; do echo "$envvar"="${!envvar}"; done

	# Strip the prefix from each devlink value.
	# Write each out as a separate persistent identifier of the appropriate type.
	# Use separate fields so we can query the data with journalctl, which
	# does not support wildcards.
	for devlink in "${devlinks[@]}"
	do
		if [[ "$devlink" =~ ^/dev/disk/by-id/(.*) ]]; then echo PERSISTENT_STORAGE_ID="${BASH_REMATCH[1]}"; fi
		if [[ "$devlink" =~ ^/dev/disk/by-label/(.*) ]]; then echo PERSISTENT_STORAGE_LABEL="${BASH_REMATCH[1]}"; fi
		if [[ "$devlink" =~ ^/dev/disk/by-partlabel/(.*) ]]; then echo PERSISTENT_STORAGE_PARTLABEL="${BASH_REMATCH[1]}"; fi
		if [[ "$devlink" =~ ^/dev/disk/by-partuuid/(.*) ]]; then echo PERSISTENT_STORAGE_PARTUUID="${BASH_REMATCH[1]}"; fi
		if [[ "$devlink" =~ ^/dev/disk/by-path/(.*) ]]; then echo PERSISTENT_STORAGE_PATH="${BASH_REMATCH[1]}"; fi
		if [[ "$devlink" =~ ^/dev/disk/by-uuid/(.*) ]]; then echo PERSISTENT_STORAGE_UUID="${BASH_REMATCH[1]}"; fi
	done

	# Now extract some useful extra fields from the system.
	# We might move some of these to earlier udev rules, store in the udev database and import via the method above.

	# Does DEVPATH contain /host ?
	if [[ "$DEVPATH" =~ ^(.*/host[^/]*/) ]]; then

		# If there is a .../host*/fc_host/*/ directory, report some fc_host attributes.
		for attr in /sys"${BASH_REMATCH[1]}"fc_host/*/@(port_id|port_name|port_state|fabric_name|node_name|speed|port_type|symbolic_name|tgtid_bind_type)
		do
			[[ -f "$attr" ]] || continue
			varname=${attr##*/}
			varname=${varname^^}
			echo UDEVLOG_FC_"${varname}"="$(cat "$attr")"
		done

		# If there is a .../host*/scsi_host/*/ directory, report some scsi_host attributes.
		for attr in /sys"${BASH_REMATCH[1]}"scsi_host/*/@(driver_version|fw_state|fw_version|model_desc|model_name|serial_num|state|active_mode)
		do
			[[ -f "$attr" ]] || continue
			varname=${attr##*/}
			varname=${varname^^}
			echo UDEVLOG_SCSI_"${varname}"="$(cat "$attr")"
		done
	fi

	# Does DEVPATH contain /nvme/ ?
	if [[ "$DEVPATH" =~ ^(.*/nvme/[^/]*/) ]]; then

		# Report some nvme attributes.
		for attr in /sys"${BASH_REMATCH[1]}"@(firmware_rev|model|state)
		do
			[[ -f "$attr" ]] || continue
			varname=${attr##*/}
			varname=${varname^^}
			echo UDEVLOG_NVME_"${varname}"="$(cat "$attr")"
		done
	fi

	# Does DEVPATH have a queue subdirectory?
	if [[ -d /sys"$DEVPATH"/queue/ ]]; then

		# Report some queue attributes.
		for attr in /sys"$DEVPATH"/queue/@(read_ahead_kb|minimum_io_size|optimal_io_size|physical_block_size|logical_block_size|rotational|scheduler|nr_requests|discard_granularity|discard_max_bytes|discard_zeroes_data|add_random|write_same_max_bytes|zoned)
		do
			[[ -f "$attr" ]] || continue
			varname=${attr##*/}
			varname=${varname^^}
			echo UDEVLOG_QUEUE_"${varname}"="$(cat "$attr")"
		done
	fi

	# Does DEVPATH have a device subdirectory?
	if [[ -d /sys"$DEVPATH"/device/ ]]; then

		# Report a device attributes.
		for attr in /sys"$DEVPATH"/device/@(rev|serial|type|vendor)
		do
			[[ -f "$attr" ]] || continue
			varname=${attr##*/}
			varname=${varname^^}
			echo UDEVLOG_DEVICE_"${varname}"="$(cat "$attr")"
		done
	fi

	# Report some block device attributes
	for attr in /sys"$DEVPATH"/@(size|ro|removable|capability|ext_range|discard_alignment|alignment_offset)
	do
		[[ -f "$attr" ]] || continue
		varname=${attr##*/}
		varname=${varname^^}
		echo UDEVLOG_BLOCK_"${varname}"="$(cat "$attr")"
	done

	# List of any holders
	for device in /sys"$DEVPATH"/holders/*/dev
	do
		[[ -f "$device" ]] || continue
		holders+=( "$(cat "$device")" )
	done
	echo UDEVLOG_BLOCK_HOLDERS="${holders[@]}"

	# List any slaves
	for device in /sys"$DEVPATH"/slaves/*/dev
	do
		[[ -f "$device" ]] || continue
		slaves+=( "$(cat "$device")" )
	done
	echo UDEVLOG_BLOCK_SLAVES="${slaves[@]}"

	# Obtain a few fields from lsblk
	if [[ "$ACTION" != "remove" && -x "$UDEVLOG_LSBLK" && -x "$UDEVLOG_XARGS" && $DEVNAME ]]; then

		# FIXME Write a shell function to do this internally
		"$UDEVLOG_LSBLK" -a --nodeps -o mountpoint,label,model,state,owner,group,mode,type -P "$DEVNAME" | "$UDEVLOG_XARGS" printf '%s\0' |
		(
			while IFS= read -r -d '' attr ;
       			do
				echo UDEVLOG_LSBLK_"$attr"
			done
		)
	fi

	# Obtain remaining device-mapper fields
	if [[ "$ACTION" != "remove" && "$DEVNAME" =~ ^/dev/dm- && -x "$UDEVLOG_DMSETUP" && "$MAJOR" && "$MINOR" ]]; then

		for attr in $("$UDEVLOG_DMSETUP" info -j "$MAJOR" -m "$MINOR" -c -o read_ahead,attr,tables_loaded,readonly,open,segments,events,device_count,devs_used,devnos_used,blkdevs_used,device_ref_count,names_using_dev,devnos_using_dev,subsystem,lv_layer --noheadings --nameprefixes --separator ' ' --rows)
		do
			echo UDEVLOG_"$attr"
		done

		# Truncate long tables
		echo UDEVLOG_DM_TABLE_LIVE=$("$UDEVLOG_DMSETUP" table -j "$MAJOR" -m "$MINOR" | "$UDEVLOG_HEAD" -c "$UDEVLOG_LOGGER_DM_TABLE_LIMIT")
		echo UDEVLOG_DM_TABLE_INACTIVE=$("$UDEVLOG_DMSETUP" table --inactive -j "$MAJOR" -m "$MINOR" | "$UDEVLOG_HEAD" -c "$UDEVLOG_LOGGER_DM_TABLE_LIMIT")
	fi

} | if [[ ($UDEVLOG_LOGGER_HAS_JOURNALD) ]]; then
	# Redirect the output to the system journal as structured data.
	"$UDEVLOG_LOGGER" --journald
else
	# So that the script can still be used on older systems,
	# fallback to logging everything as a single line, which
	# syslog might split up.
		echo $(cat -) |"$UDEVLOG_LOGGER"
fi
