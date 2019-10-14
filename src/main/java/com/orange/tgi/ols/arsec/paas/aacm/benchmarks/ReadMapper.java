package com.orange.tgi.ols.arsec.paas.aacm.benchmarks;

import java.io.Closeable;
import java.io.IOException;
import java.io.InputStream;

import org.apache.hadoop.fs.Path;
import org.apache.hadoop.mapred.Reporter;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

/**
 * Read mapper class.
 */
public class ReadMapper extends IOStatMapper {
  private static final Logger LOG = LoggerFactory.getLogger(ReadMapper.class);

  public ReadMapper() {
  }

  @Override // IOMapperBase
  public Closeable getIOStream(String name) throws IOException {
    // open file
    InputStream in = fs.open(new Path(TestDFSIO.getDataDir(getConf()), name));
    if (compressionCodec != null)
      in = compressionCodec.createInputStream(in);
    LOG.info("in = " + in.getClass().getName());
    return in;
  }

  @Override // IOMapperBase
  public Long doIO(Reporter reporter, String name, long totalSize // in bytes
  ) throws IOException {
    InputStream in = (InputStream) this.stream;
    long actualSize = 0;
    while (actualSize < totalSize) {
      int curSize = in.read(buffer, 0, bufferSize);
      if (curSize < 0)
        break;
      actualSize += curSize;
      reporter.setStatus("reading " + name + "@" + actualSize + "/" + totalSize
          + " ::host = " + hostName);
    }
    return Long.valueOf(actualSize);
  }
}
