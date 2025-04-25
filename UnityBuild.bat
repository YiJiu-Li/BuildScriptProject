@echo off
setlocal enabledelayedexpansion

:: Unity自动打包脚本
echo =================================
echo Unity安卓打包自动化工具
echo =================================

:: 设置默认路径
set "UNITY_DEFAULT=D:\UnityVs\Unity Hub\Unitys\2022.3.53f1\Editor\Unity.exe"
set "PROJECT_DEFAULT=E:\Unity\YZJ\2025\BuildScriptProject"
set "OUTPUT_DIR=%~dp0Builds\APK"
set "CONFIG_FILE=%~dp0build_config.txt"
set "LOG_DIR=%~dp0logs"
set "DEV_NULL=nul"

:: 读取保存的配置
call :readConfig

:: 处理命令行参数
if not "%~1"=="" set "UNITY_PATH=%~1"
if not "%~2"=="" set "PROJECT_PATH=%~2"

:: 确保Unity路径设置正确
if not defined UNITY_PATH call :promptUnityPath
call :validateUnityPath

:: 确保项目路径设置正确
if not defined PROJECT_PATH call :promptProjectPath
call :validateProjectPath

:: 创建必要的目录
call :createDirs

:: 保存配置
call :saveConfig

:: 设置时间戳
call :createTimestamp

:: 选择构建平台
call :selectPlatform

:: 选择构建选项
call :selectBuildOptions

:: 显示构建信息
call :showBuildInfo

:: 执行构建
call :doBuild

:: 脚本结束
goto :end

:readConfig
if exist "%CONFIG_FILE%" (
    echo 读取配置文件...
    for /f "usebackq tokens=1,* delims==" %%a in ("%CONFIG_FILE%") do (
        if "%%a"=="UNITY_PATH" set "UNITY_PATH=%%b"
        if "%%a"=="PROJECT_PATH" set "PROJECT_PATH=%%b"
    )
)
exit /b

:promptUnityPath
echo.
echo 请输入Unity编辑器路径 [%UNITY_DEFAULT%]:
set /p "INPUT="
if "!INPUT!"=="" (
    set "UNITY_PATH=%UNITY_DEFAULT%"
) else (
    set "UNITY_PATH=!INPUT!"
)
exit /b

:validateUnityPath
if not exist "%UNITY_PATH%" (
    echo 警告: Unity路径不存在: "%UNITY_PATH%"
    echo 将使用默认路径: "%UNITY_DEFAULT%"
    set "UNITY_PATH=%UNITY_DEFAULT%"
    
    if not exist "%UNITY_PATH%" (
        echo 错误: 默认Unity路径也不存在!
        echo 请确认Unity的安装路径并重新运行此脚本。
        pause
        exit 1
    )
)
exit /b

:promptProjectPath
echo.
echo 请输入项目路径 [%PROJECT_DEFAULT%]:
set /p "INPUT="
if "!INPUT!"=="" (
    set "PROJECT_PATH=%PROJECT_DEFAULT%"
) else (
    set "PROJECT_PATH=!INPUT!"
)
exit /b

