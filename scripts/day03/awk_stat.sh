#!/bin/bash
set -euo pipefail
log_file="test.log"
echo "日志分类统计结果："
awk -F '[ :]' '
BEGIN{
    error_cnt=0
    info_cnt=0
    warn_cnt=0
    debug_cnt=0
}
$2=="ERROR" {error_cnt++}
$2=="info" {info_cnt++}
$2=="warn" {warn_cnt++}
$2=="debug" {debug_cnt++}
END{
    print "ERROR:",error_cnt
    print "info:",info_cnt
    print "warn:",warn_cnt
    print "debug:",debug_cnt
}
' $log_file
