rem mkdir c:\backupUserProfile
rem robocopy \\PDC\backupUserProfile$ c:\backupUserProfile * /mir /r:0 /w:0
rem cd c:\backupUserProfile
Powershell.exe -executionpolicy remotesigned -File backupUserProfile.ps1