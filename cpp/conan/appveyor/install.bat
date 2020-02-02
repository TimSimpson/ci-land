if "%APPVEYOR_BUILD_FOLDER%"=="" (
    echo This is expected to be run from AppVeyor.
    exit /b 1
)

set PYTHON="C:\Python37"
set PATH=%PYTHON%\Scripts;%PATH%

call pip.exe install conan --upgrade
call conan remote add bincrafters https://api.bintray.com/conan/bincrafters/public-conan
call conan user
