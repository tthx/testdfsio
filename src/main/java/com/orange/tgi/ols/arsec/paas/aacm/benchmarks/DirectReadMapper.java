package com.orange.tgi.ols.arsec.paas.aacm.benchmarks;

import java.io.Closeable;
import java.io.IOException;
import java.io.InputStream;
import java.net.URI;
import java.nio.ByteBuffer;
import java.security.PrivilegedExceptionAction;

import org.apache.hadoop.conf.Configuration;
import org.apache.hadoop.fs.FileSystem;
import org.apache.hadoop.fs.Path;
import org.apache.hadoop.hdfs.DistributedFileSystem;
import org.apache.hadoop.hdfs.client.HdfsDataInputStream;
import org.apache.hadoop.mapred.Reporter;
import org.apache.hadoop.security.UserGroupInformation;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

/**
 * Direct read mapper class.
 */
public class DirectReadMapper extends IOStatMapper {
  private static final Logger LOG
      = LoggerFactory.getLogger(DirectReadMapper.class);

  public DirectReadMapper() {
  }

  private DistributedFileSystem getFileSystem()
      throws InterruptedException, IOException {
    UserGroupInformation ugi = UserGroupInformation.createRemoteUser(
        UserGroupInformation.getCurrentUser().getShortUserName());
    return ugi.doAs(new PrivilegedExceptionAction<DistributedFileSystem>() {
      @Override
      public DistributedFileSystem run() throws Exception {
        return (DistributedFileSystem) FileSystem.get(getConf());
      }
    });
  }

  @Override // IOMapperBase
  public Closeable getIOStream(String name) throws IOException {
    // open file
    InputStream in = null;
    try {
      in = getFileSystem()
          .open(new Path(TestDFSIO.getDataDir(getConf()), name));
      if (compressionCodec != null)
        in = compressionCodec.createInputStream(in);
      LOG.info("in = " + in.getClass().getName());
    } catch (InterruptedException e) {
      // TODO Auto-generated catch block
      e.printStackTrace();
    }
    return in;
  }

  @Override // IOMapperBase
  public Long doIO(Reporter reporter, String name, long totalSize // in bytes
  ) throws IOException {
    HdfsDataInputStream in = (HdfsDataInputStream) stream;
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
