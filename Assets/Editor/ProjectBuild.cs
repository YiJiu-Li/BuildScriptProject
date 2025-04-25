using System.Collections;
using System.IO;
using UnityEditor;
using UnityEngine;
using System.Collections.Generic;
using System;
using UnityEditor.Build.Reporting;

class ProjectBuild : Editor
{

    // 缓存命令行参数，避免重复解析
    private static string[] cachedCommandLineArgs;
    private static Dictionary<string, string> cachedArgs;


    [MenuItem("构建/构建全部平台")]
    public static void BuildAll()
    {
        BuildForAndroid();
        BuildForiOS();
        BuildForWindows();
    }

    [MenuItem("构建/构建Android")]
    public static void BuildAndroidMenu()
    {
        BuildForAndroid();
    }

    [MenuItem("构建/构建iOS")]
    public static void BuildiOSMenu()
    {
        BuildForiOS();
    }

    [MenuItem("构建/构建Windows")]
    public static void BuildWindowsMenu()
    {
        BuildForWindows();
    }

    //在这里找出你当前工程所有的场景文件，假设你只想把部分的scene文件打包 那么这里可以写你的条件判断 总之返回一个字符串数组。
    static string[] GetBuildScenes()
    {
        List<string> names = new List<string>();
        foreach (EditorBuildSettingsScene e in EditorBuildSettings.scenes)
        {
            if (e == null)
                continue;
            if (e.enabled)
                names.Add(e.path);
        }
        return names.ToArray();
    }


    /// <summary>
    /// 初始化命令行参数缓存
    /// </summary>
    private static void InitCommandLineArgs()
    {
        if (cachedArgs != null)
            return;

        cachedArgs = new Dictionary<string, string>(StringComparer.OrdinalIgnoreCase);
        cachedCommandLineArgs = Environment.GetCommandLineArgs();

        for (int i = 0; i < cachedCommandLineArgs.Length; i++)
        {
            string arg = cachedCommandLineArgs[i];

            // 处理 -name=value 格式
            if (arg.StartsWith("-") && arg.Contains("="))
            {
                string key = arg.Substring(1, arg.IndexOf('=') - 1);
                string value = arg.Substring(arg.IndexOf('=') + 1);
                cachedArgs[key] = value;
                continue;
            }

            // 处理 -name value 格式
            if (arg.StartsWith("-") && i + 1 < cachedCommandLineArgs.Length && !cachedCommandLineArgs[i + 1].StartsWith("-"))
            {
                string key = arg.Substring(1);
                string value = cachedCommandLineArgs[i + 1];
                cachedArgs[key] = value;
                continue;
            }

            // 处理 -flag 格式（布尔标志）
            if (arg.StartsWith("-"))
            {
                string key = arg.Substring(1);
                cachedArgs[key] = "true";
            }
        }
    }
    /// <summary>
    /// 获取命令行参数
    /// </summary>
    private static string GetCommandLineArg(string name, string defaultValue = "")
    {
        InitCommandLineArgs();

        if (cachedArgs.TryGetValue(name, out string value))
            return value;

        return defaultValue;
    }

    /// <summary>
    /// 获取命令行布尔参数 (如 -development)
    /// </summary>
    private static bool GetCommandLineBoolArg(string name)
    {
        InitCommandLineArgs();
        return cachedArgs.ContainsKey(name);
    }

    /// <summary>
    /// 自定义工程名："project-"作为工程名的前缀参数
    /// </summary>
    public static string projectName
    {
        get
        {
            string name = GetCommandLineArg("project");
            return string.IsNullOrEmpty(name) ? Application.productName : name;
        }
    }

