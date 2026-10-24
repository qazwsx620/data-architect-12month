package com.example;

import org.apache.flink.api.common.functions.FlatMapFunction;
import org.apache.flink.api.common.typeinfo.Types;
import org.apache.flink.api.java.tuple.Tuple2;
import org.apache.flink.streaming.api.datastream.DataStream;
import org.apache.flink.streaming.api.environment.StreamExecutionEnvironment;
import org.apache.flink.util.Collector;

public class SocketWordCount {
    public static void main(String[] args) throws Exception {
        // 1. 环境（本地执行）
        StreamExecutionEnvironment env = StreamExecutionEnvironment.getExecutionEnvironment();

        // 2. Source：socket 实时流（nc -lk 9999 输入）
        DataStream<String> lines = env.socketTextStream("localhost", 9999);

        // 3. flatMap：一行 → 多个单词（匿名类写法，避免类型擦除）
        DataStream<String> words = lines.flatMap(new FlatMapFunction<String, String>() {
            @Override
            public void flatMap(String line, Collector<String> out) {
                for (String w : line.split(" ")) out.collect(w);
            }
        });

        // 4. map：单词 → (单词,1)，Lambda 返回 Tuple2 类型擦除 → returns 显式指定
        DataStream<Tuple2<String, Integer>> pairs = words
            .map(w -> Tuple2.of(w, 1))
            .returns(Types.TUPLE(Types.STRING, Types.INT));

        // 5. filter：只保留长度 > 1 的单词（演示过滤）
        DataStream<Tuple2<String, Integer>> filtered = pairs.filter(p -> p.f0.length() > 1);

        // 6. Sink：写文件（单并行 = 单文件输出）
        filtered.writeAsText("/tmp/flink_socket_out").setParallelism(1);

        // 7. 提交执行
        env.execute("socket-wordcount");
    }
}
