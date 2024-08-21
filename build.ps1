try {
    # Import module
    $modulePath = Join-Path $PSScriptRoot "Modules"  # Path to the module directory
    Import-Module (Join-Path $modulePath "ps2exe.psd1")

    # Print commands available in module
    Get-Command -Module ps2exe

    # Run command
    Invoke-ps2exe -inputFile "WhatsAppBackupRestore.ps1" -OutputFile "WhatsAppBackupRestore.exe"

    # More info "Get-Help Invoke-ps2exe"
    #EXAMPLE: Invoke-ps2exe C:\Data\MyScript.ps1
              # Compiles C:\Data\MyScript.ps1 to C:\Data\MyScript.exe as console executable
    #EXAMPLE: ps2exe -inputFile C:\Data\MyScript.ps1 -outputFile C:\Data\MyScriptGUI.exe -iconFile C:\Data\Icon.ico -noConsole -title "MyScript" -version 0.0.0.1
              # Compiles C:\Data\MyScript.ps1 to C:\Data\MyScriptGUI.exe as graphical executable, icon and meta data
}
catch {
    $_.Exception | Format-List -Force
}