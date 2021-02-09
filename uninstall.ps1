#Requires -Version 7
$isOld = $false
if ((Test-Path "Registry::HKEY_CLASSES_ROOT\Directory\shell\MenuTerminal") -and
    -not (Test-Path "Registry::HKEY_CURRENT_USER\SOFTWARE\Classes\Directory\shell\MenuTerminal")) {
    $isOld = $true
    Write-Host 'Detect Old version install.'
}

$localCache = "$Env:LOCALAPPDATA\Microsoft\WindowsApps\Cache"
if (Test-Path $localCache) {
    Remove-Item $localCache -Recurse
}

$rootKey = $isOld ? 'HKEY_CLASSES_ROOT\Directory\shell' 
                  : 'HKEY_CURRENT_USER\SOFTWARE\Classes\Directory\shell' 
foreach ($key in Get-ChildItem -Path "Registry::$rootKey") {
    if ($key.Name -like "$rootKey\MenuTerminal*") {
        Remove-Item "Registry::$key" -Recurse -ErrorAction Ignore | Out-Null
        Write-Host "Deleted `"$key`""
    }
}

$rootKey = $isOld ? 'HKEY_CLASSES_ROOT\Directory\Background\shell' 
                  : 'HKEY_CURRENT_USER\SOFTWARE\Classes\Directory\Background\shell'
foreach ($key in Get-ChildItem -Path "Registry::$rootKey") {
    if ($key.Name -like "$rootKey\MenuTerminal*") {
        Remove-Item "Registry::$key" -Recurse -ErrorAction Ignore | Out-Null
        Write-Host "Deleted `"$key`""
    }
}

$rootKey = $isOld ? 'HKEY_CLASSES_ROOT\Directory\ContextMenus' 
                  : 'HKEY_CURRENT_USER\SOFTWARE\Classes\Directory\ContextMenus'
foreach ($key in Get-ChildItem -Path "Registry::$rootKey") {
    if ($key.Name -like "$rootKey\MenuTerminal*") {
        Remove-Item "Registry::$key" -Recurse -ErrorAction Ignore | Out-Null
        Write-Host "Deleted `"$key`""
    }
}

Write-Host "`nWindows Terminal 启动项已经从资源管理器右键菜单移除。"
