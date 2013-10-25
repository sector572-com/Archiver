#!/bin/bash

################################################################################
#
# Backup Utility Script for Unix/Linux
# Copyright(c) 2013 - CodersHaven.net
#
# Author:	CodersHaven.net
# Date:		2013-10-09
# File name:	ch_backup.sh
# Version:	1.0.0
# Description:	A utility script that can automatically archive directories and
#		files. It can optionally compress and encrypt the backup files.
#
# Disclaimer:	This product is free and provided as is with no warranty of any
#		kind. You may use it at your own risk. You may also distribute
#		it so long as you leave the file information and disclaimer
#		intact.
#
#		By using this script, codershaven.net is not responsible for
#		any damages it may cause. You should probably test it on non-
#		production data to ensure it works as you expect.
#
# Homepage:	http://www.codershaven.net
#
################################################################################

app_home=""

#
# It is not recommended that you modify any of the code below this point.
#

bin_dir="$app_home/bin"
conf_dir="$app_home/conf"
log_dir="$app_home/log"
data_dir="$app_home/data"
lib_dir="$app_home/lib"

. $conf_dir/common.sh

config_file="$1"

if [ "$config_file" == "" ]
then
	$ECHO "Usage: $0 <config file>"
	exit 1
elif [ ! -e "$config_file" ]
then
	$ECHO "The config file '$config_file' does not exist."
	exit 1
fi

#
# Include the config file.
#
. $config_file

. $lib_dir/utils.sh

checkCommand "$GPG"
checkCommand "$TAR"
checkCommand "$GZIP"
checkCommand "$TR"
checkCommand "$CAT"
checkCommand "$DATE"
checkCommand "$SED"
checkCommand "$WC"
checkCommand "$ECHO"
checkCommand "$RM"
checkCommand "$SHA1SUM"
checkCommand "$FGREP"

timestamp=""

# none          - results in PREFIX_NAME.tar
# yearly        - results in PREFIX_NAME-YYYY.tar
# monthly       - results in PREFIX_NAME-YYYY-MM.tar
# daily         - results in PREFIX_NAME-YYYY-MM-DD.tar
# hourly        - results in PREFIX_NAME-YYYY-MM-DD_HH.tar
# minute        - results in PREFIX_NAME-YYYY-MM-DD_HH_MM.tar

if [ "$TS_FORMAT" == "yearly" ]
then
        timestamp=`$DATE '+-%Y' | $SED 's/\n//g'`
elif [ "$TS_FORMAT" == "monthly" ]
then
        timestamp=`$DATE '+-%Y-%m' | $SED 's/\n//g'`
elif [ "$TS_FORMAT" == "daily" ]
then
        timestamp=`$DATE '+-%Y-%m-%d' | $SED 's/\n//g'`
elif [ "$TS_FORMAT" == "hourly" ]
then
        timestamp=`$DATE '+-%Y-%m-%d_%H' | $SED 's/\n//g'`
elif [ "$TS_FORMAT" == "minute" ]
then
        timestamp=`$DATE '+-%Y-%m-%d_%H-%M' | $SED 's/\n//g'`
elif [ "$TS_FORMAT" == "none" ]
then
        timestamp=""
else
        $ECHO "Unknown or unsupported TS_FORMAT specified." 1>&2
        exit 1
fi

log_file="$log_dir/$PREFIX_NAME$timestamp.log"
backup_file="$data_dir/$PREFIX_NAME$timestamp.tar"
backup_index_file="$data_dir/$PREFIX_NAME-index$timestamp.txt"
backup_chksum_file="$data_dir/$PREFIX_NAME-checksums$timestamp.sha1"
backup_gpg_chksum_file="$data_dir/$PREFIX_NAME-gpg_checksums$timestamp.sha1"
file_list_file="$FILE_LIST"
recipient_list_file="$GPG_RECIPIENTS"

if [ ! -s "$file_list_file" ]
then
	$ECHO "The file list '$file_list_file' is empty. Please add a file" \
		" or directory to this list to continue." >> $log_file
	exit 1
fi

function removeFile
{
	file="$1"

	if [ "$file" == "" ]
	then
		ts=`$DATE | $SED 's/\n$//'`
		$ECHO "$ts: Cannot remove the file as the file name was" \
			" empty." >> $log_file
	else
		if [ -e "$file" ]
		then
			ts=`$DATE | $SED 's/\n$//'`
			$ECHO "$ts: Removing file '$file'." >> $log_file
			$RM -f $file 2> /dev/null
		fi
	fi
}

function cleanup
{
	ts=`$DATE | $SED 's/\n$//'`
	$ECHO "$ts: Cleaning up." >> $log_file

	removeFile "$backup_file"
	removeFile "$backup_file.gz"
	removeFile "$backup_index_file"
	removeFile "$backup_index_file.gz"
	removeFile "$backup_chksum_file"
	removeFile "$backup_chksum_file.gpg"
	removeFile "$backup_gpg_chksum_file"
}

