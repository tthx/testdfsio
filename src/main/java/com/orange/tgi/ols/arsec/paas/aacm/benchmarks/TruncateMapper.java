package com.orange.tgi.ols.arsec.paas.aacm.benchmarks;

import java.io.Closeable;
import java.io.IOException;

import org.apache.hadoop.fs.FileStatus;
import org.apache.hadoop.fs.Path;
import org.apache.hadoop.mapred.Reporter;

/**
 * Truncate mapper class. The mapper truncates given file to the newLength,
 * specified by -size.
 */
public class TruncateMapper extends IOStatMapper {

  private static final long DELAY = 100L;

  private Path filePath;
  private long fileSize;

  @Override // IOMapperBase
  public Closeable getIOStream(String name) throws IOException {
    filePath = new Path(TestDFSIO.getDataDir(getConf()), name);
    fileSize = fs.getFileStatus(filePath).getLen();
    return null;
  }

  @Override // IOMapperBase
  public Long doIO(Reporter reporter, String name, long newLength // in bytes
  ) throws IOException {
    boolean isClosed = fs.truncate(filePath, newLength);
    reporter.setStatus("truncating " + name + " to newLength " + newLength
        + " ::host = " + hostName);
    for (int i = 0; !isClosed; i++) {
      try {
        Thread.sleep(DELAY);
      } catch (InterruptedException ignored) {
      }
      FileStatus status = fs.getFileStatus(filePath);
      assert status != null : "status is null";
      isClosed = (status.getLen() == newLength);
      reporter.setStatus("truncate recover for " + name + " to newLength "
          + newLength + " attempt " + i + " ::host = " + hostName);
    }
    return Long.valueOf(fileSize - newLength);
  }
}