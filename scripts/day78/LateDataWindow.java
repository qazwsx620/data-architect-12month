package com.example;

import org.apache.flink.api.common.eventtime.SerializableTimestampAssigner;
import org.apache.flink.api.common.eventtime.WatermarkStrategy;
import org.apache.flink.api.common.typeinfo.Types;
import org.apache.flink.api.java.tuple.Tuple3;
import org.apache.flink.streaming.api.datastream.DataStream;
import org.apache.flink.streaming.api.datastream.SingleOutputStreamOperator;
import org.apache.flink.streaming.api.environment.StreamExecutionEnvironment;
import org.apache.flink.streaming.api.functions.windowing.AllWindowFunction;
import org.apache.flink.streaming.api.windowing.assigners.TumblingEventTimeWindows;
import org.apache.flink.streaming.api.windowing.time.Time;
import org.apache.flink.streaming.api.windowing.windows.TimeWindow;
import org.apache.flink.util.Collector;
import org.apache.flink.util.OutputTag;

import java.time.Duration;

public class LateDataWindow {
    public static void main(String[] args) throws Exception {
        StreamExecutionEnvironment env = StreamExecutionEnvironment.getExecutionEnvironment();
        env.setParallelism(1);

        // 侧输出流 tag：类型必须与窗口输入一致（Tuple3），否则编译不兼容
        OutputTag<Tuple3<Integer, Double, Long>> lateTag =
            new OutputTag<Tuple3<Integer, Double, Long>>("late") {};

        DataStream<String> lines = env.socketTextStream("localhost", 9999);

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
                    .withTimestampAssigner((e, t) -> e.f2));

        // 10s 事件时间窗口 + 允许迟到 5s + 侧输出流兜底
        SingleOutputStreamOperator<String> result = orders
            .windowAll(TumblingEventTimeWindows.of(Time.seconds(10)))
            .allowedLateness(Time.seconds(5))
            .sideOutputLateData(lateTag)
            .apply(new AllWindowFunction<Tuple3<Integer, Double, Long>, String, TimeWindow>() {
                @Override
                public void apply(TimeWindow w, Iterable<Tuple3<Integer, Double, Long>> v, Collector<String> out) {
                    long cnt = 0; double sum = 0;
                    for (Tuple3<Integer, Double, Long> x : v) { cnt++; sum += x.f1; }
                    out.collect("窗口[" + w.getStart() + "~" + w.getEnd() + ") 订单数=" + cnt + " 金额=" + sum);
                }
            });

        result.print();
        // 侧输出流单独收集（迟到兜底）
        result.getSideOutput(lateTag)
            .map(t -> "迟到旁路: order=" + t.f0 + " 金额=" + t.f1 + " 事件时间=" + t.f2)
            .print();

        env.execute("late-data-window");
    }
}