function checkFile
{
	file="$1"

	if [ "$file" == "" ]
	then
		ts=`$DATE | $SED 's/\n$//'`
		$ECHO "$ts: Cannot check the file as the file name was" \
			" empty." >> $log_file
		exit 1
	else
		if [ -e "$file" ]
		then
			ts=`$DATE | $SED 's/\n$//'`
			$ECHO "$ts: The file '$file' already" \
				" exists." >> $log_file
			exit 1
		fi
	fi
}

function checkFiles
{
	checkFile "$backup_file"
	checkFile "$backup_file.gpg"
	checkFile "$backup_index_file"
	checkFile "$backup_index_file.gpg"
	checkFile "$backup_chksum_file"
	checkFile "$backup_gpg_chksum_file"
	checkFile "$backup_file.gz"
	checkFile "$backup_index_file.gz"
	checkFile "$backup_chksum_file.gpg"
	checkFile "$backup_file.gz.gpg"
	checkFile "$backup_index_file.gz.gpg"
}

#
# Check if files already exist.
#
checkFiles

$FGREP -v "#" $file_list_file |
while read filename
do
	if [ ! -e "$filename" ]
	then
		ts=`$DATE | $SED 's/\n$//'`
		$ECHO "$ts: The file name '$filename' does not" \
			" exist." >> $log_file
		exit 1
	fi
done

file_list=`$FGREP -v "#" $file_list_file | $TR '\n' ' '`

# Create backup file.
if ! $TAR -cf $backup_file $file_list 2>> $log_file > /dev/null
then
	cleanup
	ts=`$DATE | $SED 's/\n$//'`
	$ECHO "$ts: Failed to create backup archive " \
		"'$backup_file'." >> $log_file
	exit 1
fi

# Create backup file index.

if [ "$CREATE_INDEX_FILE" -eq "0" ]
then
	ts=`$DATE | $SED 's/\n$//'`
	$ECHO "$ts: Skipping file compression." >> $log_file
elif [ "$CREATE_INDEX_FILE" -eq "1" ]
then
	if [ -e "$backup_file" ]
	then
		if ! $TAR -tvf $backup_file > $backup_index_file 2>> $log_file
		then
			cleanup
			ts=`$DATE | $SED 's/\n$//'`
			$ECHO "$ts: Failed to create backup archive index " \
				"'$backup_index_file'." >> $log_file
			exit 1
		fi
	else
		cleanup
		ts=`$DATE | $SED 's/\n$//'`
		$ECHO "$ts: The backup archive '$backup_file' does not exist." \
			" Cannot create index." >> $log_file
		exit 1
	fi
else
	cleanup
	ts=`$DATE | $SED 's/\n$//'`
	$ECHO "$ts: The create index file parameter's value " \
		"'$CREATE_INDEX_FILE' is not a valid option." >> $log_file
	exit 1
fi

#
# Perform compression
#
if [ "$COMPRESS_FILE" -eq "0" ]
then
	ts=`$DATE | $SED 's/\n$//'`
	$ECHO "$ts: Skipping file compression." >> $log_file
elif [ "$COMPRESS_FILE" -eq "1" ]
then
	if $GZIP -9 $backup_file 2>> $log_file
	then
		backup_file="$backup_file.gz"
	else
		cleanup
		ts=`$DATE | $SED 's/\n$//'`
		$ECHO "$ts: Failed to compress the backup archive " \
			"'$backup_file'." >> $log_file
		exit 1
	fi

	if [ -e "$backup_index_file" ]
	then
		if $GZIP -9 $backup_index_file 2>> $log_file
		then
			backup_index_file="$backup_index_file.gz"
		else
			cleanup
			ts=`$DATE | $SED 's/\n$//'`
			$ECHO "$ts: Failed to compress the backup archive " \
				"index '$backup_index_file'." >> $log_file
			exit 1
		fi
	fi
else
	cleanup
	ts=`$DATE | $SED 's/\n$//'`
	$ECHO "$ts: The compress file parameter's value '$COMPRESS_FILE' " \
		"is not a valid option." >> $log_file
	exit 1
fi

#
# Perform Checksum
#
if [ "$PERFORM_CHECKSUM" -eq "0" ]
then
	ts=`$DATE | $SED 's/\n$//'`
	$ECHO "$ts: Skipping checksum generation." >> $log_file
elif [ "$PERFORM_CHECKSUM" -eq "1" ]
then
	if ! $SHA1SUM $backup_file > $backup_chksum_file 2>> $log_file
	then
		cleanup
		ts=`$DATE | $SED 's/\n$//'`
		$ECHO "$ts: Failed to generate checksum on backup archive " \
			"file '$backup_file'." >> $log_file
		exit 1
	fi

	if ! $SHA1SUM $backup_index_file >> $backup_chksum_file 2>> $log_file
	then
		cleanup
		ts=`$DATE | $SED 's/\n$//'`
		$ECHO "$ts: Failed to generate checksum on backup archive " \
			"index file '$backup_index_file'." >> $log_file
		exit 1
	fi
