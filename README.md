# A corrected and enhanced version of Apache Hadoop TestDFSIO

This project is just an debugged version of [*Apache Hadoop TestDFSIO*](https://github.com/apache/hadoop/blob/master/hadoop-mapreduce-project/hadoop-mapreduce-client/hadoop-mapreduce-client-jobclient/src/test/java/org/apache/hadoop/fs/TestDFSIO.java). Purposes of this project are to:

- correct the buggy [*storage policies*](https://hadoop.apache.org/docs/current/hadoop-project-dist/hadoop-hdfs/ArchivalStorage.html) feature in TestDFSIO,
- add [*short circuit local reads*](https://hadoop.apache.org/docs/current/hadoop-project-dist/hadoop-hdfs/ShortCircuitLocalReads.html) feature.
- provide facilities to automatize tests.

## TestDFSIO Description

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

**Notes**:

- TestDFSIO is a Map/Reduce job, the Map/Reduce or [*Apache Hadoop YARN*](https://hadoop.apache.org/docs/current/hadoop-yarn/hadoop-yarn-site/YARN.html) stack of the cluster to benchmark must be correctly working.
- TestDFSIO benchmarks only the I/O performances. The YARN scheduler has no opportunity to do any optimization for the TestDFSIO Map/Reduce application: TestDFSIO intentionally avoids any overhead or optimizations induced by Map/Reduce framework.

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
|`-bufferSize <n>`|Set the size of the buffer to use to `<n>` bytes for read/write operations.|
|`-write`|Performs writes on a HDFS cluster. It is convenient to use this before the `-read` argument, so that some files are prepared for read test.<br><br>The written files are located in HDFS under folder specified by `test.build.data` property. If the folder exists, it will be first deleted.<br><br>You can set HDFS replication factor for each TestDFSIO write with the property `dfs.replication`. For example, if we set the output folder to `/home/alice/benchmarks/TestDFSIO` and the HDFS replication factor to 2, the resulting command is:<br><br>```$ yarn jar $HADOOP_HOME/share/hadoop/mapreduce/hadoop-mapreduce-client-jobclient-3.2.1-tests.jar TestDFSIO -Ddfs.replication=2 -Dtest.build.data=/home/alice/benchmarks/TestDFSIO -write -nrFiles 10 -size 2GB```<br><br>**Note**: As before each write test, TestDFSIO delete the folder specified by the property `test.build.data`. If you want to reuse an output folder and preserve the files of previous runs, you have to copy/move these files manually to a new HDFS location. The simplest way to achieve this is to use a new output directory for each write test.<br><br>TestDFSIO support several write mode:<br>- Sequential write, it’s the default,<br>- Append write, by using `-append` instead of `-write` parameter,<br>- Truncate write, by using `-truncate` instead of `-write` parameter. **Note**: With `-truncate` parameter, the value specified by the `-size` parameter must be less or equal than files size to truncate otherwise exceptions are raised.|
|`-read`|Performs reads on a HDFS cluster. Read test of TestDFSIO does not generate its own input files. For this reason, it is a convenient practice to first run a write test via -write and then follow-up with a read test via `-read` (while using the same parameters as during the previous `-write` run).<br><br>TestDFSIO support several read mode:<br>- Sequential read, it’s the default. By adding `-shortcircuit` to the `-read` parameter you can test the [*short circuit local reads*](https://hadoop.apache.org/docs/current/hadoop-project-dist/hadoop-hdfs/ShortCircuitLocalReads.html) feature. **Note**: Our tests of *short circuit local* reads compressed file as raw file: we don't decompress data (i.e.: using `-compression <codecClassName>` parameter with `-shortcircuit`parameter is useless),<br>- Random read, by adding `-random` to the `-read` parameter,<br>- Backward read, by adding `-backward` to the `-read` parameter,<br>- Skip read, by adding `-skip` to the `-read` parameter. In this mode, you can specify the value to skip with the `-skipSize` parameter.|
|`-nrFiles <n>`|Set the number of files used in test. If the test is writing, this argument defines the number of output files. If the test is reading, this argument defines the number of input files.<br><br>**Note**: Values of the parameter `-nrFiles` for append, truncate and read tests must be less or equal than to those used during the writing test otherwise exceptions are raised.<br><br>**Note**: TestDFSIO is designed in such a way that it will use one map task per file to write or to read. In parallel, each map tack attempts to create a file. But, if the value of `-nrFiles` exceeds the number of tasks which the target cluster can run in parallel, some map tasks of TestDFSIO are pending.|
|`-size <n> [B\|KB\|MB\|GB\|TB]`|Set files size used in testing. This argument takes a numerical value with optional `B\|KB\|MB\|GB\|TB`. `MB` is default.|
|`-clean`|Deletes the HDFS output folder specified by `test.build.data` (`/benchmarks/TestDFSIO` by default).|
|`-compression <codecClassName>`|Performs read/write compressions on a HDFS cluster. Available parameter values are:<br><br>- `org.apache.hadoop.io.compress.BZip2Codec`,<br>- `org.apache.hadoop.io.compress.DefaultCodec`,<br>- `org.apache.hadoop.io.compress.DeflateCodec`,<br>- `org.apache.hadoop.io.compress.GzipCodec`,<br>- `org.apache.hadoop.io.compress.Lz4Codec`,<br>- `org.apache.hadoop.io.compress.SnappyCodec`.<br><br>To be consistent, when you use compression codec at write, you must use the same compression codec at read.<br><br>**Note**: TestDFSIO reads compressed files without raising exception if you don’t specify compression codec. But it raises exceptions if you attempt to read with a different codec than the one used at write.|
|`-storagePolicy <storagePolicyName>`|Performs read/write with storages policies. Available parameter values are:<br><br>- `PROVIDED`,<br>- `COLD`,<br>- `WARM`,<br>- `HOT`,<br>- `ONE_SSD`,<br>- `ALL_SSD`,<br>- `LAZY_PERSIST`.<br><br>For their meaning, see [*Archival Storage, SSD & Memory*](https://hadoop.apache.org/docs/current/hadoop-project-dist/hadoop-hdfs/ArchivalStorage.html)|
|`-erasureCodePolicy <erasureCodePolicyName>`|Performs read/write with HDFS erasure coding. Available parameter values are:<br><br>- `RS-10-4-1024k`,<br>- `RS-3-2-1024k`,<br>- `RS-6-3-1024k`,<br>- `RS-LEGACY-6-3-1024k`,<br>- `XOR-2-1-1024k`.<br><br>For their meaning, see [*HDFS Erasure Coding*](https://hadoop.apache.org/docs/current/hadoop-project-dist/hadoop-hdfs/HDFSErasureCoding.html).|

In `[genericOptions]`, the most common HDFS behaviors we would like to alter are:

- The HDFS file block size, for a new file, set with `-Ddfs.blocksize=<n>` (default: 128m),, where `<n>` is the value of the block size. You can use the following suffix (case insensitive): `k(kilo)`, `m(mega)`, `g(giga)`, `t(tera)`, `p(peta)`, `e(exa)` to specify the size (such as 128k, 512m, 1g, etc.), Or provide complete size in bytes (such as 134217728 for 128 MB).
- The number of replication per block at HDFS file creation time, set with `-Ddfs.replication=<n>` (default: 3), where `<n>` is this number. If this number is not specify, the default value, set in `hdfs-default.xml` (or `$HADOOP_CONF_DIR/hdfs-site.xml` if you use a custom configuration file) is used. 
- Map and reduce tasks Java heap and JVM options:

  - `-Dmapreduce.task.io.sort.mb=<n>` (default: 100), where `<n>` the cumulative size of the serialization and accounting buffers storing records emitted from a map task, in megabytes.
  - `-Dyarn.app.mapreduce.am.log.level=<log level>`, where `<log level>` is the logging level for the Map/Reduce ApplicationMaster. The allowed levels are: `OFF`, `FATAL`, `ERROR`, `WARN`, `INFO`, `DEBUG`, `TRACE` and `ALL`.
  - For map tasks:
    - `-Dmapreduce.job.maps=<n>` (default: 2), where `<n>` is the number of map tasks per job,
    - `-Dmapreduce.job.running.map.limit=<n>` (default: 0), where `<n>` is the maximum number of simultaneous map tasks per job. There is no limit if this value is 0 or negative,
    - `-Dmapreduce.map.memory.mb=<n>` (default: -1), where `<n>` is the amount memory for each map task,
    - `-Dmapreduce.map.java.opts=<JVM options>`, where `<JVM options>`, are JVM options (e.g. `-XX:+UseG1GC`),
    - `-Dmapreduce.map.log.level=<log level>`, where `<log level>` is the logging level for the map task. The allowed levels are: `OFF`, `FATAL`, `ERROR`, `WARN`, `INFO`, `DEBUG`, `TRACE` and `ALL`.
  - For reduce tasks: 
    - `-Dmapreduce.job.reduces=<n>` (default: 1), where `<n>` is the number of reducer tasks per job,
    - `-Dmapreduce.job.running.reduce.limit=<n>` (default: 0), where `<n>` is the maximum number of simultaneous reducer tasks per job. There is no limit if this value is 0 or negative,
    - `-Dmapreduce.reduce.memory.mb=<n>` (default: -1),, where `<n>` is the amount memory for each reduce task,
    - `-Dmapreduce.reduce.java.opts=<JVM options>`, where `<JVM options>`, are JVM options (e.g. `-XX:+UseG1GC`),
    - `-Dmapreduce.reduce.log.level=<log level>`, where `<log level>` is the logging level for the reduce task. The allowed levels are: `OFF`, `FATAL`, `ERROR`, `WARN`, `INFO`, `DEBUG`, `TRACE` and `ALL`.

**Note**: For TestDFSIO, you should set the amount of memory for map and reduces tasks at least to 1024 and JVM garbage collector to [*G1 Garbage Collector*](https://www.oracle.com/technetwork/tutorials/tutorials-1876574.html) with `-XX:+UseG1GC`.

## Automatize Tests

To automatize tests, we provide [*testdfsio.sh*](script/testdfsio.sh), a BASH script.The script accept only one argument: a properties file. Available properties are:

|Key|Default value|Description|
|---:|:---|:---|
|`test.build.data`||HDFS directory where TestDFSIO performs operations. User's script must have read and write permission to create this directory.|
|`resultDir`||Local directory where TestDFSIO will store results.|
|`operation`||A list of operations to perform. Available operations are:<br><br>- `write`,<br> - `read`,<br> - `resize` (i.e. `append` and `truncate`),<br> - `random`,<br> - `backward`,<br> - `skip`,<br> - `shortcircuit`.<br><br>Except `resize`, others operations have the meaning given in the previous section. `resize` is a shortcut for two sequential TestDFSIO tests: `append` and `truncate`, in this order. Operation order matter. For example:<br><br>- with `operation=write read skip`, the test sequence is `write` then `read` and `skip`.<br> - with `operation=write skip read`, the test sequence is `write` then `skip` and `read`.|
|`nrFiles`||A list of number of file.|
|`size`||A list of file size.|
|`bufferSize`|`4096`|A list of buffer size.|
|`dfs.blocksize`|`256m`|A list of block size.|
|`dfs.replication`|`3`|A list of number of replication per block.|
|`compression`|`nil`|A list of compression codec|
|`storagePolicy`|`nil`|A list of storage policy.|
|`erasureCodePolicy`|`nil`|A list of erasure code policy.|
|`nrOcc.write`||Number of `write` operation for each combination for each item in:<br><br>- `nrFiles`,<br> - `size`,<br> - `bufferSize`,<br> - `dfs.blocksize`,<br> - `dfs.replication`,<br> - `compression`,<br> - `storagePolicy`,<br> - `erasureCodePolicy`.|
|`nrOcc.resize`||Number of `resize` operation for each combination involve in `write` operation to which is added each item of `resize.size`.|
|`resize.size`||For `resize` operation: list of size to append and to truncate|
|`nrOcc.read`||Number of `read`, or `random`, or `backward`, or `skip`, or `shortcircuit` operation for each combination involve in `write` operation.|
|`skipSize`||For `skip` operation: list of size to skip. Each item of this list is added each combination involve in `read` operation.|
|`java.home`||Local Java home directory.|
|`java.opts`||Local Java options.|
|`jarFile`||Local JAR file name of TestDFSIO.|
|`hadoop.home`||Local Hadoop home directory.|
|`hadoop.conf.dir`||Local Hadoop configuration directory.|
|`yarn.app.mapreduce.am.log.level`|`INFO`|See previous section.|
|`mapreduce.job.maps`|`2`|See previous section.|
|`mapreduce.job.running.map.limit`|`0`|See previous section.|
|`mapreduce.map.memory.mb`|`1024`|See previous section.|
|`mapreduce.map.java.opts`|`-XX:+UseG1GC`|See previous section.|
|`mapreduce.map.log.level`|`INFO`|See previous section.|
|`mapreduce.job.reduces`|`1`|See previous section.|
|`mapreduce.job.running.reduce.limit`|`0`|See previous section.|
|`mapreduce.reduce.memory.mb`|`1024`|See previous section.|
|`mapreduce.reduce.java.opts`|`-XX:+UseG1GC`|See previous section.|
|`mapreduce.reduce.log.level`|`INFO`|See previous section.|

### Properties example

We provide a properties file example with [*script/testdfsio.properties*](script/testdfsio.properties):

```
test.build.data=/tmp/TestDFSIO
resultDir=/tmp/TestDFSIO
operation=write resize read random backward skip shortcircuit
nrOcc.write=50
nrOcc.resize=50
resize.size=100MB 200MB
nrOcc.read=50
nrFiles=10 20 40 80 160
size=1GB 2GB
skipSize=10MB 20MB
bufferSize=4096 8192 16384 32768
dfs.blocksize=64m 128m 512m 1g
dfs.replication=1 2 3 4 5 6
compression=nil org.apache.hadoop.io.compress.SnappyCodec org.apache.hadoop.io.compress.Lz4Codec
storagePolicy=nil LAZY_PERSIST
java.home=/opt/jdk1.8.0_231
jarFile=script/TestDFSIO-0.0.1.jar
mapreduce.job.running.map.limit=16
```

With all combination of each item of `resize.size`, `nrFiles`, `size`, `skipSize`, `bufferSize`, `dfs.blocksize`, `dfs.replication`, `compression`, `storagePolicy` and the number of execution for each operation, we have:

```
Number of "write" test: 288000
Number of "resize" test: 1152000
Number of "read" test: 288000
Number of "random" test: 288000
Number of "backward" test: 288000
Number of "skip" test: 576000
Number of "shortcircuit" test: 96000
```

The sum of number of test is 2976000.