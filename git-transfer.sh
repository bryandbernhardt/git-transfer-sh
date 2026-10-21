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

source_has_extension() {
	git -C "$source_directory" ls-tree -r --name-only "$1" |
		awk -F/ -v extension="$2" '
			{
				filename = $NF
				if (index(filename, ".") > 0) {
					sub(/^.*[.]/, "", filename)
				} else {
					filename = ""
				}
				if (filename == extension) found = 1
			}
			END { exit !found }
		'
}

source_extension_sizes() {
	git -C "$source_directory" ls-tree -r -l "$1" |
		awk -F "$(printf '\t')" '
			{
				split($1, metadata, " ")
				path = $2
				path_components = split(path, components, "/")
				filename = components[path_components]
				if (index(filename, ".") > 0) {
					sub(/^.*[.]/, "", filename)
				} else {
					filename = ""
				}
				totals[filename] += metadata[4] + 0
				present[filename] = 1
			}
			END {
				for (extension in present) {
					printf "E%s\t%d\n", extension, totals[extension]
				}
			}
		'
}

write_random_ascii() {
	byte_count=$1
	seed=$2
	LC_ALL=C awk -v byte_count="$byte_count" -v seed="$seed" '
		BEGIN {
			srand(seed)
			characters = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789"
			for (position = 0; position < byte_count; position++) {
				character_index = int(rand() * length(characters)) + 1
				printf "%s", substr(characters, character_index, 1)
			}
		}
	'
}

mirror_commit_changes() {
	commit_hash=$1
	source_tree=$(git -C "$source_directory" rev-parse "$commit_hash^{tree}") || return 1
	tab=$(printf '\t')

	source_extension_sizes "$commit_hash" |
	while IFS= read -r extension_record; do
		extension_token=${extension_record%%"$tab"*}
		byte_count=${extension_record#*"$tab"}
		path_extension=${extension_token#E}
		if [ -n "$path_extension" ]; then
			generic_file="file.$path_extension"
		else
			generic_file=file
		fi
		content_seed=$(printf '%s\t%s' "$source_tree" "$path_extension" | cksum | awk '{ print $1 }') || return 1
		write_random_ascii "$byte_count" "$content_seed" > "$destination_directory/$generic_file" || return 1
		GIT_LITERAL_PATHSPECS=1 git -C "$destination_directory" add -A -- "$generic_file" || return 1
	done || return 1

	for generic_path in "$destination_directory"/file*; do
		[ -f "$generic_path" ] || continue
		generic_file=${generic_path##*/}
		if [ "$generic_file" = file ]; then
			path_extension=
		else
			path_extension=${generic_file#file.}
		fi
		if ! source_has_extension "$commit_hash" "$path_extension"; then
			rm -f "$generic_path" || return 1
			GIT_LITERAL_PATHSPECS=1 git -C "$destination_directory" add -A -- "$generic_file" || return 1
		fi
	done

	commit_date=$(git -C "$source_directory" show -s --format=%aI "$commit_hash") || return 1
	GIT_AUTHOR_DATE=$commit_date GIT_COMMITTER_DATE=$commit_date \
		git -C "$destination_directory" -c user.name='Git Transfer' -c user.email="$personal_email" \
		commit -q --allow-empty -m 'Mirrored commit'
}

mirror_author_commits() {
	processed_file="$destination_directory/.processed_commits"
	total_commits=$(git -C "$source_directory" log --format='%H%x09%ae' |
		awk -F "$(printf '\t')" -v email="$source_email" '$2 == email { count++ } END { print count + 0 }') || return 1
	already_copied=$(git -C "$source_directory" log --format='%H%x09%ae' |
		awk -F "$(printf '\t')" -v email="$source_email" '$2 == email { print $1 }' |
		grep -Fxf "$processed_file" | wc -l | tr -d '[:space:]') || return 1
	queued_commits=$((total_commits - already_copied))
	current_commit=0
	printf 'Total commits: %s\n' "$total_commits"
	printf 'Already copied: %s\n' "$already_copied"
	printf 'Queued: %s\n' "$queued_commits"

	git -C "$source_directory" log --reverse --format='%H%x09%ae' |
	while IFS="$(printf '\t')" read -r commit_hash commit_author; do
		[ "$commit_author" = "$source_email" ] || continue
		if grep -Fxq "$commit_hash" "$processed_file"; then
			continue
		fi
		current_commit=$((current_commit + 1))
		printf 'Processing: %s of %s\n' "$current_commit" "$queued_commits"
		commit_parents=$(git -C "$source_directory" rev-list --parents -n 1 "$commit_hash") || return 1
		set -- $commit_parents
		if [ "$#" -gt 2 ]; then
			printf '%s\n' "$commit_hash" >> "$processed_file" || return 1
			continue
		fi
		mirror_commit_changes "$commit_hash" || return 1
		printf '%s\n' "$commit_hash" >> "$processed_file" || return 1
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
