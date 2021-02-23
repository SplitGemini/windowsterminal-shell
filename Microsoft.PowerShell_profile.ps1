<#
 * FileName: Microsoft.PowerShell_profile.ps1
 * Author: 
 * Email: 
 * Date: 
 * Copyright: No copyright. You can use this code for anything with no warranty.
#>

# Import Modules
function Import-Profile-Modules {

    # 引入 posh-git
    Import-Module posh-git

    # 引入 oh-my-posh
    Import-Module oh-my-posh

    # PSReadLine
    Import-Module PSReadLine

    # ZLocation
    Import-Module ZLocation
    # for z.lua，类似ZLocation
    #Start-Job -ScriptBlock {iex ($(lua D:\Administrator\Documents\PowerShell\z.lua --init powershell) -join "`n")}

    # 引入 DirColors并设置颜色，已卸载
    #Import-Module DirColors
    #Update-DirColors "D:\Administrator\Documents\PowerShell\dircolors.ansi-dark"

    Import-Module Terminal-Icons
    Import-Module PowerColorLS

    # 设置个人主题
    Set-PoshPrompt -Theme powerlevel10k_classic

    Import-Module Get-MediaInfo
}

# Set Hot-keys
function Set-Profile-Hotkeys {
    # 设置 Tab 键补全
    #Set-PSReadlineKeyHandler -Key Tab -Function Complete

    # 设置 Tab 键补全
    Set-PSReadLineKeyHandler -Key "Tab" -Function MenuComplete

    # 设置 Ctrl+d 为退出 PowerShell
    Set-PSReadlineKeyHandler -Key "Ctrl+d" -Function ViExit

    # 设置 Ctrl+z 为撤销
    Set-PSReadLineKeyHandler -Key "Ctrl+z" -Function Undo

    # 设置向上键为后向搜索历史记录
    Set-PSReadLineKeyHandler -Key UpArrow -Function HistorySearchBackward

    # 设置向下键为前向搜索历史纪录
    Set-PSReadLineKeyHandler -Key DownArrow -Function HistorySearchForward

    # 设置预测文本来源为历史记录
    Set-PSReadLineOption -PredictionSource History
    # 自动移动光标到行尾
    Set-PSReadLineOption -HistorySearchCursorMovesToEnd
    # 向右删除参数
    Set-PSReadLineKeyHandler -Key Alt+c -Function ShellKillWord
    # 向左删除参数
    Set-PSReadLineKeyHandler -Key Alt+x -Function ShellBackwardKillWord
    # F7显示当前命令相关历史
    Set-PSReadLineKeyHandler -Key F7 `
                             -BriefDescription History `
                             -LongDescription 'Show command history' `
                             -ScriptBlock {
        $pattern = $null
        [Microsoft.PowerShell.PSConsoleReadLine]::GetBufferState([ref]$pattern, [ref]$null)
        if ($pattern)
        {
            $pattern = [regex]::Escape($pattern)
        }

        $history = [System.Collections.ArrayList]@(
            $last = ''
            $lines = ''
            foreach ($line in [System.IO.File]::ReadLines((Get-PSReadLineOption).HistorySavePath))
            {
                if ($line.EndsWith('`'))
                {
                    $line = $line.Substring(0, $line.Length - 1)
                    $lines = if ($lines)
                    {
                        "$lines`n$line"
                    }
                    else
                    {
                        $line
                    }
                    continue
                }

                if ($lines)
                {
                    $line = "$lines`n$line"
                    $lines = ''
                }

                if (($line -cne $last) -and (!$pattern -or ($line -match $pattern)))
                {
                    $last = $line
                    $line
                }
            }
        )
        $history.Reverse()

        $command = $history | Out-GridView -Title History -PassThru
        if ($command)
        {
            [Microsoft.PowerShell.PSConsoleReadLine]::RevertLine()
            [Microsoft.PowerShell.PSConsoleReadLine]::Insert(($command -join "`n"))
        }
    }
}


# Python 直接执行
#$env:PATHEXT += ";.py"

# 更新 pip 的方法
function Update-Pip {
    # update pip
    Write-Host "更新 pip packages" -ForegroundColor Magenta -BackgroundColor Cyan
    $a = pip list --outdated
    $num_package = $a.Length - 2
    for ($i = 0; $i -lt $num_package; $i++) {
        $tmp = ($a[2 + $i].Split(" "))[0]
        pip install -U $tmp
    }
}
# 更新modules
function Update-Modules {
    Write-Host "更新 powershell core 7 modules" -ForegroundColor Magenta -BackgroundColor Cyan
    . $PSScriptRoot/Update-AllPowerShellModules.ps1
}
function Update-All {
    Update-Pip
    Update-Modules
}


# Test a name with port if it is opened
function Test-Port {
    Param([string]$ComputerName,$Port = 2222,$timeout = 200)
    try {
        $tcpclient = New-Object -TypeName system.Net.Sockets.TcpClient
        $iar = $tcpclient.BeginConnect($ComputerName,$port,$null,$null)
        $wait = $iar.AsyncWaitHandle.WaitOne($timeout,$false)
        if(!$wait) {
            $tcpclient.Close()
            return $false
        }
        else {
            # Close the connection and report the error if there is one
            $null = $tcpclient.EndConnect($iar)
            $tcpclient.Close()
            return $true
        }
    }
    catch {
        $false
    }
}

# Set proxy to local with port
function Set-Profile-Proxy {
    #根据系统代理开关判断
    $regPath = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Internet Settings'
    $enable = (Get-ItemProperty -Path $regPath).ProxyEnable
    $port = 1080
    # 根据端口是否连通判断，如果开了系统代理则用系统代理
    if ($enable -gt 0){
        $proxy = "http://$((Get-ItemProperty -Path $regPath).ProxyServer)"
        $Env:http_proxy=$proxy
        $Env:https_proxy=$proxy
        Write-Host "Set Proxy:$proxy" -ForegroundColor Magenta -BackgroundColor Cyan
    }
    elseif (Test-Port -ComputerName "127.0.0.1" -Port $port) {
        $proxy = "http://127.0.0.1:$port"
        $Env:http_proxy=$proxy
        $Env:https_proxy=$proxy
        # 这是直接加在环境变量里
        #[Environment]::SetEnvironmentVariable('http_proxy', $proxy, 'User')
        #[Environment]::SetEnvironmentVariable('https_proxy', $proxy, 'User')
        Write-Host "Set Proxy:$proxy" -ForegroundColor Magenta -BackgroundColor Cyan
    }
}

#-------------------------------    Proxy END     -------------------------------



#-------------------------------   Set Alias Begin    -------------------------------
function zlfuc ([Parameter()][String]$param){ z -l $param }
function Set-Profile-Alias {
    # 查看目录 ls
    Set-Alias -Name ls -Value PowerColorLS -Option AllScope -Force -Scope Global
    New-Alias -Name zl -Value zlfuc -Option AllScope -Force -Scope Global
}
#-------------------------------    Set Alias END     -------------------------------
$terminal = (Get-Process -Id $PID).Parent.ProcessName
if ($terminal -ne 'WindowsTerminal') {
    # speed up starting
    Write-Host "This terminal isn't `"Windows Terminal`". Parent Process is `"${terminal}`", didn't initial modules"
}
else {
    Import-Profile-Modules
    Set-Profile-Hotkeys
    Set-Profile-Proxy
    Set-Profile-Alias
}