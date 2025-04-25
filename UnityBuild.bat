@echo off
setlocal enabledelayedexpansion

:: Unity�Զ�����ű�
echo =================================
echo Unity��׿����Զ�������
echo =================================

:: ����Ĭ��·��
set "UNITY_DEFAULT=D:\UnityVs\Unity Hub\Unitys\2022.3.53f1\Editor\Unity.exe"
set "PROJECT_DEFAULT=E:\Unity\YZJ\2025\BuildScriptProject"
set "OUTPUT_DIR=%~dp0Builds\APK"
set "CONFIG_FILE=%~dp0build_config.txt"
set "LOG_DIR=%~dp0logs"
set "DEV_NULL=nul"

:: ��ȡ���������
call :readConfig

:: ���������в���
if not "%~1"=="" set "UNITY_PATH=%~1"
if not "%~2"=="" set "PROJECT_PATH=%~2"

:: ȷ��Unity·��������ȷ
if not defined UNITY_PATH call :promptUnityPath
call :validateUnityPath

:: ȷ����Ŀ·��������ȷ
if not defined PROJECT_PATH call :promptProjectPath
call :validateProjectPath

:: ������Ҫ��Ŀ¼
call :createDirs

:: ��������
call :saveConfig

:: ����ʱ���
call :createTimestamp

:: ѡ�񹹽�ƽ̨
call :selectPlatform

:: ѡ�񹹽�ѡ��
call :selectBuildOptions

:: ��ʾ������Ϣ
call :showBuildInfo

:: ִ�й���
call :doBuild

:: �ű�����
goto :end

:readConfig
if exist "%CONFIG_FILE%" (
    echo ��ȡ�����ļ�...
    for /f "usebackq tokens=1,* delims==" %%a in ("%CONFIG_FILE%") do (
        if "%%a"=="UNITY_PATH" set "UNITY_PATH=%%b"
        if "%%a"=="PROJECT_PATH" set "PROJECT_PATH=%%b"
    )
)
exit /b

:promptUnityPath
echo.
echo ������Unity�༭��·�� [%UNITY_DEFAULT%]:
set /p "INPUT="
if "!INPUT!"=="" (
    set "UNITY_PATH=%UNITY_DEFAULT%"
) else (
    set "UNITY_PATH=!INPUT!"
)
exit /b

:validateUnityPath
if not exist "%UNITY_PATH%" (
    echo ����: Unity·��������: "%UNITY_PATH%"
    echo ��ʹ��Ĭ��·��: "%UNITY_DEFAULT%"
    set "UNITY_PATH=%UNITY_DEFAULT%"
    
    if not exist "%UNITY_PATH%" (
        echo ����: Ĭ��Unity·��Ҳ������!
        echo ��ȷ��Unity�İ�װ·�����������д˽ű���
        pause
        exit 1
    )
)
exit /b

:promptProjectPath
echo.
echo ��������Ŀ·�� [%PROJECT_DEFAULT%]:
set /p "INPUT="
if "!INPUT!"=="" (
    set "PROJECT_PATH=%PROJECT_DEFAULT%"
) else (
    set "PROJECT_PATH=!INPUT!"
)
exit /b

:validateProjectPath
if not exist "%PROJECT_PATH%" (
    echo ����: ��Ŀ·��������: "%PROJECT_PATH%"
    echo ��ʹ��Ĭ��·��: "%PROJECT_DEFAULT%"
    set "PROJECT_PATH=%PROJECT_DEFAULT%"
    
    if not exist "%PROJECT_PATH%" (
        echo ����: Ĭ����Ŀ·��Ҳ������!
        echo ��ȷ��Unity��Ŀ·�����������д˽ű���
        pause
        exit 1
    )
)
exit /b

:createDirs
if not exist "%OUTPUT_DIR%" mkdir "%OUTPUT_DIR%" 2>%DEV_NULL%
if not exist "%LOG_DIR%" mkdir "%LOG_DIR%" 2>%DEV_NULL%
exit /b

:saveConfig
(
    echo UNITY_PATH=%UNITY_PATH%
    echo PROJECT_PATH=%PROJECT_PATH%
) > "%CONFIG_FILE%" 2>%DEV_NULL%
exit /b

:createTimestamp
for /f "tokens=2-4 delims=/ " %%a in ('date /t') do (
    set "datestamp=%%c%%a%%b"
)
for /f "tokens=1-3 delims=:." %%a in ('time /t') do (
    set "timestamp=%%a%%b"
)
set "timestamp=!timestamp: =0!"
set "TIMESTAMP=!datestamp!_!timestamp!"
set "LOG_FILE=%LOG_DIR%\build_log_!TIMESTAMP!.txt"
exit /b

:selectPlatform
echo.
echo ѡ�񹹽�ƽ̨:
echo [1] Android (Ĭ��)
echo [2] iOS
echo [3] Windows
echo [4] ȫ��ƽ̨ (Android+iOS+Windows)
echo.
set /p "PLATFORM_CHOICE=��ѡ�� (1-4): "

