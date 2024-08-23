# WhatsApp Backup and Restore Script

# Get the script or executable location
$ScriptLocation = if ($MyInvocation.MyCommand.Path) {
    Split-Path -Parent $MyInvocation.MyCommand.Path
} else {
    Split-Path -Parent $([System.Diagnostics.Process]::GetCurrentProcess().MainModule.FileName)
}

# Generate a timestamp for the backup folder
$Timestamp = Get-Date -Format "yyyy.MM.dd_tt-HH.mm.ss"
$BackupRootPath = "$ScriptLocation\WhatsApp_Backups\"  # Root backup location
$DefaultBackupPath = "$BackupRootPath\Backup_$Timestamp\"  # Default backup location with timestamp
$MergedBackupPath = "$BackupRootPath\Backup_All_Merged\"  # Merged backup location

# Locate the WhatsApp package directory using a specific pattern
$WhatsAppBasePath = Get-ChildItem "$env:LOCALAPPDATA\Packages" | Where-Object { $_.Name -like "*.WhatsAppDesktop_*" } | Select-Object -ExpandProperty FullName

$global:WhatsAppLocalCachePath = "$WhatsAppBasePath\LocalCache"
$global:WhatsAppTransfersPath = "$WhatsAppBasePath\LocalState\shared\transfers"

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
    if (Test-Path -Path $global:WhatsAppLocalCachePath) {
        $LocalCacheBackupPath = "$DefaultBackupPath\LocalCache"
        if (-not (Test-Path -Path $LocalCacheBackupPath)) {
            New-Item -ItemType Directory -Path $LocalCacheBackupPath
        }
        if (-not (Test-Path -Path "$MergedBackupPath\LocalCache")) {
            New-Item -ItemType Directory -Path "$MergedBackupPath\LocalCache"
        }
        Copy-Item -Path "$global:WhatsAppLocalCachePath\*" -Destination $LocalCacheBackupPath -Recurse -Force
        Copy-Item -Path "$global:WhatsAppLocalCachePath\*" -Destination "$MergedBackupPath\LocalCache" -Recurse -Force
    } else {
        Write-Host "LocalCache directory not found. Skipping backup for LocalCache."
    }

    # Backup Transfers
    if (Test-Path -Path $global:WhatsAppTransfersPath) {
        $TransfersBackupPath = "$DefaultBackupPath\LocalState\shared\transfers"
        if (-not (Test-Path -Path $TransfersBackupPath)) {
            New-Item -ItemType Directory -Path $TransfersBackupPath -Force
        }

        # Ensure that directories are created before copying files
        Get-ChildItem -Path $global:WhatsAppTransfersPath -Directory | ForEach-Object {
            $SubDir = "$MergedBackupPath\LocalState\shared\transfers\$($_.Name)"
            if (-not (Test-Path -Path $SubDir)) {
                New-Item -ItemType Directory -Path $SubDir -Force
            }
            Copy-Item -Path "$($_.FullName)\*" -Destination $SubDir -Recurse -Force
        }

        Copy-Item -Path "$global:WhatsAppTransfersPath\*" -Destination $TransfersBackupPath -Recurse -Force
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

    # Ask user for testing or real WhatsApp paths
    AskWhereToRestore

    # Restore LocalCache
    $LocalCacheBackupPath = "$BackupPath\LocalCache"
    if (Test-Path -Path $LocalCacheBackupPath) {
        if (-not (Test-Path -Path $global:WhatsAppLocalCachePath)) {
            New-Item -ItemType Directory -Path $global:WhatsAppLocalCachePath
        }
        Copy-Item -Path "$LocalCacheBackupPath\*" -Destination $global:WhatsAppLocalCachePath -Recurse -Force
    } else {
        Write-Host "LocalCache backup folder not found."
    }

    # Restore Transfers
    $TransfersBackupPath = "$BackupPath\LocalState\shared\transfers"
    if (Test-Path -Path $TransfersBackupPath) {
        if (-not (Test-Path -Path $global:WhatsAppTransfersPath)) {
            New-Item -ItemType Directory -Path $global:WhatsAppTransfersPath -Force
        }
        Copy-Item -Path "$TransfersBackupPath\*" -Destination $global:WhatsAppTransfersPath -Recurse -Force
    } else {
        Write-Host "Transfers backup folder not found."
    }

    Write-Host "WhatsApp data has been restored from $BackupPath."
}

function AskWhereToRestore {
    Write-Host "Press T: to restore into testing directory"
    Write-Host "Press W: to restore into real WhatsApp directory :"

    do{
        $key = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown").Character
    } while (-not [char]::IsLetterOrDigit($key))

    if ($key -eq 'T') {  # 'T' key
        # Update paths for testing
        $global:WhatsAppLocalCachePath = "$ScriptLocation\$env:USERNAME\AppData\Local\Packages\$(Get-ChildItem "$env:LOCALAPPDATA\Packages\" | Where-Object { $_.Name -like "*.WhatsAppDesktop_*" }).Name\LocalCache"
        $global:WhatsAppTransfersPath = "$ScriptLocation\$env:USERNAME\AppData\Local\Packages\$(Get-ChildItem "$env:LOCALAPPDATA\Packages\" | Where-Object { $_.Name -like "*.WhatsAppDesktop_*" }).Name\LocalState\shared\transfers"
    } elseif ($key -eq 'W') {  # 'W' key
        # Use real WhatsApp paths (paths are already set)
        Write-Host "Using real WhatsApp paths."
    } else {
        Write-Host "Invalid key pressed. Exiting."
        exit
    }
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
