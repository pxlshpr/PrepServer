unixtime=$(date +%s)
cd /home/ahmed/PrepBackups
#file="prep-backup-${unixtime}.sql"
file="prep-backup.sql"
pg_dump -U pxlshpr prep --exclude-table-data "preset_foods" > $file
echo "         💾 Backup saved to: ${file}"
git add .
git commit -a -m "added backup"
git push