set "BUILD_METHOD=ProjectBuild.BuildForAndroid"
if "!PLATFORM_CHOICE!"=="2" set "BUILD_METHOD=ProjectBuild.BuildForiOS"
if "!PLATFORM_CHOICE!"=="3" set "BUILD_METHOD=ProjectBuild.BuildForWindows"
if "!PLATFORM_CHOICE!"=="4" set "BUILD_METHOD=ProjectBuild.BuildAll"
exit /b

:selectBuildOptions
echo.
echo ѡ�񹹽�ѡ�� (�����Ӧ�����֣����ѡ���ÿո�ָ�):
echo [1] ����ģʽ���� (Development Build)
echo [2] �������ܷ��� (Connect Profiler)
echo [3] ���ýű����� (Allow Debugging)
echo [4] ��ϸ������־ (Verbose)
echo [5] ������װAPK�����ӵ��豸
echo [6] ����������Ӧ�ó���
echo.
set /p "BUILD_OPTIONS=��ѡ�񹹽�ѡ�� (����: 1 3): "

set "OPTION_PARAMS="
echo %BUILD_OPTIONS% | findstr /C:"1" >nul && set "OPTION_PARAMS=%OPTION_PARAMS% -development"
echo %BUILD_OPTIONS% | findstr /C:"2" >nul && set "OPTION_PARAMS=%OPTION_PARAMS% -profiling"
echo %BUILD_OPTIONS% | findstr /C:"3" >nul && set "OPTION_PARAMS=%OPTION_PARAMS% -scriptDebugging"
echo %BUILD_OPTIONS% | findstr /C:"4" >nul && set "OPTION_PARAMS=%OPTION_PARAMS% -verbose"

set "AUTO_INSTALL=false"
set "AUTO_RUN=false"
echo %BUILD_OPTIONS% | findstr /C:"5" >nul && set "AUTO_INSTALL=true"
echo %BUILD_OPTIONS% | findstr /C:"6" >nul && (set "AUTO_INSTALL=true" & set "AUTO_RUN=true")
exit /b

:processBuiltApk
if "%AUTO_INSTALL%"=="true" (
    echo �������¹�����APK...
    for /f "delims=" %%a in ('dir /b /od /a-d "%OUTPUT_DIR%\*.apk" 2^>nul') do set "LATEST_APK=%%a"
    
    if defined LATEST_APK (
        echo �ҵ�APK: "%OUTPUT_DIR%\%LATEST_APK%"
        
        echo ��������ӵ�Android�豸...
        adb devices | findstr "device$" >nul
        if !errorlevel! equ 0 (
            echo ���ڰ�װAPK���豸...
            adb install -r "%OUTPUT_DIR%\%LATEST_APK%"
            
            if "%AUTO_RUN%"=="true" (
                echo ��������Ӧ��...
                for /f "tokens=1 delims=-" %%p in ("!LATEST_APK!") do set "PACKAGE_NAME=%%p"
                adb shell monkey -p !PACKAGE_NAME! -c android.intent.category.LAUNCHER 1
            )
        ) else (
            echo ����: δ�ҵ������ӵ�Android�豸
        )
    ) else (
        echo ����: δ�ҵ�APK�ļ�
    )
)
exit /b

:showBuildInfo
echo.
echo =================================
echo ������Ϣ:
echo ---------------------------------
echo Unity·��: %UNITY_PATH%
echo ��Ŀ·��: %PROJECT_PATH%
echo ���Ŀ¼: %OUTPUT_DIR%
echo ��־�ļ�: %LOG_FILE%
echo ��������: %BUILD_METHOD%
echo =================================
echo.
pause
exit /b

:doBuild
echo ��������Unity��������...
echo ��ʼʱ��: %date% %time%
echo ����׼����������...

:: ���Unity�༭��
if not exist "%UNITY_PATH%" (
    echo ����: Unity�༭�������� - %UNITY_PATH%
    call :logError "Unity�༭��·����Ч"
    goto :error
)

:: �����ĿĿ¼
if not exist "%PROJECT_PATH%\Assets" (
    echo ����: ��Ŀ·����Ч��δ�ҵ�Assets�ļ��� - %PROJECT_PATH%
    call :logError "��Ŀ·����Ч��δ�ҵ�Assets�ļ���"
    goto :error
)

:: ��鹹���ű�
if not exist "%PROJECT_PATH%\Assets\Editor\ProjectBuild.cs" (
    echo ����: δ�ҵ������ű� - %PROJECT_PATH%\Assets\Editor\ProjectBuild.cs
    call :logError "δ�ҵ�ProjectBuild.cs�����ű�"
    goto :error
)

:: ���ó�ʱʱ��(����)
set /p "TIMEOUT_MINUTES=���ù�����ʱʱ��(���ӣ�Ĭ��120): "
if "!TIMEOUT_MINUTES!"=="" set "TIMEOUT_MINUTES=120"

:: ��Ӱ汾��Ϣ����
set /p "VERSION_NAME=����汾�� (���� 1.0.0) [����ʹ��Ĭ��ֵ]: "
set /p "BUILD_NUMBER=���빹���� (���� 1) [����ʹ��Ĭ��ֵ]: "

