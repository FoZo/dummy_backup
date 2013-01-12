#!/bin/bash

# Configs
DATE=$(date +%_d_%m_%Y)

DIRS="bin home  lib32 run usr boot etc lib lib64 opt root sbin var"
EXCLUDE_DIRS="/var/tmp/* /usr/portage/*"

SERVER_NAME="latop"
PASSPHRASE="$DATE"
BACKUP_DIR="/mnt/Backup/backup-$SERVER_NAME/$DATE"

function check_user {

	if [ "$(whoami)" != "root" ] ; then
		echo "Only root can run this backup script"
		exit
	fi
}

function mount_nfs {
	
# 1. Mount Bakup
	if mount|grep '/volume1/NetBackup' 2>&1 ; then
                echo "Mount exist, skipping this step"
	elif ping -c 1 192.168.1.125 -q 2>&1 ; then
		echo "Mounting nfs backup"
		if ! mount.nfs 192.168.1.125:/volume1/NetBackup /mnt/Backup/ -o nolock ; then
			echo "Can't mount nfs"
			exit
		fi
	else
		echo "Can't mount"
		exit 0
	fi
}

function mkback_dir {
	
# 2. Making Backup dir
	if [ -d $BACKUP_DIR ] ; then
		echo "Backup dir exist"
	else
		echo "Macking $BACKUP_DIR"
		mkdir -p $BACKUP_DIR
	fi

}

function check_backup_type {

	if [ $(date +%u) != "7" ] ; then
		echo "Macking incremental backup"
		BACKUP_T="i"
	else
		echo "Backing full backup"
		BACKUP_T="f"
	fi 

}

function mk_backup {
	
# 3. Bakup dirs

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

echo "Start backuping at `date`."
check_user
mount_nfs
mkback_dir
check_backup_type
mk_backup
#umount /mnt/Backup/
echo "Finish backuping at `date`."
