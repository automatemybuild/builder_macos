# !/usr/bin/env python3
# python3 lg_file_finder.py - finds the top 20 largest files with the option to remove

import os
import shutil
from tqdm import tqdm

def get_largest_files(directory, num_files=20):
    files = []
    for root, _, filenames in os.walk(directory, followlinks=False):  # Add followlinks=False to skip symbolic links
        for filename in filenames:
            filepath = os.path.join(root, filename)
            try:
                size = os.path.getsize(filepath)
                files.append((filepath, size))
            except OSError as e:
                print(f"Error getting size of {filepath}: {e}")
    
    sorted_files = sorted(files, key=lambda x: x[1], reverse=True)
    return sorted_files[:num_files]

def main():
    directory_path = input("Enter the directory path to search for large files: ")
    num_files_to_display = 20

    # Get the 20 largest files
    largest_files = get_largest_files(directory_path, num_files_to_display)

    for file, size in largest_files:
        response = input(f"Do you want to delete {file} ({size//1024} KB)? (y/n) [n]: ").lower()
        if response == "y":
            try:
                if os.path.exists(file):
                    if os.path.isfile(file):
                        os.remove(file)
                    elif os.path.isdir(file):
                        shutil.rmtree(file)
                    print(f"Deleted: {file}")
                else:
                    print(f"File not found: {file}")
            except Exception as e:
                print(f"An error occurred while deleting {file}: {e}")

if __name__ == "__main__":
    main()
