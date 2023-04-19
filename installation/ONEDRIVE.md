# OneDrive/SharePoint client

https://github.com/abraunegg/onedrive

https://github.com/abraunegg/onedrive/blob/master/docs/USAGE.md

```bash
onedrive # auth
onedrive --synchronize --verbose --dry-run
vim ~/.config/onedrive/sync_list
systemctl --user enable onedrive
```

## Backup KeePass DB

```bash
# Set save mode in KeePass settings to cloud-compatible (temp file)
yay -S backintime # cron: cronie
backintime-qt # launch app
```

### BackInTime Config

#### General

Save to ~/keepassxc-backups/backintime

Schedule repeatedly (anacron) every hour (otherwise it might skip executions if the PC was off).

Don't forget to `systemctl enable cronie`, otherwise it won't really work.

#### Include

Include kdbx file

#### Auto-remove

Older than 1 year

Smart remove

