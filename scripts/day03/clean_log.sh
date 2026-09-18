#!/bin/bash
set -euo pipefail
file_log="test.log"
echo "筛选和替换之后的结果"
awk -F '[ :]' '$2=="ERROR" || $2=="warn" {print $0}' $file_log | sed 's/ERROR/ERR/g;s/warn/WARN/g'
echo "清洗后的记录数"
awk -F '[ :]' '$2=="ERROR" || $2=="warn" {print $0}' $file_log | sed 's/ERROR/ERR/g;s/warn/WARN/g' | awk 'END{print NR}'
