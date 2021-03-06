﻿###########################
######## Variables ########
###########################
$downloadfolder = "C:\milo\temp\WindowsUpdates\"
$logfile = "$downloadfolder\MDSUpdate.log"
$KBs = @("KB4499154", "KB4494440", "KB4499181", "KB4499179", "KB4499167", "KB4494441", "KB4497936", "KB4499164","KB4499175", "KB4499151", "KB4499165", "KB4499164", "KB4499175", "KB4499164", "KB4499175", "KB4499171", "KB4499158", "KB4499171", "KB4499158", "KB4499151", "KB4499165", "KB4499151", "KB4499165", "KB4494440", "KB4494440", "KB4494441", "KB4494441", "KB4499167", "KB4497936")
$Installed = Get-HotFix
$patched = "0"
$computername = $env:computername
$versionbuild = (Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion" -Name ReleaseId).ReleaseId
$bitver = (gwmi win32_operatingsystem | select osarchitecture).osarchitecture
$logdate = Get-Date -UFormat "%d-%m-%Y - %I:%M:%S"

##########################
######## Logging: ########
##########################
Function createLog($computername, $versionbuild, $bitver, $patched, $patchedver)
{
	Write-Output "********************************************************"
	Write-Output "** MDS Update check ran with the following variables: **"
	Write-Output "********************************************************"
	Write-Output "**************** $logdate *****************"
	Write-Output "********************************************************"
	Write-Output "** Computername: $computername"
    if ($versionbuild) {
        Write-Output "** Version Build: $versionbuild"
    }
    if ($bitver) {
        Write-Output "** Version Build: $bitver"
    }
    if ($patched -eq "1") { 
        Write-Output "** Patched status: Patched"
    }
    else { 
        Write-Output "** Patched status: Unpatched"
    }
    if ($patchedver) {
        Write-Output "** Patched by: $patchedver"
    }
	Write-Output "********************************************************"
	Write-Output "******************* Script Output **********************"
	Write-Output "********************************************************"
}


##############################
######## Update Check ########
##############################
Foreach ($install in $installed) {
    if ($KBs -contains $install.HotFixID) {
        Write-Host "$($install.HotFixID) - patched the system"
        $patched = "1"
        $patchedver = $($install.HotFixID)
    }
}
if ($patched -eq "1") {
    Write-Host "This machine has been patched." -ForegroundColor Green
    createLog -computername $computername -patched $patched -patchedver $patchedver -versionbuild $versionbuild -bitver $bitver | Out-File -filepath $logfile -Append -NoClobbe
} else {
    Write-Host "This machine is not patched." -ForegroundColor Red
    createLog -computername $computername -patched $patched -versionbuild $versionbuild -bitver $bitver | Out-File -filepath $logfile -Append -NoClobbe
}

if (!(Test-Path $env:systemroot\SysWOW64\wusa.exe)){
  $Wus = "$env:systemroot\System32\wusa.exe"
}
else {
  $Wus = "$env:systemroot\SysWOW64\wusa.exe"
}


###########################
######## Functions ########
###########################

Function CreateDownFolder($downloadfolder) {
    Try {
        Add-Content $logfile "$logdate - [$computername] - [CreateFolders] Creating download folder!"
        $createdownloadfolder = New-Item -Path "$downloadfolder" -ItemType Directory
    }
    Catch {
        $ErrorMessage = $_.Exception.Message
        Write-Host "[$computername] - [CreateFolders] <font color='red'>Errors found during attempt:`n$_</font><br>"
        Add-Content $logfile "$logdate - [$computername] - [CreateFolders] Errors found during attempt:`n$_"
        BREAK
    }
    Finally {
        if (!$ErrorMessage) {
            Add-Content $logfile "$logdate - [$computername] - [CreateFolders] Created download folder: $createdownloadfolder"
        }
    }
    Try {
        Add-Content $logfile "$logdate - [$computername] - [CreateFolders] Creating log folder!"
        $createlogfolder = New-Item -Path "$downloadfolder\logs" -ItemType Directory
    }
    Catch {
        $ErrorMessage = $_.Exception.Message
        Write-Host "[$computername] - [CreateFolders] <font color='red'>Errors found during attempt:`n$_</font><br>"
        Add-Content $logfile "$logdate - [$computername] - [CreateFolders] Errors found during attempt:`n$_"
        BREAK
    }
    Finally {
        if (!$ErrorMessage) {
            Add-Content $logfile "$logdate - [$computername] - [CreateFolders] Created log folder: $createlogfolder"
        }
    }
}
Function DownloadUpdate($downloadURL) {
    Try {
        Add-Content $logfile "$logdate - [$computername] - [DownloadUpdate] Downloading MDS update!"
        $downloadupdate = Invoke-WebRequest -Uri $downloadURL -OutFile "$downloadfolder\WindowsUpdate.msu"
    }
    Catch {
        $ErrorMessage = $_.Exception.Message
        Write-Host "[$computername] - [DownloadUpdate] <font color='red'>Errors found during attempt:`n$_</font><br>"
        Add-Content $logfile "$logdate - [$computername] - [DownloadUpdate] Errors found during attempt:`n$_"
        BREAK
    }
    Finally {
        if (!$ErrorMessage) {
            Add-Content $logfile "$logdate - [$computername] - [DownloadUpdate] Downloaded Update: $downloadupdate"
        }
    }
}
Function InstallUpdate() {
    Try {
        Add-Content $logfile "$logdate - [$computername] - [InstallUpdate] Installing MDS update!"
        $downloadupdate = Start-Process -FilePath $Wus -ArgumentList ("$downloadfolder\WindowsUpdate.msu", '/quiet', '/norestart', "/log:$downloadfolder\logs\WindowsUpdate.log") -Wait
    }
    Catch {
        $ErrorMessage = $_.Exception.Message
        Write-Host "[$computername] - [InstallUpdate] <font color='red'>Errors found during attempt:`n$_</font><br>"
        Add-Content $logfile "$logdate - [$computername] - [InstallUpdate] Errors found during attempt:`n$_"
        BREAK
    }
    Finally {
        if (!$ErrorMessage) {
            Add-Content $logfile "$logdate - [$computername] - [InstallUpdate] Installed Update: $downloadupdate"
        }
    }
}


#######################################
######## Update if not patched ########
#######################################
Write-Host $versionbuild
if ($patched -eq "0") {
    if ($versionbuild -eq "1903") {
        Add-Content $logfile "$logdate - [$computername] - [CreateFolders] Initiating 'CreateDownloadFolder -downloadfolder $downloadfolder'"
        CreateDownFolder -downloadfolder $downloadfolder
        if ($bitver -eq "64-bit") {
            #64 bit logic here
            $url = "http://download.windowsupdate.com/c/msdownload/update/software/secu/2019/05/windows10.0-kb4497936-x64_4ac9328bb1376d2cadb09f56ba95ac9b08b88fba.msu"
            Write "x64"
            Add-Content $logfile "$logdate - [$computername] - [DownloadUpdate] Initiating 'DownloadUpdate -downloadURL $url'"
            DownloadUpdate -downloadURL $url
            Add-Content $logfile "$logdate - [$computername] - [InstallUpdate] Initiating 'InstallUpdate'"
            InstallUpdate
        }
        else {
            #32 bit logic here
            $url = "http://download.windowsupdate.com/c/msdownload/update/software/secu/2019/05/windows10.0-kb4497936-x86_2d93313d2c7e6e6feca5e974abe6f67dbd8e9394.msu"
            Write "x86"
            Add-Content $logfile "$logdate - [$computername] - [DownloadUpdate] Initiating 'DownloadUpdate -downloadURL $url'"
            DownloadUpdate -downloadURL $url
            Add-Content $logfile "$logdate - [$computername] - [InstallUpdate] Initiating 'InstallUpdate'"
            InstallUpdate
        }
    }
    if ($versionbuild -eq "1809") {
        CreateDownFolder -downloadfolder $downloadfolder
        if ($bitver -eq "64-bit") {
            #64 bit logic here
            $url = "http://download.windowsupdate.com/c/msdownload/update/software/secu/2019/05/windows10.0-kb4494441-x64_8910e3c3ee2743e9ff1241557a5c447ef853f495.msu"
            Write "x64"
            Add-Content $logfile "$logdate - [$computername] - [DownloadUpdate] Initiating 'DownloadUpdate -downloadURL $url'"
            DownloadUpdate -downloadURL $url
            Add-Content $logfile "$logdate - [$computername] - [InstallUpdate] Initiating 'InstallUpdate'"
            InstallUpdate
        }
        else {
            #32 bit logic here
            $url = "http://download.windowsupdate.com/d/msdownload/update/software/secu/2019/05/windows10.0-kb4494441-x86_83f1e00d2082f615d52e2b2b73d2a065f9ad71a7.msu"
            Write "x86"
            Add-Content $logfile "$logdate - [$computername] - [DownloadUpdate] Initiating 'DownloadUpdate -downloadURL $url'"
            DownloadUpdate -downloadURL $url
            Add-Content $logfile "$logdate - [$computername] - [InstallUpdate] Initiating 'InstallUpdate'"
            InstallUpdate
        }
    }
    if ($versionbuild -eq "1803") {
        CreateDownFolder -downloadfolder $downloadfolder
        if ($bitver -eq "64-bit") {
            #64 bit logic here
            $url = "http://download.windowsupdate.com/c/msdownload/update/software/secu/2019/05/windows10.0-kb4499167-x64_23697fcf76f2d755b492415eb89aa573c8804765.msu"
            Write "x64"
            Add-Content $logfile "$logdate - [$computername] - [DownloadUpdate] Initiating 'DownloadUpdate -downloadURL $url'"
            DownloadUpdate -downloadURL $url
            Add-Content $logfile "$logdate - [$computername] - [InstallUpdate] Initiating 'InstallUpdate'"
            InstallUpdate
        }
        else {
            #32 bit logic here
            $url = "http://download.windowsupdate.com/c/msdownload/update/software/secu/2019/05/windows10.0-kb4499167-x86_d7157d185683e47ed0b45c911aeae7d44f944f5e.msu"
            Write "x86"
            Add-Content $logfile "$logdate - [$computername] - [DownloadUpdate] Initiating 'DownloadUpdate -downloadURL $url'"
            DownloadUpdate -downloadURL $url
            Add-Content $logfile "$logdate - [$computername] - [InstallUpdate] Initiating 'InstallUpdate'"
            InstallUpdate
        }
    }
    if ($versionbuild -eq "1709") {
        CreateDownFolder -downloadfolder $downloadfolder
        if ($bitver -eq "64-bit") {
            #64 bit logic here
            $url = "http://download.windowsupdate.com/c/msdownload/update/software/secu/2019/05/windows10.0-kb4499179-x64_d3751b768e6e533a0d9a14cc16747b2c2d69f949.msu"
            Write "x64"
            Add-Content $logfile "$logdate - [$computername] - [DownloadUpdate] Initiating 'DownloadUpdate -downloadURL $url'"
            DownloadUpdate -downloadURL $url
            Add-Content $logfile "$logdate - [$computername] - [InstallUpdate] Initiating 'InstallUpdate'"
            InstallUpdate
        }
        else {
            #32 bit logic here
            $url = "http://download.windowsupdate.com/c/msdownload/update/software/secu/2019/05/windows10.0-kb4499179-x86_d8ba729b15c7f3208b404dd2ce1a20533ad10ce7.msu"
            Write "x86"
            Add-Content $logfile "$logdate - [$computername] - [DownloadUpdate] Initiating 'DownloadUpdate -downloadURL $url'"
            DownloadUpdate -downloadURL $url
            Add-Content $logfile "$logdate - [$computername] - [InstallUpdate] Initiating 'InstallUpdate'"
            InstallUpdate
        }
    }
    if ($versionbuild -eq "1703") {
        CreateDownFolder -downloadfolder $downloadfolder
        if ($bitver -eq "64-bit") {
            #64 bit logic here
            $url = "http://download.windowsupdate.com/c/msdownload/update/software/secu/2019/05/windows10.0-kb4499181-x64_c4a9019ea375860fb7745d465336ed7e387871e3.msu"
            Write "x64"
            Add-Content $logfile "$logdate - [$computername] - [DownloadUpdate] Initiating 'DownloadUpdate -downloadURL $url'"
            DownloadUpdate -downloadURL $url
            Add-Content $logfile "$logdate - [$computername] - [InstallUpdate] Initiating 'InstallUpdate'"
            InstallUpdate
        }
        else {
            #32 bit logic here
            $url = "http://download.windowsupdate.com/c/msdownload/update/software/secu/2019/05/windows10.0-kb4499181-x86_5b1c93e2876be1708e50dc03dedfe9aabf8d85c6.msu"
            Write "x86"
            Add-Content $logfile "$logdate - [$computername] - [DownloadUpdate] Initiating 'DownloadUpdate -downloadURL $url'"
            DownloadUpdate -downloadURL $url
            Add-Content $logfile "$logdate - [$computername] - [InstallUpdate] Initiating 'InstallUpdate'"
            InstallUpdate
        }
    }
    if ($versionbuild -eq "1607") {
        CreateDownFolder -downloadfolder $downloadfolder
        if ($bitver -eq "64-bit") {
            #64 bit logic here
            $url = "http://download.windowsupdate.com/c/msdownload/update/software/secu/2019/05/windows10.0-kb4494440-x64_390f926659a23a56cc9cbb331e5940e132ad257d.msu"
            Write "x64"
            Add-Content $logfile "$logdate - [$computername] - [DownloadUpdate] Initiating 'DownloadUpdate -downloadURL $url'"
            DownloadUpdate -downloadURL $url
            Add-Content $logfile "$logdate - [$computername] - [InstallUpdate] Initiating 'InstallUpdate'"
            InstallUpdate
        }
        else {
            #32 bit logic here
            $url = "http://download.windowsupdate.com/c/msdownload/update/software/secu/2019/05/windows10.0-kb4494440-x86_5d118db43440bcbe1bb142e9eaf0004726517720.msu"
            Write "x86"
            Add-Content $logfile "$logdate - [$computername] - [DownloadUpdate] Initiating 'DownloadUpdate -downloadURL $url'"
            DownloadUpdate -downloadURL $url
            Add-Content $logfile "$logdate - [$computername] - [InstallUpdate] Initiating 'InstallUpdate'"
            InstallUpdate
        }
    }
    if ($versionbuild -eq "1507") {
        CreateDownFolder -downloadfolder $downloadfolder
        if ($bitver -eq "64-bit") {
            $url = "http://download.windowsupdate.com/c/msdownload/update/software/secu/2019/05/windows10.0-kb4499154-x64_89080f533990e07678ad67141dfae65fe3150624.msu"
            Write "x64"
            Add-Content $logfile "$logdate - [$computername] - [DownloadUpdate] Initiating 'DownloadUpdate -downloadURL $url'"
            DownloadUpdate -downloadURL $url
            Add-Content $logfile "$logdate - [$computername] - [InstallUpdate] Initiating 'InstallUpdate'"
            InstallUpdate
        } else {
            $url = "http://download.windowsupdate.com/c/msdownload/update/software/secu/2019/05/windows10.0-kb4499154-x86_d1d1da33e3b5a5863cfece4357285f7e2f1293fb.msu"
            Write "x86"
            Add-Content $logfile "$logdate - [$computername] - [DownloadUpdate] Initiating 'DownloadUpdate -downloadURL $url'"
            DownloadUpdate -downloadURL $url
            Add-Content $logfile "$logdate - [$computername] - [InstallUpdate] Initiating 'InstallUpdate'"
            InstallUpdate
        }
    }
    if ("1507","1607","1703","1709","1803","1809","1903" -notcontains $versionbuild) {
        Add-Content $logfile "$logdate - [$computername] - [UnableToUpdate] Unable to update this windows version: '$versionbuild - $bitver'"
        Write-Host "No mitigation from OS possible"
    }
}
