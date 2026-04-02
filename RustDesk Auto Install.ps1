# ===== LOCALIZATION (RU/EN) =====
$IsRussian = (Get-UICulture).Name -like "ru-*"

$Messages = @{
    ConfigSuccess   = if ($IsRussian) { "[*] Внешняя конфигурация успешно загружена." } else { "[*] External configuration successfully loaded." }
    ConfigError     = if ($IsRussian) { "[Err] Ошибка чтения config.json: {0}" } else { "[Err] Error reading the config.json: {0}" }
    FirstClean      = if ($IsRussian) { "[*] Глубокая очистка от старых настроек..." } else { "[*] Deep cleaning old data..." }
    Cleaning        = if ($IsRussian) { "└[+] Очистка данных в {0} (сохранение peers)..." } else { "└[+] Cleaning data in {0} (saving peers)..." }
    GitHub          = if ($IsRussian) { "[*] Запрос к GitHub API..." } else { "[*] Requesting GitHub API..." }
    UsingToken      = if ($IsRussian) { "[*] Используется GitHub Token для обхода стандартных лимитов..." } else { "[*] Using GitHub Token to bypassing standard limits..." }
    Downloading     = if ($IsRussian) { "[*] Скачивание: {0}" } else { "[*] Downloading: {0}" }
    Installing      = if ($IsRussian) { "[*] Установка RustDesk..." } else { "[*] Installing RustDesk..." }
    FilesCopied     = if ($IsRussian) { "`n[OK] Файлы скопированы." } else { "`n[OK] Files Copied." }
    KillProcess     = if ($IsRussian) { "[*] Остановка фоновых процессов для настройки..." } else { "[*]Stopping background processes for configuration" }
    FolderCreated   = if ($IsRussian) { "└[+] Создана папка: {0}" } else { "└[+] Folder created: {0}" }
    ConfigProtected = if ($IsRussian) { "└[+] Конфиг защищен от перезаписи: {0}" } else { "└[+] Config file write-protected: {0}" }
    ServiceInstall  = if ($IsRussian) { "[*] Регистрация службы и пароля..." } else { "[*] Registering service and password..." }
    Cleanup         = if ($IsRussian) { "[*] Финализация и очистка мусора..." } else { "[*] Finalizing and cleaning up..." }
    Success         = if ($IsRussian) { "[OK] Установка завершена успешно!" } else { "[OK] Installation completed successfully!" }
    Error           = if ($IsRussian) { "[Err] ОШИБКА: {0}" } else { "[Err] ERROR: {0}" }
    Exit            = if ($IsRussian) { "[...] Нажми любую клавишу для выхода..." } else { "[...] Press any key to exit..." }
}
# ===============================

# =========== SETTINGS ===========
$RelayServer      = ""
$RendezvousPort   = "21116"
$RelayPort        = "21117"

$StaticPassword   = "uNeedToChangeThis"
$Key              = ""
$GitToken         = ""

$InstallPath      = "C:\Program Files\RustDesk"
$TempInstaller    = "$env:TEMP\rustdesk_setup.exe"
# ================================

$BaseDir = if ($PSScriptRoot) { $PSScriptRoot } else { [System.IO.Path]::GetDirectoryName([System.Diagnostics.Process]::GetCurrentProcess().MainModule.FileName) }
$ConfigFile = Join-Path $BaseDir "config.json"

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

if ($PSScriptRoot -like "\\*") { Set-Location "$env:TEMP" }
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Start-Process powershell.exe "-NoProfile -ExecutionPolicy Bypass -File "$PSCommandPath"" -Verb RunAs
    exit
}

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

