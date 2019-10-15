package com.orange.tgi.ols.arsec.paas.aacm.benchmarks;

import java.io.Closeable;
import java.io.IOException;
import java.io.OutputStream;
import java.util.EnumSet;
import java.util.Random;

import org.apache.hadoop.fs.CreateFlag;
import org.apache.hadoop.fs.Path;
import org.apache.hadoop.fs.permission.FsPermission;
import org.apache.hadoop.hdfs.DFSConfigKeys;
import org.apache.hadoop.mapred.Reporter;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

/**
 * Write mapper class.
 */
public class WriteMapper extends IOStatMapper {
  private static final Logger LOG = LoggerFactory.getLogger(WriteMapper.class);

  public WriteMapper() {
  }

  @Override // IOMapperBase
  public Closeable getIOStream(String name) throws IOException {
    // create file
    Path filePath = new Path(TestDFSIO.getDataDir(getConf()), name);
    OutputStream out;
    if (blockStoragePolicy != null) {
      out = fs.create(
          filePath, FsPermission.getFileDefault(), EnumSet.of(CreateFlag.CREATE,
              CreateFlag.OVERWRITE, CreateFlag.valueOf(blockStoragePolicy)),
          bufferSize,
          (short) getConf().getInt(DFSConfigKeys.DFS_REPLICATION_KEY,
              DFSConfigKeys.DFS_REPLICATION_DEFAULT),
          getConf().getLongBytes(DFSConfigKeys.DFS_BLOCK_SIZE_KEY,
              DFSConfigKeys.DFS_BLOCK_SIZE_DEFAULT),
          null);
    } else
      out = fs.create(filePath, true, bufferSize);
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
