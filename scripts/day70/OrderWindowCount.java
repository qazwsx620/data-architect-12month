package com.example;

import org.apache.flink.api.common.typeinfo.Types;
import org.apache.flink.api.java.tuple.Tuple2;
import org.apache.flink.streaming.api.datastream.DataStream;
import org.apache.flink.streaming.api.environment.StreamExecutionEnvironment;
import org.apache.flink.streaming.api.functions.windowing.AllWindowFunction;
import org.apache.flink.streaming.api.windowing.assigners.SlidingProcessingTimeWindows;
import org.apache.flink.streaming.api.windowing.assigners.TumblingProcessingTimeWindows;
import org.apache.flink.streaming.api.windowing.time.Time;
import org.apache.flink.streaming.api.windowing.windows.TimeWindow;
import org.apache.flink.util.Collector;

public class OrderWindowCount {
    public static void main(String[] args) throws Exception {
        StreamExecutionEnvironment env = StreamExecutionEnvironment.getExecutionEnvironment();

        // Source：socket 流，格式 "user_id,amount"
        DataStream<String> lines = env.socketTextStream("localhost", 9999);

        // 解析成 (user_id, amount)
        DataStream<Tuple2<Integer, Double>> orders = lines
            .map(line -> {
                String[] s = line.split(",");
                return Tuple2.of(Integer.parseInt(s[0]), Double.parseDouble(s[1]));
            })
            .returns(Types.TUPLE(Types.INT, Types.DOUBLE));

        // ① 滚动窗口：10s 一个窗（不重叠），统计订单数和金额
        DataStream<Tuple2<Long, Long>> tumbling = orders
            .windowAll(TumblingProcessingTimeWindows.of(Time.seconds(10)))
            .apply(new AllWindowFunction<Tuple2<Integer, Double>, Tuple2<Long, Long>, TimeWindow>() {
                @Override
                public void apply(TimeWindow window, Iterable<Tuple2<Integer, Double>> values,
                                  Collector<Tuple2<Long, Long>> out) {
                    long cnt = 0; double sum = 0;
                    for (Tuple2<Integer, Double> v : values) { cnt++; sum += v.f1; }
                    out.collect(Tuple2.of(cnt, (long) sum));
                }
            });

        tumbling.map(t -> "滚动10s窗口: 订单数=" + t.f0 + " 金额=" + t.f1)
                .print().setParallelism(1);

        // ② 滑动窗口：窗 10s、步长 5s（重叠，一条数据可属 2 窗）
        DataStream<Tuple2<Long, Long>> sliding = orders
            .windowAll(SlidingProcessingTimeWindows.of(Time.seconds(10), Time.seconds(5)))
            .apply(new AllWindowFunction<Tuple2<Integer, Double>, Tuple2<Long, Long>, TimeWindow>() {
                @Override
                public void apply(TimeWindow window, Iterable<Tuple2<Integer, Double>> values,
                                  Collector<Tuple2<Long, Long>> out) {
                    long cnt = 0; double sum = 0;
                    for (Tuple2<Integer, Double> v : values) { cnt++; sum += v.f1; }
                    out.collect(Tuple2.of(cnt, (long) sum));
                }
            });

        sliding.map(t -> "滑动10s/5s窗口: 订单数=" + t.f0 + " 金额=" + t.f1)
                .print().setParallelism(1);

        env.execute("order-window-count");
    }
}
