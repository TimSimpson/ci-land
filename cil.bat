@echo off
setlocal

set script_dir=%~dp0

set arg=%~1

if "%arg%"=="" (
    CALL :cmd_splash
    ECHO.
    CALL :show_help
    exit /b 1
)

if "%arg%"=="run" (
    CALL "%script_dir%\cpp\conan\conan.bat" run %2 %3 %4 %5 %6 %7 %8 %9
    exit /b %ERRORLEVEL%
)
if "%arg%"=="build" (
    CALL :cmd_run
    exit /b %ERRORLEVEL%
)
if "%arg%"=="conan" (
    CALL :cmd_conan %*
    exit /b %ERRORLEVEL%
)
if "%arg%"=="clean" GOTO cmd_clean
if "%arg%"=="profiles" GOTO cmd_profilescd

ECHO "'%arg%' is not a valid command."
exit /b 1

:cmd_splash
type "%script_dir%\splash-win.txt"
GOTO :EOF

:show_help
ECHO Usage: %0 [command]
ECHO.
ECHO     Commands:
ECHO           profiles    - Show list of Conan profiles
ECHO           build       - Builds C++ stuff (call run first)
ECHO           clean       - Clean up output directory
ECHO           conan       - Runs conan commands
ECHO           format      - Formats code
ECHO           generate    - Generates common CI configs
ECHO           package     - Runs package script
ECHO           run         - Installs and builds C++ stuff
ECHO           splash      - Really important picture with a bird
ECHO           test        - Run ctests in build directory
ECHO.
GOTO :EOF

:cmd_clean
@RD /S /Q output
GOTO :EOF

:cmd_conan
    CALL "%script_dir%\cpp\conan\conan.bat" %2 %3 %4 %5 %6 %7 %8 %9
GOTO :EOF

:cmd_profiles
dir "%script_dir%\cpp\conan\profiles"
GOTO :EOF

:cmd_run
%script_dir%\cpp\conan\run.bat
GOTO :EOF
