# PowerShell Scripts to Install/Uninstall Context Menu Items for Windows Terminal

*A project backed by [LeXtudio Inc.](https://www.lextudio.com)*

## 1. 部署

1. [安装 Windows Terminal](https://github.com/microsoft/terminal).
1. [安装 PowerShell 7](https://docs.microsoft.com/en-us/powershell/scripting/install/installing-powershell-core-on-windows?view=powershell-7).
1. 以**管理员身份**启动 PowerShell 7 控制台 (Powershell < 7 是**不行**的)，然后运行 `install.ps1` 脚本，将【上下文菜单项】安装到 Windows 资源管理器。现在，菜单项已添加到 Windows 资源管理器上下文菜单了。
    > 快速运行
    >```powershell
    > Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; iex ((New-Object System.Net.WebClient).DownloadString('https://raw.githubusercontent.com/SplitGemini/windowsterminal-shell/master/install.ps1'))
    >``` 
## 2. 参数说明

### -Layout
> 可选：['Default', 'Flat', 'Mini']，默认为`Default`

可直接运行`.\install.ps1 mini`或`.\install.ps1 flat`安装其他布局  
Default：  
![Default](img/default_chs.png)  
Flat：  
![Flat](img/flat_chs.png)  
Mini：  
![Mini](img/mini_chs.png) 

### -PreRelease
支持PreRelease版本的Windows Terminal。

### -UseEnglish
Just English Version.  
默认为中文，参数添加`-UseEnglish`改为英文版本  
预览如下：    
Default：  
![Default](img/default.png)  
Flat：  
![Flat](img/flat.png)  
Mini：  
![Mini](img/mini.png)  

### -Extended
参数添加`-Extended`安装后，只有在按住`Shift`键之后按下右键才会显示安装的选项。  
[参照](https://docs.microsoft.com/en-us/windows/win32/shell/context#shortcut-menu-verbs)

### -MenuType
> 可选['Both', 'OnlyUser', 'OnlyAdmin']，默认为Both

- OnlyUser: 只安装非管理员选项  
- OnlyAdmin: 只安装管理员选项  
- Both: 两者都安装  

## 3. 卸载

以管理员身份，在 PowerShell Core 7 中，执行 `uninstall.ps1` 即可删除配置。

## 4. 注意

- 当前版本仅支持 Windows 10；
- `install.ps1` 和 `uninstall.ps1` 脚本**必须**以管理员身份运行；
- **必须**在版本 >= 7 的 PowerShell 下执行脚本；
- `install.ps1` 和 `uninstall.ps1` 仅操作上下文菜单项的 Windows 资源管理器设置，而不写入 Windows Terminal 的设置；
- 从 GitHub 下载 Windows Terminal 图标 (在 `install.ps1` 中) 需要 Internet 连接，最好在运行 `install.ps1` 时，将代理软件设置为全局代理；
- 善用`Tab`自动补全