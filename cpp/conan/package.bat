@echo off
setlocal

set script_dir=%~dp0
set root_dir=%CD%

if "%PROFILE%"=="" (
    set PROFILE=%%PROFILE%%
)

if "%CONAN_USERNAME%"=="" (
    set CONAN_USERNAME=_
)
if "%CONAN_CHANNEL%"=="" (
    set CONAN_CHANNEL=_
)

set script_name=%~0
set profile_path=%script_dir%\profiles\%PROFILE%
set output_root_dir=%root_dir%\output
set output_dir=%output_root_dir%\%PROFILE%
set source_folder=%output_dir%\source
set install_folder=%output_dir%\install
set build_folder=%output_dir%\build
set package_folder=%output_dir%\package

set build_dir=%output_dir%\%PROFILE%

set arg=%~1

if "%arg%"=="" (
    CALL :show_help
    exit /b 1
)

if "%arg%"=="all" GOTO cmd_all
if "%arg%"=="build" GOTO cmd_build
if "%arg%"=="clean" GOTO cmd_clean
if "%arg%"=="create" GOTO cmd_create
if "%arg%"=="export" GOTO cmd_export
if "%arg%"=="install" GOTO cmd_install
if "%arg%"=="package" GOTO cmd_package
if "%arg%"=="profiles" GOTO cmd_profiles
if "%arg%"=="rebuild" GOTO cmd_rebuild
if "%arg%"=="settings" GOTO cmd_settings
if "%arg%"=="source" GOTO cmd_source
if "%arg%"=="run" GOTO cmd_run
if "%arg%"=="test" GOTO cmd_test
if "%arg%"=="test_package" GOTO cmd_test_package
if "%arg%"=="upload" GOTO cmd_upload

ECHO "%arg%" is not a valid command.
exit /b 1

:show_help
    CALL :set_package_vars
    ECHO Usage: %script_name% [command]
    ECHO.
    ECHO    Commands:
    ECHO            profiles     - List all profiles in %script_dir%\profiles
    ECHO            clean        - Erase %output_dir%
    ECHO            source       - run conan source, put in %source_folder%
    ECHO            install      - install to %install_folder%
    ECHO            build        - build in %build_folder%
    ECHO            package      - package in %package_folder%
    ECHO            export       - export package to local cache
    ECHO            test         - tests binaries in %build_folder%
    ECHO            test_package - tests package "%package_name_and_version%"
    ECHO            all          - do all of the above
    ECHO            create       - run conan create
    ECHO            upload       - uploads "%package_reference%"
    ECHO            settings     - show paths and other variables
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
        rem hi
    ) else (
        ECHO     Warning: %%PROFILE%% is invalid; Conan profile file not found at "%profile_path%"
        ECHO .
    )
GOTO :EOF

:print_name_and_version
    set PYTHONPATH=%script_dir%\version_extractor
    python conanfile.py
GOTO :EOF

:print_package_reference
    set package_name_and_version=%2
    ECHO %package_name_and_version%@%CONAN_USERNAME%/%CONAN_CHANNEL%
GOTO :EOF

:check_upload_settings
    if "%CONAN_USERNAME%"=="_" (
        ECHO CONAN_USERNAME is not set. Aborting!
        rem (GOTO) 2>NUL exits instantly, and is apparently a huge hack. Oh well.
        (GOTO) 2>NUL
    )
    if "%CONAN_CHANNEL%"=="_" (
        ECHO CONAN_CHANNEL is not set. Aborting!
        (GOTO) 2>NUL
    )
GOTO :EOF

:set_package_vars
    set oldpythonpath=%PYTHONPATH%
    set PYTHONPATH=%script_dir%\version_extractor
    for /f "tokens=*" %%a in ('python conanfile.py') do set package_name_and_version=%%a
    set PYTHONPATH=%oldpythonpath%
    set package_reference=%package_name_and_version%@%CONAN_USERNAME%/%CONAN_CHANNEL%
GOTO :EOF

:make_build_dir
    if exist %build_dir% (
        rem wassup
    ) else (
        md %build_dir%
    )
GOTO :EOF

:make_dir
    if exist %dir% (
        rem wassup
    ) else (
        md %dir%
    )
GOTO :EOF

:cmd_build
    set CONAN_SKIP_TESTS=true
    CALL :require_valid_profile
    set dir=%build_folder%
    CALL :make_dir
    call conan build %root_dir% --source-folder=%source_folder% --install-folder=%install_folder% --build-folder=%build_folder%
    if not %ERRORLEVEL%==0 (
        exit /b %ERRORLEVEL%
    )
