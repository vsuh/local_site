@echo off
setlocal

set HOOKS_DIR=.githooks
set VENV_DIR=.venv
set HOOK_FILE=%HOOKS_DIR%\pre-commit

:: ������� ����������� ���������
if not exist "%VENV_DIR%" (
    echo Creating Python virtual environment...
    python -m venv "%VENV_DIR%"
    if errorlevel 1 exit /b 1
)

:: ������������� �����������
echo Installing Python dependencies...
call "%VENV_DIR%\Scripts\python.exe" -m pip install -r requirements.txt
if errorlevel 1 exit /b 1

:: ����������� hooksPath
echo Configuring git hooks path...
git config --unset core.hooksPath
git config --local core.hooksPath "%HOOKS_DIR%"
if errorlevel 1 exit /b 1

:: ������� ���������� ��� �����
if not exist "%HOOKS_DIR%" mkdir "%HOOKS_DIR%"

:: ������� ���� ����
echo Creating pre-commit hook...
echo #!/bin/sh > "%HOOK_FILE%"
echo. >> "%HOOK_FILE%"
echo CHANGED_FILES=^$(git diff --cached --name-only --diff-filter=ACM ^| grep -E 'src/(index\.tpl^|site\.json)') >> "%HOOK_FILE%"
echo. >> "%HOOK_FILE%"
echo if [ -n "^$CHANGED_FILES^" ] ^|^| [ ! -f index.html ]; then >> "%HOOK_FILE%"
echo     echo 'Changes detected in template or config, generating index.html...' >> "%HOOK_FILE%"
echo     .venv/Scripts/python.exe src/generate.py ^|^| exit 1 >> "%HOOK_FILE%"
echo     # git add index.html >> "%HOOK_FILE%"
echo fi >> "%HOOK_FILE%"
echo exit 0 >> "%HOOK_FILE%"

:: ������������� ����� ����� Git Bash
where bash >nul 2>&1
if %errorlevel% equ 0 (
    bash -c "chmod +x '%HOOK_FILE%'"
)

echo Hook system configured successfully
endlocal







///////////////////


@echo off
setlocal

set HOOK_FILE=.git\hooks\pre-commit
set HOOK_SCRIPT=#!/bin/sh

set HOOK_SCRIPT=%HOOK_SCRIPT%^

# ��������� ��������� � �������� ������^
CHANGED_FILES=^$(git diff --cached --name-only --diff-filter=ACM | grep -E 'src/(index\.tpl|site\.json)'^)^

if [ -n "^$CHANGED_FILES^" ] || [ ! -f index.html ]; then^
    echo 'Changes detected in template or config, generating index.html...'^
    ^
    # ��������� �����������^
    if ! python -c "import jinja2" >nul 2>&1; then^
        echo 'Installing requirements...'^
        pip install -r requirements.txt || exit 1^
    fi^
    ^
    # ���������� ����^
    python src\generate.py || exit 1^
    ^
    # ��������� � ������^
    git add index.html^
fi^
^
exit 0

:: ������� ���������� �����
if not exist ".git\hooks" mkdir ".git\hooks"

:: ���������� ������
echo %HOOK_SCRIPT% > %HOOK_FILE%

:: ������������� ����� ��� Git Bash
where bash >nul 2>&1
if %errorlevel% equ 0 (
    bash -c "chmod +x '%HOOK_FILE%'"
)

echo Pre-commit hook installed successfully
endlocal