:validateProjectPath
if not exist "%PROJECT_PATH%" (
    echo 警告: 项目路径不存在: "%PROJECT_PATH%"
    echo 将使用默认路径: "%PROJECT_DEFAULT%"
    set "PROJECT_PATH=%PROJECT_DEFAULT%"
    
    if not exist "%PROJECT_PATH%" (
        echo 错误: 默认项目路径也不存在!
        echo 请确认Unity项目路径并重新运行此脚本。
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
echo 选择构建平台:
echo [1] Android (默认)
echo [2] iOS
echo [3] Windows
echo [4] 全部平台 (Android+iOS+Windows)
echo.
set /p "PLATFORM_CHOICE=请选择 (1-4): "

set "BUILD_METHOD=ProjectBuild.BuildForAndroid"
if "!PLATFORM_CHOICE!"=="2" set "BUILD_METHOD=ProjectBuild.BuildForiOS"
if "!PLATFORM_CHOICE!"=="3" set "BUILD_METHOD=ProjectBuild.BuildForWindows"
if "!PLATFORM_CHOICE!"=="4" set "BUILD_METHOD=ProjectBuild.BuildAll"
exit /b

:selectBuildOptions
echo.
echo 选择构建选项 (输入对应的数字，多个选项用空格分隔):
echo [1] 开发模式构建 (Development Build)
echo [2] 启用性能分析 (Connect Profiler)
echo [3] 启用脚本调试 (Allow Debugging)
echo [4] 详细构建日志 (Verbose)
echo [5] 构建后安装APK到连接的设备
echo [6] 构建后启动应用程序
echo.
set /p "BUILD_OPTIONS=请选择构建选项 (例如: 1 3): "

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
    echo 查找最新构建的APK...
    for /f "delims=" %%a in ('dir /b /od /a-d "%OUTPUT_DIR%\*.apk" 2^>nul') do set "LATEST_APK=%%a"
    
    if defined LATEST_APK (
        echo 找到APK: "%OUTPUT_DIR%\%LATEST_APK%"
        
        echo 检测已连接的Android设备...
        adb devices | findstr "device$" >nul
        if !errorlevel! equ 0 (
            echo 正在安装APK到设备...
            adb install -r "%OUTPUT_DIR%\%LATEST_APK%"
            
            if "%AUTO_RUN%"=="true" (
                echo 正在启动应用...
                for /f "tokens=1 delims=-" %%p in ("!LATEST_APK!") do set "PACKAGE_NAME=%%p"
                adb shell monkey -p !PACKAGE_NAME! -c android.intent.category.LAUNCHER 1
            )
        ) else (
            echo 警告: 未找到已连接的Android设备
        )
    ) else (
        echo 警告: 未找到APK文件
    )
)
exit /b

:showBuildInfo
echo.
echo =================================
echo 构建信息:
echo ---------------------------------
echo Unity路径: %UNITY_PATH%
echo 项目路径: %PROJECT_PATH%
echo 输出目录: %OUTPUT_DIR%
echo 日志文件: %LOG_FILE%
echo 构建方法: %BUILD_METHOD%
echo =================================
echo.
pause
exit /b

:doBuild
echo 正在启动Unity构建过程...
echo 开始时间: %date% %time%
echo 正在准备构建环境...

:: 检查Unity编辑器
if not exist "%UNITY_PATH%" (
    echo 错误: Unity编辑器不存在 - %UNITY_PATH%
    call :logError "Unity编辑器路径无效"
    goto :error
)

:: 检查项目目录
if not exist "%PROJECT_PATH%\Assets" (
    echo 错误: 项目路径无效，未找到Assets文件夹 - %PROJECT_PATH%
    call :logError "项目路径无效，未找到Assets文件夹"
    goto :error
)

:: 检查构建脚本
if not exist "%PROJECT_PATH%\Assets\Editor\ProjectBuild.cs" (
    echo 错误: 未找到构建脚本 - %PROJECT_PATH%\Assets\Editor\ProjectBuild.cs
    call :logError "未找到ProjectBuild.cs构建脚本"
    goto :error
)

:: 设置超时时间(分钟)
set /p "TIMEOUT_MINUTES=设置构建超时时间(分钟，默认120): "
if "!TIMEOUT_MINUTES!"=="" set "TIMEOUT_MINUTES=120"

:: 添加版本信息参数
set /p "VERSION_NAME=输入版本号 (例如 1.0.0) [留空使用默认值]: "
set /p "BUILD_NUMBER=输入构建号 (例如 1) [留空使用默认值]: "

set "VERSION_PARAMS="
if not "!VERSION_NAME!"=="" set "VERSION_PARAMS=-version !VERSION_NAME!"
if not "!BUILD_NUMBER!"=="" set "VERSION_PARAMS=!VERSION_PARAMS! -buildNumber !BUILD_NUMBER!"

:: 创建一个临时的命令文件，便于查看完整命令
set "CMD_FILE=%TEMP%\unity_build_cmd_%TIMESTAMP%.txt"
(
    echo 执行的Unity命令:
    echo "%UNITY_PATH%" -batchmode -nographics -projectPath "%PROJECT_PATH%" ^
               -executeMethod %BUILD_METHOD% ^
               %OPTION_PARAMS% %VERSION_PARAMS% ^
               -outputDir "%OUTPUT_DIR%" ^
               -project "%projectName%" ^
               -logFile "%LOG_FILE%" -quit
) > "%CMD_FILE%"

echo 完整命令已保存到: %CMD_FILE%
echo 正在启动Unity构建进程...

:: 执行Unity命令
"%UNITY_PATH%" -batchmode -nographics -projectPath "%PROJECT_PATH%" ^
               -executeMethod %BUILD_METHOD% ^
               %OPTION_PARAMS% %VERSION_PARAMS% ^
               -outputDir "%OUTPUT_DIR%" ^
               -project MyProject ^
               -logFile "%LOG_FILE%" -quit

set BUILD_RESULT=%ERRORLEVEL%
echo Unity进程已结束，退出代码: %BUILD_RESULT%

:: 检查日志文件是否存在
if not exist "%LOG_FILE%" (
    echo 警告: 未找到日志文件 - %LOG_FILE%
    call :logError "Unity未生成日志文件，可能启动失败"
)

:: 分析日志文件中的错误
if exist "%LOG_FILE%" (
    echo 分析日志文件中的错误...
    
    :: 创建一个错误摘要文件
    set "ERROR_SUMMARY=%LOG_DIR%\error_summary_%TIMESTAMP%.txt"
    
    :: 提取关键错误信息
    findstr /C:"Error:" /C:"Exception:" /C:"failed" /C:"错误" "%LOG_FILE%" > "%ERROR_SUMMARY%" 2>nul
    
    if %errorlevel% equ 0 (
        echo 在日志中发现错误，已摘录到: %ERROR_SUMMARY%
        echo 错误摘要:
        type "%ERROR_SUMMARY%"
    ) else (
        echo 日志文件中没有找到明显错误信息。
    )
)

if %BUILD_RESULT% neq 0 (
    echo 构建过程返回错误代码: %BUILD_RESULT%
    call :logError "Unity构建返回错误代码: %BUILD_RESULT%"
    goto :error
)

:: 检查是否有构建输出
set "BUILD_OUTPUT_FOUND=0"
for %%F in ("%OUTPUT_DIR%\*.apk") do (
    echo 找到APK输出: %%F
    set "BUILD_OUTPUT_FOUND=1"
)

if %BUILD_OUTPUT_FOUND% equ 0 (
    :: 检查其他可能的路径
    set "ALT_PATHS=%PROJECT_PATH%\Builds %PROJECT_PATH%\build\outputs\apk"
    
    echo 在标准输出目录未找到APK，检查替代位置...
    for %%P in (%ALT_PATHS%) do (
        echo 检查: %%P
        if exist "%%P" (
            for %%F in ("%%P\*.apk") do (
                echo 在替代位置找到APK: %%F
                set "BUILD_OUTPUT_FOUND=1"
                :: 可选：复制到预期位置
                echo 复制APK到预期输出目录...
                copy "%%F" "%OUTPUT_DIR%\" > nul
                if errorlevel 0 (
                    echo 已复制: %OUTPUT_DIR%\%%~nxF
                )
            )
        )
    )
)

if %BUILD_OUTPUT_FOUND% equ 0 (
    echo 未找到构建输出文件(APK)
    call :logError "构建可能已完成但未找到输出文件"
    goto :warning
)

echo 构建过程似乎已成功完成。
goto :success

:logError
echo [%date% %time%] 错误: %~1 >> "%LOG_DIR%\build_errors.log"
exit /b

:warning
echo.
echo =================================
echo 警告! 构建可能未正确完成
echo 请检查以下内容:
echo 1. Unity日志: %LOG_FILE%
echo 2. 错误摘要: %ERROR_SUMMARY%
echo 3. 确认ProjectBuild.cs中的输出路径配置
echo =================================
pause
exit /b 1

:error
echo.
echo =================================
echo 构建失败! 
echo 请检查日志文件: %LOG_FILE%
echo 错误摘要文件: %ERROR_SUMMARY%
echo =================================
pause
exit /b 1

:success
echo.
echo =================================
echo 构建成功完成!
echo 结束时间: %date% %time%
echo 构建输出目录: %OUTPUT_DIR%
echo =================================
pause
exit /b 0

:end
exit /b 0