GOTO :EOF

:cmd_clean
    CALL :require_valid_profile
    if exist %build_dir% (
        @RD /S /Q %build_dir%
    ) else (
        ECHO It was already gone...
    )
GOTO :EOF

:cmd_export
    set CONAN_SKIP_TESTS=true
    CALL :require_valid_profile
    CALL :set_package_vars
    CALL conan remove -f %package_reference%
    if not %ERRORLEVEL%==0 (
        echo Oh well! We're going to add it!
    )
    CALL conan export-pkg %root_dir% -f --package=%package_folder% -pr=%profile_path%
    if not %ERRORLEVEL%==0 (
        exit /b %ERRORLEVEL%
    )
GOTO :EOF

:cmd_source
    CALL :require_valid_profile
    set dir=%source_folder%
    CALL :make_dir
    CALL conan source . --source-folder=%source_folder%
    if not %ERRORLEVEL%==0 (
        exit /b %ERRORLEVEL%
    )
GOTO :EOF

:cmd_install
    set CONAN_SKIP_TESTS=true
    CALL :require_valid_profile
    set dir=%install_folder%
    CALL :make_dir
    call conan install %root_dir% --install-folder=%install_folder% -pr=%profile_path% --build missing
    if not %ERRORLEVEL%==0 (
        exit /b %ERRORLEVEL%
    )
GOTO :EOF

:cmd_package
    set CONAN_SKIP_TESTS=true
    CALL :require_valid_profile
    set dir=%package_folder%
    CALL :make_dir
    call conan package %root_dir% --source-folder=%source_folder% --install-folder=%install_folder% --build-folder=%build_folder% --package=%package_folder%
    if not %ERRORLEVEL%==0 (
        exit /b %ERRORLEVEL%
    )
GOTO :EOF

:cmd_profiles
    ECHO Set the %%PROFILES%% environment variable to the name of a file below:
    ECHO.
    dir "%script_dir%\profiles"
GOTO :EOF

:cmd_rebuild
GOTO :EOF

:cmd_settings
    CALL :set_package_vars
    ECHO .
    ECHO    Paths:
    ECHO          package_reference        - %package_reference%
    ECHO          package_name_and_version - %package_name_and_version%
    ECHO          source_folder            - %source_folder%
    ECHO          install_folder           - %install_folder%
    ECHO          build_folder             - %build_folder%
    ECHO          package_folder           - %package_folder%
    ECHO.
    CALL :profile_warning
GOTO :EOF


:cmd_run
    CALL :cmd_install
    CALL :cmd_bt
GOTO :EOF

:cmd_test
    set CONAN_SKIP_TESTS=true
    CALL :require_valid_profile
    set dir=%build_folder%
    CALL :make_dir
    cd %build_folder%
    CALL ctest %2 %3 %4 %5 %6 %7 %8 %9
    if not %ERRORLEVEL%==0 (
        set result=%ERRORLEVEL%
        cd %root_dir%
        exit /b %result%
    )
    cd %root_dir%
GOTO :EOF

:cmd_test_package
    set CONAN_SKIP_TESTS=true
    CALL :require_valid_profile
    CALL :set_package_vars
    CALL conan test test_package -pr=%profile_path% --build missing %package_reference%
    if not %ERRORLEVEL%==0 (
        exit /b %ERRORLEVEL%
    )
GOTO :EOF

:cmd_all
    CALL :require_valid_profile
    CALL :cmd_clean
    if not %ERRORLEVEL%==0 (
        exit /b %ERRORLEVEL%
    )
    CALL :cmd_source
    if not %ERRORLEVEL%==0 (
        exit /b %ERRORLEVEL%
    )
    CALL :cmd_install
    if not %ERRORLEVEL%==0 (
        exit /b %ERRORLEVEL%
    )
    CALL :cmd_build
    if not %ERRORLEVEL%==0 (
        exit /b %ERRORLEVEL%
    )
    CALL :cmd_test
    if not %ERRORLEVEL%==0 (
        exit /b %ERRORLEVEL%
    )
    CALL :cmd_package
    if not %ERRORLEVEL%==0 (
        exit /b %ERRORLEVEL%
    )
    CALL :cmd_export
    if not %ERRORLEVEL%==0 (
        exit /b %ERRORLEVEL%
    )
    CALL :cmd_test_package
    if not %ERRORLEVEL%==0 (
        exit /b %ERRORLEVEL%
    )
GOTO :EOF
