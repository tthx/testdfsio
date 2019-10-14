package com.orange.tgi.ols.arsec.paas.aacm.benchmarks;

import java.io.IOException;

import org.apache.hadoop.io.Text;
import org.apache.hadoop.io.compress.CompressionCodec;
import org.apache.hadoop.mapred.JobConf;
import org.apache.hadoop.mapred.OutputCollector;
import org.apache.hadoop.util.ReflectionUtils;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

/**
 * Write/Read mapper base class.
 * <p>
 * Collects the following statistics per task:
 * <ul>
 * <li>number of tasks completed</li>
 * <li>number of bytes written/read</li>
 * <li>execution time</li>
 * <li>i/o rate</li>
 * <li>i/o rate squared</li>
 * </ul>
 */
public abstract class IOStatMapper extends IOMapperBase<Long> {
  private static final Logger LOG = LoggerFactory.getLogger(IOStatMapper.class);
  protected CompressionCodec compressionCodec;
  protected String blockStoragePolicy;

  IOStatMapper() {
  }

  @Override // Mapper
  public void configure(JobConf conf) {
    super.configure(conf);

    // grab compression
    String compression = getConf().get("test.io.compression.class", null);
    Class<? extends CompressionCodec> codec;

    // try to initialize codec
    try {
      codec = (compression == null) ? null
          : Class.forName(compression).asSubclass(CompressionCodec.class);
    } catch (Exception e) {
      throw new RuntimeException("Compression codec not found: ", e);
    }

    if (codec != null) {
      compressionCodec
          = (CompressionCodec) ReflectionUtils.newInstance(codec, getConf());
    }

    blockStoragePolicy = getConf().get(TestDFSIO.STORAGE_POLICY_NAME_KEY, null);
  }

  @Override // IOMapperBase
  void collectStats(OutputCollector<Text, Text> output, String name,
      long execTime, Long objSize) throws IOException {
    long totalSize = objSize.longValue();
    float ioRateMbSec = (float) totalSize * 1000 / (execTime * TestDFSIO.MEGA);
    LOG.info("Number of bytes processed = " + totalSize);
    LOG.info("Exec time = " + execTime);
    LOG.info("IO rate = " + ioRateMbSec);

    output.collect(new Text(AccumulatingReducer.VALUE_TYPE_LONG + "tasks"),
        new Text(String.valueOf(1)));
    output.collect(new Text(AccumulatingReducer.VALUE_TYPE_LONG + "size"),
        new Text(String.valueOf(totalSize)));
    output.collect(new Text(AccumulatingReducer.VALUE_TYPE_LONG + "time"),
        new Text(String.valueOf(execTime)));
    output.collect(new Text(AccumulatingReducer.VALUE_TYPE_FLOAT + "rate"),
        new Text(String.valueOf(ioRateMbSec * 1000)));
    output.collect(new Text(AccumulatingReducer.VALUE_TYPE_FLOAT + "sqrate"),
        new Text(String.valueOf(ioRateMbSec * ioRateMbSec * 1000)));
  }
}