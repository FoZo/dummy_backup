#!/bin/bash

# Configs
DATE=$(date +%_d_%m_%Y)

DIRS="home bin lib32 run usr boot etc lib lib64 opt root sbin var" # Add base dir
EXCLUDE_DIRS="/home/walker/Downloads/* /var/tmp/* /usr/portage/* /var/log/*" # Add exclude dirs

SERVER_NAME="acer_latop" # Set name for backup dir
NFS_SERVER_IP="set NFS server" # Set NFS server ip address
PASSPHRASE="test-$DATE" # Set passphrase for gpg encryption
BACKUP_DIR="/mnt/Backup/backup-$SERVER_NAME/$DATE" # Set path to backup dir



function check_user {

        if [ "$(whoami)" != "root" ] ; then
                echo "Only root can run this backup script"
                exit
        fi
}

function mount_nfs {

        echo "Mount NFS"
        if mount|grep '/volume1/NetBackup' 2>&1 ; then
                echo " Mount exist, skipping this step"
        elif ping -c 1 $NFS_SERVER_IP -q 2>&1 ; then
                echo "Mounting nfs backup"
                if ! mount.nfs $NFS_SERVER_IP:/volume1/NetBackup /mnt/Backup/ -o nolock 2>&1 ; then
                        echo " Can't mount nfs"
                        exit
                fi
        else
                echo " Can't mount"
                exit 0
        fi
}

function mkback_dir {

        echo "Making Backup dir"
        if [ -d $BACKUP_DIR ] ; then
                echo " Backup dir exist"
        else
                echo " Making $BACKUP_DIR"
                mkdir -p $BACKUP_DIR
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

function mk_backup {

        echo "Create backup files"

        EXCLUDE=""

        for LIST in $EXCLUDE_DIRS
        do 
                EXCLUDE=$EXCLUDE" --exclude=$LIST"
        done

        for DIR in $DIRS
        do
                if [ $BACKUP_T != "i" ] ; then
                        if [ ! -f $BACKUP_DIR/$DIR.`date +%_d-%m-%Y`.f.ok ] ; then
                                tar czvf - /$DIR $EXCLUDE 2>&1 | gpg2 -c --batch --yes --passphrase t -o $BACKUP_DIR/$DIR.`date +%_d-%m-%Y`.f.tar.gz.gpg
                                touch /mnt/Backup/$DIR.`date +%_d-%m-%Y`.f.ok
                        fi
                else
                        if [ ! -f $BACKUP_DIR/$DIR.`date +%_d-%m-%Y`.i.ok ] ; then
                                tar czvf - /$DIR --newer-mtime='1' $EXCLUDE 2>&1 | gpg2 -c --batch --yes --passphrase t -o $BACKUP_DIR/$DIR.`date +%_d-%m-%Y`.i.tar.gz.gpg
                                touch $BACKUP_DIR/$DIR.`date +%_d-%m-%Y`.i.ok
                        fi
                fi
        done
}

echo "-------------------------"
echo "Start backuping at `date`."
check_user
mount_nfs
mkback_dir
check_backup_type
mk_backup
umount /mnt/Backup/
echo "Finish backuping at `date`."
echo "-------------------------"
