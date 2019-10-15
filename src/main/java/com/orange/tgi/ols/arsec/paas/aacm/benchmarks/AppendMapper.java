package com.orange.tgi.ols.arsec.paas.aacm.benchmarks;

import java.io.Closeable;
import java.io.IOException;
import java.io.OutputStream;
import java.util.Random;

import org.apache.hadoop.fs.Path;
import org.apache.hadoop.mapred.Reporter;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

/**
 * Append mapper class.
 */
public class AppendMapper extends IOStatMapper {
  private static final Logger LOG = LoggerFactory.getLogger(AppendMapper.class);

  public AppendMapper() {
  }

  @Override // IOMapperBase
  public Closeable getIOStream(String name) throws IOException {
    // open file for append
    OutputStream out = fs
        .append(new Path(TestDFSIO.getDataDir(getConf()), name), bufferSize);
    if (compressionCodec != null)
      out = compressionCodec.createOutputStream(out);
    LOG.info("out = " + out.getClass().getName());
    return out;
  }

  @Override // IOMapperBase
  public Long doIO(Reporter reporter, String name, long totalSize // in bytes
  ) throws IOException {
    byte[] buffer = new byte[bufferSize];
    Random random = new Random();
    OutputStream out = (OutputStream) stream;
    // write to the file
    long nrRemaining;
    int curSize;
    for (nrRemaining = totalSize; nrRemaining > 0; nrRemaining -= bufferSize) {
      random.nextBytes(buffer);
      curSize = (bufferSize < nrRemaining) ? bufferSize : (int) nrRemaining;
      out.write(buffer, 0, curSize);
      reporter.setStatus("writing " + name + "@" + (totalSize - nrRemaining)
          + "/" + totalSize + " ::host = " + hostName);
    }
    return Long.valueOf(totalSize);
  }
}