try {
    Write-Host $Messages.FirstClean -ForegroundColor Yellow

    Get-Process "rustdesk" -ErrorAction SilentlyContinue | Stop-Process -Force
    Start-Sleep -Seconds 1

    $RegPaths = @("HKLM:\SOFTWARE\RustDesk", "HKCU:\SOFTWARE\RustDesk")
    foreach ($Reg in $RegPaths) { if (Test-Path $Reg) { Remove-Item $Reg -Recurse -Force -ErrorAction SilentlyContinue } }

    $OldFolders = @(
        "$env:APPDATA\RustDesk", 
        "C:\Windows\ServiceProfiles\LocalService\AppData\Roaming\RustDesk",
        $InstallPath
    )

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

    Write-Host $Messages.GitHub -ForegroundColor Cyan
    $Headers = @{ "User-Agent" = "Mozilla/5.0" }
    if (-not [string]::IsNullOrWhiteSpace($GitToken)) {
        Write-Host $Messages.UsingToken -ForegroundColor Gray
        $Headers.Add("Authorization", "token $GitToken")
    }

    $Architecture = if ([IntPtr]::Size -eq 8) { "x86_64" } else { "x86" }
    $ReleaseData = Invoke-RestMethod -Uri "https://api.github.com/repos/rustdesk/rustdesk/releases/latest" -Headers $Headers
    $DownloadUrl = $ReleaseData.assets | Where-Object { $_.name -like "*$Architecture*" -and $_.name -like "*.exe" -and $_.name -notlike "*sciter*" } | Select-Object -ExpandProperty browser_download_url -First 1

    Write-Host ($Messages.Downloading -f $DownloadUrl)
    Invoke-WebRequest -Uri $DownloadUrl -OutFile $TempInstaller

    Write-Host $Messages.Installing -ForegroundColor Cyan
    Start-Process -FilePath $TempInstaller -ArgumentList "--silent-install"
    
    $Wait = 60
    while (-not (Test-Path "$InstallPath\rustdesk.exe") -and $Wait -gt 0) {
        Start-Sleep -Seconds 2
        $Wait -= 2
        Write-Host "." -NoNewline
    }
    Write-Host $Messages.FilesCopied -ForegroundColor Green

    Write-Host $Messages.KillProcess -ForegroundColor Yellow
    Get-Process "rustdesk" -ErrorAction SilentlyContinue | Stop-Process -Force
    Start-Sleep -Seconds 2

    $ConfigPaths = @(
        "$env:APPDATA\RustDesk\config",
        "C:\Windows\ServiceProfiles\LocalService\AppData\Roaming\RustDesk\config"
    )

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

    foreach ($CP in $ConfigPaths) {
        if (-not (Test-Path $CP)) { 
            New-Item -ItemType Directory -Path $CP -Force | Out-Null 
            Write-Host ($Messages.FolderCreated -f $CP) -ForegroundColor Gray
        }
        
        $ConfigFile = "$CP\RustDesk2.toml"
        $ConfigContent | Out-File -FilePath $ConfigFile -Encoding utf8 -Force
        
        try {
            $EveryoneIdentity = New-Object System.Security.Principal.SecurityIdentifier("S-1-1-0")
            $Acl = Get-Acl $ConfigFile
            $Ar = New-Object System.Security.AccessControl.FileSystemAccessRule($EveryoneIdentity, "ReadAndExecute", "Allow")
            $Acl.AddAccessRule($Ar)
            Set-Acl $ConfigFile $Acl
        } catch { }

        Set-ItemProperty -Path $ConfigFile -Name IsReadOnly -Value $true
        Write-Host ($Messages.ConfigProtected -f $ConfigFile) -ForegroundColor Gray
    }

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

    Write-Host $Messages.Cleanup -ForegroundColor Yellow
        
    foreach ($CP in $ConfigPaths) {
        $MainFile = "$CP\RustDesk2.toml"
            
        if (Test-Path $MainFile) {
            Set-ItemProperty -Path $MainFile -Name IsReadOnly -Value $false
        }

        Get-ChildItem -Path $CP -Filter "RustDesk2.*" | Where-Object { $_.Name -ne "RustDesk2.toml" } | Remove-Item -Force -ErrorAction SilentlyContinue
    }

    Write-Host $Messages.Success -ForegroundColor Green
}
catch { Write-Host ($Messages.Error -f $($_.Exception.Message)) -ForegroundColor Red }

Write-Host $Messages.Exit
$null = [Console]::ReadKey()