    /// <summary>
    /// 获取输出目录
    /// </summary>
    private static string GetOutputDirectory()
    {
        // 优先从命令行参数获取
        string outputDir = GetCommandLineArg("outputDir");
        if (!string.IsNullOrEmpty(outputDir))
        {
            // 确保路径末尾有分隔符
            outputDir = outputDir.Replace("\\", "/");
            if (!outputDir.EndsWith("/"))
                outputDir += "/";

            // 确保目录存在
            if (!Directory.Exists(outputDir))
                Directory.CreateDirectory(outputDir);

            return outputDir;
        }

        // 默认使用项目目录下的APK文件夹
        string defaultDir = Application.dataPath.Replace("/Assets", "/APK/");
        if (!Directory.Exists(defaultDir))
            Directory.CreateDirectory(defaultDir);

        return defaultDir;
    }

    /// <summary>
    /// 通用的构建方法
    /// </summary>
    private static void PerformBuild(BuildTarget target, string platformName, string fileExtension = "")
    {
        Debug.Log($"开始构建 {platformName} 应用...");

        try
        {
            // 准备输出路径
            string outputDir = GetOutputDirectory();
            string timestamp = DateTime.Now.ToString("yyyyMMdd_HHmmss");
            string fileName = $"{projectName}_{timestamp}";

            if (!string.IsNullOrEmpty(fileExtension) && !fileExtension.StartsWith("."))
                fileExtension = "." + fileExtension;

            string outputPath = Path.Combine(outputDir, fileName + fileExtension);

            Debug.Log($"{platformName} 输出路径: {outputPath}");

            // 执行构建
            BuildPlayerOptions buildOptions = new BuildPlayerOptions();
            buildOptions.scenes = GetBuildScenes();
            buildOptions.locationPathName = outputPath;
            buildOptions.target = target;

            // 构建选项配置
            BuildOptions options = BuildOptions.None;

            // 检查是否启用增量构建
            // if (GetCommandLineBoolArg("incremental") && IsIncrementalBuildAvailable(target))
            // {
            //     options |= BuildOptions.InstallInBuildFolder;
            //     Debug.Log("启用增量构建");
            // }

            // 检查是否为开发构建
            if (GetCommandLineBoolArg("development"))
            {
                options |= BuildOptions.Development;
                Debug.Log("启用开发者构建模式");
            }
            // 检查是否启用性能分析
            if (GetCommandLineBoolArg("profiling"))
            {
                options |= BuildOptions.ConnectWithProfiler;
                Debug.Log("启用性能分析");
            }

            // 检查是否启用脚本调试
            if (GetCommandLineBoolArg("scriptDebugging"))
            {
                options |= BuildOptions.AllowDebugging;
                Debug.Log("启用脚本调试");
            }

            // 检查是否为详细构建
            if (GetCommandLineBoolArg("verbose"))
            {
                options |= BuildOptions.DetailedBuildReport;
                Debug.Log("启用详细构建报告");
            }

            buildOptions.options = options;

            // 执行构建
            BuildReport report = BuildPipeline.BuildPlayer(buildOptions);

            // 输出构建结果
            BuildSummary summary = report.summary;
            if (summary.result == BuildResult.Succeeded)
            {
                // 获取实际文件大小
                FileInfo buildFile = new FileInfo(outputPath);
                long actualFileSize = buildFile.Exists ? buildFile.Length : 0;

                // 创建构建信息文件
                CreateBuildInfoFile(outputPath, summary, actualFileSize);

                Debug.Log($"构建成功: {outputPath}");
                Debug.Log($"资源总大小: {(summary.totalSize / 1048576f).ToString("F2")} MB");
                Debug.Log($"实际文件大小: {(actualFileSize / 1048576f).ToString("F2")} MB");
                Debug.Log($"构建时间: {summary.totalTime.TotalSeconds.ToString("F2")} 秒");


                // 返回成功代码，批处理可以检测到
                ConditionalExit(0);
            }
            else
            {
                Debug.LogError($"构建失败: {summary.result}");
                // 返回错误代码
                ConditionalExit(1);
            }
        }
        catch (Exception e)
        {
            Debug.LogError($"{platformName} 构建过程中发生错误: {e.Message}\n{e.StackTrace}");
            // 返回错误代码
            ConditionalExit(2);
        }
    }

