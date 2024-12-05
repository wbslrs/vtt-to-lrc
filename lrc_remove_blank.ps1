# 获取当前脚本所在目录
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Definition
Set-Location $scriptPath

# 获取当前目录下所有 .vtt 文件
$lrcFiles = Get-ChildItem -Filter "*.lrc"

if ($lrcFiles.Count -eq 0) {
    Write-Host "当前目录内没有找到任何 .lrc 文件！" -ForegroundColor Yellow
    exit
}

function Convert-ToSeconds {
    param ([string]$timestamp)
    $parts = $timestamp -split "[:.]"
    return [int]$parts[0] * 60 + [int]$parts[1] + ([double]$parts[2] / 1000)
}

foreach ($lrcFile in $lrcFiles) {
    $inputFile = $lrcFile.FullName
    # $outputFile = [System.IO.Path]::ChangeExtension($inputFile, "lrc1")
    $content = Get-Content -Path $inputFile -Encoding UTF8
    $result = @()

    # 遍历内容
    for ($i = 0; $i -lt $content.Count; $i++) {
        $line = $content[$i]
        # 如果是空行，进行处理
         if ($line -match '^\[(\d+):(\d+)\.(\d+)\]$') {
             # 当前空行的时间戳
            $currentTimestamp = "$($matches[1]):$($matches[2]).$($matches[3])"
            $currentSeconds = Convert-ToSeconds $currentTimestamp
            # 判断下一行是否是非空行
            if ($i + 1 -lt $content.Count -and $content[$i + 1] -match '^\[(\d+):(\d+)\.(\d+)\]') {
                # 下一行的时间戳
                $nextTimestamp = "$($matches[1]):$($matches[2]).$($matches[3])"
                $nextSeconds = Convert-ToSeconds $nextTimestamp
                # 如果时间间隔大于 1 秒，保留当前空行
                if (($nextSeconds - $currentSeconds) -ge 1) {
                $result += $line
                }
            } else {
            # 最后一行空行无条件保留
            $result += $line
            }
        } else {
        # 非空行直接保留
        $result += $line
        }
    }
    # 写入结果到输出文件
    $result | Set-Content -Path $inputFile -Encoding UTF8
    Write-Host "处理完成，结果已保存到 $inputFile"
}

Write-Host "所有文件已处理完成！共处理 $($lrcFiles.Count) 个文件。" -ForegroundColor Green
