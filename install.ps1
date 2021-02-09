#Requires -RunAsAdministrator
#Requires -Version 7

[CmdletBinding()]
param(
    [Parameter(Position = 0)]
    [ValidateSet('Default', 'Flat', 'Mini')]
    [string] $Layout = 'Default',
    [Parameter()]
    [switch] $PreRelease,
    [Parameter()]
    [switch] $UseEnglish,
    [Parameter()]
    [switch] $Extended,
    [Parameter()]
    [ValidateSet('Both', 'OnlyUser', 'OnlyAdmin')]
    [string] $MenuType = 'Both'
)


# 生成帮助脚本
function Generate-HelperScript(
        # The cache folder
        [Parameter(Mandatory=$true)]
        [string]$cache) {
    $content = @'
Set shell = WScript.CreateObject("Shell.Application")
executable = WSCript.Arguments(0)
folder = WScript.Arguments(1)
If Wscript.Arguments.Count > 2 Then
    profile = WScript.Arguments(2)
    shell.ShellExecute "powershell", "Start-Process \""" & executable & _
    "\"" -ArgumentList \""-p \""\""" & profile & "\""\"" -d \""\""" & _
    folder & "\""\"" \"" ", "", "runas", 0
Else
    shell.ShellExecute "powershell", "Start-Process \""" & executable & _
    "\"" -ArgumentList \""-d \""\""" & folder & "\""\"" \"" ", "", "runas", 0
End If
'@
    Set-Content -Path "$cache/helper.vbs" -Value $content
}


# 获取 icon
# 源地址：https://github.com/Duffney/PowerShell/blob/master/FileSystems/Get-Icon.ps1
Function Get-Icon {

    [CmdletBinding()]
    Param ( 
        [Parameter(Mandatory=$True, Position=1, HelpMessage="Enter the location of the .EXE file")]
        [string]$File,

        # If provided, will output the icon to a location
        [Parameter(Position=1, ValueFromPipelineByPropertyName=$true)]
        [string]$OutputFile
    )

    [System.Reflection.Assembly]::LoadWithPartialName('System.Drawing')  | Out-Null
    [System.Drawing.Icon]::ExtractAssociatedIcon($File).ToBitmap().Save($OutputFile)
}


# 转换为 icon
# https://gist.github.com/darkfall/1656050
function ConvertTo-Icon {
    <#
    .Synopsis
        Converts image to icons
    .Description
        Converts an image to an icon
    .Example
        ConvertTo-Icon -File .\Logo.png -OutputFile .\Favicon.ico
    #>
    [CmdletBinding()]
    param(
    # The file
    [Parameter(Mandatory=$true, Position=0, ValueFromPipelineByPropertyName=$true)]
    [Alias('Fullname')]
    [string]$File,

    # If provided, will output the icon to a location
    [Parameter(Position=1, ValueFromPipelineByPropertyName=$true)]
    [string]$OutputFile
    )

    begin {
        Add-Type -AssemblyName System.Drawing
    }

    process {
        #region Load Icon
        $resolvedFile = $ExecutionContext.SessionState.Path.GetResolvedPSPathFromPSPath($file)
        if (-not $resolvedFile) { return }
        $inputBitmap = [Drawing.Image]::FromFile($resolvedFile)
        $width = $inputBitmap.Width
        $height = $inputBitmap.Height
        $size = New-Object Drawing.Size $width, $height
        $newBitmap = New-Object Drawing.Bitmap $inputBitmap, $size
        #endregion Load Icon

        #region Save Icon
        $memoryStream = New-Object System.IO.MemoryStream
        $newBitmap.Save($memoryStream, [System.Drawing.Imaging.ImageFormat]::Png)

        $resolvedOutputFile = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($outputFile)
        $output = [IO.File]::Create("$resolvedOutputFile")

        $iconWriter = New-Object System.IO.BinaryWriter($output)
        # 0-1 reserved, 0
        $iconWriter.Write([byte]0)
        $iconWriter.Write([byte]0)

        # 2-3 image type, 1 = icon, 2 = cursor
        $iconWriter.Write([short]1);

        # 4-5 number of images
        $iconWriter.Write([short]1);

        # image entry 1
        # 0 image width
        $iconWriter.Write([byte]$width);
        # 1 image height
        $iconWriter.Write([byte]$height);

        # 2 number of colors
        $iconWriter.Write([byte]0);

        # 3 reserved
        $iconWriter.Write([byte]0);

        # 4-5 color planes
        $iconWriter.Write([short]0);

        # 6-7 bits per pixel
        $iconWriter.Write([short]32);

        # 8-11 size of image data
        $iconWriter.Write([int]$memoryStream.Length);

        # 12-15 offset of image data
        $iconWriter.Write([int](6 + 16));

        # write image data
        # png data must contain the whole png data file
        $iconWriter.Write($memoryStream.ToArray());

        $iconWriter.Flush();
        $output.Close()
        #endregion Save Icon

        #region Cleanup
        $memoryStream.Dispose()
        $newBitmap.Dispose()
        $inputBitmap.Dispose()
        #endregion Cleanup
    }
}


# 获取 Program Files 文件夹
function GetProgramFilesFolder(
    [Parameter(Mandatory=$true)]
    [bool]$includePreview) {
    $versionFolders = (Get-ChildItem "$Env:ProgramFiles\WindowsApps" | Where-Object {
            if ($includePreview) {
                $_.Name -like "Microsoft.WindowsTerminal_*__*" -or
                $_.Name -like "Microsoft.WindowsTerminalPreview_*__*"
            } else {
                $_.Name -like "Microsoft.WindowsTerminal_*__*"
            }
        })
    $foundVersion = $null
    $result = $null
    foreach ($versionFolder in $versionFolders) {
        if ($versionFolder.Name -match "[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+") {
            $version = [version]$Matches.0
            if ($null -eq $foundVersion -or $version -gt $foundVersion) {
                $foundVersion = $version
                $result = $versionFolder.FullName
            }
        } else {
            if ($UseEnglish) {
                Write-Warning "Found Windows Terminal unsupported version in $versionFolder."
            }
            else {
                Write-Warning "在 `"$versionFolder`"发现到Windows Terminal不支持版本。"
            }
        }
    }
    if ($UseEnglish) {
        Write-Host "Found Windows Terminal version $foundVersion."
    }
    else {
        Write-Host "发现Windows Terminal版本：$foundVersion。"
    }
    
    if ($foundVersion -lt [version]"0.11") {
        if ($UseEnglish) {
            Write-Warning "The latest version found is less than 0.11, which is not tested."+
                           "The install script might fail in certain way."
        }
        else {
            Write-Warning "发现的最新版本小于0.11， 该版本未经过测试，"+
                          "安装脚本可能会以某种方式失败。"
        }
    }
    if ($null -eq $result) {
        if ($UseEnglish) {
            Write-Error "Failed to find Windows Terminal actual folder. "+
                        "The install script might fail in certain way."
        }
        else {
            Write-Error "无法找到Windows Terminal安装路径，"+
                        "安装脚本可能会以某种方式失败。"
        }
    }
    return $result
}


# 获取 Windows Terminal 的 icon
function GetWindowsTerminalIcon(
    [Parameter(Mandatory=$true)]
    [string]$folder,
    [Parameter(Mandatory=$true)]
    [string]$localCache) {
    $icon = "$localCache\wt.ico"
    $actual = $folder + "\WindowsTerminal.exe"
    if (Test-Path $actual) {
        # use app icon directly.
        if ($UseEnglish) {
            Write-Host "Found actual executable $actual."
        }
        else {
            Write-Host "发现可执行文件：`"$actual`"。"
        }
        $temp = "$localCache\wt.png"
        Get-Icon -File $actual -OutputFile $temp
        ConvertTo-Icon -File $temp -OutputFile $icon
    } else {
        # download from GitHub
        if ($UseEnglish) {
            Write-Warning "Didn't find actual executable $actual so download icon from GitHub."
        }
        else {
            Write-Warning "未发现可执行文件：`"$actual`"，将从GitHub下载。"
        }
        Invoke-WebRequest -UseBasicParsing `
        "https://raw.githubusercontent.com/microsoft/terminal/master/res/terminal.ico" -OutFile $icon
    }

    return $icon
}


# 获取 Windows Terminal 的配置文件
function GetActiveProfiles(
    [Parameter(Mandatory=$true)]
    [bool]$isPreview) {
    if ($isPreview) {
        $file = "$env:LocalAppData\Packages\Microsoft.WindowsTerminalPreview_8wekyb3d8bbwe\LocalState\settings.json"
    } else {
        $file = "$env:LocalAppData\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json"
    }
    if (-not (Test-Path $file)) {
        if ($UseEnglish) {
            Write-Error "Couldn't find profiles. Please run Windows "+
                        "Terminal at least once after installing it. Exit."
        }
        else {
            Write-Error "未找到配置，请在安装Windows Terminal后至少运行一次，退出。"
        }
        exit 1
    }

    $settings = Get-Content $file | Out-String | ConvertFrom-Json
    if ($settings.profiles.PSObject.Properties.name -match "list") {
        $list = $settings.profiles.list
    } else {
        $list = $settings.profiles 
    }
    return $list | Where-Object { -not $_.hidden} | `
    Where-Object { ($null -eq $_.source) -or -not ($settings.disabledProfileSources -contains $_.source) }
}


function GetProfileIcon (
    [Parameter(Mandatory=$true)]
    $profile,
    [Parameter(Mandatory=$true)]
    [string]$folder,
    [Parameter(Mandatory=$true)]
    [string]$localCache,
    [Parameter(Mandatory=$true)]
    [string]$defaultIcon,
    [Parameter(Mandatory=$true)]
    [bool]$isPreview) {
    $guid = $profile.guid
    $name = $profile.name
    $result = $null
    $profilePng = $null
    $icon = $profile.icon
    if ($null -ne $icon) {
        if (Test-Path $icon) {
            # use user setting
            $profilePng = $icon  
        } elseif ($profile.icon -like "ms-appdata:///Roaming/*") {
            #resolve roaming cache
            if ($isPreview) {
                $profilePng = $icon -replace "ms-appdata:///Roaming", `
                "$Env:LOCALAPPDATA\Packages\Microsoft.WindowsTerminalPreview_8wekyb3d8bbwe\RoamingState" -replace "/", "\"
            } else {
                $profilePng = $icon -replace "ms-appdata:///Roaming", `
                "$Env:LOCALAPPDATA\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\RoamingState" -replace "/", "\"
            }
        } elseif ($profile.icon -like "ms-appdata:///Local/*") {
            #resolve local cache
            if ($isPreview) {
                $profilePng = $icon -replace "ms-appdata:///Local", `
                "$Env:LOCALAPPDATA\Packages\Microsoft.WindowsTerminalPreview_8wekyb3d8bbwe\LocalState" -replace "/", "\"
            } else {
                $profilePng = $icon -replace "ms-appdata:///Local", `
                "$Env:LOCALAPPDATA\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState" -replace "/", "\"
            }
        } elseif ($profile.icon -like "ms-appx:///*") {
            # resolve app cache
            $profilePng = $icon -replace "ms-appx://", $folder -replace "/", "\"
        } elseif ($profile.icon -like "*%*") {
            $profilePng = [System.Environment]::ExpandEnvironmentVariables($icon)
        } else {
            if ($UseEnglish) {
                Write-Host "Invalid profile icon found $icon. "+
                           "Please report an issue at https://github.com/SplitGemini/windowsterminal-shell/issues ."
            }
            else {
                Write-Host "图片不合标准： $icon。"+
                           "请在`"https://github.com/SplitGemini/windowsterminal-shell/issues`"提Issue。"
            }
        }
    }

    if (($null -eq $profilePng) -or -not (Test-Path $profilePng)) {
        # fallback to profile PNG
        $profilePng = "$folder\ProfileIcons\$guid.scale-200.png"
        if (-not (Test-Path($profilePng))) {
            if ($profile.source -eq "Windows.Terminal.Wsl") {
                $profilePng = "$folder\ProfileIcons\{9acb9455-ca41-5af7-950f-6bca1bc9722f}.scale-200.png"
            }
        }
    }

    if (Test-Path $profilePng) {
        if ($profilePng -like "*.png") {
            # found PNG, convert to ICO
            $result = "$localCache\$guid.ico"
            ConvertTo-Icon -File $profilePng -OutputFile $result
        } elseif ($profilePng -like "*.ico") {
            $result = $profilePng
        } else {
            if ($UseEnglish) {
                Write-Warning "Icon format is not supported by this script $profilePng."+
                              " Please use PNG or ICO format."
            }
            else {
                Write-Warning "$profilePng的图标格式不受该脚本支持，请使用PNG或ICO格式。"
            }
        }
    } else {
        if ($UseEnglish) {
            Write-Warning "Didn't find icon for profile $name."
        }
        else {
            Write-Warning "在配置`"$name`"中未发现图标。"
        }
    }
    
    if ($null -eq $result) {
        # final fallback
        $result = $defaultIcon
    }
    return $result
}


function CreateMenuItem(
    [Parameter(Mandatory=$true)]
    [string]$rootKey,
    [Parameter(Mandatory=$true)]
    [string]$name,
    [Parameter(Mandatory=$true)]
    [string]$icon,
    [Parameter(Mandatory=$true)]
    [AllowEmptyString()]
    [string]$command,
    [Parameter(Mandatory=$true)]
    [bool]$elevated) {
    New-Item -Path $rootKey -Force | Out-Null
    New-ItemProperty -Path $rootKey -Name 'MUIVerb' -PropertyType String -Value $name | Out-Null
    New-ItemProperty -Path $rootKey -Name 'Icon' -PropertyType String -Value $icon | Out-Null
    if ($Extended -and -not($rootKey.contains('ContextMenus'))) {
        New-ItemProperty -Path $rootKey -Name 'Extended' -PropertyType String -Value "" | Out-Null
    }
    if (!$command) {
        if ($elevated){
            New-ItemProperty -Path $rootKey -Name 'ExtendedSubCommandsKey'`
            -PropertyType String -Value 'Directory\\ContextMenus\\MenuTerminalAdmin' | Out-Null
        }
        else {
            New-ItemProperty -Path $rootKey -Name 'ExtendedSubCommandsKey'`
            -PropertyType String -Value 'Directory\\ContextMenus\\MenuTerminal' | Out-Null
        }
    }
    else {
        New-Item -Path "$rootKey\command" -Force | Out-Null
        New-ItemProperty -Path "$rootKey\command" -Name '(Default)' -PropertyType String -Value $command | Out-Null
    }
    if ($elevated) {
        New-ItemProperty -Path $rootKey -Name 'HasLUAShield' -PropertyType String -Value '' | Out-Null
    }
    if ($UseEnglish) {
        Write-Host "Create $name"
    }
    else {
        Write-Host "创建：`"$name`""
    }
}


function CreateProfileMenuItems(
    [Parameter(Mandatory=$true)]
    $profile,
    [Parameter(Mandatory=$true)]
    [string]$executable,
    [Parameter(Mandatory=$true)]
    [string]$folder,
    [Parameter(Mandatory=$true)]
    [string]$localCache,
    [Parameter(Mandatory=$true)]
    [string]$icon,
    [Parameter(Mandatory=$true)]
    [string]$layout,
    [Parameter(Mandatory=$true)]
    [bool]$isPreview) {
    $guid = $profile.guid
    $name = $profile.name
    $command = """$executable"" -p ""$name"" -d ""%V."""
    $elevated = "wscript.exe ""$localCache/helper.vbs"" ""$executable"" ""%V."" ""$name"""
    $profileIcon = GetProfileIcon $profile $folder $localCache $icon $isPreview
    
    if ($layout -eq "Default") { 
        if ($MenuType -ne 'OnlyAdmin') {
            CreateMenuItem "Registry::HKEY_CURRENT_USER\SOFTWARE\Classes\Directory\ContextMenus\MenuTerminal\shell\$guid"`
            $name $profileIcon $command $false
        }
        if ($MenuType -ne 'OnlyUser') {
            CreateMenuItem "Registry::HKEY_CURRENT_USER\SOFTWARE\Classes\Directory\ContextMenus\MenuTerminalAdmin\shell\$guid"`
            $name $profileIcon $elevated $true
        }
    } elseif ($layout -eq "Flat") {
        if ($MenuType -ne 'OnlyAdmin') {
            CreateMenuItem "Registry::HKEY_CURRENT_USER\SOFTWARE\Classes\Directory\shell\MenuTerminal_$guid"`
            ($UseEnglish ? "$name Here" : "在此打开 $name") $profileIcon $command $false
            CreateMenuItem "Registry::HKEY_CURRENT_USER\SOFTWARE\Classes\Directory\Background\shell\MenuTerminal_$guid"`
            ($UseEnglish ? "$name Here" : "在此打开 $name") $profileIcon $command $false
        }
        if ($MenuType -ne 'OnlyUser') {
            CreateMenuItem "Registry::HKEY_CURRENT_USER\SOFTWARE\Classes\Directory\shell\MenuTerminal_$($guid)_Admin"`
            ($UseEnglish ? "$name Here as Administrator" : "在此打开 $name (管理员)") $profileIcon $elevated $true
            CreateMenuItem "Registry::HKEY_CURRENT_USER\SOFTWARE\Classes\Directory\Background\shell\MenuTerminal_$($guid)_Admin"`
            ($UseEnglish ? "$name Here as Administrator" : "在此打开 $name (管理员)") $profileIcon $elevated $true
        }
    }
}


