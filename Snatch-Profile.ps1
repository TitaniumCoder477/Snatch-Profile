#C:\PS> . .\Snatch-Profile.ps1
#C:\PS> Get-Help Snatch-Profile -Full | more
function Snatch-Profile {
<#
	.SYNOPSIS 
	Copies the sub-folders of a Windows user profile into a different location or into a zip

	.DESCRIPTION
	Copies sub-folders from a local or remote profile into a local or remote path or zip file.
	Works with folder redirection and offline files. *
	Looks for non-standard folders within the remote or local profile and prompt.
	Produces detailed OSD and log files.
	Utilizes Robocopy for the copy.
	Utilizes 7z.exe for the compress to zip file.
	
	*Only if run locally and within the user's profile
	
	.PARAMETER src
	Specifies the source local or remote path.

	.PARAMETER dst
	Specifies the destination local or remote path.
	
	.PARAMETER zip
	If included, will copy sub-folders into compressed zip files rather than folders.
	
	.PARAMETER nst
	If included, will search for non-standard sub-folders and and prompt for inclusion.
	
	.PARAMETER nst
	If included, will create log files at this path.

	.INPUTS
	None. You cannot pipe objects to Snatch-Profile.

	.OUTPUTS
	None. 

	.EXAMPLE
	C:\PS> Snatch-Profile -src c:\users\jdoe -dst \\newcomp\c$\users\jdoe -log c:\temp		

	.EXAMPLE
	C:\PS> Snatch-Profile -src \\oldcomp\c$\users\jdoe -dst \\newcomp\c$\users\jdoe -log c:\temp
	
	.EXAMPLE
	C:\PS> Snatch-Profile -src \\oldcomp\c$\users\jdoe -dst \\nas\profilebackups\jdoe -zip -log c:\temp

	.EXAMPLE
	C:\PS> Snatch-Profile -src c:\users\jdoe -dst \\nas\profilebackups\jdoe -nst -log c:\temp

	.NOTES
		MIT License

		Copyright (c) 2017 James Wilmoth

		Permission is hereby granted, free of charge, to any person obtaining a copy
		of this software and associated documentation files (the "Software"), to deal
		in the Software without restriction, including without limitation the rights
		to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
		copies of the Software, and to permit persons to whom the Software is
		furnished to do so, subject to the following conditions:

		The above copyright notice and this permission notice shall be included in all
		copies or substantial portions of the Software.

		THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
		IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
		FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
		AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
		LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
		OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
		SOFTWARE.
		
	.LINK
	https://github.com/TitaniumCoder477/ProfileSnatcher
	
	.LINK
	http://opensource.org/licenses/MIT
	
#>
	param(
		[parameter(Position=1,Mandatory=$True)][String]$src,
		[parameter(Position=2,Mandatory=$True)][String]$dst,
		[parameter(Position=3,Mandatory=$False)][switch]$zip,
		[parameter(Position=4,Mandatory=$False)][switch]$nst,
		[parameter(Position=5,Mandatory=$False)][String]$log
	)
	
	#Change Continue to SilentlyContinue to disable output
	$VerbosePreference = "Continue"

	#Setup color coding
	$a = (Get-Host).PrivateData
	$a.WarningBackgroundColor = "red"
	$a.WarningForegroundColor = "white"

	#Start a log file if requested
	if($log) {
		if((Test-Path $log -PathType Container) -eq $False) {
			New-Item $log -type directory
		}
		Start-Transcript -Path "$log\results.log"
	}

	try {
		
		#Make sure source exists
		if((Test-Path $src -PathType Container) -eq $False) {		
			Write-Warning ("> Source path {0} does not exist!" -f $src)			
			throw ("> Aborting...")		
		}
		
		#Make sure destination exists
		if((Test-Path $dst -PathType Container) -eq $False) {		
			Write-Warning ("> Destination path {0} does not exist!" -f $dst)			
			throw ("> Aborting...")		
		}
		
		#Determine if this function was called on the computer in question or remotely
		$thiscomputer = $env:computername
		$thisuser = $env:username		
		Write-Verbose ""
		Write-Verbose("This workstation is {0} and this user is {1}." -f $thiscomputer,$thisuser)
		if(($src.Contains(":\")) -and ($src.ToLower().Contains($thisuser))) {
			Write-Verbose("> You are running this command on the source computer and within the source user profile.")
			Write-Verbose("> Therefore, testing for redirected folders and offline files...")
			
			#Logic goes here to identifiy common source path sub-folders that might be redirected
			$paths = @()			
			$paths += "Desktop"
			$paths += "Programs"
			$paths += "MyDocuments"
			$paths += "Personal"
			$paths += "Favorites"
			$paths += "Startup"
			$paths += "Recent"
			$paths += "SendTo"
			$paths += "StartMenu"
			$paths += "MyMusic"
			$paths += "MyVideos"
			$paths += "DesktopDirectory"
			$paths += "MyComputer"
			$paths += "NetworkShortcuts"
			$paths += "Fonts"
			$paths += "Templates"
			$paths += "CommonStartMenu"
			$paths += "CommonPrograms"
			$paths += "CommonStartup"
			$paths += "CommonDesktopDirectory"
			$paths += "ApplicationData"
			$paths += "PrinterShortcuts"
			$paths += "LocalApplicationData"
			$paths += "InternetCache"
			$paths += "Cookies"
			$paths += "History"
			$paths += "CommonApplicationData"
			$paths += "Windows"
			$paths += "System"
			$paths += "ProgramFiles"
			$paths += "MyPictures"
			$paths += "UserProfile"
			$paths += "SystemX86"
			$paths += "ProgramFilesX86"
			$paths += "CommonProgramFiles"
			$paths += "CommonProgramFilesX86"
			$paths += "CommonTemplates"
			$paths += "CommonDocuments"
			$paths += "CommonAdminTools"
			$paths += "AdminTools"
			$paths += "CommonMusic"
			$paths += "CommonPictures"
			$paths += "CommonVideos"
			$paths += "Resources"
			$paths += "LocalizedResources"
			$paths += "CommonOemLinks"
			$paths += "CDBurning"
			
			$count = 0
			Write-Verbose ""
			Write-Verbose ("Checking for redirected folders for {0}..." -f $thisuser)
			foreach($path in $paths) {				
				$result = [environment]::getfolderpath($path)
				if($result.StartsWith("\\") -eq $True) {
					Write-Warning ("> {0} is redirected to {1}..." -f $path,$result)							
					$count++
				} else {
					Write-Verbose ("> {0} is pointing to {1}..." -f $path,$result)		
				}
			}			
			if($count > 0) {
				Write-Warning ("> {0} folders were found to be redirected!" -f $count)							
			} else {
				Write-Verbose ("> No folders redirected.")		
			}

			Write-Verbose ""
			Write-Verbose ("Checking for offline files status for {0}..." -f $thisuser)
			$cache = Get-WmiObject -Class "Win32_OfflineFilesCache"	
			$result = ($cache.Enabled -eq $True)
			if($result) {
				Write-Warning ("> Offline files is enabled!")								
				$wmiCSC = [wmiclass]"Win32_OfflineFilesCache"
				$wmiCSC = [wmiclass]"Win32_OfflineFilesItem"
				$wmiCSC | Select-Object -Property *
				<#
				foreach($path in $paths) {			
					Write-Verbose ("Attempting to force sync on {0}..." -f "\\dc2\redirectedfolders$\$thisuser\$path")
					$result = $wmiCSC.Synchronize("\\dc2\redirectedfolders$\$thisuser\$path")
					Write-Verbose ("> Result = {0}" -f $result.ReturnValue)
					if($result.ReturnValue -eq 0) {
						Write-Verbose ("> Success")
					} else {
						Write-Warning ("> FAILED")
					} 
				}
				#>
				
			} else {
				Write-Verbose ("> Offline files is not enabled.")
			}				
		} else {
			Write-Verbose("> You are NOT running this command on the source computer and within the source user profile...")
		}
		
		#Common user profile sub-folders
		# NOTE: Comment out ones you do NOT wish to copy
		$paths = @()
		$paths += "AppDataRoaming"
		$paths += "Desktop"
		#$paths += "StartMenu"
		$paths += "Pictures"
		$paths += "Music"
		$paths += "Videos"
		$paths += "Favorites"
		$paths += "Contacts"
		$paths += "Downloads"
		#$paths += "Links"
		#$paths += "Searches"
		#$paths += "SavedGames"
		$paths += "Documents"
		
		#Optional compress to single zip file
		if($zip) {
			Write-Verbose ""
			Write-Verbose ("You requested a zip file!")
			
			#Zip user profile sub-folders to destination
			Write-Verbose ""
			Write-Verbose ("Zipping user folders...")
			try {				
				
				foreach($path in $paths) {
					
					Write-Verbose ("Zipping files for {0}..." -f $path)
					switch ($path) {
						"AppDataRoaming" {
							$srcFolder = [environment]::getfolderpath("ApplicationData")							
							break						
						}
						"Desktop" {
							$srcFolder = [environment]::getfolderpath($path)							
							break						
						}
						"StartMenu" {
							$srcFolder = [environment]::getfolderpath($path)							
							break						
						}
						"Pictures" {
							$srcFolder = [environment]::getfolderpath("MyPictures")
							break						
						}
						"Music" {
							$srcFolder = [environment]::getfolderpath("MyMusic")
							break						
						}
						"Videos" {
							$srcFolder = [environment]::getfolderpath("MyVideos")
							break						
						}
						"Favorites" {
							$srcFolder = [environment]::getfolderpath($path)							
							break						
						}
						"Contacts" { 
							$srcFolder = [environment]::getfolderpath("UserProfile")
							$srcFolder += "\Contacts"
							break; 
						}
						"Downloads" {
							$srcFolder = [environment]::getfolderpath("UserProfile")
							$srcFolder += "\Downloads"
							break; 
						}
						"Links" {
							$srcFolder = [environment]::getfolderpath("UserProfile")
							$srcFolder += "\Links"
							break; 
						}
						"Searches" {
							$srcFolder = [environment]::getfolderpath("UserProfile")
							$srcFolder += "\Searches"
							break; 
						}
						"SavedGames" { 
							$srcFolder = [environment]::getfolderpath("UserProfile")
							$srcFolder += "\SavedGames"
							break; 
						}
						"Documents" { 
							$srcFolder = [environment]::getfolderpath("MyDocuments")
							break
						}
					}
										
					if((Test-Path "$srcFolder") -and (Test-Path "$dst")) {
						#Write-Verbose ("> .\res\7z\7z.exe a {0}\{1}.zip {2}\ > {0}\{1}.log..." -f $dst,$path,$srcFolder)
						& '.\res\7z\7z.exe' a $dst\$path.zip $srcFolder\ > $dst\$path.log
						Write-Verbose ("> See log file {0}\{1}.log" -f $dst,$path)
					} else {
						if((Test-Path "$srcFolder") -eq $False) {
							Write-Warning ("> Failed to copy {0} due to source folder {1} not existing..." -f $path,$srcFolder)
						} elseif ((Test-Path "$dst") -eq $False) {
							Write-Warning ("> Failed to copy {0} due to destination folder {1} not existing..." -f $path,$dst)
						} else {
							Write-Warning ("> Failed to copy {0} due to unknown reason..." -f $path)
						}
					}					
				}
				
			} catch {
				Write-Warning $_.Exception.Message					
			}
		
			#Optional search for non-standard sub-folders
			if($nst) {
				Write-Verbose ""
				Write-Verbose ("You requested a search for non-standard sub-folders!")
			}
			
		} else {
			Write-Verbose ""
			Write-Verbose ("You did not request a zip file.")
			
			#Create user profile sub-folders in destination			
			Write-Verbose ""
			Write-Verbose ("Creating user folders...")
			foreach($path in $paths) {				
				$subfolder = "$dst\$path"
				Write-Verbose ("> {0}..." -f $subfolder)
				try {			
					New-Item "$subfolder" -Type directory
					if((Test-Path "$subfolder") -eq $False) {
						throw ("> Sub-folder does not exist and could not be created!")
					}				
				} catch {
					Write-Warning $_.Exception.Message					
				}
			}
			
			#Copy user profile sub-folders to destination
			Write-Verbose ""
			Write-Verbose ("Copying user folders...")
			try {				
				
				foreach($path in $paths) {
					
					Write-Verbose ("Copying files for {0}..." -f $path)
					switch ($path) {
						"AppDataRoaming" {
							$srcFolder = [environment]::getfolderpath("ApplicationData")							
							break						
						}
						"Desktop" {
							$srcFolder = [environment]::getfolderpath($path)							
							break						
						}
						"StartMenu" {
							$srcFolder = [environment]::getfolderpath($path)							
							break						
						}
						"Pictures" {
							$srcFolder = [environment]::getfolderpath("MyPictures")
							break						
						}
						"Music" {
							$srcFolder = [environment]::getfolderpath("MyMusic")
							break						
						}
						"Videos" {
							$srcFolder = [environment]::getfolderpath("MyVideos")
							break						
						}
						"Favorites" {
							$srcFolder = [environment]::getfolderpath($path)							
							break						
						}
						"Contacts" { 
							$srcFolder = [environment]::getfolderpath("UserProfile")
							$srcFolder += "\Contacts"
							break; 
						}
						"Downloads" {
							$srcFolder = [environment]::getfolderpath("UserProfile")
							$srcFolder += "\Downloads"
							break; 
						}
						"Links" {
							$srcFolder = [environment]::getfolderpath("UserProfile")
							$srcFolder += "\Links"
							break; 
						}
						"Searches" {
							$srcFolder = [environment]::getfolderpath("UserProfile")
							$srcFolder += "\Searches"
							break; 
						}
						"SavedGames" { 
							$srcFolder = [environment]::getfolderpath("UserProfile")
							$srcFolder += "\SavedGames"
							break; 
						}
						"Documents" { 
							$srcFolder = [environment]::getfolderpath("MyDocuments")
							break
						}
					}
					
					$dstFolder = "$dst\$path"
					if((Test-Path "$srcFolder") -and (Test-Path "$dstFolder")) {
						robocopy $srcFolder $dstFolder * /MIR /R:0 /W:0 /NP /TEE /LOG:$dst\$path.log
						Write-Verbose ("> See log file {0}\{1}.log..." -f $dst,$path)
					} else {
						if((Test-Path "$srcFolder") -eq $False) {
							Write-Warning ("> Failed to copy {0} due to source folder {1} not existing..." -f $path,$srcFolder)
						} elseif ((Test-Path "$dstFolder") -eq $False) {
							Write-Warning ("> Failed to copy {0} due to destination folder {1} not existing..." -f $path,$dstFolder)
						} else {
							Write-Warning ("> Failed to copy {0} due to unknown reason..." -f $path)
						}
					}					
				}
				
			} catch {
				Write-Warning $_.Exception.Message					
			}
		
			#Optional search for non-standard sub-folders
			if($nst) {
				Write-Verbose ""
				Write-Verbose ("You requested a search for non-standard sub-folders!")
			}
			
		}	
	
	} catch {
		Write-Warning $_.Exception.Message
		Write-Verbose "For help, type: Get-Help Snatch-Profile -Full | more"
	}
	
	if($log) {
		Stop-Transcript
	}
}
<#
Write-Verbose("Sending email...")
\\PDC\syncOfflineCacheSimpl$\sendemail.exe -f $thisworkstation@bitechnologysolutions.com -s exchange.biztechnologysolutions.com:25 -t jwilmoth@biztechnologysolutions.com -u NEDH Sync Offline Files Issue -m Please review the attached log file. -a results.log
#>