#!/usr/bin/env bash
# md2zim - Create a Zim note from Markdown content in Clipboard
#
# Usage:
#   md2zim [title] [zim_data_dir]
#
# If title is not provided, uses the first level 1 heading (# Heading) from clipboard content.
# If zim_data_dir is not provided, tries $ZIM_DATA_DIR environment variable.
# If still not set, prompts user to enter the path and optionally saves it to ~/.bashrc.
#
# Dependencies:
#   - Git Bash on Windows 11 (for /dev/clipboard, sed, date)
#   - pandoc installed and in PATH
#
# This script:
#   1. Reads Markdown content from clipboard (/dev/clipboard)
#   2. Determines output filename (.txt) from title or first H1 heading
#   3. Converts Markdown to zimwiki format using pandoc
#   4. Prepends required zimwiki headers with sed
#   5. Saves the file in the specified Zim data directory (Notes folder)
#

set -euo pipefail
trap 'echo "An unexpected error occurred at line $LINENO: $BASH_COMMAND" >&2' ERR

# Check if running in Git Bash on Windows
if [[ ! -e /dev/clipboard ]]; then
  echo "Error: This script is intended to run in Git Bash on Windows."
  echo "Please run it in Git Bash or ensure /dev/clipboard is available."
  exit 1
fi

# --- Functions ---

function check_pandoc {
  if ! command -v pandoc >/dev/null 2>&1; then
    echo "Error: pandoc is not installed or not in PATH."
    echo "Please install pandoc for Windows:"
    echo "  https://pandoc.org/installing.html#windows"
    echo "After installing, restart Git Bash and try again."
    exit 1
  fi
}

function read_clipboard {
  if [[ -e /dev/clipboard ]]; then
    cat /dev/clipboard
  else
    echo "Error: /dev/clipboard not found. Are you running this in Git Bash on Windows?" >&2
    exit 1
  fi
}

function sanitize_filename {
  # Remove or replace characters not allowed in filenames
  local filename="$1"
  # Replace spaces with underscores, remove problematic chars
  filename="${filename// /_}"
  filename="${filename//[^a-zA-Z0-9._-]/}"
  echo "$filename"
}

function get_first_line_h1_heading {
  local content="$1"
  # Extract the first line
  local first_line
  first_line="$(echo "$content" | head -n 1)"
  # Check if it starts with '# ' (Level 1 heading)
  if [[ "$first_line" =~ ^#\ (.*) ]]; then
    # Return the heading text (without '# ')
    echo "${BASH_REMATCH[1]}"
  else
    echo ""
  fi
}

function prompt_zim_dir {
  echo "Zim data directory not set."
  read -rp "Please enter the full path to your Zim data directory (e.g. /c/Users/YourName/Zim): " input_dir
  input_dir="${input_dir/#\~/$HOME}"  # expand ~ if entered
  if [[ ! -d "$input_dir" ]]; then
    echo "Directory does not exist: $input_dir" >&2
    echo "Please create the directory or specify an existing one."
    exit 1
  fi

  # Ask to save in ~/.bashrc for future runs
  read -rp "Save this path to your ~/.bashrc as ZIM_DATA_DIR for future use? (y/n): " yn
  if [[ "$yn" =~ ^[Yy]$ ]]; then
    echo "export ZIM_DATA_DIR=\"$input_dir\"" >> ~/.bashrc
    echo "Saved ZIM_DATA_DIR in ~/.bashrc. Please restart Git Bash or run 'source ~/.bashrc'."
  fi

  echo "$input_dir"
}

# Function to check if first line is a level 1 heading
is_first_line_h1() {
  local first_line
  first_line="$(echo "$1" | head -n 1)"
  [[ "$first_line" =~ ^#\  ]]
}

# --- Main script ---

check_pandoc

# Read markdown content from clipboard
markdown_content=$(read_clipboard)

if [[ -z "$markdown_content" ]]; then
  echo "Clipboard is empty or does not contain Markdown content." >&2
  echo "Please copy some Markdown content to the clipboard and try again." 1>&2  
  exit 1
fi

# Determine title
title_arg="${1:-}"

if [[ -n "$title_arg" ]]; then
  title="$title_arg"
  # If no level 1 heading, prepend one with the title
  if ! is_first_line_h1 "$markdown_content"; then
    markdown_content="# $title"$'\n'"$markdown_content"
  fi
else
  # Try to extract first line H1 heading from clipboard content
  title=$(get_first_line_h1_heading "$markdown_content")
  if [[ -z "$title" ]]; then
    # Prompt user for title, then prepend it as H1 heading
    read -rp "No level 1 heading found. Please enter a title for the note: " title
    if [[ -z "$title" ]]; then
      echo "No title entered. Aborting."
      exit 1
    fi
    markdown_content="# $title"$'\n'"$markdown_content"
  fi
fi

# Sanitize filename and append .txt
filename="$(sanitize_filename "$title").txt"

# Determine Zim data directory
zim_dir="${2:-${ZIM_DATA_DIR:-}}"

if [[ -z "$zim_dir" ]]; then
  zim_dir=$(prompt_zim_dir)
fi

# Notes directory inside Zim data directory (default location for notes)
notes_dir="$zim_dir"

if [[ ! -d "$notes_dir" ]]; then
  echo "Zim data directory does not exist: $notes_dir"
  exit 1
fi

# Create a temp markdown file for pandoc input
tmp_md=$(mktemp /tmp/md2zim.XXXXXX.md)
tmp_zim=$(mktemp /tmp/md2zim.XXXXXX.txt)

# Write clipboard markdown content to temp file
echo "$markdown_content" > "$tmp_md"

# Convert markdown to zimwiki format using pandoc
pandoc --from markdown --to zimwiki --output "$tmp_zim" "$tmp_md"

# Prepend zimwiki headers with sed
creation_date=$(date --iso-8601=minutes)
sed -i "1iContent-Type: text/x-zim-wiki\nWiki-Format: zim 0.6\nCreation-Date: $creation_date\n" "$tmp_zim"

# Move final file to Zim notes directory
output_path="$notes_dir/$filename"

if [[ -e "$output_path" ]]; then
  echo "Warning: $output_path already exists. Overwrite? (y/n)"
  read -r answer
  if [[ ! "$answer" =~ ^[Yy]$ ]]; then
    echo "Aborting."
    rm -f "$tmp_md" "$tmp_zim"
    exit 1
  fi
fi

mv "$tmp_zim" "$output_path"
rm -f "$tmp_md"

echo "Zim note created at: $output_path"
echo "You can now open it in Zim."