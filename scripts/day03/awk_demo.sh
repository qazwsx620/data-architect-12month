#!/bin/bash
set -euo pipefail
file_log="test.log"
echo "提取日期和日志级别"
awk '{print $1,$2}' $file_log