function CreateMenuItems(
    [Parameter(Mandatory=$true)]
    [string]$executable,
    [Parameter(Mandatory=$true)]
    [string]$layout,
    [Parameter(Mandatory=$true)]
    [bool]$includePreview) {
    $folder = GetProgramFilesFolder $includePreview
    $localCache = "$Env:LOCALAPPDATA\Microsoft\WindowsApps\Cache"

    if (-not (Test-Path $localCache)) {
        New-Item $localCache -ItemType Directory | Out-Null
    }

    Generate-HelperScript $localCache
    $icon = GetWindowsTerminalIcon $folder $localCache

    if ($layout -eq "Default") {
        # defaut layout creates two menus
        if ($MenuType -ne 'OnlyAdmin') {
            CreateMenuItem 'Registry::HKEY_CURRENT_USER\SOFTWARE\Classes\Directory\shell\MenuTerminal'`
            ($UseEnglish ? "Windows Terminal Here" : "在此打开 Windows Terminal") $icon '' $false
            CreateMenuItem 'Registry::HKEY_CURRENT_USER\SOFTWARE\Classes\Directory\Background\shell\MenuTerminal'`
            ($UseEnglish ? "Windows Terminal Here" : "在此打开 Windows Terminal") $icon '' $false
            New-Item -Path 'Registry::HKEY_CURRENT_USER\SOFTWARE\Classes\Directory\ContextMenus\MenuTerminal\shell' -Force | Out-Null
        }
        if ($MenuType -ne 'OnlyUser') {
            CreateMenuItem 'Registry::HKEY_CURRENT_USER\SOFTWARE\Classes\Directory\shell\MenuTerminalAdmin'`
            ($UseEnglish ? "Windows Terminal Here as Administrator" : "在此打开 Windows Terminal (管理员)") $icon '' $true
            CreateMenuItem 'Registry::HKEY_CURRENT_USER\SOFTWARE\Classes\Directory\Background\shell\MenuTerminalAdmin'`
            ($UseEnglish ? "Windows Terminal Here as Administrator" : "在此打开 Windows Terminal (管理员)") $icon '' $true
            New-Item -Path 'Registry::HKEY_CURRENT_USER\SOFTWARE\Classes\Directory\ContextMenus\MenuTerminalAdmin\shell' -Force | Out-Null
        }
        
    } elseif ($layout -eq "Mini") {
        if ($MenuType -ne 'OnlyAdmin') {
            $command = """$executable"" -p ""$name"" -d ""%V."""
            CreateMenuItem "Registry::HKEY_CURRENT_USER\SOFTWARE\Classes\Directory\shell\MenuTerminalMini"`
            ($UseEnglish ? "Windows Terminal Here" : "在此打开 Windows Terminal") $icon $command $false
            CreateMenuItem "Registry::HKEY_CURRENT_USER\SOFTWARE\Classes\Directory\Background\shell\MenuTerminalMini"`
            ($UseEnglish ? "Windows Terminal Here" : "在此打开 Windows Terminal") $icon $command $false
        }
        if ($MenuType -ne 'OnlyUser') {
            $elevated = "wscript.exe ""$localCache/helper.vbs"" ""$executable"" ""%V."""
            CreateMenuItem "Registry::HKEY_CURRENT_USER\SOFTWARE\Classes\Directory\shell\MenuTerminalMini_Admin"`
            ($UseEnglish ? "Windows Terminal Here as Administrator" : "在此打开 Windows Terminal (管理员)") $icon $elevated $true
            CreateMenuItem "Registry::HKEY_CURRENT_USER\SOFTWARE\Classes\Directory\Background\shell\MenuTerminalMini_Admin"`
            ($UseEnglish ? "Windows Terminal Here as Administrator" : "在此打开 Windows Terminal (管理员)") $icon $elevated $true
        }
        return
    }
    
    $isPreview = $folder -like "*WindowsTerminalPreview*"
    $profiles = GetActiveProfiles $isPreview
    foreach ($profile in $profiles) {
        CreateProfileMenuItems $profile $executable $folder $localCache $icon $layout $isPreview
    }
}


