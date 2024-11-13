# !/usr/bin/env python3
# python3 directory_fix_v2.py

import os
import re
import argparse

def rename_directory(dir_path, dry_run=False):
    try:
        # Get the directory name without the path
        dir_name = os.path.basename(dir_path)

        # Remove "'s" sequences
        dir_name = dir_name.replace("'s", "")

        # Remove single quotes
        dir_name = dir_name.replace("'", "")
        dir_name = dir_name.replace("&", "")
        dir_name = dir_name.replace("(", "")
        dir_name = dir_name.replace(")", "")
        dir_name = dir_name.replace("[", "")
        dir_name = dir_name.replace("]", "")
        dir_name = dir_name.replace("   ", " ")
        dir_name = dir_name.replace("  ", " ")

        # Replace spaces with underscores
        new_dir_name = dir_name.replace(" ", "_")

        if new_dir_name != dir_name:
            # Create the new directory name
            new_dir_path = os.path.join(os.path.dirname(dir_path), new_dir_name)

            print(f"Renamed '{dir_name}' to '{new_dir_name}'")

            if not dry_run:
                # Rename the directory
                os.rename(dir_path, new_dir_path)

    except Exception as e:
        print(f"Error while renaming '{dir_path}': {e}")

def rename_directories_recursively(current_dir, dry_run=False):
    for root, directories, _ in os.walk(current_dir, topdown=False):
        for directory in directories:
            dir_path = os.path.join(root, directory)
            rename_directory(dir_path, dry_run=dry_run)

def main():
    parser = argparse.ArgumentParser(description="Rename directories and subdirectories")
    parser.add_argument("--dry-run", action="store_true", help="Show changes without renaming")
    args = parser.parse_args()

    current_dir = os.getcwd()

    print("Renaming directories and subdirectories in the following directory:")
    print(current_dir)

    rename_directories_recursively(current_dir, dry_run=args.dry_run)

if __name__ == "__main__":
    main()

