@echo off
setlocal
if "%~1"=="" (
    echo Missing profile name for argument 1.
    exit /b 1
)

set conan_profile=%1
set script_dir=%~dp0
set root_dir=%script_dir%\..
set profile_path=%script_dir%\profiles\%conan_profile%
set build_dir=%root_dir%\output\%conan_profile%

if not exist %profile_path% (
    echo Conan profile file not found at %profile_path%
    exit /b 1
)

md %build_dir%
cd %build_dir%
call conan install %root_dir% -pr=%profile_path% --build missing
if not %ERRORLEVEL%==0 (
    exit /b %ERRORLEVEL%
)
set LP3_ROOT_PATH=%root_dir%\ci\media
call conan build %root_dir%
exit /b %ERRORLEVEL%
