# ===== LOCALIZATION (RU/EN) =====
$UI = @{
    RU = @{
        ConfigSuccess   = "[*] Внешняя конфигурация успешно загружена."
        ConfigError     = "[Err] Ошибка чтения config.json: {0}"
        FirstClean      = "[*] Глубокая очистка от старых настроек..."
        Cleaning        = "└[+] Очистка данных в {0} (сохранение peers)..."
        AssetFolder     = "└[+] Создана папка для локальных установщиков: {0}"
        FolderError     = "[Err] Не удалось создать папку для локальных установщиков: {0}"
        loDialog1       = "[!] Найден локальный установщик: {0} (v{1})"
        loDialog2       = "└[1] Использовать установщик локально (Быстро)"
        loDialog3       = "└[2] Загрузить последний релиз с GitHub (Онлайн)"
        Choose          = "[#] Выберите действие [1-2] (Стандартно - 1)"
        CopyingAssets   = "[*] Копирование локального установщика..."
        ghUnreachable   = "[!] GitHub недоступен. Возвращение к локальным установщикам..."
        AssetsErr       = "[Err] Нет соединения и нет локальных ассетов..."
        GitHub          = "[*] Запрос к GitHub API..."
        UsingToken      = "[*] Используется GitHub Token для обхода стандартных лимитов..."
        Downloading     = "[*] Скачивание: {0}"
        Saved           = "└[+] Новый установщик сохранён: {0}"
        Installing      = "[*] Установка RustDesk..."
        FilesCopied     = "`n[OK] Файлы скопированы."
        KillProcess     = "[*] Остановка фоновых процессов для настройки..."
        FolderCreated   = "└[+] Создана папка: {0}"
        ServiceInstall  = "[*] Регистрация службы и пароля..."
        Cleanup         = "[*] Финализация и очистка мусора..."
        Success         = "[OK] Установка завершена успешно!"
        Error           = "[Err] ОШИБКА: {0}"
        Exit            = "[...] Нажми любую клавишу для выхода..."
    }
    EN = @{
        ConfigSuccess   = "[*] External configuration successfully loaded."
        ConfigError     = "[Err] Error reading the config.json: {0}"
        FirstClean      = "[*] Deep cleaning old data..."
        Cleaning        = "└[+] Cleaning data in {0} (saving peers)..."
        AssetFolder     = "└[+] Created assets folder: {0}"
        FolderError     = "[Err] Could not create assets folder: {0}"
        loDialog1       = "[!] Found local asset: {0} (v{1})"
        loDialog2       = "└[1] Use local asset (Fast)"
        loDialog3       = "└[2] Download latest from GitHub (Online)"
        Choose          = "[#] Select option [1-2] (Default is 1)"
        CopyingAssets   = "[*] Copying local asset..."
        ghUnreachable   = "[!] GitHub unreachable. Falling back to local asset..."
        AssetsErr       = "[Err] No internet and no local assets found."
        GitHub          = "[*] Requesting GitHub API..."
        UsingToken      = "[*] Using GitHub Token to bypassing standard limits..."
        Downloading     = "[*] Downloading: {0}"
        Saved           = "└[+] Asset saved: {0}"
        Installing      = "[*] Installing RustDesk..."
        FilesCopied     = "`n[OK] Files Copied."
        KillProcess     = "[*]Stopping background processes for configuration"
        FolderCreated   = "└[+] Folder created: {0}"
        ServiceInstall  = "[*] Registering service and password..."
        Cleanup         = "[*] Finalizing and cleaning up..."
        Success         = "[OK] Installation completed successfully!"
        Error           = "[Err] ERROR: {0}"
        Exit            = "[...] Press any key to exit..."
    }
}
# ===============================

# =========== SETTINGS ===========
$RelayServer      = ""
$RendezvousPort   = "21116"
$RelayPort        = "21117"