    /// <summary>
    /// 打包Android应用
    /// </summary>
    public static void BuildForAndroid()
    {
        try
        {
            // 环境验证
            if (!ValidateBuildEnvironment(BuildTarget.Android))
            {
                ConditionalExit(3);
                return;
            }

            // 签名文件配置
            ConfigureAndroidKeystore();

            // 配置版本
            ConfigureVersionInfo();

            // 执行构建
            PerformBuild(BuildTarget.Android, "Android", ".apk");
        }
        catch (Exception e)
        {
            Debug.LogError($"Android 构建配置错误: {e.Message}");
            ConditionalExit(4);
        }
    }

    /// <summary>
    /// 配置Android签名
    /// </summary>
    private static void ConfigureAndroidKeystore()
    {
        string keystoreName = GetCommandLineArg("keystoreName");
        string keystorePass = GetCommandLineArg("keystorePass");
        string keyaliasName = GetCommandLineArg("keyaliasName");
        string keyaliasPass = GetCommandLineArg("keyaliasPass");

        // 如果命令行没有提供签名信息，使用默认签名文件
        if (string.IsNullOrEmpty(keystoreName))
        {
            string defaultKeystorePath = Application.dataPath.Replace("/Assets", "") + "/BenheroGithub.jks";
            if (File.Exists(defaultKeystorePath))
            {
                PlayerSettings.Android.useCustomKeystore = true;
                PlayerSettings.Android.keyaliasName = "BenheroGithub";
                PlayerSettings.Android.keyaliasPass = "BenheroGithub";
                PlayerSettings.Android.keystoreName = defaultKeystorePath;
                PlayerSettings.Android.keystorePass = "BenheroGithub";
                Debug.Log("已配置默认签名文件: " + defaultKeystorePath);
            }
            else
            {
                PlayerSettings.Android.useCustomKeystore = false;
                Debug.Log("未找到签名文件，使用Unity默认签名");
            }
        }
        else
        {
            // 使用命令行提供的签名信息
            PlayerSettings.Android.useCustomKeystore = true;
            PlayerSettings.Android.keystoreName = keystoreName;
            PlayerSettings.Android.keystorePass = keystorePass ?? "";
            PlayerSettings.Android.keyaliasName = keyaliasName ?? "";
            PlayerSettings.Android.keyaliasPass = keyaliasPass ?? "";
            Debug.Log("已配置签名文件: " + keystoreName);
        }
    }

    /// <summary>
    /// 打包iOS应用
    /// </summary>
    public static void BuildForiOS()
    {
        PerformBuild(BuildTarget.iOS, "iOS");
    }

    /// <summary>
    /// 打包Windows应用
    /// </summary>
    public static void BuildForWindows()
    {
        PerformBuild(BuildTarget.StandaloneWindows64, "Windows", ".exe");
    }

    /// <summary>
    /// 获取版本号
    /// </summary>
    private static string GetVersionName()
    {
        string versionName = GetCommandLineArg("versionName", Application.version);
        return versionName;
    }

    /// <summary>
    /// 获取构建号
    /// </summary>
    private static int GetBuildNumber()
    {
        string buildNumberStr = GetCommandLineArg("buildNumber", PlayerSettings.iOS.buildNumber);
        if (int.TryParse(buildNumberStr, out int buildNumber) && buildNumber > 0)
            return buildNumber;
        return 1; // 确保返回一个正整数
    }

    /// <summary>
    /// 配置版本信息
    /// </summary>
    private static void ConfigureVersionInfo()
    {
        string versionName = GetVersionName();
        int buildNumber = GetBuildNumber();

        PlayerSettings.bundleVersion = versionName;
        PlayerSettings.iOS.buildNumber = buildNumber.ToString();
        PlayerSettings.Android.bundleVersionCode = buildNumber;

        Debug.Log($"版本名: {versionName}, 构建号: {buildNumber}");
    }

