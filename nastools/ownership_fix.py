# !/usr/bin/env python3
# python3 ownership_fix.py - Used for NAS and flash drives to set ownership to nobody and 777/666 for dir/files

import os

def print_permissions(path):
    stat_info = os.stat(path)
    print("Before:")
    print(f"Path: {path}")
    print(f"Owner: {stat_info.st_uid} Group: {stat_info.st_gid}")
    print(f"Permissions: {oct(stat_info.st_mode)[-3:]}")

def change_permissions(path):
    for root, dirs, files in os.walk(path):
        for dir in dirs:
            dir_path = os.path.join(root, dir)
            print_permissions(dir_path)
            os.chown(dir_path, 65534, 65534)  # nobody:nogroup
            os.chmod(dir_path, 0o0777)  # 0777 permission
            print("After:")
            print_permissions(dir_path)
            print("=" * 40)

        for file in files:
            file_path = os.path.join(root, file)
            print_permissions(file_path)
            os.chown(file_path, 65534, 65534)  # nobody:nogroup
            os.chmod(file_path, 0o0666)  # 0666 permission
            print("After:")
            print_permissions(file_path)
            print("=" * 40)

if __name__ == "__main__":
    current_directory = os.getcwd()

    if os.geteuid() == 0:
        print("Sample directory permissions:")
        sample_dir = input("Enter a directory within the current path to show permissions: ")
        sample_dir_path = os.path.join(current_directory, sample_dir)
        print_permissions(sample_dir_path)

        confirmation = input("Do you want to proceed with the changes? (yes/no): ")
        if confirmation.lower() == "yes":
            change_permissions(current_directory)
            print("Permissions and ownership changed successfully.")
        else:
            print("No changes were made.")
    else:
        print("This script must be run as root.")

