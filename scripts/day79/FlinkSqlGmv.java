package com.example;

import org.apache.flink.streaming.api.environment.StreamExecutionEnvironment;
import org.apache.flink.table.api.bridge.java.StreamTableEnvironment;

public class FlinkSqlGmv {
    public static void main(String[] args) {
        StreamExecutionEnvironment env = StreamExecutionEnvironment.getExecutionEnvironment();
        env.enableCheckpointing(5000);
        StreamTableEnvironment tableEnv = StreamTableEnvironment.create(env);

        // Kafka 源表（CSV: user_id,amount,status；proc_time = 处理时间）
        tableEnv.executeSql(
            "CREATE TABLE order_tb (" +
            "  user_id STRING," +
            "  amount  DOUBLE," +
            "  status  INT," +
            "  proc_time AS PROCTIME()" +
            ") WITH (" +
            "  'connector' = 'kafka'," +
            "  'topic' = 'order_topic'," +
            "  'properties.bootstrap.servers' = '127.0.0.1:9092'," +
            "  'properties.group.id' = 'flink_sql'," +
            "  'scan.startup.mode' = 'latest-offset'," +
            "  'format' = 'csv'" +
            ")");

        // print 结果表（输出到 TaskManager .out 日志）
        tableEnv.executeSql(
            "CREATE TABLE gmv_sink (" +
            "  window_start TIMESTAMP(3)," +
            "  window_end   TIMESTAMP(3)," +
            "  gmv DOUBLE," +
            "  cnt BIGINT" +
            ") WITH ('connector' = 'print')");

        // SQL 窗口聚合：10s 滚动窗口 GMV（status=2 口径，一行 SQL）
        tableEnv.executeSql(
            "INSERT INTO gmv_sink " +
            "SELECT TUMBLE_START(proc_time, INTERVAL '10' SECOND)," +
            "       TUMBLE_END(proc_time, INTERVAL '10' SECOND)," +
            "       SUM(amount), COUNT(*)" +
            "FROM order_tb WHERE status = 2" +
            "GROUP BY TUMBLE(proc_time, INTERVAL '10' SECOND)");
    }
}