    /// <summary>
    /// 创建构建信息文件，记录构建的详细信息
    /// </summary>
    private static void CreateBuildInfoFile(string buildPath, BuildSummary summary, long actualFileSize = 0)
    {
        try
        {
            // 如果没有传入实际大小，尝试获取
            if (actualFileSize <= 0)
            {
                FileInfo buildFile = new FileInfo(buildPath);
                if (buildFile.Exists)
                    actualFileSize = buildFile.Length;
            }

            string infoPath = Path.ChangeExtension(buildPath, ".buildinfo");
            using (StreamWriter writer = new StreamWriter(infoPath))
            {
                writer.WriteLine($"构建时间: {DateTime.Now}");
                writer.WriteLine($"产品名称: {Application.productName}");
                writer.WriteLine($"包名: {PlayerSettings.applicationIdentifier}");
                writer.WriteLine($"构建版本: {PlayerSettings.bundleVersion}");
                writer.WriteLine($"构建号: {PlayerSettings.Android.bundleVersionCode}");
                writer.WriteLine($"资源总大小: {(summary.totalSize / 1048576f).ToString("F2")} MB");
                writer.WriteLine($"实际文件大小: {(actualFileSize / 1048576f).ToString("F2")} MB");
                writer.WriteLine($"压缩率: {(actualFileSize > 0 ? (100 - actualFileSize * 100.0f / summary.totalSize).ToString("F1") + "%" : "未知")}");
                writer.WriteLine($"构建时长: {summary.totalTime.TotalSeconds.ToString("F2")} 秒");
                writer.WriteLine($"Unity版本: {Application.unityVersion}");
                // 添加更多详细信息
                writer.WriteLine($"脚本后端: {PlayerSettings.GetScriptingBackend(EditorUserBuildSettings.selectedBuildTargetGroup)}");
                writer.WriteLine($"IL2CPP编译选项: {PlayerSettings.GetIl2CppCompilerConfiguration(EditorUserBuildSettings.selectedBuildTargetGroup)}");
                writer.WriteLine($"API兼容级别: {PlayerSettings.GetApiCompatibilityLevel(EditorUserBuildSettings.selectedBuildTargetGroup)}");

                if (EditorUserBuildSettings.selectedBuildTargetGroup == BuildTargetGroup.Android)
                {
                    writer.WriteLine($"目标API: {PlayerSettings.Android.targetSdkVersion}");
                    writer.WriteLine($"最低API: {PlayerSettings.Android.minSdkVersion}");
                    writer.WriteLine($"目标架构: {PlayerSettings.Android.targetArchitectures}");
                }

                // 添加机器信息
                writer.WriteLine($"\n构建环境信息:");
                writer.WriteLine($"  操作系统: {SystemInfo.operatingSystem}");
                writer.WriteLine($"  处理器: {SystemInfo.processorType}");
                writer.WriteLine($"  内存: {SystemInfo.systemMemorySize} MB");

                // 尝试获取Git信息
                try
                {
                    string gitHead = File.ReadAllText(Path.Combine(Application.dataPath, "../.git/HEAD")).Trim();
                    writer.WriteLine($"  Git引用: {gitHead}");
                }
                catch
                {
                    writer.WriteLine("  Git信息: 不可用");
                }

                // 添加场景列表
                writer.WriteLine("\n包含场景:");
                string[] scenes = GetBuildScenes();
                foreach (string scene in scenes)
                {
                    writer.WriteLine($"  - {scene}");
                }

                // 添加构建选项
                writer.WriteLine("\n构建选项:");
                writer.WriteLine($"  开发者模式: {((summary.options & BuildOptions.Development) != 0)}");
                writer.WriteLine($"  脚本调试: {((summary.options & BuildOptions.AllowDebugging) != 0)}");
                writer.WriteLine($"  性能分析: {((summary.options & BuildOptions.ConnectWithProfiler) != 0)}");
            }

            Debug.Log($"构建信息已保存至: {infoPath}");
        }
        catch (Exception e)
        {
            Debug.LogError($"创建构建信息文件失败: {e.Message}");
        }
    }

