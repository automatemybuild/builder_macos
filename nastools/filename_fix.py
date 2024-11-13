# !/usr/bin/env python3
# python filename_fix.py - Replaces spaces, removes 's, and remove parentheses. Created for format image filenames for Unix.
# python filename_fix.py --dry-run
# python filename_fix.py --recursive --dry-run

import os
import argparse
import re

def rename_file(file_path, dry_run=False):
    try:
        # Get the file name without the path
        file_name = os.path.basename(file_path)

        # Remove "'s" sequences
        file_name = file_name.replace("'s", "")

        # Remove parentheses using regular expression
        file_name = re.sub(r'\(|\)', '', file_name)

        # Replace spaces with underscores
        new_file_name = file_name.replace(" ", "_")

        if new_file_name != file_name:
            # Create the new file name
            new_file_path = os.path.join(os.path.dirname(file_path), new_file_name)

            if dry_run:
                print(f"Before: '{file_name}', After: '{new_file_name}'")
            else:
                # Rename the file
                os.rename(file_path, new_file_path)
                print(f"Renamed '{file_name}' to '{new_file_name}'")
        #else:
            #print(f"No need to rename '{file_name}'")

    except Exception as e:
        print(f"Error while renaming '{file_path}': {e}")

def rename_files_in_directory(directory, recursive=False, dry_run=False):
    for root, _, files in os.walk(directory):
        for file in files:
            file_path = os.path.join(root, file)
            rename_file(file_path, dry_run=dry_run)

def main():
    parser = argparse.ArgumentParser(description="Rename files in the current directory")
    parser.add_argument("--dry-run", action="store_true", help="Show before and after without renaming")
    parser.add_argument("--recursive", action="store_true", help="Rename files recursively in current directory")
    args = parser.parse_args()

    # Get the current directory
    current_dir = os.getcwd()

    if args.recursive:
        rename_files_in_directory(current_dir, recursive=True, dry_run=args.dry_run)
    else:
        # List all files in the current directory
        files = [f for f in os.listdir(current_dir) if os.path.isfile(f)]
        for file in files:
            file_path = os.path.join(current_dir, file)
            rename_file(file_path, dry_run=args.dry_run)

if __name__ == "__main__":
    main()

