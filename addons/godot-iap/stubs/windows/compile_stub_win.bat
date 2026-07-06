@echo off
setlocal

set "VSWHERE=%ProgramFiles(x86)%\Microsoft Visual Studio\Installer\vswhere.exe"
if not exist "%VSWHERE%" (
	echo ERROR: vswhere.exe not found. Install Visual Studio C++ build tools.
	exit /b 1
)

for /f "usebackq delims=" %%i in (`"%VSWHERE%" -latest -products * -requires Microsoft.VisualStudio.Component.VC.Tools.x86.x64 -property installationPath`) do set "VSINSTALL=%%i"
if not defined VSINSTALL (
	echo ERROR: Visual Studio C++ tools not found.
	exit /b 1
)

call "%VSINSTALL%\VC\Auxiliary\Build\vcvars64.bat" >nul
if %ERRORLEVEL% neq 0 exit /b %ERRORLEVEL%

set OUT_DLL=%~1
if "%OUT_DLL%"=="" (
	echo Usage: %~nx0 ^<output.dll^>
	exit /b 1
)

cl /nologo /LD stub.c /Fe:%OUT_DLL% >nul
if %ERRORLEVEL% neq 0 exit /b %ERRORLEVEL%

del /q *.obj *.exp *.lib 2>nul
echo Built %OUT_DLL%
exit /b 0
