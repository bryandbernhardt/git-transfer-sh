setup_spec() {
  SPEC_TEMP=$(mktemp -d)
  SPEC_SOURCE="$SPEC_TEMP/source"
  SPEC_SCRIPT="$SHELLSPEC_PROJECT_ROOT/git-transfer.sh"
  SPEC_SOURCE_EMAIL='corporate@example.com'
  SPEC_PERSONAL_EMAIL='personal@example.com'
  mkdir -p "$SPEC_SOURCE"
  git -C "$SPEC_SOURCE" init -q
  git -C "$SPEC_SOURCE" config user.name 'Corporate Author'
  git -C "$SPEC_SOURCE" config user.email "$SPEC_SOURCE_EMAIL"
}

cleanup_spec() {
  rm -rf "$SPEC_TEMP"
}

create_source_commit() {
  source_message=$1
  source_date=$2
  source_file=$3
  source_content=$4
  source_parent=${source_file%/*}
  if [ "$source_parent" != "$source_file" ]; then
    mkdir -p "$SPEC_SOURCE/$source_parent"
  fi
  printf '%s\n' "$source_content" > "$SPEC_SOURCE/$source_file"
  git -C "$SPEC_SOURCE" add "$source_file"
  commit_source_change "$source_message" "$source_date"
}

commit_source_change() {
  GIT_AUTHOR_DATE=$2 GIT_COMMITTER_DATE=$2 \
    git -C "$SPEC_SOURCE" commit -q -m "$1"
}

run_transfer() {
  printf '%s\n' "$SPEC_SOURCE_EMAIL" "$SPEC_PERSONAL_EMAIL" |
    (cd "$SPEC_SOURCE" && sh "$SPEC_SCRIPT")
}

transfer_and_assert_destination() {
  run_transfer >/dev/null && assert_destination_repository_exists
}

transfer_and_assert_anonymized_commit() {
  run_transfer >/dev/null && assert_mirrored_commit_is_anonymized
}

transfer_and_assert_file_changes() {
  run_transfer >/dev/null && assert_file_changes_were_mirrored
}

transfer_and_assert_flattened_files() {
  run_transfer >/dev/null && assert_files_are_flattened_by_extension
}

transfer_and_assert_requested_author() {
  run_transfer >/dev/null && assert_only_requested_author_was_mirrored
}

transfer_and_assert_hash_tracking() {
  run_transfer >/dev/null && assert_processed_hashes_are_recorded
}

transfer_twice_and_assert_no_duplicate() {
  run_transfer >/dev/null && run_transfer >/dev/null && assert_commit_was_not_duplicated
}

transfer_twice_after_removing_hash() {
  run_transfer >/dev/null && remove_recorded_hashes && run_transfer >/dev/null &&
    assert_removed_hash_was_reprocessed
}

transfer_and_assert_merge_is_safe() {
  run_transfer >/dev/null && assert_mirrored_history_is_safe
}

transfer_and_assert_empty_commit() {
  run_transfer >/dev/null && assert_mirrored_empty_commit
}

destination_repository() {
  find "$SPEC_TEMP" -type d -name .git -print |
    while IFS= read -r git_directory; do
      repository=${git_directory%/.git}
      if [ "$repository" != "$SPEC_SOURCE" ]; then
        printf '%s\n' "$repository"
      fi
    done
}

assert_destination_repository_exists() {
  repository=$(destination_repository)
  [ -n "$repository" ] && [ -d "$repository/.git" ]
}

assert_mirrored_commit_is_anonymized() {
  repository=$(destination_repository)
  source_date=$(git -C "$SPEC_SOURCE" log -1 --format=%aI)
  [ "$(git -C "$repository" rev-list --count HEAD)" -eq 1 ] || return 1
  [ "$(git -C "$repository" log -1 --format=%ae)" = "$SPEC_PERSONAL_EMAIL" ] || return 1
  [ "$(git -C "$repository" log -1 --format=%aI)" = "$source_date" ] || return 1
  [ "$(git -C "$repository" log -1 --format=%s)" != 'Confidential original message' ] || return 1
  [ "$(git -C "$repository" ls-tree -r --name-only HEAD)" = file.js ] || return 1
  git -C "$repository" show HEAD:file.js | grep -qi 'lorem ipsum' || return 1
  if git -C "$repository" show HEAD:file.js | grep -q 'corporate'; then
    return 1
  fi
}

assert_file_changes_were_mirrored() {
  repository=$(destination_repository)
  [ "$(git -C "$repository" rev-list --count HEAD)" -eq 3 ] || return 1
  source_dates=$(git -C "$SPEC_SOURCE" log --reverse --format=%aI --author="$SPEC_SOURCE_EMAIL") || return 1
  destination_dates=$(git -C "$repository" log --reverse --format=%aI) || return 1
  [ "$destination_dates" = "$source_dates" ] || return 1
  if git -C "$repository" log --format=%s | grep -Fvx 'Mirrored commit'; then
    return 1
  fi
  if git -C "$repository" log -p | grep -E 'firstSecret|second_secret|Add JavaScript source|Add Python source|Remove JavaScript source'; then
    return 1
  fi
  [ "$(git -C "$repository" ls-tree -r --name-only HEAD)" = file.py ] || return 1
  [ ! -e "$repository/tools" ] || return 1
  git -C "$repository" show HEAD:file.py | grep -qi 'lorem ipsum'
}

assert_files_are_flattened_by_extension() {
  repository=$(destination_repository)
  destination_paths=$(git -C "$repository" ls-tree -r --name-only HEAD) || return 1
  [ "$destination_paths" = "$(printf '%s\n' file.js file.py)" ] || return 1
  [ -f "$repository/file.js" ] || return 1
  [ -f "$repository/file.py" ] || return 1
  git -C "$repository" show HEAD:file.js | grep -qi 'lorem ipsum' || return 1
  git -C "$repository" show HEAD:file.py | grep -qi 'lorem ipsum'
}

assert_only_requested_author_was_mirrored() {
  repository=$(destination_repository)
  [ "$(git -C "$repository" rev-list --count HEAD)" -eq 1 ] || return 1
  [ "$(git -C "$repository" log -1 --format=%ae)" = "$SPEC_PERSONAL_EMAIL" ]
}

assert_processed_hashes_are_recorded() {
  repository=$(destination_repository)
  processed_file="$repository/.processed_commits"
  original_hash=$(git -C "$SPEC_SOURCE" rev-parse HEAD)
  [ -f "$processed_file" ] || return 1
  [ "$(wc -l < "$processed_file" | tr -d ' ')" -eq 1 ] || return 1
  [ "$(cat "$processed_file")" = "$original_hash" ] || return 1
  printf '%s\n' "$original_hash" | grep -Eq '^[[:xdigit:]]{40}$'
}

assert_commit_was_not_duplicated() {
  repository=$(destination_repository)
  [ "$(git -C "$repository" rev-list --count HEAD)" -eq 1 ]
}

remove_recorded_hashes() {
  repository=$(destination_repository)
  : > "$repository/.processed_commits"
}

assert_removed_hash_was_reprocessed() {
  repository=$(destination_repository)
  original_hash=$(git -C "$SPEC_SOURCE" rev-parse HEAD)
  [ "$(git -C "$repository" rev-list --count HEAD)" -eq 2 ] || return 1
  grep -Fxq "$original_hash" "$repository/.processed_commits"
}

assert_mirrored_history_is_safe() {
  repository=$(destination_repository)
  [ "$(git -C "$repository" rev-list --count HEAD)" -ge 2 ] || return 1
  if git -C "$repository" log --format=%s | grep -E 'Base corporate|Feature corporate|Main corporate|Merge confidential'; then
    return 1
  fi
  git -C "$repository" ls-tree -r --name-only HEAD | while IFS= read -r path; do
    if git -C "$repository" show "HEAD:$path" | grep -qi 'corporate secret'; then
      return 1
    fi
  done
}

assert_mirrored_empty_commit() {
  repository=$(destination_repository)
  [ "$(git -C "$repository" rev-list --count HEAD)" -eq 1 ] || return 1
  [ -z "$(git -C "$repository" ls-tree -r --name-only HEAD)" ] || return 1
  [ "$(git -C "$repository" log -1 --format=%s)" != 'Confidential empty commit' ]
}

Describe 'git-transfer.sh'
  Before 'setup_spec'
  After 'cleanup_spec'

  It 'accepts source and destination emails and creates a destination repository (RF-01, RF-02)'
    create_source_commit 'Initial corporate change' '2020-01-02T03:04:05+00:00' 'app.js' 'const secret = "corporate";'
    When call transfer_and_assert_destination
    The status should be success
  End

  It 'mirrors commit dates and anonymizes content and messages (RF-03)'
    create_source_commit 'Confidential original message' '2020-01-02T03:04:05+00:00' 'app.js' 'const secret = "corporate";'
    When call transfer_and_assert_anonymized_commit
    The status should be success
  End

  It 'preserves changed file extensions and additions and deletions (RF-03)'
    create_source_commit 'Add JavaScript source' '2020-01-02T03:04:05+00:00' 'app.js' 'const firstSecret = true;'
    create_source_commit 'Add Python source' '2020-01-03T03:04:05+00:00' 'tools/helper.py' 'second_secret = True'
    rm "$SPEC_SOURCE/app.js"
    git -C "$SPEC_SOURCE" add -A
    commit_source_change 'Remove JavaScript source' '2020-01-04T03:04:05+00:00'
    When call transfer_and_assert_file_changes
    The status should be success
  End

  It 'flattens source paths and maps each extension to a generic filename (RF-07, RF-08)'
    create_source_commit 'First JavaScript file' '2020-01-02T03:04:05+00:00' 'src/private/app.js' 'first secret'
    create_source_commit 'Second JavaScript file' '2020-01-03T03:04:05+00:00' 'other/private/module.js' 'second secret'
    create_source_commit 'Python file' '2020-01-04T03:04:05+00:00' 'tools/private/helper.py' 'third secret'
    When call transfer_and_assert_flattened_files
    The status should be success
  End

  It 'mirrors only commits authored by the requested source email (RF-01, RF-03)'
    create_source_commit 'Corporate commit' '2020-01-02T03:04:05+00:00' 'owned.js' 'corporate_secret = true'
    printf '%s\n' 'other author content' > "$SPEC_SOURCE/other.txt"
    git -C "$SPEC_SOURCE" add other.txt
    GIT_AUTHOR_NAME='Other Author' GIT_AUTHOR_EMAIL='other@example.com' \
      GIT_COMMITTER_NAME='Other Author' GIT_COMMITTER_EMAIL='other@example.com' \
      git -C "$SPEC_SOURCE" commit -q -m 'Other author commit'
    When call transfer_and_assert_requested_author
    The status should be success
  End

  It 'stores only each original commit hash in the processing file (RF-04, RN-01)'
    create_source_commit 'Hash tracking change' '2020-01-02T03:04:05+00:00' 'tracked.txt' 'private source text'
    When call transfer_and_assert_hash_tracking
    The status should be success
  End

  It 'does not duplicate commits already recorded as processed (RF-04)'
    create_source_commit 'Single source commit' '2020-01-02T03:04:05+00:00' 'once.txt' 'private source text'
    When call transfer_twice_and_assert_no_duplicate
    The status should be success
  End

  It 'reprocesses a commit after its hash is removed from the processing file (RF-05)'
    create_source_commit 'Commit to reprocess' '2020-01-02T03:04:05+00:00' 'again.txt' 'private source text'
    When call transfer_twice_after_removing_hash
    The status should be success
  End

  It 'reports total, already copied, and currently processed commit counts (RF-06)'
    create_source_commit 'Progress reporting change' '2020-01-02T03:04:05+00:00' 'progress.txt' 'private source text'
    When call run_transfer
    The output should include 'Total commits'
    The output should include 'Already copied'
    The output should include 'Queued: 1'
    The output should include 'Processing: 1 of 1'
  End

  It 'handles merge commits without leaking source content or failing'
    create_source_commit 'Base corporate change' '2020-01-02T03:04:05+00:00' 'base.txt' 'base corporate secret'
    source_branch=$(git -C "$SPEC_SOURCE" branch --show-current)
    git -C "$SPEC_SOURCE" checkout -q -b feature
    create_source_commit 'Feature corporate change' '2020-01-03T03:04:05+00:00' 'feature.txt' 'feature corporate secret'
    git -C "$SPEC_SOURCE" checkout -q "$source_branch"
    create_source_commit 'Main corporate change' '2020-01-04T03:04:05+00:00' 'main.txt' 'main corporate secret'
    git -C "$SPEC_SOURCE" merge -q --no-ff feature -m 'Merge confidential branches'
    When call transfer_and_assert_merge_is_safe
    The status should be success
  End

  It 'preserves empty commits without adding files or original messages'
    GIT_AUTHOR_DATE='2020-01-02T03:04:05+00:00' GIT_COMMITTER_DATE='2020-01-02T03:04:05+00:00' \
      git -C "$SPEC_SOURCE" commit -q --allow-empty -m 'Confidential empty commit'
    When call transfer_and_assert_empty_commit
    The status should be success
  End
End