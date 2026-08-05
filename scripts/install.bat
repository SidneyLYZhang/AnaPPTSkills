@echo off
setlocal enabledelayedexpansion

REM AnaPPTSkills installer entry point (BAT wrapper).
REM Pure ASCII. Calls install.ps1 with -ExecutionPolicy Bypass so users can
REM double-click without first loosening PowerShell policy.
REM
REM Args are normalized (--foo -> -foo) so both --cn and -cn work.

set "SCRIPT_DIR=%~dp0"
if "!SCRIPT_DIR:~-1!"=="\" set "SCRIPT_DIR=!SCRIPT_DIR:~0,-1!"

set "PS_EXE=powershell.exe"
where /q pwsh.exe 2>nul
if %ERRORLEVEL% equ 0 set "PS_EXE=pwsh.exe"

set "PS_ARGS="
set "PS_FILE=!SCRIPT_DIR!\install.ps1"

if not exist "!PS_FILE!" (
    echo [ERROR] install.ps1 not found next to install.bat: !PS_FILE!
    exit /b 65
)

REM --------------------------------------------------------------------------
REM Parse and normalize args
REM --------------------------------------------------------------------------
:parse_args
if "%~1"=="" goto after_parse

set "ARG=%~1"

REM If the arg starts with --, strip one dash so PS binds it correctly.
if /i "!ARG:~0,2!"=="--" set "ARG=-!ARG:~2!"

REM If the arg is a path value following -Source/-Target, do NOT touch it.
REM Values are detected by position: the previous token was -Source or -Target.
REM To keep the parser simple we just append the (already-normalized) token;
REM PS's parameter binder accepts -Source <path> regardless of leading dashes
REM in the value because <path> does not start with -.
set "PS_ARGS=!PS_ARGS! "!ARG!""

shift
goto parse_args
:after_parse

REM --------------------------------------------------------------------------
REM Hand off to PowerShell
REM --------------------------------------------------------------------------
"!PS_EXE!" -NoProfile -ExecutionPolicy Bypass -File "!PS_FILE!" !PS_ARGS!
set "EXITCODE=%ERRORLEVEL%"

endlocal & exit /b %EXITCODE%
