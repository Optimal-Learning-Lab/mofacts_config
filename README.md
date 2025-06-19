# MoFaCTS Configuration Repository

This repository contains configuration files and stimulus files for various MoFaCTS lessons and experiments. Files are organized into directories by project or semester. Example `.json` lesson files and associated stimulus sets are included.

## Duplicate file helper

The `find_duplicates.py` script checks this repository for duplicate files. It detects files that share the same name and modification date and reports pairs of zip archives with matching folders.

Run the script from the repository root:

```bash
python3 find_duplicates.py
```

The script lists any duplicates it finds and prints suggested `git rm` commands for removing redundant copies.
