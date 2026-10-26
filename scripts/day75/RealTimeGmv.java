package com.example;

import org.apache.flink.api.common.eventtime.WatermarkStrategy;
import org.apache.flink.api.common.serialization.SimpleStringSchema;
import org.apache.flink.api.common.typeinfo.Types;
import org.apache.flink.api.java.tuple.Tuple3;
import org.apache.flink.connector.kafka.source.KafkaSource;
import org.apache.flink.connector.kafka.source.enumerator.initializer.OffsetsInitializer;
import org.apache.flink.streaming.api.datastream.DataStream;
import org.apache.flink.streaming.api.environment.StreamExecutionEnvironment;
import org.apache.flink.streaming.api.functions.windowing.AllWindowFunction;
import org.apache.flink.streaming.api.windowing.assigners.TumblingProcessingTimeWindows;
import org.apache.flink.streaming.api.windowing.time.Time;
import org.apache.flink.streaming.api.windowing.windows.TimeWindow;
import org.apache.flink.util.Collector;

public class RealTimeGmv {
    public static void main(String[] args) throws Exception {
        StreamExecutionEnvironment env = StreamExecutionEnvironment.getExecutionEnvironment();
        env.enableCheckpointing(5000);   // ODS→DWD→DWS→ADS 全程有容错

        // ODS：Kafka 订单原始流
        KafkaSource<String> source = KafkaSource.<String>builder()
            .setBootstrapServers("127.0.0.1:9092")
            .setTopics("order_topic")
            .setGroupId("flink_gmv")
            .setStartingOffsets(OffsetsInitializer.latest())
            .setValueOnlyDeserializer(new SimpleStringSchema())
            .build();

        DataStream<String> lines = env.fromSource(source, WatermarkStrategy.noWatermarks(), "kafka-order");

        // 解析 (user_id, amount, status)
        DataStream<Tuple3<String, Double, Integer>> orders = lines
            .map(line -> {
                String[] s = line.split(",");
                return Tuple3.of(s[0], Double.parseDouble(s[1]), Integer.parseInt(s[2]));
            })
            .returns(Types.TUPLE(Types.STRING, Types.DOUBLE, Types.INT));

        // DWD：过滤 status=2（已支付）——GMV 口径（和离线完全一致）
        DataStream<Tuple3<String, Double, Integer>> paid = orders.filter(t -> t.f2 == 2);

        // DWS/ADS：10s 窗口实时 GMV
        paid
            .windowAll(TumblingProcessingTimeWindows.of(Time.seconds(10)))
            .apply(new AllWindowFunction<Tuple3<String, Double, Integer>, String, TimeWindow>() {
                @Override
                public void apply(TimeWindow w, Iterable<Tuple3<String, Double, Integer>> v, Collector<String> out) {
                    double gmv = 0; long cnt = 0;
                    for (Tuple3<String, Double, Integer> x : v) { gmv += x.f1; cnt++; }
                    out.collect("实时GMV[" + w.getStart() + "~" + w.getEnd() + ") 订单数=" + cnt + " GMV=" + gmv);
                }
            })
            .print();

        env.execute("realtime-gmv");
    }
}
