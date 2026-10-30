@echo off
:: Portable build of this fork: one folder (plus a zip of it), no installer.
:: RHI keeps its settings, caches, logs and downloads in a "Data" folder next to RHI.exe.
:: Self-contained, so the target PC does not need the .NET runtime installed.
setlocal
cd /d "%~dp0"
set OUT=%~dp0dist\RHI-Portable
set ZIP=%~dp0dist\RHI-Portable.zip
set SRC=RenoDXCommander

if exist "%OUT%" (
    :: Keep an existing Data folder so rebuilding doesn't wipe your settings
    if exist "%OUT%\Data" move "%OUT%\Data" "%~dp0dist\Data.keep" >nul
    rmdir /s /q "%OUT%"
)

dotnet publish %SRC%\RenoDXCommander.csproj -c Release -r win-x64 -p:PublishSingleFile=true -p:Platform=x64 --self-contained true -o "%OUT%"
if %errorlevel% neq 0 (
    echo dotnet publish failed.
    exit /b 1
)

:: Drop helper (non-elevated overlay for admin mode drag-drop)
dotnet build RHI.DropHelper\RHI.DropHelper.csproj -c Release -v quiet
copy /y "RHI.DropHelper\bin\x64\Release\net8.0-windows\RHI.DropHelper.exe" "%OUT%\" >nul
copy /y "RHI.DropHelper\bin\x64\Release\net8.0-windows\RHI.DropHelper.dll" "%OUT%\" >nul 2>nul
copy /y "RHI.DropHelper\bin\x64\Release\net8.0-windows\RHI.DropHelper.runtimeconfig.json" "%OUT%\" >nul

:: Content files the app reads from its own folder
for %%F in (icon.ico 7z.exe 7z.dll ReShade.ini ReShade.Vulkan.ini ReShade64.json RHI_PatchNotes.md relimiter.ini DisplayCommander.ini dxvk.conf reshade.rdr2.ini) do (
    if exist "%SRC%\%%F" copy /y "%SRC%\%%F" "%OUT%\" >nul
)
copy /y "%SRC%\OptiScaler*.ini" "%OUT%\" >nul
if not exist "%OUT%\Assets\icons" mkdir "%OUT%\Assets\icons"
copy /y "%SRC%\Assets\icons\*.ico" "%OUT%\Assets\icons\" >nul
copy /y "%SRC%\Assets\icons\*.png" "%OUT%\Assets\icons\" >nul

:: ClrMD for freeze diagnostics (optional; only present if the package is in the NuGet cache)
set CLRMD=%USERPROFILE%\.nuget\packages\microsoft.diagnostics.runtime\3.1.512801\lib\net6.0\Microsoft.Diagnostics.Runtime.dll
if exist "%CLRMD%" copy /y "%CLRMD%" "%OUT%\" >nul

:: Debug symbols aren't needed in the portable copy
del /q "%OUT%\*.pdb" 2>nul

if exist "%ZIP%" del /q "%ZIP%"
powershell -NoProfile -Command "Compress-Archive -Path '%OUT%\*' -DestinationPath '%ZIP%'"

if exist "%~dp0dist\Data.keep" move "%~dp0dist\Data.keep" "%OUT%\Data" >nul

echo.
echo Portable build: %OUT%
echo Zip:            %ZIP%
endlocal
