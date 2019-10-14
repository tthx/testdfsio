package com.orange.tgi.ols.arsec.paas.aacm.benchmarks;

import java.io.IOException;
import java.nio.ByteBuffer;

import org.apache.hadoop.hdfs.client.HdfsDataInputStream;
import org.apache.hadoop.mapred.Reporter;

/**
 * Direct read mapper class.
 */
public class DirectReadMapper extends ReadMapper {

  public DirectReadMapper() {
  }

  @Override // IOMapperBase
  public Long doIO(Reporter reporter, String name, long totalSize // in bytes
  ) throws IOException {
    HdfsDataInputStream in = (HdfsDataInputStream) this.stream;
    ByteBuffer buffer = ByteBuffer.allocateDirect(bufferSize);
    long actualSize = 0;
    int curSize;
    buffer.limit(buffer.capacity());
    while (buffer.hasRemaining()) {
      curSize = in.read(buffer);
      if (curSize < 0)
        break;
      actualSize += curSize;
      reporter.setStatus("reading " + name + "@" + actualSize + "/" + totalSize
          + " ::host = " + hostName);
    }
    return Long.valueOf(actualSize);
  }
}
