# Audix

[![GitHub license](https://img.shields.io/github/license/Naereen/StrapDown.js.svg)](https://github.com/Naereen/StrapDown.js/blob/master/LICENSE)

**Audix** is a PowerShell tool to correctly configure Windows Audit Policies for security monitoring.

Audix will allow for the SIMPLE configuration of Windows Event Audit Policies. Window's Audit Policies are restricted by default. This means that for Blue Teamers, CISO's & people looking to monitor their environment through use of Windows Event Logs, must configure the audit policy settings to provide more advanced logging. 

This utility, aims to capture the current audit policy setting, perform a backup of it (incase a restore to previous state is required) and apply a more advanced Audit Policy setting to allow for better detection capability. 

**Please note, these settings may be altered if GPO settings override* 
(I'm working on a GPO script for this)

Some examples of enabled policy settings that Audix will enable:

-Event ID: 4698-4702	(A scheduled task was created/updated/disabled)

-Event ID: 4688	(A new process has been created.)

    _______       _____________          
    _______       _____________          
    ___    |___  _______  /__(_)___  __  
    __  /| |  / / /  __  /__  /__  |/_/  
    _  ___ / /_/ // /_/ / _  / __>  <    
    /_/  |_\__,_/ \__,_/  /_/  /_/|_| 

### Running Audix

Git Clone the repo
```
git clone https://github.com/littl3field/Audix.git
```
Navigate to the folder and execute the command in your terminal. You must ensure you have Administrator rights to do this.
```
.\Audix.ps1
```
### Development

- **I will be adding these settings as a priority**: 
    - Increase logging size limit ✓ (DONE)
    - Enforce audit policy subcategory setting  ✓ (DONE)
- Add restore option
- Add Script for deploying at scale
