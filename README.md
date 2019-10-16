# A corrected and enhanced version of Apache Hadoop TestDFSIO

This project is just an debugged version of [*Apache Hadoop TestDFSIO*](https://github.com/apache/hadoop/blob/master/hadoop-mapreduce-project/hadoop-mapreduce-client/hadoop-mapreduce-client-jobclient/src/test/java/org/apache/hadoop/fs/TestDFSIO.java). Purposes of this project are to:

- correct the buggy [*storage policies*](https://hadoop.apache.org/docs/current/hadoop-project-dist/hadoop-hdfs/ArchivalStorage.html) feature in TestDFSIO,
- add [*short circuit local reads*](https://hadoop.apache.org/docs/current/hadoop-project-dist/hadoop-hdfs/ShortCircuitLocalReads.html) feature.

TestDFSIO is claimed as a distributed I/O benchmark. TestDFSIO writes into or reads from a specified number of files. Number of bytes to write or read is specified as a parameter to the test. Each file is accessed in a separate map task. The reducer collects the following statistics:

- number of tasks completed,
- number of bytes written/read,
- execution time,
- I/O rate,
- I/O rate squared.

Finally, the following information is appended to a local file:

- read or write test,
- date and time the test finished,
- number of files,
- total number of bytes processed,
- throughput in mb/sec (total number of bytes/sum of processing times),
- average I/O rate in mb/sec per file,
- standard deviation of I/O rate.

**Note**: TestDFSIO is a Map/Reduce job, the Map/Reduce or [*Apache Hadoop YARN*](https://hadoop.apache.org/docs/current/hadoop-yarn/hadoop-yarn-site/YARN.html) stack of the cluster to benchmark must be correctly working.

TestDFSIO arguments are prompted by the following command:

```shell
$ yarn jar TestDFSIO-0.0.1.jar com.orange.tgi.ols.arsec.paas.aacm.benchmarks.TestDFSIO
Missing arguments.
Usage: TestDFSIO [genericOptions] -read [-random | -backward | -skip [-skipSize Size] | -shortcircuit] | -write | -append | -truncate | -clean [-compression codecClassName] [-nrFiles N] [-size Size[B|KB|MB|GB|TB]] [-resFile resultFileName] [-bufferSize Bytes] [-storagePolicy storagePolicyName] [-erasureCodePolicy erasureCodePolicyName]
```

By default, TestDFSIO read/write on HDFS in the `/benchmarks/TestDFSIO` directory. As a default user, you must not have rights to write in HDFS root. To use TestDFSIO, you must set the property `test.build.data` to a directory where you have enough rights to read/write. For example, if the HDFS administrator has created the directory `/home/alice` for an Alice user with enough read/write rights, Alice can set the property `test.build.data` to `/home/alice/benchmarks/TestDFSIO`:

```shell
$ yarn jar TestDFSIO-0.0.1.jar com.orange.tgi.ols.arsec.paas.aacm.benchmarks.TestDFSIO -Dtest.build.data=/home/alice/benchmarks/TestDFSIO -write -nrFiles 10 -size 1000
```

By default, TestDFSIO appends its results in a local file named `TestDFSIO_results.log` in the local directory where the command was executed. You can override this behavior by setting the argument `-resFile resultFileName`. Here follows an example of a result file after two tests have been run:

```
----- TestDFSIO ----- : write
            Date & time: Fri Sep 27 13:01:56 CEST 2019
        Number of files: 10
 Total MBytes processed: 20480
      Throughput mb/sec: 102.13
 Average IO rate mb/sec: 131.86
  IO rate std deviation: 112.7
     Test exec time sec: 56.09

----- TestDFSIO ----- : write
            Date & time: Fri Sep 27 13:04:01 CEST 2019
        Number of files: 20
 Total MBytes processed: 40960
      Throughput mb/sec: 84.02
 Average IO rate mb/sec: 87.96
  IO rate std deviation: 26.31
     Test exec time sec: 94.96
```

**Note**: TestDFSIO results don’t include the parameters of the runs. You should wrap TestDFSIO command in a script to persist the parameters of a TestDFSIO run.

The following table describes others TestDFSIO arguments:

|TestDFSIO parameters|Description|
|---:|:---|
|`[genericOptions]`|TestDFSIO honors the [*Hadoop command-line Generic Options*](https://hadoop.apache.org/docs/current/hadoop-project-dist/hadoop-common/CommandsManual.html#Generic_Options) to alter its behavior.|
|`-write`|Performs writes on a HDFS cluster. It is convenient to use this before the `-read` argument, so that some files are prepared for read test.<br><br>The written files are located in HDFS under folder specified by `test.build.data` property. If the folder exists, it will be first deleted.<br><br>You can set HDFS replication factor for each TestDFSIO write with the property `dfs.replication`. For example, if we set the output folder to `/home/alice/benchmarks/TestDFSIO` and the HDFS replication factor to 2, the resulting command is:<br><br>```$ yarn jar $HADOOP_HOME/share/hadoop/mapreduce/hadoop-mapreduce-client-jobclient-3.2.1-tests.jar TestDFSIO -Ddfs.replication=2 -Dtest.build.data=/home/alice/benchmarks/TestDFSIO -write -nrFiles 10 -size 2GB```<br><br>**Note**: As before each write test, TestDFSIO delete the folder specified by the property `test.build.data`. If you want to reuse an output folder and preserve the files of previous runs, you have to copy/move these files manually to a new HDFS location. The simplest way to achieve this is to use a new output directory for each write test.<br><br>TestDFSIO support several write mode:<br>- Sequential write, it’s the default,<br>- Append write, by using `-append` instead of `-write` parameter,<br>- Truncate write, by using `-truncate` instead of `-write` parameter. **Note**: With `-truncate` parameter, the value specified by the `-size` parameter must be less or equal than files size to truncate otherwise exceptions are raised.|
|`-read`|Performs reads on a HDFS cluster. Read test of TestDFSIO does not generate its own input files. For this reason, it is a convenient practice to first run a write test via -write and then follow-up with a read test via `-read` (while using the same parameters as during the previous `-write` run).<br><br>TestDFSIO support several read mode:<br>- Sequential read, it’s the default. By adding `-shortcircuit` to the `-read` parameter you can test the [*short circuit local reads*](https://hadoop.apache.org/docs/current/hadoop-project-dist/hadoop-hdfs/ShortCircuitLocalReads.html) feature. **Note**: Our tests of *short circuit local* reads compressed file as raw file: we don't decompress data (i.e.: using `-compression <codecClassName>` parameter with `-shortcircuit`parameter is useless),<br>- Random read, by adding `-random` to the `-read` parameter,<br>- Backward read, by adding `-backward` to the `-read` parameter,<br>- Skip read, by adding `-skip` to the `-read` parameter. In this mode, you can specify the value to skip with the `-skipSize` parameter.|
|`-nrFiles <n>`|Set the number of files used in test. If the test is writing, this argument defines the number of output files. If the test is reading, this argument defines the number of input files.<br><br>**Note**: Values of the parameter `-nrFiles` for append, truncate and read tests must be less or equal than to those used during the writing test otherwise exceptions are raised.<br><br>**Note**: TestDFSIO is designed in such a way that it will use one map task per file to write or to read. In parallel, each map tack attempts to create a file. But, if the value of `-nrFiles` exceeds the number of tasks which the target cluster can run in parallel, some map tasks of TestDFSIO are pending.|
|`-size <n> [B\|KB\|MB\|GB\|TB]`|Set files size used in testing. This argument takes a numerical value with optional `B\|KB\|MB\|GB\|TB`. `MB` is default.|
|`-clean`|Deletes the HDFS output folder specified by `test.build.data` (`/benchmarks/TestDFSIO` by default).|
|`-compression <codecClassName>`|Performs read/write compressions on a HDFS cluster. Available parameter values are:<br><br>- `org.apache.hadoop.io.compress.BZip2Codec`,<br>- `org.apache.hadoop.io.compress.DefaultCodec`,<br>- `org.apache.hadoop.io.compress.DeflateCodec`,<br>- `org.apache.hadoop.io.compress.GzipCodec`,<br>- `org.apache.hadoop.io.compress.Lz4Codec`,<br>- `org.apache.hadoop.io.compress.SnappyCodec`.<br><br>To be consistent, when you use compression codec at write, you must use the same compression codec at read.<br><br>**Note**: TestDFSIO reads compressed files without raising exception if you don’t specify compression codec. But it raises exceptions if you attempt to read with a different codec than the one used at write.|
|`-storagePolicy <storagePolicyName>`|Performs read/write with storages policies. Available parameter values are:<br><br>- `PROVIDED`,<br>- `COLD`,<br>- `WARM`,<br>- `HOT`,<br>- `ONE_SSD`,<br>- `ALL_SSD`,<br>- `LAZY_PERSIST`.<br><br>For their meaning, see [*Archival Storage, SSD & Memory*](https://hadoop.apache.org/docs/current/hadoop-project-dist/hadoop-hdfs/ArchivalStorage.html)|
|`-erasureCodePolicy <erasureCodePolicyName>`|Performs read/write with HDFS erasure coding. Available parameter values are:<br><br>- `RS-10-4-1024k`,<br>- `RS-3-2-1024k`,<br>- `RS-6-3-1024k`,<br>- `RS-LEGACY-6-3-1024k`,<br>- `XOR-2-1-1024k`,<br><br>For their meaning, see [*HDFS Erasure Coding*](https://hadoop.apache.org/docs/current/hadoop-project-dist/hadoop-hdfs/HDFSErasureCoding.html).|

In `[genericOptions]`, the most common HDFS behaviors we would like to alter are:

- The HDFS file block size, for a new file, set with `-Ddfs.blocksize=<n>` (default: 128m),, where `<n>` is the value of the block size. You can use the following suffix (case insensitive): `k(kilo)`, `m(mega)`, `g(giga)`, `t(tera)`, `p(peta)`, `e(exa)` to specify the size (such as 128k, 512m, 1g, etc.), Or provide complete size in bytes (such as 134217728 for 128 MB).
- The number of replication per block at HDFS file creation time, set with `-Ddfs.replication=<n>` (default: 3), where `<n>` is this number. If this number is not specify, the default value, set in `hdfs-default.xml` (or `$HADOOP_CONF_DIR/hdfs-site.xml` if you use a custom configuration file) is used. 
- Map and reduce tasks Java heap and JVM options:

  - `-Dmapreduce.task.io.sort.mb=<n>` (default: 100), where `<n>` the cumulative size of the serialization and accounting buffers storing records emitted from a map task, in megabytes.
  - For map tasks:
    - `-Dmapreduce.job.maps=<n>` (default: 2), where `<n>` is the number of map tasks per job, 
    - `-Dmapreduce.map.memory.mb=<n>` (default: -1), where `<n>` is the amount memory for each map task,
    - `-Dmapreduce.map.java.opts=<JVM options>`, where `<JVM options>`, are JVM options (e.g. `-XX:+UseG1GC`).
  - For reduce tasks: 
    - `-Dmapreduce.job.reduces=<n>` (default: 1), where `<n>` is the number of reducer tasks per job,
    - `-Dmapreduce.reduce.memory.mb=<n>` (default: -1),, where `<n>` is the amount memory for each reduce task,
    - `-Dmapreduce.reduce.java.opts=<JVM options>`, where `<JVM options>`, are JVM options (e.g. `-XX:+UseG1GC`).

**Note**: For TestDFSIO, you should set the amount of memory for map and reduces tasks at least to 1024 and JVM garbage collector to [*G1 Garbage Collector*](https://www.oracle.com/technetwork/tutorials/tutorials-1876574.html) with `-XX:+UseG1GC`.