    /// <summary>
    /// 添加增量构建支持
    /// </summary>
    private static bool IsIncrementalBuildAvailable(BuildTarget target)
    {
        // 检查是否存在之前的构建缓存
        string cacheDir = Path.Combine(Application.dataPath, "../Library/Bee/buildprogram0.traceevents");
        return File.Exists(cacheDir) && GetCommandLineBoolArg("incremental");
    }

    /// <summary>
    /// 验证构建环境和参数
    /// </summary>
    private static bool ValidateBuildEnvironment(BuildTarget target)
    {
        bool isValid = true;

        // 检查Unity模块是否已安装
        switch (target)
        {
            case BuildTarget.Android:
                if (!BuildPipeline.IsBuildTargetSupported(BuildTargetGroup.Android, BuildTarget.Android))
                {
                    Debug.LogError("错误: 未安装Android构建支持模块。请通过Unity Hub安装Android构建支持。");
                    isValid = false;
                }
                break;

            case BuildTarget.iOS:
#if !UNITY_EDITOR_OSX
                Debug.LogError("错误: iOS构建只支持在macOS上进行。");
                isValid = false;
#else
                if (!BuildPipeline.IsBuildTargetSupported(BuildTargetGroup.iOS, BuildTarget.iOS))
                {
                    Debug.LogError("错误: 未安装iOS构建支持模块。请通过Unity Hub安装iOS构建支持。");
                    isValid = false;
                }
#endif
                break;
        }

        // 验证场景配置
        string[] scenes = GetBuildScenes();
        if (scenes.Length == 0)
        {
            Debug.LogError("错误: 没有场景被添加到构建列表。请在 File > Build Settings 中添加场景。");
            isValid = false;
        }

        return isValid;
    }

    /// <summary>
    /// 更新进度状态文件
    /// </summary>
    private static void UpdateProgressStatus(string stage, float progress)
    {
        try
        {
            string statusFile = Path.Combine(Application.temporaryCachePath, "build_status.json");
            string json = JsonUtility.ToJson(new BuildStatus
            {
                stage = stage,
                progress = progress,
                timestamp = DateTime.Now.ToString("yyyy-MM-dd HH:mm:ss")
            });

            File.WriteAllText(statusFile, json);
        }
        catch (Exception e)
        {
            Debug.LogWarning($"更新状态文件失败: {e.Message}");
        }
    }

    [Serializable]
    private class BuildStatus
    {
        public string stage;
        public float progress;
        public string timestamp;
    }

    // 添加静态构造函数以初始化常用参数
    static ProjectBuild()
    {
        // 初始化命令行参数
        InitCommandLineArgs();

        // 配置版本信息
        ConfigureVersionInfo();

        // 添加编辑器启动时的初始化逻辑
        Debug.Log("ProjectBuild 初始化完成");
    }

    /// <summary>
    /// 根据运行模式有条件地退出编辑器
    /// </summary>
    /// <param name="exitCode">退出代码</param>
    private static void ConditionalExit(int exitCode)
    {
        // 检查是否在批处理模式下运行
        bool isBatchMode = false;

        // 检查命令行参数中是否包含批处理模式标志
        foreach (string arg in Environment.GetCommandLineArgs())
        {
            if (arg == "-batchmode" || arg == "-quit")
            {
                isBatchMode = true;
                break;
            }
        }

        // 也可以使用 Application.isBatchMode (Unity 2018.2+)
        // isBatchMode = Application.isBatchMode;

        if (isBatchMode)
        {
            Debug.Log($"批处理模式下退出，退出代码: {exitCode}");
            EditorApplication.Exit(exitCode);
        }
        else
        {
            Debug.Log($"编辑器模式下，不退出应用，退出代码: {exitCode}");
        }
    }
}