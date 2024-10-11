# snippets.nvim

A lightweight and efficient snippet expansion plugin for Neovim using native neovim snippet features.

## Features

- LSP integration for seamless snippet suggestions alongside language server completions
- JSON-based snippet definitions
- Fuzzy matching for snippet completion
- Variable expansion in snippets

## Installation

Using your preferred plugin manager, add the following:

```lua
{'ccaglak/snippets.nvim'}
```

# Usage
Snippets will automatically be suggested in the completion menu when typing. The plugin integrates with LSP completions, so you'll see snippets alongside other suggestions.

# Snippet Format
Snippets are defined in JSON files. Each snippet is defined as a JSON object with the following structure:
```json
{
  "Console Log": {
    "prefix": "log",
    "body": "console.log($1);",
    "description": "Log output to console"
  }
}
```
assumes filetype.json located in nvim config snippets folder.

```lua vim.fn.stdpath('config') .. '/snippets/' ```

## Variables
The plugin supports various built-in variables for snippet expansion:

- TM_FILENAME: Current file name
- TM_FILENAME_BASE: Current file name without extension
- TM_FILEPATH: Full path of the current file
- TM_DIRECTORY: Directory of the current file
- CURRENT_YEAR: Current year
- CURRENT_MONTH: Current month
- CURRENT_DATE: Current date

# Contributing
Contributions are welcome! Please feel free to submit a Pull Request.

# Special thanks to L3MON4D3

# License
This project is licensed under the MIT License.