$StaticPassword   = "uNeedToChangeThis"
$Key              = ""
$GitToken         = ""

$AssetDir         = ""
$InstallPath      = "C:\Program Files\RustDesk"
$TempInstaller    = "$env:TEMP\rustdesk_setup.exe"
# ================================

$Host.UI.RawUI.WindowTitle = "RustDesk Auto Installer by Xellita"

# ru/en win detection
$Messages = if ((Get-Culture).Name -match "ru") { $UI.RU } else { $UI.EN }

$BaseDir = if ($PSScriptRoot) { $PSScriptRoot } else { [System.IO.Path]::GetDirectoryName([System.Diagnostics.Process]::GetCurrentProcess().MainModule.FileName) }
$ConfigFile = Join-Path $BaseDir "config.json"

# try to load config file
if (Test-Path $ConfigFile) {
    try {
        $ExternalSettings = Get-Content $ConfigFile -Raw | ConvertFrom-Json
        
        foreach ($Property in $ExternalSettings.psobject.Properties) {
            $VarName = $Property.Name
            $VarValue = $Property.Value
            
            if (Get-Variable -Name $VarName -ErrorAction SilentlyContinue) {
                Set-Variable -Name $VarName -Value $VarValue
            }
        }
        Write-Host $Messages.ConfigSuccess -ForegroundColor Green
    }
    catch {
        Write-Host ($Messages.ConfigError -f $_.Exception.Message) -ForegroundColor Red
    }
}

# fix for smb and launch with admin permissions
if ($PSScriptRoot -like "\\*") { Set-Location "$env:TEMP" }
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Start-Process powershell.exe "-NoProfile -ExecutionPolicy Bypass -File "$PSCommandPath"" -Verb RunAs
    exit
}

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

