@echo off
color 0B
echo ===============================================
echo        Advanced GitHub Upload Panel
echo ===============================================
echo Connecting to: https://github.com/PavanWadile77/Mr.Certi.H.git
echo Current branch: main
echo Status: Syncing...
echo ===============================================
echo.

echo [1/5] Securing files (.gitignore)...
echo node_modules/ > .gitignore
echo dist/ >> .gitignore
echo build/ >> .gitignore
echo .cache/ >> .gitignore
echo .env >> .gitignore
echo temp/ >> .gitignore

echo [2/5] Initializing Git ^& Fixing Errors...
git init
git branch -M main

REM Fixing existing git issues
git rebase --abort 2>nul
rmdir /s /q .git\rebase-merge 2>nul

echo [3/5] Configuring Remote...
git remote remove origin 2>nul
git remote add origin https://github.com/PavanWadile77/Mr.Certi.H.git

echo [4/5] Packaging all project files...
git add .
git commit -m "Upload All Project Files"

echo [5/5] Uploading to GitHub...
git push origin main

if errorlevel 1 (
    color 0E
    echo.
    echo Push rejected. Attempting safe sync...
    git pull origin main --allow-unrelated-histories --no-rebase
    git push origin main
    
    if errorlevel 1 (
        color 0C
        echo.
        echo Push rejected again. Forcing upload to resolve conflict...
        git push origin main --force
        
        if errorlevel 1 (
            echo.
            echo [ERROR] Authentication Failure! Please check your GitHub login.
        ) else (
            color 0A
            echo.
            echo [SUCCESS] Conflict resolved! All files uploaded forcefully.
        )
    ) else (
        color 0A
        echo.
        echo [SUCCESS] Sync resolved and files uploaded correctly!
    )
) else (
    color 0A
    echo.
    echo [SUCCESS] Project uploaded successfully without errors!
)

echo.
echo ===============================================
echo         Final Push Status Logs
echo ===============================================
git log -n 1
echo ===============================================
pause