else
	cleanup
	ts=`$DATE | $SED 's/\n$//'`
	$ECHO "$ts: The checksum parameter's value '$PERFORM_CHECKSUM' is " \
		"not a valid option." >> $log_file
	exit 1
fi

#
# Perform file encryption.
#
if [ "$ENCRYPT_FILE" -eq "0" ]
then
	ts=`$DATE | $SED 's/\n$//'`
	$ECHO "$ts: Skipping file encryption." >> $log_file
elif [ "$ENCRYPT_FILE" -eq "1" ]
then
	if [ ! -s "$recipient_list_file" ]
	then
		$ECHO "The recipient list '$recipient_list_file' is empty. " \
			"Please add a valid GPG recipient to this " \
			"list." >> $log_file
		exit 1
	fi

	r_list=`$FGREP -v "#" $recipient_list_file | $TR '\n' " " | \
		$SED "s| | -r |g" | $SED "s| -r $||"`

	if $GPG -r $r_list -e $backup_file 2>> $log_file
	then
		if ! $RM -f $backup_file 2>> $log_file
		then
			cleanup
			ts=`$DATE | $SED 's/\n$//'`
			$ECHO "$ts: Failed to remove the backup archive " \
				"file '$backup_file' after " \
				"encryption." >> $log_file
			exit 1
		fi

		if [ "$PERFORM_CHECKSUM" -eq "1" ]
		then
			if ! $SHA1SUM $backup_file.gpg > \
				$backup_gpg_chksum_file 2>> $log_file
			then
				cleanup
				ts=`$DATE | $SED 's/\n$//'`
				$ECHO "$ts: Failed to generate checksum on " \
					"backup archive file '$backup_file'." \
					 >> $log_file
				exit 1
			fi
		fi
	else
		cleanup
		ts=`$DATE | $SED 's/\n$//'`
		$ECHO "$ts: Failed to encrypt the backup archive file " \
			"'$backup_file'." >> $log_file
		exit 1
	fi

	if [ -e "$backup_index_file" ]
	then
		if $GPG -r $r_list -e $backup_index_file 2>> $log_file
		then
			if ! $RM -f $backup_index_file 2>> $log_file
			then
				cleanup
				ts=`$DATE | $SED 's/\n$//'`
				$ECHO "$ts: Failed to remove the backup " \
					"archive index file " \
					"'$backup_index_file' after " \
					"encryption." >> $log_file
				exit 1
			fi

			if [ "$PERFORM_CHECKSUM" -eq "1" ]
			then
				if ! $SHA1SUM $backup_index_file.gpg \
					>> $backup_gpg_chksum_file 2>> $log_file
				then
					cleanup
					ts=`$DATE | $SED 's/\n$//'`
					$ECHO "$ts: Failed to generate " \
						"checksum on backup archive " \
						"index file " \
						"'$backup_index_file'." \
						 >> $log_file
					exit 1
				fi
			fi
		else
			cleanup
			ts=`$DATE | $SED 's/\n$//'`
			$ECHO "$ts: Failed to encrypt the backup archive " \
				"file '$backup_file'." >> $log_file
			exit 1
		fi
	fi

	if [ -e "$backup_chksum_file" ]
	then
		if $GPG -r $r_list -e $backup_chksum_file 2>> $log_file
		then
			if ! $RM -f $backup_chksum_file 2>> $log_file
			then
				cleanup
				ts=`$DATE | $SED 's/\n$//'`
				$ECHO "$ts: Failed to remove the backup " \
					"archive checksum file " \
					"'$backup_chksum_file' after " \
					"encryption." >> $log_file
				exit 1
			fi

			if [ "$PERFORM_CHECKSUM" -eq "1" ]
			then
				if ! $SHA1SUM $backup_chksum_file.gpg \
					>> $backup_gpg_chksum_file 2>> $log_file
				then
					cleanup
					ts=`$DATE | $SED 's/\n$//'`
					$ECHO "$ts: Failed to generate " \
						"checksum on backup archive " \
						"checksum file " \
						"'$backup_chksum_file'." \
						 >> $log_file
					exit 1
				fi
			fi
		else
			cleanup
			ts=`$DATE | $SED 's/\n$//'`
			$ECHO "$ts: Failed to encrypt the backup archive " \
				"file '$backup_file'." >> $log_file
			exit 1
		fi
	fi
else
	cleanup
	ts=`$DATE | $SED 's/\n$//'`
	$ECHO "$ts: The file encryption parameter's value '$ENCRYPT_FILE' "\
		" is not a valid option." >> $log_file
	exit 1
fi

exit 0

