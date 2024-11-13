# !/usr/bin/env python3
#
# 09/04/2023 - Update to include source sub-directories and use file timestamp if exiftool date has an IndexError
# Description: take all photos and video files  in a directory recursive structure move file preserving  original file date stamp based based on the year & month the photos and videos were taken  using exiftool similar command to new directory structure that is "$prefix_$year_$month". Use the file timestamp if values are out of range or issue with IndexError and continue Show a progress bar during this process. prompt for source directory and destination directory and prefix

import os
import subprocess
import datetime
from tqdm import tqdm
import shutil

def get_creation_date(file_path):
    try:
        # Get the creation year and month using exiftool
        creation_date = subprocess.check_output(["exiftool", "-s", "-s", "-s", "-CreateDate", file_path]).decode().strip()
        creation_parts = creation_date.split(":")
        if len(creation_parts) >= 2:
            return creation_parts[0], creation_parts[1]
        else:
            return None, None
    except subprocess.CalledProcessError as e:
        return None, None

def organize_media_recursive(src_directory, dest_directory, prefix):
    # Ensure the source directory exists
    if not os.path.exists(src_directory):
        print("Source directory does not exist.")
        exit(1)

    # Ensure the destination directory exists
    os.makedirs(dest_directory, exist_ok=True)

    # Initialize tqdm progress bar
    with tqdm(unit="file") as pbar:
        for root, _, files in os.walk(src_directory):
            for file in files:
                src_path = os.path.join(root, file)

                creation_year, creation_month = get_creation_date(src_path)

                if creation_year is None or creation_month is None:
                    # Use file date stamp if exiftool command fails
                    file_timestamp = os.path.getmtime(src_path)
                    creation_year = datetime.datetime.fromtimestamp(file_timestamp).strftime("%Y")
                    creation_month = datetime.datetime.fromtimestamp(file_timestamp).strftime("%m")

                try:
                    # Handle out-of-range values and skip file
                    if not (1900 <= int(creation_year) <= 9999 and 1 <= int(creation_month) <= 12):
                        print(f"Skipped: {src_path} - Invalid or out-of-range date values")
                        pbar.update(1)
                        continue

                    # Create the destination directory
                    dest_dir = os.path.join(dest_directory, f"{prefix}_{creation_year}_{creation_month}")
                    os.makedirs(dest_dir, exist_ok=True)

                    # Construct the new path
                    new_path = os.path.join(dest_dir, file)

                    # Move the file and preserve timestamps
                    shutil.move(src_path, new_path)

                except ValueError:
                    print(f"Skipped: {src_path} - Invalid date values")
                except Exception as e:
                    print(f"Error processing {src_path}: {str(e)}")

                # Update tqdm progress bar
                pbar.update(1)

    print("Done!")

if __name__ == "__main__":
    src_directory = input("Enter the source directory: ")
    dest_directory = input("Enter the destination directory: ")
    prefix = input("Enter the prefix for the new directory structure: ")

    organize_media_recursive(src_directory, dest_directory, prefix)

