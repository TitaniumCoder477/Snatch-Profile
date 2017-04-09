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
