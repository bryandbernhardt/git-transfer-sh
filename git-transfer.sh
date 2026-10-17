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

mirror_commit_changes() {
	commit_hash=$1

	git -C "$source_directory" diff-tree --root --no-commit-id --name-only -r --no-renames "$commit_hash" |
	while IFS= read -r path; do
		if ! git -C "$source_directory" cat-file -e "$commit_hash:$path" 2>/dev/null; then
			rm -f "$destination_directory/$path" || return 1
			GIT_LITERAL_PATHSPECS=1 git -C "$destination_directory" add -A -- "$path" || return 1
		fi
	done || return 1

	git -C "$source_directory" diff-tree --root --no-commit-id --name-only -r --no-renames "$commit_hash" |
	while IFS= read -r path; do
		if git -C "$source_directory" cat-file -e "$commit_hash:$path" 2>/dev/null; then
			rm -rf "$destination_directory/$path" || return 1
			parent_directory=${path%/*}
			if [ "$parent_directory" != "$path" ]; then
				mkdir -p "$destination_directory/$parent_directory" || return 1
			fi
			printf '%s\n' 'Lorem ipsum dolor sit amet, consectetur adipiscing elit.' > "$destination_directory/$path" || return 1
			GIT_LITERAL_PATHSPECS=1 git -C "$destination_directory" add -A -- "$path" || return 1
		fi
	done || return 1

	commit_date=$(git -C "$source_directory" show -s --format=%aI "$commit_hash") || return 1
	GIT_AUTHOR_DATE=$commit_date GIT_COMMITTER_DATE=$commit_date \
		git -C "$destination_directory" -c user.name='Git Transfer' -c user.email="$personal_email" \
		commit -q --allow-empty -m 'Mirrored commit'
}

mirror_author_commits() {
	git -C "$source_directory" log --reverse --format='%H%x09%ae' |
	while IFS="$(printf '\t')" read -r commit_hash commit_author; do
		[ "$commit_author" = "$source_email" ] || continue
		if grep -Fxq "$commit_hash" "$destination_directory/.processed_commits"; then
			continue
		fi
		commit_parents=$(git -C "$source_directory" rev-list --parents -n 1 "$commit_hash") || return 1
		set -- $commit_parents
		if [ "$#" -gt 2 ]; then
			printf '%s\n' "$commit_hash" >> "$destination_directory/.processed_commits" || return 1
			continue
		fi
		mirror_commit_changes "$commit_hash" || return 1
		printf '%s\n' "$commit_hash" >> "$destination_directory/.processed_commits" || return 1
	done
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
	if ! : >> "$destination_directory/.processed_commits"; then
		printf 'Failed to initialize processed commits file: %s\n' "$destination_directory/.processed_commits" >&2
		return 1
	fi

	if ! mirror_author_commits; then
		printf '%s\n' 'Failed to mirror source commits.' >&2
		return 1
	fi

	printf 'Destination repository initialized: %s\n' "$destination_directory"
}

main "$@"
