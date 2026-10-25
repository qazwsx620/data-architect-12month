package com.example;

import org.apache.flink.api.common.eventtime.SerializableTimestampAssigner;
import org.apache.flink.api.common.eventtime.WatermarkStrategy;
import org.apache.flink.api.common.typeinfo.Types;
import org.apache.flink.api.java.tuple.Tuple3;
import org.apache.flink.streaming.api.datastream.DataStream;
import org.apache.flink.streaming.api.environment.StreamExecutionEnvironment;
import org.apache.flink.streaming.api.functions.windowing.AllWindowFunction;
import org.apache.flink.streaming.api.windowing.assigners.TumblingEventTimeWindows;
import org.apache.flink.streaming.api.windowing.time.Time;
import org.apache.flink.streaming.api.windowing.windows.TimeWindow;
import org.apache.flink.util.Collector;

import java.time.Duration;

public class EventTimeWindow {
    public static void main(String[] args) throws Exception {
        StreamExecutionEnvironment env = StreamExecutionEnvironment.getExecutionEnvironment();
        env.setParallelism(1);

        // Source：socket，格式 "order_id,amount,event_time_epochMillis"
        DataStream<String> lines = env.socketTextStream("localhost", 9999);

        // 解析 + 指定事件时间 + Watermark（允许乱序 3 秒）
        DataStream<Tuple3<Integer, Double, Long>> orders = lines
            .map(line -> {
                String[] s = line.split(",");
                return Tuple3.of(Integer.parseInt(s[0]),
                        Double.parseDouble(s[1]), Long.parseLong(s[2]));
            })
            .returns(Types.TUPLE(Types.INT, Types.DOUBLE, Types.LONG))
            .assignTimestampsAndWatermarks(
                WatermarkStrategy
                    .<Tuple3<Integer, Double, Long>>forBoundedOutOfOrderness(Duration.ofSeconds(3))
                    .withTimestampAssigner(
                        (SerializableTimestampAssigner<Tuple3<Integer, Double, Long>>)
                        (e, t) -> e.f2));   // 事件时间 = f2（毫秒）

        // 10s 滚动事件时间窗口
        DataStream<String> result = orders
            .windowAll(TumblingEventTimeWindows.of(Time.seconds(10)))
            .apply(new AllWindowFunction<Tuple3<Integer, Double, Long>, String, TimeWindow>() {
                @Override
                public void apply(TimeWindow window, Iterable<Tuple3<Integer, Double, Long>> values,
                                  Collector<String> out) {
                    long cnt = 0; double sum = 0;
                    for (Tuple3<Integer, Double, Long> v : values) { cnt++; sum += v.f1; }
                    out.collect("窗口[" + window.getStart() + "~" + window.getEnd() + ") "
                            + "订单数=" + cnt + " 金额=" + sum);
                }
            });

        result.print();
        env.execute("event-time-window");
    }
}
