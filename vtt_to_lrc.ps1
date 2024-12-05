# 获取当前脚本所在目录
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Definition
Set-Location $scriptPath

# 获取当前目录下所有 .vtt 文件
$vttFiles = Get-ChildItem -Filter "*.vtt"

if ($vttFiles.Count -eq 0) {
    Write-Host "当前目录内没有找到任何 .vtt 文件！" -ForegroundColor Yellow
    exit
}

# 函数：将时间戳转换为秒数
function Convert-ToSeconds {
    param ([string]$timestamp)
    $parts = $timestamp -split "[:.]"
    return [int]$parts[0] * 3600 + [int]$parts[1] * 60 + [int]$parts[2] + ([double]$parts[3] / 1000)
}

# 函数：将秒数转换为时间戳格式
function Format-Timestamp {
    param ([double]$seconds)
    $timespan = [timespan]::FromSeconds($seconds)
    $totalMinutes = $timespan.Minutes + 60 * $timespan.Hours
    return "{0:D2}:{1:00}.{2:000}" -f $totalMinutes, $timespan.Seconds, $timespan.Milliseconds
}

function Convert-ToLrcTimestamp {
    param ([string]$timestamp)
    # 拆分时间戳为小时、分钟、秒和毫秒
    $parts = $timestamp -split "[:.]"
    if ($parts.Count -eq 4) {
        # 含有小时部分
        $hours = [int]$parts[0]
        $minutes = [int]$parts[1] + ($hours * 60) # 小时转换为分钟并累加
        $seconds = [int]$parts[2]
        $milliseconds = [int]$parts[3]
    } elseif ($parts.Count -eq 3) {
        # 不含小时部分
        $minutes = [int]$parts[0]
        $seconds = [int]$parts[1]
        $milliseconds = [int]$parts[2]
    } else {
        throw "无法解析时间戳: $timestamp"
    }

    # 格式化为 LRC 时间戳
    return "{0:D2}:{1:00}.{2:000}" -f $minutes, $seconds, $milliseconds
}

# 遍历每个 .vtt 文件并转换为 .lrc
foreach ($vttFile in $vttFiles) {
    $inputPath = $vttFile.FullName
    $outputPath = [System.IO.Path]::ChangeExtension($inputPath, "lrc")

    Write-Host "正在转换: $($vttFile.Name)"

    # 读取 .vtt 文件内容
    $lines = Get-Content -Path $inputPath -Encoding UTF8
    $outputLines = @()
    $currentLine = ""  # 用于存储当前字幕内容
    # $lastEndTime = 0   # 上一句的结束时间（秒）

    foreach ($line in $lines) {
        # 跳过无用的行
        if ($line -eq "WEBVTT" -or [string]::IsNullOrWhiteSpace($line)) {
            continue
        }

        # 移除数字编号行
        if ($line -match "^\d+$") {
            continue
        }

        # 处理时间戳行
        if ($line -match "^\d{2}:\d{2}:\d{2}\.\d{3} --> \d{2}:\d{2}:\d{2}\.\d{3}") {
            if (-not [string]::IsNullOrWhiteSpace($currentLine)) {
                # 如果有尚未输出的字幕内容，先将其写入
                $outputLines += $currentLine.Trim()
                $outputLines += "[$(Convert-ToLrcTimestamp $endTime)]"  # 添加空行，时间戳为上一句的结束时间
                $currentLine = ""
            }

            # 提取时间戳
            $timestamps = $line -split " --> "
            $startTime = $timestamps[0]
            $endTime = $timestamps[1]

            # 更新最后一句的结束时间
            # $lastEndTime = Convert-ToSeconds $endTime

            # 格式化起始时间戳
            $formattedStartTime = Convert-ToLrcTimestamp $startTime # 去掉小时数转换为分钟
            $currentLine = "[" + $formattedStartTime + "]"          # 初始化当前行
            continue
        }

        # 如果是字幕内容，直接拼接到当前行
        $currentLine += " " + $line.Trim()
    }

    # 处理最后一行字幕
    if (-not [string]::IsNullOrWhiteSpace($currentLine)) {
        $outputLines += $currentLine.Trim()
        $outputLines += "[$(Convert-ToLrcTimestamp $endTime)]"  # 添加最后一句的空行
    }

    # 写入 .lrc 文件
    $outputLines | Set-Content -Path $outputPath -Encoding UTF8
    Write-Host "转换完成: $($vttFile.Name) -> $([System.IO.Path]::GetFileName($outputPath))"
}

Write-Host "所有文件已处理完成！共处理 $($vttFiles.Count) 个文件。" -ForegroundColor Green