set "VERSION_PARAMS="
if not "!VERSION_NAME!"=="" set "VERSION_PARAMS=-version !VERSION_NAME!"
if not "!BUILD_NUMBER!"=="" set "VERSION_PARAMS=!VERSION_PARAMS! -buildNumber !BUILD_NUMBER!"

:: ����һ����ʱ�������ļ������ڲ鿴��������
set "CMD_FILE=%TEMP%\unity_build_cmd_%TIMESTAMP%.txt"
(
    echo ִ�е�Unity����:
    echo "%UNITY_PATH%" -batchmode -nographics -projectPath "%PROJECT_PATH%" ^
               -executeMethod %BUILD_METHOD% ^
               %OPTION_PARAMS% %VERSION_PARAMS% ^
               -outputDir "%OUTPUT_DIR%" ^
               -project "%projectName%" ^
               -logFile "%LOG_FILE%" -quit
) > "%CMD_FILE%"

echo ���������ѱ��浽: %CMD_FILE%
echo ��������Unity��������...

:: ִ��Unity����
"%UNITY_PATH%" -batchmode -nographics -projectPath "%PROJECT_PATH%" ^
               -executeMethod %BUILD_METHOD% ^
               %OPTION_PARAMS% %VERSION_PARAMS% ^
               -outputDir "%OUTPUT_DIR%" ^
               -project MyProject ^
               -logFile "%LOG_FILE%" -quit

set BUILD_RESULT=%ERRORLEVEL%
echo Unity�����ѽ������˳�����: %BUILD_RESULT%

:: �����־�ļ��Ƿ����
if not exist "%LOG_FILE%" (
    echo ����: δ�ҵ���־�ļ� - %LOG_FILE%
    call :logError "Unityδ������־�ļ�����������ʧ��"
)

:: ������־�ļ��еĴ���
if exist "%LOG_FILE%" (
    echo ������־�ļ��еĴ���...
    
    :: ����һ������ժҪ�ļ�
    set "ERROR_SUMMARY=%LOG_DIR%\error_summary_%TIMESTAMP%.txt"
    
    :: ��ȡ�ؼ�������Ϣ
    findstr /C:"Error:" /C:"Exception:" /C:"failed" /C:"����" "%LOG_FILE%" > "%ERROR_SUMMARY%" 2>nul
    
    if %errorlevel% equ 0 (
        echo ����־�з��ִ�����ժ¼��: %ERROR_SUMMARY%
        echo ����ժҪ:
        type "%ERROR_SUMMARY%"
    ) else (
        echo ��־�ļ���û���ҵ����Դ�����Ϣ��
    )
)

if %BUILD_RESULT% neq 0 (
    echo �������̷��ش������: %BUILD_RESULT%
    call :logError "Unity�������ش������: %BUILD_RESULT%"
    goto :error
)

:: ����Ƿ��й������
set "BUILD_OUTPUT_FOUND=0"
for %%F in ("%OUTPUT_DIR%\*.apk") do (
    echo �ҵ�APK���: %%F
    set "BUILD_OUTPUT_FOUND=1"
)

if %BUILD_OUTPUT_FOUND% equ 0 (
    :: ����������ܵ�·��
    set "ALT_PATHS=%PROJECT_PATH%\Builds %PROJECT_PATH%\build\outputs\apk"
    
    echo �ڱ�׼���Ŀ¼δ�ҵ�APK��������λ��...
    for %%P in (%ALT_PATHS%) do (
        echo ���: %%P
        if exist "%%P" (
            for %%F in ("%%P\*.apk") do (
                echo �����λ���ҵ�APK: %%F
                set "BUILD_OUTPUT_FOUND=1"
                :: ��ѡ�����Ƶ�Ԥ��λ��
                echo ����APK��Ԥ�����Ŀ¼...
                copy "%%F" "%OUTPUT_DIR%\" > nul
                if errorlevel 0 (
                    echo �Ѹ���: %OUTPUT_DIR%\%%~nxF
                )
            )
        )
    )
)

if %BUILD_OUTPUT_FOUND% equ 0 (
    echo δ�ҵ���������ļ�(APK)
    call :logError "������������ɵ�δ�ҵ�����ļ�"
    goto :warning
)

echo ���������ƺ��ѳɹ���ɡ�
goto :success

:logError
echo [%date% %time%] ����: %~1 >> "%LOG_DIR%\build_errors.log"
exit /b

:warning
echo.
echo =================================
echo ����! ��������δ��ȷ���
echo ������������:
echo 1. Unity��־: %LOG_FILE%
echo 2. ����ժҪ: %ERROR_SUMMARY%
echo 3. ȷ��ProjectBuild.cs�е����·������
echo =================================
pause
exit /b 1

:error
echo.
echo =================================
echo ����ʧ��! 
echo ������־�ļ�: %LOG_FILE%
echo ����ժҪ�ļ�: %ERROR_SUMMARY%
echo =================================
pause
exit /b 1

:success
echo.
echo =================================
echo �����ɹ����!
echo ����ʱ��: %date% %time%
echo �������Ŀ¼: %OUTPUT_DIR%
echo =================================
pause
exit /b 0

:end
exit /b 0