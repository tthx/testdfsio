package com.orange.tgi.ols.arsec.paas.aacm.benchmarks;

import java.io.Closeable;
import java.io.IOException;
import java.io.InputStream;
import java.util.concurrent.ThreadLocalRandom;

import org.apache.hadoop.fs.FSDataInputStream;
import org.apache.hadoop.fs.Path;
import org.apache.hadoop.fs.PositionedReadable;
import org.apache.hadoop.mapred.JobConf;
import org.apache.hadoop.mapred.Reporter;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

/**
 * Mapper class for random reads. The mapper chooses a position in the file and
 * reads bufferSize bytes starting at the chosen position. It stops after
 * reading the totalSize bytes, specified by -size.
 * 
 * There are three type of reads. 1) Random read always chooses a random
 * position to read from: skipSize = 0 2) Backward read reads file in reverse
 * order : skipSize < 0 3) Skip-read skips skipSize bytes after every read :
 * skipSize > 0
 */
public class RandomReadMapper extends IOStatMapper {
  private static final Logger LOG
      = LoggerFactory.getLogger(RandomReadMapper.class);

  private ThreadLocalRandom rnd;
  private long fileSize;
  private long skipSize;

  @Override // Mapper
  public void configure(JobConf conf) {
    super.configure(conf);
    skipSize = conf.getLong("test.io.skip.size", 0);
  }

  public RandomReadMapper() {
    rnd = ThreadLocalRandom.current();
  }

  @Override // IOMapperBase
  public Closeable getIOStream(String name) throws IOException {
    Path filePath = new Path(TestDFSIO.getDataDir(getConf()), name);
    this.fileSize = fs.getFileStatus(filePath).getLen();
    InputStream in = fs.open(filePath);
    if (compressionCodec != null)
      in = new FSDataInputStream(compressionCodec.createInputStream(in));
    LOG.info("in = " + in.getClass().getName());
    LOG.info("skipSize = " + skipSize);
    return in;
  }

  @Override // IOMapperBase
  public Long doIO(Reporter reporter, String name, long totalSize // in bytes
  ) throws IOException {
    PositionedReadable in = (PositionedReadable) this.stream;
    long actualSize = 0;
    for (long pos = nextOffset(-1); actualSize < totalSize;
        pos = nextOffset(pos)) {
      int curSize = in.read(pos, buffer, 0, bufferSize);
      if (curSize < 0)
        break;
      actualSize += curSize;
      reporter.setStatus("reading " + name + "@" + actualSize + "/" + totalSize
          + " ::host = " + hostName);
    }
    return Long.valueOf(actualSize);
  }

  /**
   * Get next offset for reading. If current < 0 then choose initial offset
   * according to the read type.
   * 
   * @param current offset
   * @return
   */
  private long nextOffset(long current) {
    if (skipSize == 0)
      return rnd.nextLong(fileSize);
    if (skipSize > 0)
      return (current < 0) ? 0 : (current + bufferSize + skipSize);
    // skipSize < 0
    return (current < 0) ? Math.max(0, fileSize - bufferSize)
        : Math.max(0, current + skipSize);
  }
}
