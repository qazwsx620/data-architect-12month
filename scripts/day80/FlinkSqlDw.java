package com.example;

import org.apache.flink.streaming.api.environment.StreamExecutionEnvironment;
import org.apache.flink.table.api.bridge.java.StreamTableEnvironment;

public class FlinkSqlDw {
    public static void main(String[] args) {
        StreamExecutionEnvironment env = StreamExecutionEnvironment.getExecutionEnvironment();
        env.enableCheckpointing(5000);   // 容错：Checkpoint + Kafka offset 协同
        StreamTableEnvironment tEnv = StreamTableEnvironment.create(env);

        // ODS：Kafka 原始订单流
        tEnv.executeSql("CREATE TABLE order_tb (" +
            " user_id STRING, amount DOUBLE, status INT, proc_time AS PROCTIME()" +
            ") WITH ('connector'='kafka','topic'='order_topic'," +
            "'properties.bootstrap.servers'='127.0.0.1:9092'," +
            "'properties.group.id'='flink_dw'," +
            "'scan.startup.mode'='latest-offset','format'='csv')");

        // DWD：清洗 + 口径统一（只留已支付 status=2）
        tEnv.executeSql("CREATE VIEW dwd_order AS " +
            "SELECT user_id, amount, proc_time FROM order_tb WHERE status = 2");

        // DWS：10s 窗口轻度汇总（GMV + 订单数）
        tEnv.executeSql("CREATE VIEW dws_gmv AS " +
            "SELECT TUMBLE_START(proc_time, INTERVAL '10' SECOND) AS ws," +
            "       TUMBLE_END(proc_time, INTERVAL '10' SECOND) AS we," +
            "       SUM(amount) AS gmv, COUNT(*) AS cnt " +
            "FROM dwd_order GROUP BY TUMBLE(proc_time, INTERVAL '10' SECOND)");

        // ADS：print sink 输出实时 GMV（生产落 MySQL/Redis/大屏）
        tEnv.executeSql("CREATE TABLE ads_sink (" +
            " ws TIMESTAMP(3), we TIMESTAMP(3), gmv DOUBLE, cnt BIGINT" +
            ") WITH ('connector'='print')");

        tEnv.executeSql("INSERT INTO ads_sink SELECT * FROM dws_gmv");
    }
}
