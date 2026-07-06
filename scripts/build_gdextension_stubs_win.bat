@echo off
setlocal

set ROOT=%~dp0..
set FAILED=0

pushd "%ROOT%\addons\apple_sign_in\stubs\windows"
call compile_stub_win.bat apple_sign_in.windows.stub.x86_64.dll
if %ERRORLEVEL% neq 0 set FAILED=1
popd

pushd "%ROOT%\addons\godot-iap\stubs\windows"
call compile_stub_win.bat godot_iap.windows.stub.x86_64.dll
if %ERRORLEVEL% neq 0 set FAILED=1
popd

if %FAILED% neq 0 (
	echo.
	echo One or more stub builds failed.
	exit /b 1
)

echo.
echo All GDExtension Windows stubs built successfully.
exit /b 0
