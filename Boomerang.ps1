 # Primary Script Variables
 $Username = "USERNAME"
 $Password = "PASSWORD"
 $LogFile = "C:\EsetRemoval\setupLog.txt"
 $WinlogonRegistryBackupPath = "C:\EsetRemoval\winlogonRegistryBackup.reg"
 $agentInstallerPath = "C:\EsetRemoval\Trend\EndpointBasecamp.exe"
 $SecondaryScriptPath = "C:\EsetRemoval\Boomerang.ps1"
 $MarkerFile = "C:\EsetRemoval\SafeModeMarker.txt"
 $ESETUninstallerPath = 'C:\EsetRemoval\esetuninstaller.exe'
 
 # Initialize success tracker
 $StepsSuccessful = $true
 
 # Function to log messages
 function Write-Log {
     Param ([string]$Message)
     $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
     "${timestamp}: $Message" | Out-File -FilePath $LogFile -Append
 }
 
 # Function to log errors and prevent script from continuing
 function Log-ErrorAndStopScript {
     Param ([string]$ErrorMessage)
     Write-Log "Error: $ErrorMessage"
     throw $ErrorMessage
 }
 
 # Function to check if current user is an administrator
 function Check-Administrator {
     try {
         $currentUser = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
         if (-not $currentUser.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
             Log-ErrorAndStopScript "Current user is not an administrator. Script requires administrator privileges."
         } else {
             Write-Log "Current user is an administrator."
         }
     } catch {
         Log-ErrorAndStopScript "Failed to check administrator privileges. Error: $_"
     }
 }
 
 # Function to perform pre-flight checks
 function Perform-PreFlightChecks {
     Write-Log "Performing pre-flight checks..."
     # Check if current user is an administrator
     Check-Administrator
 
     # Check if agent installer exists
     if (-not (Test-Path $agentInstallerPath)) {
         Log-ErrorAndStopScript "Agent installer not found at path: $agentInstallerPath"
     } else {
         Write-Log "Agent installer found at path: $agentInstallerPath"
     }
 
     # Check if secondary script exists
     if (-not (Test-Path $SecondaryScriptPath)) {
         Log-ErrorAndStopScript "Secondary script not found at path: $SecondaryScriptPath"
     } else {
         Write-Log "Secondary script found at path: $SecondaryScriptPath"
     }
 
     # Check if ESET Uninstaller exists
     if (-not (Test-Path $ESETUninstallerPath)) {
         Log-ErrorAndStopScript "ESET Uninstaller not found at path: $ESETUninstallerPath"
     } else {
         Write-Log "ESET Uninstaller found at path: $ESETUninstallerPath"
     }
 
     Write-Log "Pre-flight checks completed."
 }
 
 # Install Vision One agent
 function Install-VisionOneAgent {
     try {
         Write-Log "Installing Vision One agent."
         Start-Process -FilePath $agentInstallerPath -ArgumentList "/quiet" -Wait -PassThru
         Write-Log "Vision One agent installed successfully."
     } catch {
         Log-ErrorAndStopScript "Failed to install Vision One agent. Error: $_"
     }
 }
 
 # Configure auto-login
 function Set-AutoLogin {
     param($Username, $Password)
     try {
         Write-Log "Configuring automatic login for $Username."
         Set-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon" "AutoAdminLogon" "1"
         Set-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon" "DefaultUsername" $Username
         Set-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon" "DefaultPassword" $Password
         Write-Log "Automatic login configured successfully."
     } catch {
         Log-ErrorAndStopScript "Failed to configure automatic login. Error: $_"
     }
 }
 
 # Enable Safe Mode with Networking
 function Set-SafeBootWithNetworking {
     try {
         Write-Log "Setting Windows to boot in Safe Mode with Networking on next reboot."
         Start-Process -FilePath "cmd.exe" -ArgumentList "/c bcdedit /set {current} safeboot network" -Wait -PassThru -WindowStyle Hidden
         Write-Log "Successfully set Windows to boot in Safe Mode with Networking on next reboot."
     } catch {
         Log-ErrorAndStopScript "Failed to set Windows to boot in Safe Mode with Networking. Error: $_"
     }
 }
 
 # Backup Winlogon registry key
 function Backup-WinlogonRegistry {
     try {
         Write-Log "Backing up Winlogon registry key."
         reg export "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon" $WinlogonRegistryBackupPath
         Write-Log "Winlogon registry key backed up."
     } catch {
         Log-ErrorAndStopScript "Failed to back up Winlogon registry key. Error: $_"
     }
 }
 
 # Add Script to Winlogon
 function Add-WinlogonScript {
     try {
         Write-Log "Adding the secondary script to the Winlogon Shell value."
         $originalShell = (Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon").Shell
         $newShellValue = "$originalShell, powershell.exe -ExecutionPolicy Bypass -File `"$SecondaryScriptPath`""
         Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon" -Name "Shell" -Value $newShellValue
         Write-Log "Secondary script added to the Winlogon Shell value."
     } catch {
         Log-ErrorAndStopScript "Failed to modify the Winlogon Shell value. Error: $_"
     }
 }
 
 # Function to create marker file
 function Create-MarkerFile {
     try {
         Write-Log "Creating marker file to track Safe Mode execution."
         New-Item -ItemType File -Path $MarkerFile -Force | Out-Null
         Write-Log "Marker file created."
     } catch {
         Log-ErrorAndStopScript "Failed to create marker file. Error: $_"
     }
 }
 
 # Function to execute Safe Mode steps
 function Execute-SafeModeSteps {
     Write-Log "Executing Safe Mode steps."
     try {
         # Restoring the original Shell value
         $originalShell = 'explorer.exe'
         Set-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon' -Name 'Shell' -Value $originalShell
         Write-Log "Winlogon Shell value restored to original."
 
         # Starting ESET Uninstaller
         Write-Log "Starting ESET Uninstaller."
         $process = Start-Process -FilePath $ESETUninstallerPath -ArgumentList '/force' -Wait -PassThru
         if ($process.ExitCode -ne 0) {
             Write-Log "ESET Uninstaller exited with code $($process.ExitCode)."
         } else {
             Write-Log "ESET Uninstaller completed successfully."
         }
 
         # Resetting boot configuration
         Write-Log "Resetting boot configuration."
         Start-Process -FilePath 'cmd.exe' -ArgumentList '/c bcdedit /deletevalue {current} safeboot' -Wait -PassThru | Out-Null
         Write-Log "Boot configuration reset."
 
         # Removing AutoLogon configuration
         Write-Log "Removing AutoLogon configuration."
         Remove-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon' -Name 'AutoAdminLogon'
         Remove-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon' -Name 'DefaultUsername'
         Remove-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon' -Name 'DefaultPassword'
         Write-Log "AutoLogon configuration removed."
 
         # Initiating reboot
         Write-Log "Initiating reboot."
         shutdown.exe /r /t 0 | Out-Null
 
         # Removing marker file
         Remove-MarkerFile
     } catch {
         Log-ErrorAndStopScript "Failed to execute Safe Mode steps. Error: $_"
         Revert-ChangesAndReboot
     }
 }
 
 # Function to remove marker file
 function Remove-MarkerFile {
     try {
         Write-Log "Removing marker file."
         Remove-Item $MarkerFile -Force
         Write-Log "Marker file removed."
     } catch {
         Log-ErrorAndStopScript "Failed to remove marker file. Error: $_"
     }
 }
 
 # Function to revert changes and reboot to normal mode
 function Revert-ChangesAndReboot {
     try {
         Write-Log "Reverting changes and rebooting to normal mode."
 
         # Restore Winlogon registry from backup
         Write-Log "Restoring Winlogon registry from backup."
         reg import $WinlogonRegistryBackupPath | Out-Null
         Write-Log "Winlogon registry restored."
 
         # Remove marker file if exists
         if (Test-Path $MarkerFile) {
             Remove-MarkerFile
         }
 
         # Reset boot configuration
         Write-Log "Resetting boot configuration."
         Start-Process -FilePath 'cmd.exe' -ArgumentList '/c bcdedit /deletevalue {current} safeboot' -Wait -PassThru | Out-Null
         Write-Log "Boot configuration reset."
 
         # Remove AutoLogon configuration
         Write-Log "Removing AutoLogon configuration."
         Remove-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon' -Name 'AutoAdminLogon'
         Remove-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon' -Name 'DefaultUsername'
         Remove-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon' -Name 'DefaultPassword'
         Write-Log "AutoLogon configuration removed."
 
         # Reboot to normal mode
         Write-Log "Rebooting to normal mode."
         shutdown.exe /r /t 0 | Out-Null
     } catch {
         Log-ErrorAndStopScript "Failed to revert changes and reboot to normal mode. Error: $_"
     }
 }
 
 # Main script execution
 try {
     # Perform pre-flight checks
     Perform-PreFlightChecks
 
     Write-Log "Starting setup for Safe Mode operations with Networking."
 
     # Check if the marker file exists
     $inSafeMode = Test-Path $MarkerFile
 
     if ($inSafeMode) {
         Write-Log "System was previously in Safe Mode. Executing Safe Mode steps."
         Execute-SafeModeSteps
     } else {
         Write-Log "System is not in Safe Mode. Continuing with normal operation."
 
         # Perform initial setup in normal mode
         Set-AutoLogin -Username $Username -Password $Password
         Backup-WinlogonRegistry
         Set-SafeBootWithNetworking
         Add-WinlogonScript
         Create-MarkerFile
     }
 
     # Only reboot if all steps were successful
     if ($StepsSuccessful) {
         Write-Log "All steps executed successfully. System will now reboot to apply changes."
         Restart-Computer -Force
     } else {
         Write-Log "One or more steps failed. Reverting changes and rebooting to normal mode."
         Revert-ChangesAndReboot
     }
 } catch {
     Write-Log "Script execution halted due to an error: $_"
 } 
 