# Based on @nerdio01's version in https://github.com/microsoft/terminal/issues/1060
if ((Test-Path "Registry::HKEY_CLASSES_ROOT\Directory\shell\MenuTerminal") -and
    -not (Test-Path "Registry::HKEY_CURRENT_USER\SOFTWARE\Classes\Directory\shell\MenuTerminal")) {
    if ($UseEnglish) {
        Write-Error "Please execute uninstall.old.ps1 to remove previous installation."
            }
    else {
        Write-Error "Please execute uninstall.old.ps1 to remove previous installation."
    }
    exit 1
}

if ($PSVersionTable.PSVersion.Major -lt 7) {
    if ($UseEnglish) {
        Write-Error "Must be executed in PowerShell 7 and above."+
                    " Learn how to install it from https://docs.microsoft.com/"+
                    "en-us/powershell/scripting/install/installing-powershell-co"+
                    "re-on-windows?view=powershell-7 . Exit."
    }
    else {
        Write-Error "使用的PowerShell版本必须大于7，"+
                    "在此安装最新版：`"https://docs.microsoft.com/"+
                    "en-us/powershell/scripting/install/installing-powershell-co"+
                    "re-on-windows?view=powershell-7`"，退出。"
    }
    exit 1
}


$executable = "$Env:LOCALAPPDATA\Microsoft\WindowsApps\wt.exe"
if (-not (Test-Path $executable)) {
    if ($UseEnglish) {
        Write-Error "Windows Terminal not detected. "+
                    "Learn how to install it from https://github.com/microsoft/terminal "+
                    "(via Microsoft Store is recommended). Exit."
    }
    else {
        Write-Error "未检测到Windows Terminal。"+
                    "在此安装：`"https://github.com/microsoft/terminal`""+
                    "，（推荐通过Microsoft Store安装）, 退出。"
    }
    exit 1
}


# main
if ($UseEnglish) {
    Write-Host "Layout: $Layout"
    CreateMenuItems $executable $Layout $PreRelease
    Write-Host ""
    Write-Host "Windows Terminal installed to Windows Explorer context menu."
    Write-Host "P.S. Uninstall use '.\uninstall.ps1' please"
}
else {
    Write-Host "布局风格：$Layout"
    CreateMenuItems $executable $Layout $PreRelease
    Write-Host ""
    Write-Host "Windows Terminal 启动选项已添加到资源管理器右键菜单"
    Write-Host "P.S. 卸载请使用 `".\uninstall.ps1`""
}

