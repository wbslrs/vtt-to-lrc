vtt字幕文件转lrc字幕文件的powershell脚本            
> vtt_to_lrc 用于同目录下文件转换  
转换后的格式为 
```lrc 
[时间戳1] 内容1   
[时间戳2] 
[时间戳3] 内容2 
[时间戳4] 
```
在每一行字幕后都会有一个空行                   

---

> lrc_remove_blank 用于移除空行 
> 当空行与下一行的时间戳间隔小于1秒时将移除空行
> 最后一行的空行无条件保留
```lrc 
[时间戳1] 内容1
[时间戳3] 内容2
[时间戳4] 
```
