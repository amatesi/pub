<#
.SYNOPSIS
    Save Credentials to Encrypted File.

.DESCRIPTION
    This script prompts you for Credentials to save to an encrypted file.
    - You can specify a filename as a Parameter when running the script.
    
    If you don't specify a filename:
    1. The script will prompt you to enter a Custom filename.
    2. A Default Value for the filename is also provided (so you won't have to type anything - just press Enter to test it out!).

    Your encrypted Credential files will be saved in your User's Documents\"Credentials"-Folder.
    If the Credentials Folder Does Not Exist it'll be created.
    	If the "Credentials"-Folder already exists, it will not be overwritten.
	
    The builtin Microsoft Dot Net Data Protection API is used to encrypt the Credential File.

.PARAMETER [FileName]
    Optional filename Parameter can be specified during execution - this is the name of the file to which the credentials will be saved.

    This parameter is optional. If not provided, you will be prompted to specify a Custom filename.
        
    Filenames are tested for compliance with characters allowed by NTFS.
    
.OUTPUT
    - New User's Documents\"Credentials"-Folder created upon first execution.
    - Credentials Folder will not be overwritten if it already exists.
    - All Encrypted Credentials Files will be automatically saved within the Credentials Folder.

.EXAMPLE    
    .\SaveCredsToFile.ps1 Server01-FileName.ps1.credential
    This command saves your Credentials to the file "Server01-FileName.ps1.credential".

.EXAMPLE
    .\SaveCredsToFile.ps1
    This command prompts you to Enter a filename.
    If you just press Enter without typing anything, the credentials will be saved to the file "whatchamacallit.ps1.credential".

.NOTES
    The encrypted file can only be decrypted by the same user on the same computer where the file was created.
    The file cannot be used on a different computer or by a different user.

.AUTHOR
    Andrea Matesi
    Copilot

.DATE
    Created: 2023-Dec-22.

.LICENSE
    MIT License.

#>

Param (
  # Declare the $FileName parameter
  [Parameter(Mandatory=$false, ValueFromPipeline=$true)]
  #[ValidateLength(1, 255)] - no need, pattern includes this
  [ValidatePattern('^(?!^(CON|PRN|AUX|NUL|COM[1-9]|LPT[1-9]|CLOCK\$|RECOVER\.|SYSTEM\$|URL:|)$)[^\x00-\x1F\/\\:*?"<>|]{1,255}$')]
  [string]$FileName
)

function GetNTFSFileName {
    param (
        [Parameter(Mandatory=$false)]
        [string]$Prompt = "`nPlease enter a filename or press Enter to use the default filename [whatchamacallit.ps1.credential]"
    )
    $pattern = '^(?!^(CON|PRN|AUX|NUL|COM[1-9]|LPT[1-9]|CLOCK\$|RECOVER\.|SYSTEM\$|URL:|)$)[^\x00-\x1F\/\\:*?`"<>|]{1,255}$'
    do {
        $input = Read-Host -Prompt $Prompt
        if ($input -eq "") {
            return "whatchamacallit.ps1.credential"
        } elseif ($input -match $pattern) {
            return $input
        } else {
            Write-Host "`nInvalid filename. Please enter a valid filename."
        }
    } while ($true)
}

if (-not $FileName) {
    $FileName = GetNTFSFileName
}

Write-Host "`n - Save Credentials to Encrypted File on your `"Documents`" -> `"Credentials`"-SubFolder." -Foreground Green

Write-Host "`nSaved Credentials securely written to File Name `"$FileName`"."

Write-Host "`n`n`nUSAGE:`n`n.\SaveCredsToFile.ps1 Server01-FileName.ps1.credential"

Write-Host "`nOr simply type: `n`n.\SaveCredsToFile.ps1 (without params) `n`n...To save test creds to File Name eq `"whatchamacallit.ps1.credential`"!"

Write-Host "`nNOTE-1: *Only* your User Account And *Only on This Computer* you can Decrypt (Use) The Saved Credential File!" -ForegroundColor Red

Write-Host "`nNOTE-2: The `"$FileName`" *CAN'T Be Used on a Different Computer or by Another User*!!" -ForegroundColor Yellow

Write-Host "`nNOTE-3: Multiple Credentials can be saved - Simply pass Different File Names during each run!!!" -Foreground Green

do {
Write-Host "`nPress ENTER to Launch a New Credentials Prompt (popup window on WinPS, Creds Prompt on PS7+)."
    $input = Read-Host
} while ($input -ne "")

$Credential = $null


while ($Credential -eq $null) {
    $Credential = Get-Credential
    if ($Credential -eq $null) {
        Write-Host "`nNO CREDENTIALS SPECIFIED - Please Enter Valid Credentials to Save to `"$FileName`" File." -ForegroundColor Red
        Write-Host "`nOR`n`n- Type 'exit' (without quotes, case insensitive) to Stop Execution (Return to PS Prompt)." -ForegroundColor Green
        if (($response = Read-Host "`nDo you want to continue? Press Enter to try again.`n") -eq 'exit') {
            exit
        }
    }
}

$SavedCredsPath = [System.IO.Directory]::CreateDirectory([Environment]::GetFolderPath("MyDocuments") + "\Credentials")# | Out-Null

$DestinationFile = Join-Path -Path $SavedCredsPath.FullName -ChildPath $FileName

if (-not (Test-Path -Path $DestinationFile)) {
    
    try {
        $Credential | Export-Clixml $DestinationFile
        Write-Host "`nCredentials Successfully Exported to (location):`n$DestinationFile`n" -ForegroundColor Green
    } catch {
        Write-Host "Failed to export credentials.`nReason:`n $($_.Exception.Message)`n" -ForegroundColor Red
    }
    
} else  {
    
    Write-Host "`nThe File $DestinationFile Already Exists!" -ForegroundColor Red
	
    $Overwrite = $null
    while ($Overwrite -ne "Y" -and $Overwrite -ne "N") {
        $Overwrite = Read-Host "`nDo you want to Overwrite $DestinationFile (Y/N)?"
        if ($Overwrite -eq "Y") {
            try {
                $Credential | Export-Clixml $DestinationFile -Force
                Write-Host "`nCredentials Successfully Exported to (location):`n$DestinationFile`n" -ForegroundColor Green
            } catch {
                Write-Host "`nFailed to export credentials.`nReason:`n $($_.Exception.Message)`n" -ForegroundColor Red
            }
        } elseif ($Overwrite -eq "N") {
            Write-Host "`nCreds Not Saved - No changes made to $DestinationFile`n" -ForegroundColor Yellow
        } else {
            Write-Host "`nWrong Answer! Please Press Y or N (case insensitive).`n" -ForegroundColor Orange
        }
    }
}
