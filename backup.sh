unixtime=$(date +%s)
cd /home/ahmed/PrepBackups

#file="prep-backup-${unixtime}.sql"
#file="prep-backup.sql"
#pg_dump -U pxlshpr prep --exclude-table-data "preset_foods" > $file

fileSchema="prep-schema.sql"
fileData="prep-data.sql"
pg_dump -U pxlshpr prep --schema-only > $fileSchema
pg_dump -U pxlshpr prep --data-only --exclude-table-data "preset_foods" > $fileData

echo "         💾 Backup saved to: ${fileData} and ${fileSchema}"
git add .
git commit -a -m "added backup"
git push
