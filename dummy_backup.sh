#!/bin/bash

# Configs
DATE=$(date +%d_%m_%Y) # Set date format. I use this for file names.

DIRS="home bin lib32 run usr boot etc lib lib64 opt root sbin var" # Add base dir
EXCLUDE_DIRS="/home/walker/Downloads/* /var/tmp/* /usr/portage/* /var/log/*" # Add exclude dirs

SERVER_NAME="acer_latop" # Set name for backup dir
NFS_SERVER_IP="set NFS server" # Set NFS server ip address
PASSPHRASE="$DATE" # Set passphrase for gpg encryption
BACKUP_DIR="/mnt/Backup/backup-$SERVER_NAME/$DATE" # Set path to backup dir


function checks {

        if [ "$(whoami)" != "root" ] ; then
                echo "Only root can run this backup script"
                exit
        fi

        if [ -f /tmp/dummy_backup.$DATE.ok ] ; then
                echo "You have already made a backup today"
                echo "-------------------------"
                exit
        fi
}

function mount_nfs {

        echo "Mount NFS"
        if mount|grep '/volume1/NetBackup' 2>&1 ; then
                echo " Mount exist, skipping this step"
        elif ping -c 1 $NFS_SERVER_IP -q 2>&1|grep "1 received" 2>&1; then
                echo "Mounting nfs backup"
                if ! /sbin/mount.nfs $NFS_SERVER_IP:/volume1/NetBackup /mnt/Backup/ -o nolock ; then
                        echo " Can't mount nfs"
                        exit
                fi
        else
                echo " Can't mount"
                exit 0
        fi
}

function check_backup_type {

        if [ $(date +%u) != "7" ] ; then
                echo "Making incremental backup"
                BACKUP_T="i"
        else
                echo "Backing full backup"
                BACKUP_T="f"
        fi 

}

function mkback_dir {

        echo "Making Backup dir"
        if [ -d $BACKUP_DIR.$BACKUP_T ] ; then
                echo " Backup dir exist"
        else
                echo " Making $BACKUP_DIR.$BACKUP_T"
                mkdir -p $BACKUP_DIR.$BACKUP_T
        fi

}


function mk_backup {

        echo "Create backup files"

        EXCLUDE=""

        for LIST in $EXCLUDE_DIRS
        do 
                EXCLUDE=$EXCLUDE" --exclude=$LIST"
        done

        for DIR in $DIRS
        do
                if [ $BACKUP_T == "f" ] ; then
                        if [ ! -f $BACKUP_DIR.f/$DIR.$DATE.f.ok ] ; then
                                tar czf - /$DIR $EXCLUDE | gpg2 -c --batch --yes --passphrase $PASSPHRASE -o $BACKUP_DIR.f/$DIR.$DATE.f.tar.gz.gpg
                                touch $BACKUP_DIR.f/$DIR.$DATE.f.ok
                                echo "$DIR.$DATE.f.tar.gz.gpg Done"
                        fi
                else
                        if [ ! -f $BACKUP_DIR.i/$DIR.`date +%_d-%m-%Y`.i.ok ] ; then
                                tar czf - /$DIR --newer-mtime='1' $EXCLUDE | gpg2 -c --batch --yes --passphrase $PASSPHRASE -o $BACKUP_DIR.i/$DIR.$DATE.i.tar.gz.gpg
                                touch $BACKUP_DIR.i/$DIR.$DATE.i.ok
                                echo "$DIR.$DATE.i.tar.gz.gpg Done"
                        fi
                fi
        done
        touch /tmp/dummy_backup.$DATE.ok
}

echo "-------------------------"
echo "Start backuping at `date`."
checks
mount_nfs
check_backup_type
mkback_dir
mk_backup
umount /mnt/Backup/
echo "Finish backuping at `date`.
