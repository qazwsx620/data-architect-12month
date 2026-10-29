package com.example;

import org.apache.flink.streaming.api.environment.StreamExecutionEnvironment;
import org.apache.flink.table.api.bridge.java.StreamTableEnvironment;

public class FlinkSqlReport {
    public static void main(String[] args) {
        StreamExecutionEnvironment env = StreamExecutionEnvironment.getExecutionEnvironment();
        env.enableCheckpointing(5000);
        StreamTableEnvironment tEnv = StreamTableEnvironment.create(env);

        // ODS：Kafka 原始订单流
        tEnv.executeSql("CREATE TABLE order_tb (" +
            " user_id STRING, amount DOUBLE, status INT, proc_time AS PROCTIME()" +
            ") WITH ('connector'='kafka','topic'='order_topic'," +
            "'properties.bootstrap.servers'='127.0.0.1:9092'," +
            "'properties.group.id'='flink_report'," +
            "'scan.startup.mode'='latest-offset','format'='csv')");

        // DWD：口径统一 status=2（只留已支付）
        tEnv.executeSql("CREATE VIEW dwd_order AS " +
            "SELECT user_id, amount, proc_time FROM order_tb WHERE status = 2");

        // DWS：10s 窗口 GMV（别名与 MySQL 物理列名对齐）
        tEnv.executeSql("CREATE VIEW dws_gmv AS " +
            "SELECT TUMBLE_START(proc_time, INTERVAL '10' SECOND) AS window_start," +
            "       TUMBLE_END(proc_time, INTERVAL '10' SECOND) AS window_end," +
            "       SUM(amount) AS gmv, COUNT(*) AS cnt " +
            "FROM dwd_order GROUP BY TUMBLE(proc_time, INTERVAL '10' SECOND)");

        // ADS：JDBC sink 落 MySQL ads_realtime_gmv
        // 注意：字段名/类型必须与物理表对齐；主键决定 upsert 覆盖语义
        tEnv.executeSql("CREATE TABLE ads_mysql (" +
            " window_start TIMESTAMP(3), window_end TIMESTAMP(3)," +
            " gmv DOUBLE, cnt BIGINT," +
            " PRIMARY KEY (window_start) NOT ENFORCED" +
            ") WITH ('connector'='jdbc'," +
            "'url'='jdbc:mysql://127.0.0.1:3306/dw_project?useSSL=false&serverTimezone=Asia/Shanghai&allowPublicKeyRetrieval=true'," +
            "'table-name'='ads_realtime_gmv'," +
            "'username'='root','password'='123456'," +
            "'sink.buffer-flush.max-rows'='1','sink.buffer-flush.interval'='1s')");

        tEnv.executeSql("INSERT INTO ads_mysql SELECT * FROM dws_gmv");
    }
}
