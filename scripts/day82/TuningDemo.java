package com.example;

import org.apache.flink.api.common.restartstrategy.RestartStrategies;
import org.apache.flink.api.common.state.ValueState;
import org.apache.flink.api.common.state.ValueStateDescriptor;
import org.apache.flink.api.common.typeinfo.Types;
import org.apache.flink.api.java.tuple.Tuple2;
import org.apache.flink.configuration.Configuration;
import org.apache.flink.streaming.api.CheckpointingMode;
import org.apache.flink.streaming.api.datastream.DataStream;
import org.apache.flink.streaming.api.environment.StreamExecutionEnvironment;
import org.apache.flink.streaming.api.functions.KeyedProcessFunction;
import org.apache.flink.util.Collector;

public class TuningDemo {
    public static void main(String[] args) throws Exception {
        StreamExecutionEnvironment env = StreamExecutionEnvironment.getExecutionEnvironment();

        // ===== 调优配置段（面试参数落地）=====
        env.enableCheckpointing(5000, CheckpointingMode.EXACTLY_ONCE); // 间隔5s + 精确一次
        env.getCheckpointConfig().setCheckpointTimeout(60000);         // 快照超时60s
        env.getCheckpointConfig().setMinPauseBetweenCheckpoints(2000); // 两次快照最小间隔2s
        env.getCheckpointConfig().setCheckpointStorage("file:///tmp/ckpt-tuning");
        env.setRestartStrategy(RestartStrategies.fixedDelayRestart(3, 5000)); // 失败重启3次间隔5s
        // env.setParallelism(2); // 本机1slot受限；生产按分区数/资源设，瓶颈算子单独调
        // 大状态换 RocksDB：env.setStateBackend(new EmbeddedRocksDBStateBackend());

        DataStream<String> lines = env.socketTextStream("127.0.0.1", 9999);
        lines.map(s -> { String[] a = s.split(","); return Tuple2.of(a[0], Double.parseDouble(a[1])); })
             .returns(Types.TUPLE(Types.STRING, Types.DOUBLE))
             .keyBy(t -> t.f0)
             .process(new KeyedProcessFunction<String, Tuple2<String, Double>, String>() {
                 private ValueState<Double> sum;
                 @Override public void open(Configuration p) {
                     sum = getRuntimeContext().getState(new ValueStateDescriptor<>("amt", Types.DOUBLE));
                 }
                 @Override public void processElement(Tuple2<String, Double> v, Context ctx,
                                                      Collector<String> out) throws Exception {
                     double cur = sum.value() == null ? 0 : sum.value();
                     cur += v.f1;
                     sum.update(cur);
                     out.collect("user=" + v.f0 + " 累计=" + cur);
                 }
             })
             .print();

        env.execute("TuningDemo");
    }
}
