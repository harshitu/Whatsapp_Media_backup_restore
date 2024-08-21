# WhatsApp Backup and Restore Script

# Get the script or executable location
$ScriptLocation = Split-Path -Parent $MyInvocation.MyCommand.Path

# Generate a timestamp for the backup folder
$Timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
$DefaultBackupPath = "$ScriptLocation\WhatsApp_Backup_$Timestamp\"  # Default backup location with timestamp

$WhatsAppLocalCachePath = "C:\Users\Harshit\AppData\Local\Packages\5319275A.WhatsAppDesktop_cv1g1gvanyjgm\LocalCache"
$WhatsAppTransfersPath = "C:\Users\Harshit\AppData\Local\Packages\5319275A.WhatsAppDesktop_cv1g1gvanyjgm\LocalState\shared\transfers"

# Check if a folder was provided by dragging and dropping
if ($args.Count -gt 0) {
    $DefaultBackupPath = $args[0] + "_$Timestamp\"
}

# Function to Back Up WhatsApp Data
function Backup-WhatsApp {
    $BackupPath = $DefaultBackupPath
    if (-not (Test-Path -Path $BackupPath)) {
        New-Item -ItemType Directory -Path $BackupPath
    }

    # Backup LocalCache
    if (Test-Path -Path $WhatsAppLocalCachePath) {
        $LocalCacheBackupPath = "$BackupPath\LocalCache"
        if (-not (Test-Path -Path $LocalCacheBackupPath)) {
            New-Item -ItemType Directory -Path $LocalCacheBackupPath
        }
        Copy-Item -Path "$WhatsAppLocalCachePath\*" -Destination $LocalCacheBackupPath -Recurse -Force
    } else {
        Write-Host "LocalCache directory not found. Skipping backup for LocalCache."
    }

    # Backup Transfers
    if (Test-Path -Path $WhatsAppTransfersPath) {
        $TransfersBackupPath = "$BackupPath\Transfers"
        if (-not (Test-Path -Path $TransfersBackupPath)) {
            New-Item -ItemType Directory -Path $TransfersBackupPath
        }
        Copy-Item -Path "$WhatsAppTransfersPath\*" -Destination $TransfersBackupPath -Recurse -Force
    } else {
        Write-Host "Transfers directory not found. Skipping backup for Transfers."
    }

    Write-Host "WhatsApp data has been backed up to $BackupPath."
}

# Function to Restore WhatsApp Data
function Restore-WhatsApp {
    # Let the user select the backup folder
    $BackupRootPath = "$ScriptLocation\WhatsApp_Backup_*"
    $BackupFolders = Get-ChildItem -Path $BackupRootPath -Directory

    if ($BackupFolders.Count -eq 0) {
        Write-Host "No backup folders found in $ScriptLocation."
        return
    }

    Write-Host "Available Backups:"
    for ($i = 0; $i -lt $BackupFolders.Count; $i++) {
        Write-Host "$($i + 1). $($BackupFolders[$i].Name)"
    }

    $selectedIndex = Read-Host "Select the number of the backup you want to restore"

    if (-not ($selectedIndex -as [int] -and $selectedIndex -gt 0 -and $selectedIndex -le $BackupFolders.Count)) {
        Write-Host "Invalid selection. Please run the script again and select a valid backup."
        return
    }

    $BackupPath = $BackupFolders[$selectedIndex - 1].FullName

    $WhatsAppLocalCachePath2 = "C:\Users\Harshit\Desktop\Whatsapp\LocalCache"
    $WhatsAppTransfersPath2 = "C:\Users\Harshit\Desktop\Whatsapp\LocalState\shared\transfers"

    # Restore LocalCache
    $LocalCacheBackupPath = "$BackupPath\LocalCache"
    if (Test-Path -Path $LocalCacheBackupPath) {
        if (-not (Test-Path -Path $WhatsAppLocalCachePath2)) {
            New-Item -ItemType Directory -Path $WhatsAppLocalCachePath2
        }
        Copy-Item -Path "$LocalCacheBackupPath\*" -Destination $WhatsAppLocalCachePath2 -Recurse -Force
    } else {
        Write-Host "LocalCache backup folder not found."
    }

    # Restore Transfers
    $TransfersBackupPath = "$BackupPath\Transfers"
    if (Test-Path -Path $TransfersBackupPath) {
        if (-not (Test-Path -Path $WhatsAppTransfersPath2)) {
            New-Item -ItemType Directory -Path $WhatsAppTransfersPath2
        }
        # Ensure the subdirectories in Transfers exist before copying
        Get-ChildItem -Path $TransfersBackupPath -Directory | ForEach-Object {
            $SubDir = "$WhatsAppTransfersPath2\$($_.Name)"
            if (-not (Test-Path -Path $SubDir)) {
                New-Item -ItemType Directory -Path $SubDir
            }
            Copy-Item -Path "$($_.FullName)\*" -Destination $SubDir -Recurse -Force
        }
    } else {
        Write-Host "Transfers backup folder not found."
    }

    Write-Host "WhatsApp data has been restored from $BackupPath."
}

# Main Menu
Write-Host "WhatsApp Backup & Restore"
Write-Host "1. Backup WhatsApp Data"
Write-Host "2. Restore WhatsApp Data"
Write-Host "3. Exit"
$choice = Read-Host "Select an option (1-3)"

switch ($choice) {
    1 { Backup-WhatsApp }
    2 { Restore-WhatsApp }
    3 { exit }
    default { Write-Host "Invalid choice. Please run the script again." }
}
