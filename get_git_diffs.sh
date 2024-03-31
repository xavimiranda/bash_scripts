#!/bin/bash

: '
Author: Xavier Miranda
Date Created: 2024-03-10
Last Mofidied: 2024-03-18

Description: 
	Checks if there are any differences between the local and remote git branch on a list of directories.
	It prints out the a summary of the detected changes at the end and keeps a file with the differences named gdiffs.txt

Usage:
	To check every git repository in the current directory just call the script.
	./get_diffs.sh

	To check only a list of repos, any number of arguments can be passed. Example of checking every dir that starts with "morphis"
	./get_diffs morphis*

Notes: 
	The script leverages the parallel execution of xargs -P0, by piping it the list of directories.
'
# Define the parent directory containing all git repositories
PARENT_DIR=$(pwd)

# Declare the final file. export it so subprocesses can append to it
CHANGES_FILE=$PARENT_DIR/gdiffs.txt
export CHANGES_FILE

# Remove the changes.txt file
if [ -e "$CHANGES_FILE" ] ; then
	rm "$CHANGES_FILE" 
fi;

touch "$CHANGES_FILE"

#Create a temp file to store the passed arguments
tempfile=$(mktemp)
# Mark the file to be removed after the scripts exits
trap "rm -f '$tempfile'" EXIT


# The subprocess main function. Will compare the branches hashes
check_rev_parse() {
	echo -e "Checking $1..."
        cd "$1"

        # Fetch the latest changes without merging
        git fetch origin &>/dev/null

        # Check for changes by comparing the local branch with the remote branch
        LOCAL=$(git rev-parse @)
        REMOTE=$(git rev-parse "@{u}")

        # If there are changes, add the directory to the array
        if [ "$LOCAL" != "$REMOTE" ]; then
            echo -e "\tChanges detected in $1"
	    echo "$1" >> "$CHANGES_FILE"
        fi
}

export -f check_rev_parse

if [ $# -gt 0 ]; then
	printf "%s\n" "$@" > "$tempfile"
	cat $tempfile | xargs -I{} -P0 sh -c 'check_rev_parse {}'
else
	find -maxdepth 2 -type d -name .git | sed 's|/.git||' | xargs -I{} -P0 sh -c 'check_rev_parse {}'

fi;

# Check if any directories had changes
if [ $(cat "$CHANGES_FILE" | wc -l) -eq 0 ]; then
    echo -e "\nNo changes detected in any repositories."
else
    echo -e "\nDirectories with changes:"
    cat "$CHANGES_FILE" 
fi