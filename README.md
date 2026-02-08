# grepstein.sh

`grepstein.sh` is a small Bash script for searching and reading PDF documents from the U.S. Department of Justice (justice.gov) multimedia archive directly in the terminal.

It allows you to search by keyword, browse results page by page, and open PDF files without leaving the command line.

## Features

- Keyword search on justice.gov  
- Paginated results (navigate with NEXT)  
- Read PDF files directly in the terminal  
- No browser required  

## Requirements

The following tools must be installed on your system:

- `pdftotext`
- `jq`
- `httpie`

The script automatically checks for missing dependencies before running.

### Arch / CachyOS

```bash
sudo pacman -S poppler jq httpie
```

### Debian / Ubuntu

```bash
sudo apt install poppler-utils jq httpie
```

## Installation

```bash
git clone https://github.com/sertacartun/grepstein.git
cd grepstein
chmod +x grepstein.sh
```

## Usage

```bash
./grepstein.sh <search_term>
```

Example:

```bash
./grepstein.sh epstein
```

After listing the results, the script waits for a command:

- `OPEN` → Open a selected PDF in the terminal  
- `NEXT` → Go to the next page  
- `EXIT` → Exit the program  

When opening a file, enter the index number shown in the list.

## Notes

- PDF files are downloaded temporarily to `/tmp` and removed after viewing.
- Some justice.gov content requires an age-verification cookie; this script includes it automatically.
- Intended for reading and research purposes only.

## License

MIT
