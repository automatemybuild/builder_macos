# !/usr/bin/env python3
# python3 uppercase_fix.py - Intended for photos to convert file names to uppercase

import os

def convert_filename_to_uppercase(file_path):
    directory, filename = os.path.split(file_path)
    new_filename = filename.upper()
    new_file_path = os.path.join(directory, new_filename)
    os.rename(file_path, new_file_path)
    print(f"Converted {file_path} to {new_file_path}")

def recursive_convert_filenames(directory):
    for root, _, files in os.walk(directory):
        for filename in files:
            if any(c.islower() for c in filename):
                file_path = os.path.join(root, filename)
                convert_filename_to_uppercase(file_path)

if __name__ == "__main__":
    current_directory = os.getcwd()
    recursive_convert_filenames(current_directory)

