#!/bin/sh

read_email() {
	prompt=$1

	printf '%s' "$prompt"
	IFS= read -r REPLY || return 1
	if [ -z "$REPLY" ]; then
		printf '%s\n' 'Email cannot be empty.' >&2
		return 1
	fi
}

main() {
	source_directory=$(git rev-parse --show-toplevel 2>/dev/null) || {
		printf '%s\n' 'Run this script from inside a Git repository.' >&2
		return 1
	}
	destination_directory="${source_directory}-anonymized"

	read_email 'Source email: ' || {
		printf '%s\n' 'Failed to read source email.' >&2
		return 1
	}
	source_email=$REPLY

	read_email 'Personal email: ' || {
		printf '%s\n' 'Failed to read personal email.' >&2
		return 1
	}
	personal_email=$REPLY

	if ! mkdir -p "$destination_directory" || ! git -C "$destination_directory" init -q; then
		printf 'Failed to initialize destination repository: %s\n' "$destination_directory" >&2
		return 1
	fi

	printf 'Destination repository initialized: %s\n' "$destination_directory"
}

main "$@"
