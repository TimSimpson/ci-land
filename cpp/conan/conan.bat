@echo off
setlocal

set script_dir=%~dp0
set root_dir=%CD%

if "%PROFILE%"=="" (
    set PROFILE=%%PROFILE%%
)

set script_name=%~0
set profile_path=%script_dir%\profiles\%PROFILE%
set output_dir=%root_dir%\output
set build_dir=%output_dir%\%PROFILE%

set arg=%~1

if "%arg%"=="" (
    CALL :show_help
    exit /b 1
)

if "%arg%"=="bt" GOTO cmd_bt
if "%arg%"=="build" GOTO cmd_build
if "%arg%"=="clean" GOTO cmd_clean
if "%arg%"=="install" GOTO cmd_install
if "%arg%"=="package" GOTO cmd_package
if "%arg%"=="profiles" GOTO cmd_profiles
if "%arg%"=="rebuild" GOTO cmd_rebuild
if "%arg%"=="run" GOTO cmd_run
if "%arg%"=="test" GOTO cmd_test

ECHO "%arg%" is not a valid command.
exit /b 1

:show_help
    ECHO Usage: %script_name% [command]
    ECHO.
    ECHO     Commands:
    ECHO               bt           - build and run ctest in %build_dir%
    ECHO               build        - build in %build_dir%
    ECHO               clean        - Erase %build_dir%
    ECHO               install      - install to %build_dir%
    ECHO               package      - create and test package
    ECHO               profiles     - list profiles
    ECHO               rebuild      - calls CMake directly in %build_dir%
    ECHO               run          - install, build, and test
    ECHO               test         - run ctest in %build_dir%
    ECHO.
GOTO :EOF

:profile_hint
    ECHO See valid profiles using:
    ECHO.
    ECHO       %script_name% profiles
    ECHO.
GOTO :EOF

:require_valid_profile
    if "%PROFILE%"=="%%PROFILE%%" (
        ECHO PROFILE environment variable not set. Set it to a valid profile.
        CALL :profile_hint
        rem (GOTO) 2>NUL exits instantly, and is apparently a huge hack. Oh well.
        (GOTO) 2>NUL
    )
    if exist %profile_path% (
        rem hi
    ) else (
        ECHO Conan profile file not found at "%profile_path%"
        CALL :profile_hint
        (GOTO) 2>NUL
    )
GOTO :EOF

:profile_warning
    if "%PROFILE%"=="%%PROFILE%%" (
        ECHO     Warning: %%PROFILE%% not set. Set it to a valid profile.
        GOTO :EOF
    )
    if exist %profile_path% (
        rem whaddup
    ) else (
        ECHO     Warning: %%PROFILE%% is invalid; Conan profile file not found at "%profile_path%"
        ECHO .
    )
GOTO :EOF

:make_build_dir
    if exist %build_dir% (
        rem wassup
    ) else (
        md %build_dir%
    )
GOTO :EOF

:cmd_bt
    CALL :cmd_build
    CALL :cmd_test
GOTO :EOF

:cmd_build
    CALL :require_valid_profile
    cd %build_dir%
    call conan build %root_dir%
    if not %ERRORLEVEL%==0 (
        cd %root_dir%
        exit /b %ERRORLEVEL%
    )
    cd %root_dir%
    if "%~1"=="test" (
        CALL :cmd_test
    )
    cd %root_dir%
GOTO :EOF

:cmd_clean
    CALL :require_valid_profile
    if exist %build_dir% (
        @RD /S /Q %build_dir%
    ) else (
        ECHO It was already gone...
    )
GOTO :EOF

:cmd_install
    CALL :require_valid_profile
    CALL :make_build_dir
    cd %build_dir%
    call conan install %root_dir% -pr=%profile_path% --build missing
    if not %ERRORLEVEL%==0 (
        set result=%ERRORLEVEL%
        cd %root_dir%
        exit /b %result%
    )
    cd %root_dir%
GOTO :EOF

:cmd_package
    CALL "%script_dir%\package.bat" %2 %3 %4 %5 %6 %7 %8 %9
GOTO :EOF

:cmd_profiles
    ECHO Set the %%PROFILES%% environment variable to the name of a file below:
    ECHO.
    dir "%script_dir%\profiles"
GOTO :EOF

:cmd_rebuild
GOTO :EOF

:cmd_run
    CALL :cmd_install
    CALL :cmd_bt
GOTO :EOF

:cmd_test
    CALL :make_build_dir
    cd %build_dir%
    set CTEST_OUTPUT_ON_FAILURE=1
    ctest
    if not %ERRORLEVEL%==0 (
        set result=%ERRORLEVEL%
        cd %root_dir%
        exit /b %result%
    )
    cd %root_dir%
GOTO :EOF
