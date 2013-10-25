#!/bin/bash

function checkCommand
{
	command="$1"

	if [ "$command" != "" ]
	then
		if [ ! -e "$command" ]
		then
			echo "The command '$command' does not exist."
			exit 1
		fi

		if [ ! -r "$command" ]
		then
			echo "The command '$command' is not readable."
			exit 1
		fi

		if [ ! -x "$command" ]
		then
			echo "The command '$command' is not executable."
			exit 1
		fi
	else
		echo "The command was empty."
		exit 1
	fi
}

function fileCheck
{
	fileName="$1"
	if [ "$fileName" != "" ]
	then
		if [ ! -e "$fileName" ]
		then
			echo "The file name '$fileName' does not exist."
			exit 1
		fi
	else
		echo "The file name is empty."
		exit 1
	fi
}
