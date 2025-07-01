# md2zim

**md2zim** is a Bash utility for Windows (Git Bash) that creates a [Zim Wiki](https://zim-wiki.org/) note from Markdown content in your clipboard. It uses [pandoc](https://pandoc.org/) to convert Markdown to Zimwiki format and automatically handles note naming, metadata, and file placement.


## Purpose

This script was written with the intent of capturing conversations with various generative AI LLM models, which typically provide their output in Markdown format, and integrating that content seamlessly into an existing Zim Wiki. By streamlining the process of transferring AI-generated Markdown responses into your personal knowledge base, md2zim helps you organize, archive, and reference valuable insights from your AI interactions directly within Zim Wiki.

## Features

- Reads Markdown from your Windows clipboard
- Converts Markdown to Zimwiki format using `pandoc`
- Automatically determines the note title from the first level-1 heading, or accepts a custom title
- Prompts for or remembers your Zim data directory
- Prepends Zimwiki metadata (Content-Type, Wiki-Format, Creation-Date)
- Prevents accidental overwrites of existing notes

## Requirements

- [Git Bash](https://gitforwindows.org/) on Windows 11
- [pandoc](https://pandoc.org/installing.html#windows) installed and available in your `PATH`
- Zim Wiki installed (optional, for using the notes)

## Installation

1. **Download the script**

   Save the script as `md2zim` (no extension) or `md2zim.sh`.

2. **Make it executable**

   ```bash
   chmod +x md2zim
   ```

3. *(Optional)* Move it to a directory in your `PATH` for easy access.

## Usage

1. **Copy Markdown content** to your clipboard.

2. **Run the script in Git Bash:**

   ```bash
   ./md2zim [note-title] [zim-data-directory]
   ```

   - **note-title** (optional): The desired title for your Zim note. If omitted, the script uses the first `# Heading` in your Markdown.
   - **zim-data-directory** (optional): The path to your Zim notes folder. If omitted, the script uses the `$ZIM_DATA_DIR` environment variable or prompts you to enter and save it.

   Example:

   ```bash
   ./md2zim "My Meeting Notes" "/c/Users/YourName/Zim"
   ```

## First Run

On your first run, if the Zim data directory is not set, you’ll be prompted to enter it. You can choose to save this path to your `~/.bashrc` for future runs.

## Output

- The note is saved as a `.txt` file in your Zim data directory.
- The filename is derived from the note title, sanitized (spaces become underscores, special characters removed).
- If a file with the same name exists, you’ll be asked before overwriting.

## Troubleshooting

- **Pandoc not found:**  
  If you see an error about `pandoc` not being installed, [download and install pandoc for Windows](https://pandoc.org/installing.html#windows), then restart Git Bash.

- **Clipboard not working:**  
  Make sure you’re running the script in Git Bash, which provides `/dev/clipboard`.

## License

MIT License 

## Credits

- Inspired by workflows for Zim Wiki and Markdown interoperability.
- Uses [pandoc](https://pandoc.org/) for format conversion.

## Contributing

Pull requests and suggestions are welcome!

**Enjoy seamless note-taking between Markdown and Zim Wiki!**
