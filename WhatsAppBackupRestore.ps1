# WhatsApp Backup and Restore Script

# Get the script or executable location
$ScriptLocation = Split-Path -Parent $MyInvocation.MyCommand.Path

# Generate a timestamp for the backup folder
$Timestamp = Get-Date -Format "yyyy.MM.dd_tt-HH.mm.ss"
$BackupRootPath = "$ScriptLocation\WhatsApp_Backups\"  # Root backup location
$DefaultBackupPath = "$BackupRootPath\Backup_$Timestamp\"  # Default backup location with timestamp
$MergedBackupPath = "$BackupRootPath\Backup_All_Merged\"  # Merged backup location

# Locate the WhatsApp package directory using a specific pattern
$WhatsAppBasePath = Get-ChildItem "$env:LOCALAPPDATA\Packages" | Where-Object { $_.Name -like "*.WhatsAppDesktop_*" } | Select-Object -ExpandProperty FullName

$WhatsAppLocalCachePath = "$WhatsAppBasePath\LocalCache"
$WhatsAppTransfersPath = "$WhatsAppBasePath\LocalState\shared\transfers"

# Check if a folder was provided by dragging and dropping
if ($args.Count -gt 0) {
    $DefaultBackupPath = $args[0] + "_$Timestamp\"
}

# Function to Back Up WhatsApp Data
function Backup-WhatsApp {
    if (-not (Test-Path -Path $DefaultBackupPath)) {
        New-Item -ItemType Directory -Path $DefaultBackupPath
    }

    if (-not (Test-Path -Path $MergedBackupPath)) {
        New-Item -ItemType Directory -Path $MergedBackupPath
    }

    # Backup LocalCache
    if (Test-Path -Path $WhatsAppLocalCachePath) {
        $LocalCacheBackupPath = "$DefaultBackupPath\LocalCache"
        if (-not (Test-Path -Path $LocalCacheBackupPath)) {
            New-Item -ItemType Directory -Path $LocalCacheBackupPath
        }
        Copy-Item -Path "$WhatsAppLocalCachePath\*" -Destination $LocalCacheBackupPath -Recurse -Force
        Copy-Item -Path "$WhatsAppLocalCachePath\*" -Destination "$MergedBackupPath\LocalCache" -Recurse -Force
    } else {
        Write-Host "LocalCache directory not found. Skipping backup for LocalCache."
    }

    # Backup Transfers
    if (Test-Path -Path $WhatsAppTransfersPath) {
        $TransfersBackupPath = "$DefaultBackupPath\LocalState\shared\transfers"
        if (-not (Test-Path -Path $TransfersBackupPath)) {
            New-Item -ItemType Directory -Path $TransfersBackupPath -Force
        }

        # Ensure that directories are created before copying files
        Get-ChildItem -Path $WhatsAppTransfersPath -Directory | ForEach-Object {
            $SubDir = "$MergedBackupPath\LocalState\shared\transfers\$($_.Name)"
            if (-not (Test-Path -Path $SubDir)) {
                New-Item -ItemType Directory -Path $SubDir -Force
            }
            Copy-Item -Path "$($_.FullName)\*" -Destination $SubDir -Recurse -Force
        }

        Copy-Item -Path "$WhatsAppTransfersPath\*" -Destination $TransfersBackupPath -Recurse -Force
    } else {
        Write-Host "Transfers directory not found. Skipping backup for Transfers."
    }

    Write-Host "WhatsApp data has been backed up to $DefaultBackupPath."
}

# Function to Restore WhatsApp Data
function Restore-WhatsApp {
    # Let the user select the backup folder
    $BackupRootPath = "$ScriptLocation\WhatsApp_Backups\Backup_*"
    $BackupFolders = Get-ChildItem -Path $BackupRootPath -Directory

    if ($BackupFolders.Count -eq 0) {
        Write-Host "No backup folders found in $BackupRootPath."
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

    #testing
    $WhatsAppLocalCachePath = "C:\Users\Harshit\Desktop\Whatsapp\LocalCache"
    $WhatsAppTransfersPath = "C:\Users\Harshit\Desktop\Whatsapp\LocalState\shared\transfers"

    # Restore LocalCache
    $LocalCacheBackupPath = "$BackupPath\LocalCache"
    if (Test-Path -Path $LocalCacheBackupPath) {
        if (-not (Test-Path -Path $WhatsAppLocalCachePath)) {
            New-Item -ItemType Directory -Path $WhatsAppLocalCachePath
        }
        Copy-Item -Path "$LocalCacheBackupPath\*" -Destination $WhatsAppLocalCachePath -Recurse -Force
    } else {
        Write-Host "LocalCache backup folder not found."
    }

    # Restore Transfers
    $TransfersBackupPath = "$BackupPath\LocalState\shared\transfers"
    if (Test-Path -Path $TransfersBackupPath) {
        if (-not (Test-Path -Path $WhatsAppTransfersPath)) {
            New-Item -ItemType Directory -Path $WhatsAppTransfersPath -Force
        }
        Copy-Item -Path "$TransfersBackupPath\*" -Destination $WhatsAppTransfersPath -Recurse -Force
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
