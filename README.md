# Git Transfer SH

Git Transfer SH is a lightweight, interactive shell script that creates a local, anonymized copy of selected Git commit history. It mirrors commits authored with a specified source email while preserving their dates and changed file paths/extensions, replacing file contents and commit messages with generic text.

The generated repository is intended to help reproduce contribution history without copying source code or original commit messages. The script only creates a local repository; publishing it is a separate, manual action.

## Requirements

- Git installed and available on `PATH`.
- A POSIX-compatible shell (`sh`).
- No additional runtime libraries or packages.

## Usage

Run the script from inside the source Git repository. For example:

```sh
cd /path/to/source-repository
sh /path/to/git-transfer-sh/git-transfer.sh
```

When prompted, enter:

1. The email address used as the author in the source commits to mirror.
2. The personal email address to use for the generated commits.

The script creates or reuses a sibling directory named `<source-repository>-anonymized`. That directory is initialized as a Git repository. Mirrored files contain generic placeholder text, commit messages are `Mirrored commit`, and the original author timestamps are preserved. The `.processed_commits` file in the generated repository records source commit hashes so rerunning the script does not duplicate commits already processed.

The source repository is not modified. Inspect the generated repository before publishing it. To push it, configure your own remote and push manually, for example:

```sh
cd /path/to/source-repository-anonymized
git remote add origin <your-personal-repository-url>
git push -u origin HEAD
```

## Tests

The test suite uses ShellSpec. With ShellSpec installed, run it from the project root:

```sh
shellspec
```

GitHub Actions runs the same test command on pushes, pull requests, and manual workflow dispatches.
