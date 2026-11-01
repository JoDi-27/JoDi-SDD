# Shared by the hooks (sourced, not registered in hooks.json).
# On Windows (Git Bash), jq.exe and python print CRLF line endings, paths in
# the hook input use backslashes, and python3 may be missing or the Store stub,
# so the helpers below even those out.

# json <filter>: jq -r of the hook input in $input, without CRs. Empty if jq is missing.
json() { printf '%s' "$input" | jq -r "$1" 2>/dev/null | tr -d '\r'; }

# posix_path <path>: C:\a\b as C:/a/b, which bash, git, and case patterns all handle.
posix_path() { printf '%s' "$1" | tr '\\' '/'; }

# find_python: print the name of a working Python 3 (python3, else python), or fail.
find_python() {
  local p
  for p in python3 python; do
    "$p" -c 'import sys; sys.exit(sys.version_info[0] < 3)' >/dev/null 2>&1 && { echo "$p"; return 0; }
  done
  return 1
}
