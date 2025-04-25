# Unity自动化构建脚本工具

[![Unity版本](https://img.shields.io/badge/Unity-2019.4+-blue.svg)](https://unity.com/)
[![平台](https://img.shields.io/badge/平台-Android%20%7C%20iOS%20%7C%20Windows-green.svg)]()
[![最后更新](https://img.shields.io/badge/更新-2025.04-brightgreen.svg)]()

## 📋 目录

- [Unity自动化构建脚本工具](#unity自动化构建脚本工具)
  - [📋 目录](#-目录)
  - [项目介绍](#项目介绍)
  - [主要功能](#主要功能)
  - [快速开始](#快速开始)
  - [详细使用方法](#详细使用方法)
    - [在Unity编辑器中使用](#在unity编辑器中使用)
    - [通过命令行使用](#通过命令行使用)
      - [可用命令行参数](#可用命令行参数)
  - [构建输出](#构建输出)
  - [批处理脚本示例](#批处理脚本示例)
  - [常见问题](#常见问题)
      - [Q: 如何更改默认的构建输出路径？](#q-如何更改默认的构建输出路径)
      - [Q: 构建失败，如何排查问题？](#q-构建失败如何排查问题)
      - [Q: 如何在Jenkins等CI工具中集成？](#q-如何在jenkins等ci工具中集成)
  - [系统要求](#系统要求)
  - [贡献指南](#贡献指南)

## 项目介绍

这是一个Unity项目，提供了一套完整的自动化构建解决方案，支持Android、iOS和Windows平台的一键构建。该工具旨在简化Unity项目的构建过程，提高开发效率，特别适用于CI/CD流程集成。

## 主要功能

- **🔄 多平台支持**：支持Android、iOS和Windows平台的构建
- **⌨️ 命令行支持**：提供完整的命令行参数，可以在批处理模式下运行
- **📝 构建信息记录**：自动生成构建信息文件，记录构建详情
- **🏷️ 版本管理**：支持通过命令行参数配置版本号和构建号
- **🔐 Android签名配置**：支持自定义签名文件或使用默认签名
- **⚡ 增量构建支持**：提供增量构建选项，加快构建速度
- **🤖 CI/CD友好**：设计适合自动化流程，可轻松集成至Jenkins、GitHub Actions等

## 快速开始

1. 克隆本项目到本地
2. 使用Unity 2019.4或更高版本打开项目
3. 选择菜单 `构建/构建Android` 进行首次构建测试
4. 或运行根目录下的 `UnityBuild.bat` 进行命令行构建

## 详细使用方法

### 在Unity编辑器中使用

1. 打开Unity项目
2. 通过菜单栏选择：
   - `构建/构建全部平台` - 构建所有平台
   - `构建/构建Android` - 仅构建Android平台
   - `构建/构建iOS` - 仅构建iOS平台
   - `构建/构建Windows` - 仅构建Windows平台

### 通过命令行使用

使用以下命令在命令行中执行构建：

```bash
"C:\Program Files\Unity\Hub\Editor\2022.3.18f1\Editor\Unity.exe" -batchmode -quit -projectPath "项目路径" -executeMethod ProjectBuild.BuildForAndroid -logFile build.log -outputDir "D:/Builds" -versionName "1.0.0" -buildNumber 1
```

#### 可用命令行参数

| 参数 | 类型 | 必填 | 说明 | 示例 |
|------|------|------|------|------|
| `-project` | 字符串 | 否 | 自定义项目名称 | `-project=MyGame` |
| `-outputDir` | 路径 | 否 | 输出目录路径 | `-outputDir=D:/Builds` |
| `-versionName` | 字符串 | 否 | 版本名称 | `-versionName=1.0.0` |
| `-buildNumber` | 整数 | 否 | 构建号 | `-buildNumber=10` |
| `-keystoreName` | 路径 | 否 | Android签名文件路径 | `-keystoreName=path/to/keystore.jks` |
| `-keystorePass` | 字符串 | 否 | 签名文件密码 | `-keystorePass=password` |
| `-keyaliasName` | 字符串 | 否 | 密钥别名 | `-keyaliasName=alias` |
| `-keyaliasPass` | 字符串 | 否 | 密钥密码 | `-keyaliasPass=password` |
| `-development` | 布尔 | 否 | 启用开发者模式 | `-development` |
| `-profiling` | 布尔 | 否 | 启用性能分析 | `-profiling` |
| `-scriptDebugging` | 布尔 | 否 | 启用脚本调试 | `-scriptDebugging` |
| `-verbose` | 布尔 | 否 | 启用详细日志 | `-verbose` |

## 构建输出

构建完成后，在指定的输出目录或默认的`APK`目录中，你将会找到:

1. 构建的应用文件(APK/EXE等)
2. `.buildinfo`文件，包含构建的详细信息:
   - 构建时间和环境信息
   - 产品名称和版本信息
   - 构建大小和压缩率
   - 使用的Unity版本和构建选项
   - 包含的场景列表

## 批处理脚本示例

项目中包含了`UnityBuild.bat`批处理脚本示例，可以用于快速构建:

```batch
@echo off
set UNITY_PATH="C:\Program Files\Unity\Hub\Editor\2022.3.18f1\Editor\Unity.exe"
set PROJECT_PATH=%~dp0
set OUTPUT_DIR=%~dp0APK

%UNITY_PATH% -batchmode -quit -projectPath %PROJECT_PATH% -executeMethod ProjectBuild.BuildForAndroid -logFile build.log -outputDir "%OUTPUT_DIR%" -versionName "1.0.0" -buildNumber 1

echo 构建完成，日志文件：build.log
pause
```

## 常见问题

#### Q: 如何更改默认的构建输出路径？
A: 可以通过 `-outputDir` 参数指定自定义输出路径。

#### Q: 构建失败，如何排查问题？
A: 查看构建日志文件（默认为项目根目录下的`build.log`），通常会包含错误信息。

#### Q: 如何在Jenkins等CI工具中集成？
A: 创建一个调用Unity的脚本任务，加入必要的命令行参数，并确保CI环境中已安装Unity。

## 系统要求

- Unity 2019.4 或更高版本
- 对应平台的构建支持模块（Android/iOS/Windows）
- Android构建需要安装Android SDK和JDK
- iOS构建只能在macOS系统上进行

## 贡献指南

1. Fork本仓库
2. 创建你的特性分支 (`git checkout -b feature/amazing-feature`)
3. 提交你的更改 (`git commit -m 'Add some amazing feature'`)
4. 推送到分支 (`git push origin feature/amazing-feature`)
5. 开启一个Pull Request

---

📅 更新日期: 2025年4月25日