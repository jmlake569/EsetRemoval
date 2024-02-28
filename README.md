# Safe Mode Setup Script Guide

## Introduction

This guide provides instructions on using the Safe Mode Setup Script. This script automates the process of preparing a Windows system for Safe Mode operations with Networking, performing essential tasks such as installing software, configuring system settings, and executing scripts.

## Script Details

The script consists of the following main components:

- **Pre-flight Checks**: Verifies administrator privileges and the existence of required files.
- **Setup Functions**: Functions to install the Vision One agent, configure auto-login, set Safe Mode with Networking, backup Winlogon registry, add script to Winlogon, and create a marker file.
- **Safe Mode Execution**: Executes Safe Mode steps, including ESET Uninstaller, resetting boot configuration, and removing AutoLogon configuration.
- **Reverting Changes**: Reverts changes and reboots the system to normal mode in case of errors.


## Prerequisites

Before using the Safe Mode Setup Script, ensure the following prerequisites are met:

- **Administrator Privileges**: You must log in to Windows with an account that has administrator privileges.
- **Required Software**: Ensure that the necessary software components are available on the system:
  - Vision One agent installer (`EndpointBasecamp.exe`) located at `C:\EsetRemoval\Trend\`
  - Secondary script (`boomarang.ps1`) located at `C:\EsetRemoval\`
  - ESET Uninstaller (`esetuninstaller.exe`) located at `C:\EsetRemoval\`

## Usage

1. **Download the Script**: Download the Safe Mode Setup Script to the target Windows system.

2. **Modify Variables**: Open the script file (`SafeModeSetup.ps1`) in a text editor and modify the following variables as per your environment:
   - `$Username`: Specify the username for automatic login.
   - `$Password`: Specify the password for automatic login.
   - `$LogFile`: Specify the path for the setup log file.
   - `$WinlogonRegistryBackupPath`: Specify the path for backing up the Winlogon registry key.
   - `$agentInstallerPath`: Specify the path for the Vision One agent installer.
   - `$SecondaryScriptPath`: Specify the path for the secondary script.
   - `$MarkerFile`: Specify the path for the marker file.
   - `$ESETUninstallerPath`: Specify the path for the ESET Uninstaller.

3. **Run the Script**: Right-click on the script file and select "Run with PowerShell" to execute the script. Alternatively, open PowerShell as an administrator and run the script using the following command:
   ```powershell
   .\SafeModeSetup.ps1

## Follow Instructions

The script will guide you through the setup process, performing pre-flight checks, configuring system settings, and executing required tasks. Follow the on-screen instructions and monitor the setup log for any errors.

## Reboot

After successful execution, the system will automatically reboot to apply changes. Ensure that all steps are completed successfully before the reboot.

## Troubleshooting

### Script Errors

If you encounter any errors during script execution, refer to the setup log file (`setupLog.txt`) for detailed error messages. You can also troubleshoot by checking the script code and ensuring that prerequisites are met.

### Reverting Changes

If the script encounters errors or fails to complete, it will automatically revert changes and reboot the system to normal mode. Review the setup log to identify the cause of failure and take appropriate action.