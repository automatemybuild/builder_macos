#!/bin/bash
#
# rsync_nas_offsite_v2.sh - New backup mirror process created by AI
#
# 1. Mount Veracrypt partition 
# 2. Confirm /opt/diskstation/partitions are mounted
# 3. Run clean_thumbs.py to remove thumbnails saved by diskstation
# 4. Run this command as root to avoid any source read issues
#    sudo su; /opt/diskstation/bin/nas/rsync_nas_offsite_v2.sh
#
# 09/01/2023 - removed --checksum from rsync due to possible performance. Not sure if rsync replaces changed files.

umask 0000

# Set the source and backup base directories
source_base_dir="/opt/diskstation/"
backup_base_dir="/media/veracrypt1/"

# List of directories to mirror
directories_to_mirror=("backup" "common" "emiller" "homes" "jenn_folders" "music" "photos")

# Log file path
log_file="$backup_base_dir/last_$(date +%Y%m%dT%H%M).log"

# Function to log messages
log() {
    local message="$1"
    echo "$(date +"%Y-%m-%d %H:%M:%S") - $message" >> "$log_file"
}

# Check if the backup directory exists
if [ ! -d "$backup_base_dir" ]; then
    log "Backup directory '$backup_base_dir' does not exist. Aborting."
    exit 1
fi

# Iterate over selected directories and mirror them
for directory in "${directories_to_mirror[@]}"; do
    source_dir="${source_base_dir}/${directory}"
    backup_dir="${backup_base_dir}/${directory}"

    # Check if the source directory exists
    if [ ! -d "$source_dir" ]; then
        log "Source directory '$source_dir' does not exist. Skipping."
        continue
    fi

    # Use rsync to mirror the contents while maintaining file dates
    rsync -av \
        --delete \
        --ignore-existing \
        --no-links \
        --chown=nobody: --no-group \
        --exclude="@eaDir" --exclude="*iso" --exclude="*qcow2" --exclude="Thumb.db" \
        "$source_dir/" "$backup_dir/"
    if [ $? -eq 0 ]; then
        log "Mirrored '$source_dir' to '$backup_dir'"
    else
        log "Error mirroring '$source_dir' to '$backup_dir'"
    fi
done
log "Backup process completed."

# Cleanup: Remove files from the backup that are no longer in the source
for directory in "${directories_to_mirror[@]}"; do
    source_dir="${source_base_dir}/${directory}"
    backup_dir="${backup_base_dir}/${directory}"

    for item in "${backup_dir}"/*; do
        item_name=$(basename "$item")

        if [ ! -e "${source_dir}/${item_name}" ]; then
            if [ -f "$item" ]; then
                rm "$item"
                log "Removed '$item' from the backup."
            elif [ -d "$item" ]; then
                rm -r "$item"
                log "Removed directory '$item' from the backup."
            fi
        fi
    done
done

log "Cleanup process completed."
