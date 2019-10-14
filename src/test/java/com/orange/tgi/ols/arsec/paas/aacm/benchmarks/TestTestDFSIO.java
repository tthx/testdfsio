package com.orange.tgi.ols.arsec.paas.aacm.benchmarks;

import org.apache.hadoop.fs.FileSystem;
import org.apache.hadoop.hdfs.DFSConfigKeys;
import org.apache.hadoop.hdfs.MiniDFSCluster;
import org.junit.AfterClass;
import org.junit.BeforeClass;
import org.junit.Test;

import com.orange.tgi.ols.arsec.paas.aacm.benchmarks.TestDFSIO.TestType;

public class TestTestDFSIO {

  private static final int DEFAULT_NR_BYTES = 128;
  private static final int DEFAULT_NR_FILES = 4;
  private static MiniDFSCluster cluster;
  private static TestDFSIO bench;

  @BeforeClass
  public static void beforeClass() throws Exception {
    bench = new TestDFSIO();
    bench.getConf().setInt(DFSConfigKeys.DFS_HEARTBEAT_INTERVAL_KEY, 1);
    cluster = new MiniDFSCluster.Builder(bench.getConf()).numDataNodes(2)
        .format(true).build();
    FileSystem fs = cluster.getFileSystem();
    bench.createControlFile(fs, DEFAULT_NR_BYTES, DEFAULT_NR_FILES);

    /** Check write here, as it is required for other tests */
    testWrite();
  }

  @AfterClass
  public static void afterClass() throws Exception {
    if (cluster == null)
      return;
    FileSystem fs = cluster.getFileSystem();
    bench.cleanup(fs);
    cluster.shutdown();
  }

  public static void testWrite() throws Exception {
    FileSystem fs = cluster.getFileSystem();
    long execTime = bench.writeTest(fs);
    bench.analyzeResult(fs, TestType.TEST_TYPE_WRITE, execTime);
  }

  @Test(timeout = 10000)
  public void testRead() throws Exception {
    FileSystem fs = cluster.getFileSystem();
    long execTime = bench.readTest(fs);
    bench.analyzeResult(fs, TestType.TEST_TYPE_READ, execTime);
  }

  @Test(timeout = 10000)
  public void testReadRandom() throws Exception {
    FileSystem fs = cluster.getFileSystem();
    bench.getConf().setLong("test.io.skip.size", 0);
    long execTime = bench.randomReadTest(fs);
    bench.analyzeResult(fs, TestType.TEST_TYPE_READ_RANDOM, execTime);
  }

  @Test(timeout = 10000)
  public void testReadBackward() throws Exception {
    FileSystem fs = cluster.getFileSystem();
    bench.getConf().setLong("test.io.skip.size",
        -TestDFSIO.DEFAULT_BUFFER_SIZE);
    long execTime = bench.randomReadTest(fs);
    bench.analyzeResult(fs, TestType.TEST_TYPE_READ_BACKWARD, execTime);
  }

  @Test(timeout = 10000)
  public void testReadSkip() throws Exception {
    FileSystem fs = cluster.getFileSystem();
    bench.getConf().setLong("test.io.skip.size", 1);
    long execTime = bench.randomReadTest(fs);
    bench.analyzeResult(fs, TestType.TEST_TYPE_READ_SKIP, execTime);
  }

  @Test(timeout = 10000)
  public void testAppend() throws Exception {
    FileSystem fs = cluster.getFileSystem();
    long execTime = bench.appendTest(fs);
    bench.analyzeResult(fs, TestType.TEST_TYPE_APPEND, execTime);
  }

  @Test(timeout = 60000)
  public void testTruncate() throws Exception {
    FileSystem fs = cluster.getFileSystem();
    bench.createControlFile(fs, DEFAULT_NR_BYTES / 2, DEFAULT_NR_FILES);
    long execTime = bench.truncateTest(fs);
    bench.analyzeResult(fs, TestType.TEST_TYPE_TRUNCATE, execTime);
  }
}
