@echo on
set "src=%SRC_DIR%\%PKG_NAME%"

pushd %SRC_DIR%
  FOR /F "usebackq tokens=1" %%i IN (`DIR /S/B *.conda` ) DO (
    echo "Converting .conda to .tar.bz2"
    cph transmute %%i .tar.bz2
    del %%i
  )

  FOR /F "usebackq tokens=1" %%i IN (`DIR /S/B *.tar.bz2` ) DO (
    echo "Extracting .tar.bz2"
    cph extract %%i --dest %%i\..
    del %%i
  )
popd

robocopy /E "%src%" "%PREFIX%"
if %ERRORLEVEL% GEQ 8 exit 1

:: replace old info folder with our new regenerated one
rd /s /q %PREFIX%\info

:: The Intel upstream packages install license files to a shared path
:: (share\doc\mkl\licensing\) which causes conda ClobberWarnings when multiple
:: packages (e.g. mkl and mkl-include) are installed together into the same env.
:: Move them to a per-package unique path to avoid the conflict.
if exist "%PREFIX%\share\doc\mkl\licensing" if NOT "%PKG_NAME%"=="mkl" (
    mkdir "%PREFIX%\share\doc\%PKG_NAME%\licensing"
    robocopy "%PREFIX%\share\doc\mkl\licensing" "%PREFIX%\share\doc\%PKG_NAME%\licensing" /E /MOVE
    if %ERRORLEVEL% GEQ 8 exit 1
    rd /s /q "%PREFIX%\share\doc\mkl\licensing"
    rd "%PREFIX%\share\doc\mkl" 2>nul
)