try {
    Write-Host $Messages.FirstClean -ForegroundColor Yellow

    # closing rustdesk
    $processes = Get-Process -Name "rustdesk" -ErrorAction SilentlyContinue
    if ($processes) {
        Stop-Process -Name "rustdesk" -Force
        Start-Sleep -Seconds 2
    }

    # clean reg
    $RegPaths = @("HKLM:\SOFTWARE\RustDesk", "HKCU:\SOFTWARE\RustDesk")
    foreach ($Reg in $RegPaths) { if (Test-Path $Reg) { Remove-Item $Reg -Recurse -Force -ErrorAction SilentlyContinue } }

    $OldFolders = @(
        "$env:APPDATA\RustDesk", 
        "C:\Windows\ServiceProfiles\LocalService\AppData\Roaming\RustDesk",
        $InstallPath
    )

    # clean old data (except peers)
    foreach ($F in $OldFolders) {
        if (Test-Path $F) {
            if ($F -eq $InstallPath) {
                Remove-Item $F -Recurse -Force -ErrorAction SilentlyContinue
            }
            else {
                Write-Host ($Messages.Cleaning -f $F) -ForegroundColor Gray
                
                Get-ChildItem -Path $F | Where-Object { $_.Name -ne "config" } | Remove-Item -Recurse -Force -ErrorAction SilentlyContinue
                
                $ConfigPath = Join-Path $F "config"
                if (Test-Path $ConfigPath) {
                    Get-ChildItem -Path $ConfigPath | Where-Object { $_.Name -ne "peers" } | Remove-Item -Recurse -Force -ErrorAction SilentlyContinue
                }
            }
        }
    }
    
    $LocalFile = $null
    $Architecture = if ([IntPtr]::Size -eq 8) { "x86_64" } else { "x86" }

    if (![string]::IsNullOrWhiteSpace($AssetDir)) {
        if ($AssetDir -notlike "*:*" -and $AssetDir -notlike "\\*") {
            $AssetDir = Join-Path $BaseDir $AssetDir
        }

        if (!(Test-Path $AssetDir)) {
            try {
                New-Item -ItemType Directory -Path $AssetDir -Force | Out-Null
                Write-Host ($Messages.AssetFolder -f $AssetDir) -ForegroundColor Gray
            } catch {
                Write-Host ($Messages.FolderError -f $_) -ForegroundColor Yellow
            }
        }
        else {
            $Assets = Get-ChildItem -Path $AssetDir -Filter "rustdesk*$Architecture*.exe" -ErrorAction SilentlyContinue | 
                      Where-Object { $_.Name -notlike "*sciter*" } | 
                      ForEach-Object {
                          $VerMatch = [regex]::Match($_.Name, '(\d+\.\d+\.\d+)')
                          $VerObj = if ($VerMatch.Success) { [version]$VerMatch.Value } else { [version]"0.0.0" }
                          [PSCustomObject]@{
                              File    = $_
                              Version = $VerObj
                          }
                      } | Sort-Object Version -Descending

            if ($Assets) {
                $NewestAsset = $Assets[0]
                Write-Host ($Messages.loDialog1 -f  $($NewestAsset.File.Name), "$($NewestAsset.Version)") -ForegroundColor Cyan
                Write-Host $Messages.loDialog2 -ForegroundColor White
                Write-Host $Messages.loDialog3 -ForegroundColor White

                $Choice = Read-Host $Messages.Choose
                if ($Choice -ne "2") {
                    $LocalFile = $NewestAsset.File
                    Write-Host $Messages.CopyingAssets -ForegroundColor Gray
                    Copy-Item -Path $LocalFile.FullName -Destination $TempInstaller -Force
                }
            }
        }
    }

    if (!(Test-Path $TempInstaller)) {
        try {
            Write-Host $Messages.GitHub -ForegroundColor Cyan
            $Headers = @{ "User-Agent" = "Mozilla/5.0" }
            if (-not [string]::IsNullOrWhiteSpace($GitToken)) {
                Write-Host $Messages.UsingToken -ForegroundColor Gray
                $Headers.Add("Authorization", "token $GitToken")
            }

            # buiding request for correct arch release
            $ReleaseData = Invoke-RestMethod -Uri "https://api.github.com/repos/rustdesk/rustdesk/releases/latest" -Headers $Headers
            $DownloadUrl = $ReleaseData.assets | Where-Object { $_.name -like "*$Architecture*" -and $_.name -like "*.exe" -and $_.name -notlike "*sciter*" } | Select-Object -ExpandProperty browser_download_url -First 1

            Write-Host ($Messages.Downloading -f $DownloadUrl)
            Invoke-WebRequest -Uri $DownloadUrl -OutFile $TempInstaller

            # saving new asset
            if (![string]::IsNullOrWhiteSpace($AssetDir) -and (Test-Path $AssetDir)) {
                $FileName = $DownloadUrl.Split('/')[-1]
                $AssetPath = Join-Path $AssetDir $FileName

                if (!(Test-Path $AssetPath)) {
                    Copy-Item -Path $TempInstaller -Destination $AssetPath -Force
                    Write-Host ($Messages.Saved -f $FileName) -ForegroundColor Gray
                }
            }
        }
        
        catch {
            if ($Assets) {
                Write-Host $Messages.ghUnreachable -ForegroundColor Yellow
                Copy-Item -Path $Assets[0].File.FullName -Destination $TempInstaller -Force
            } else {
                throw $Messages.AssetsErr
            }
        }
    }

    Write-Host $Messages.Installing -ForegroundColor Cyan
    Start-Process -FilePath $TempInstaller -ArgumentList "--silent-install"
    
    # wait for install
    $Wait = 60
    while (-not (Test-Path "$InstallPath\rustdesk.exe") -and $Wait -gt 0) {
        Start-Sleep -Seconds 2
        $Wait -= 2
        Write-Host "." -NoNewline
    }
    Write-Host $Messages.FilesCopied -ForegroundColor Green

    # stop rustdesk process for initial setup 
    Write-Host $Messages.KillProcess -ForegroundColor Yellow
    $processes = Get-Process -Name "rustdesk" -ErrorAction SilentlyContinue
    if ($processes) {
        Stop-Process -Name "rustdesk" -Force
        Start-Sleep -Seconds 2
    }

    $ConfigPaths = @(
        "$env:APPDATA\RustDesk\config",
        "C:\Windows\ServiceProfiles\LocalService\AppData\Roaming\RustDesk\config"
    )

    # recreate RustDesk2.toml
    $ConfigContent = @"
rendezvous_server = '${RelayServer}:${RendezvousPort}'
nat_type = 1
serial = 0
unlock_pin = ''
trusted_devices = ''

[options]
allow-remove-wallpaper = 'Y'
av1-test = 'Y'
relay-server = '${RelayServer}:${RelayPort}'
verification-method = 'use-both-passwords'
allow-numeric-one-time-password = 'Y'
custom-rendezvous-server = '${RelayServer}:${RendezvousPort}'
key = '${Key}'
"@

    # create config folders (jic)
    foreach ($CP in $ConfigPaths) {
        if (-not (Test-Path $CP)) { 
            New-Item -ItemType Directory -Path $CP -Force | Out-Null 
            Write-Host ($Messages.FolderCreated -f $CP) -ForegroundColor Gray
        }
        
        $ConfigFile = "$CP\RustDesk2.toml"
        $ConfigContent | Out-File -FilePath $ConfigFile -Encoding utf8 -Force
        
        # allow for "Everyone"
        try {
            $EveryoneIdentity = New-Object System.Security.Principal.SecurityIdentifier("S-1-1-0")
            $Acl = Get-Acl $ConfigFile
            $Ar = New-Object System.Security.AccessControl.FileSystemAccessRule($EveryoneIdentity, "ReadAndExecute", "Allow")
            $Acl.AddAccessRule($Ar)
            Set-Acl $ConfigFile $Acl
        } catch { }

        # readonly while setting up
        Set-ItemProperty -Path $ConfigFile -Name IsReadOnly -Value $true
    }
    
    # install in service mode and set up password
    if (Test-Path "$InstallPath\rustdesk.exe") {
        Set-Location $InstallPath
        Write-Host $Messages.ServiceInstall -ForegroundColor Cyan
        
        $Svc = Start-Process -FilePath "./rustdesk.exe" -ArgumentList "--install-service" -PassThru
        Start-Sleep -Seconds 5
        $Svc | Stop-Process -Force -ErrorAction SilentlyContinue

        $Pass = Start-Process -FilePath "./rustdesk.exe" -ArgumentList "--password $StaticPassword" -PassThru
        Start-Sleep -Seconds 5
        $Pass | Stop-Process -Force -ErrorAction SilentlyContinue

        Restart-Service -Name "rustdesk" -Force -ErrorAction SilentlyContinue
    }

    # cleanining
    Write-Host $Messages.Cleanup -ForegroundColor Yellow
    foreach ($CP in $ConfigPaths) {
        $MainFile = "$CP\RustDesk2.toml"
            
        if (Test-Path $MainFile) {
            Set-ItemProperty -Path $MainFile -Name IsReadOnly -Value $false
        }

        Get-ChildItem -Path $CP -Filter "RustDesk2.*" | Where-Object { $_.Name -ne "RustDesk2.toml" } | Remove-Item -Force -ErrorAction SilentlyContinue
    }

    if (Test-Path $TempInstaller) {
        try {
            Remove-Item -Path $TempInstaller -Force -ErrorAction SilentlyContinue
        } catch {}
    }

    Write-Host $Messages.Success -ForegroundColor Green
}
catch { Write-Host ($Messages.Error -f $($_.Exception.Message)) -ForegroundColor Red }

Write-Host $Messages.Exit
$null = [Console]::ReadKey()
