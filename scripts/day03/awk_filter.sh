#!/bin/bash
set -euo pipefail
log_file="test.log"
echo "只筛选ERROR日志："
awk -F '[ :]' '$2=="ERROR" {print NR,$1,$2}' $log_file
