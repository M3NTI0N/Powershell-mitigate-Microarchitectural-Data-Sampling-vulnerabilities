###########################
######## Variables ########
###########################
$KBs = @("KB4499154", "KB4494440", "KB4499181", "KB4499179", "KB4499167", "KB4494441", "KB4497936", "KB4499164","KB4499175", "KB4499151", "KB4499165", "KB4499164", "KB4499175", "KB4499164", "KB4499175", "KB4499171", "KB4499158", "KB4499171", "KB4499158", "KB4499151", "KB4499165", "KB4499151", "KB4499165", "KB4494440", "KB4494440", "KB4494441", "KB4494441", "KB4499167", "KB4497936")
$Installed = Get-HotFix
$patched = "0"

##############################
######## Update Check ########
##############################
Foreach ($install in $installed) {
    if ($KBs -contains $install.HotFixID) {
        $patched = "1"
        $patchedver = $($install.HotFixID)
    }
}
if ($patched -eq "1") {
    Write-Output "This machine has been patched."
} else {
    Write-Output "This machine is not patched."
}