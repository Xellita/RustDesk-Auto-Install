# RustDesk Auto Install

[English](#english) | [Русский](#русский)

---

## English

Automated script for installing and configuring RustDesk. Designed to quickly deploy clients with pre-defined self-hosted server parameters.

### Key Features
1. **System Preparation & Cleanup**:
   - Stops all active `rustdesk.exe` processes.
   - Removes HKLM and HKCU registry keys (`Software\RustDesk`).
   - Deletes old binary files from the installation directory.
   - Cleans up old configuration files and logs in AppData and LocalService.
   - **Note**: The "peers" folder (saved contacts) is preserved if it existed.
2. **Automated Installation**:
   - Dynamic detection of system architecture (x64/x86).
   - Uses GitHub API to find and download the latest stable release.
   - Automatic background installation (Silent Install).
3. **Configuration & Security**:
   - Generates `RustDesk2.toml` with your Relay server parameters.
   - Configures Access Control Lists (ACL) for correct service operation.
   - Installs and starts RustDesk as a Windows system service.
   - Sets a static administrator password.

### Usage Instructions
1. Download the latest version from the **Releases** section.
2. Place the `config.json` file in the same directory as the executable.
3. Run the executable as Administrator.

#### config.json Structure

```json
{
    "RelayServer": "192.168.1.50",
    "RendezvousPort": "21116",
    "RelayPort": "21117",
    "StaticPassword": "YourStrongPassword",
    "Key": "Key_From_Your_Server",
    "GitToken": ""
}
```
*Note: The GitToken parameter is optional and used to bypass GitHub API rate limits during mass installations under a single IP.*

### Technical Details:
- Runtime: PowerShell 5.1+.
- Build Method: Executable built using PS2EXE.
- Localization: Console interface automatically switches between RU/EN based on OS language.

*This software is provided "AS IS" under the MIT License.*

---

## Русский

Скрипт для автоматизированной установки и настройки RustDesk. Предназначен для быстрого развертывания клиента с предустановленными параметрами собственного сервера.

### Основной функционал
1. **Подготовка и очистка системы**:
   - Остановка всех активных процессов `rustdesk.exe`.
   - Удаление веток реестра HKLM и HKCU (`Software\RustDesk`).
   - Полное удаление старых файлов из директории установки.
   - Очистка от старых конфигурационных файлов и логов в AppData и LocalService.
   - **Важно**: папка "peers" (сохраненные контакты) сохраняется, если она существовала ранее.
2. **Автоматизация процесса установки**:
   - Динамическое определение текущей архитектуры системы (x64/x86).
   - Использование GitHub API для поиска и загрузки последней стабильной версии.
   - Автоматическая фоновая установка (Silent Install).
3. **Конфигурация и защита**:
   - Автоматическое формирование файла `RustDesk2.toml` с параметрами вашего Relay-сервера.
   - Настройка прав доступа (ACL) для корректного чтения конфигурации системной службой.
   - Установка и запуск RustDesk в качестве системной службы Windows.
   - Назначение статического пароля для административного доступа.

### Инструкция по эксплуатации
1. Перейдите в раздел **Releases** и скачайте актуальную версию инсталлятора.
2. Разместите файл конфигурации `config.json` в одной директории с исполняемым файлом.
3. Запустите исполняемый файл от имени Администратора.

#### Структура файла config.json
```json
{
    "RelayServer": "192.168.1.50",
    "RendezvousPort": "21116",
    "RelayPort": "21117",
    "StaticPassword": "YourStrongPassword",
    "Key": "Key_From_Your_Server",
    "GitToken": ""
}
```
*Примечание: Параметр GitToken является опциональным и используется для обхода лимитов GitHub API при массовых одновременных установках под одним IP.*

### Технические сведения 
- Среда исполнения: PowerShell 5.1+.
- Метод сборки: Исполняемый файл собран с помощью PS2EXE.
- Локализация: Интерфейс консоли автоматически переключается между русским и английским языками в зависимости от языка ОС.

*Данное программное обеспечение предоставляется "как есть" (AS IS) под лицензией MIT.*

---
