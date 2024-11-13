# !/usr/bin/env python3
# sudo python3 permissions_fix.py - set permissions for directories to 776 and files to 666

import os
import sys
import argparse

def change_permissions(path, dry_run=False):
    for root, dirs, files in os.walk(path):
        for directory in dirs:
            dir_path = os.path.join(root, directory)
            if os.path.isdir(dir_path) and os.stat(dir_path).st_uid != 0:
                print(f"Changing directory permission: {dir_path}")
                if not dry_run:
                    os.chmod(dir_path, 0o776)
        
        for file in files:
            file_path = os.path.join(root, file)
            if os.path.isfile(file_path) and os.stat(file_path).st_uid != 0:
                print(f"Changing file permission: {file_path}")
                if not dry_run:
                    os.chmod(file_path, 0o666)

def main():
    parser = argparse.ArgumentParser(description="Change directory and file permissions.")
    parser.add_argument("--dry-run", action="store_true", help="Show changes without actually applying them.")
    parser.add_argument("--silent", action="store_true", help="Run silently without confirmation.")
    args = parser.parse_args()

    current_directory = os.getcwd()
    print(f"Current directory: {current_directory}")

    if not args.silent:
        confirmation = input("Do you want to proceed? (y/n): ")
        if confirmation.lower() != "y":
            print("Aborted.")
            sys.exit(0)

    if args.dry_run:
        print("Running in dry-run mode. Changes will not be applied.")
    else:
        print("Changing permissions...")

    change_permissions(current_directory, args.dry_run)

    print("Done!")

if __name__ == "__main__":
    main()

