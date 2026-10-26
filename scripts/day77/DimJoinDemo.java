package com.example;

import org.apache.flink.api.common.eventtime.WatermarkStrategy;
import org.apache.flink.api.common.serialization.SimpleStringSchema;
import org.apache.flink.api.common.typeinfo.Types;
import org.apache.flink.api.java.tuple.Tuple3;
import org.apache.flink.connector.kafka.source.KafkaSource;
import org.apache.flink.connector.kafka.source.enumerator.initializer.OffsetsInitializer;
import org.apache.flink.streaming.api.datastream.DataStream;
import org.apache.flink.streaming.api.environment.StreamExecutionEnvironment;

import java.util.HashMap;
import java.util.Map;

public class DimJoinDemo {
    public static void main(String[] args) throws Exception {
        StreamExecutionEnvironment env = StreamExecutionEnvironment.getExecutionEnvironment();
        env.enableCheckpointing(5000);

        // ODS：Kafka 订单流（user_id,amount,status）
        KafkaSource<String> source = KafkaSource.<String>builder()
            .setBootstrapServers("127.0.0.1:9092")
            .setTopics("order_topic")
            .setGroupId("flink_dim")
            .setStartingOffsets(OffsetsInitializer.latest())
            .setValueOnlyDeserializer(new SimpleStringSchema())
            .build();

        DataStream<String> lines = env.fromSource(source, WatermarkStrategy.noWatermarks(), "kafka-order");

        DataStream<Tuple3<String, Double, Integer>> orders = lines
            .map(line -> {
                String[] s = line.split(",");
                return Tuple3.of(s[0], Double.parseDouble(s[1]), Integer.parseInt(s[2]));
            })
            .returns(Types.TUPLE(Types.STRING, Types.DOUBLE, Types.INT));

        // 维表（教学简化：内存 Map 模拟 MySQL dim_user）
        // 生产：MySQL/HBase 维表 + 异步IO查询 + 缓存(TTL/版本号)/广播流更新
        Map<String, String> dimUser = new HashMap<>();
        dimUser.put("1", "张三");
        dimUser.put("2", "李四");
        dimUser.put("3", "王五");

        // 关联维表：订单行补上用户名（查不到给"未知用户"，明细不丢）
        orders
            .keyBy(t -> t.f0)
            .map(t -> {
                String name = dimUser.getOrDefault(t.f0, "未知用户");
                return "订单user=" + t.f0 + "(" + name + ") 金额=" + t.f1 + " status=" + t.f2;
            })
            .print();

        env.execute("dim-join-demo");
    }
}
