# Benchmark GPUDirectStorage
cpu: AMD EPYC 7742 64-Core Processor x 2
gpu: A100 x 8

| flag                     | values             | comment                                                                  |
| ------------------------ | ------------------ | ---------                                                                |
| mode `-r` `-w`           | read, write        |                                                                          |
| buffer size `-b`         | 1M, 4M, 16M, 32M   |                                                                          |
| number of workers `-t`   | 8, 16, 32          |                                                                          |
| random offset `-rand`    | on, off            |                                                                          |
| `--gdsbufreg`            | switch             | no changes                                                               |
| `--cufile`               | switch             | affects throughputs 3.4GB/s -> 6GB/s                                     |
| `--direct`               | switch             | first time very slow, 1GB/s, but consequent tries much faster , 12GB/sec |

## Write a test file

```
# write to 4-way raid0 nvme
./elbencho -w -b 1m --direct --size 1g /raid/data/yren/test_file
# write to ddn lustre
./elbencho -w -b 1m --direct --size 1g /lustre/cheetah/data/yren/test_file
```


## Test read from lustre
```
./elbencho -r -b 1M -t 32 --gpuids 0,1  --gdsbufreg  --direct  --cufile  --lat --lathisto --allelapsed --latpercent ~/cheetah/test_file
```

## Test read from nvme 4-way raid0 with cufile
```
./elbencho -r -b 1m -t 32 --gpuids 0,1  --gdsbufreg  --direct  --cufile  --lat --lathisto --allelapsed --latpercent /raid/data/yren/test_file
```

## Test read from nvme 4-way raid0 without cufile
```
./elbencho -r -b 1m -t 32 --gpuids 0,1  --direct  --lat --lathisto --allelapsed --latpercent /raid/data/yren/test_file
```

##
```
./elbencho -r -b 1M -t 8 --gpuids 0,1 --cufile --gdsbufreg --direct         ~/cheetah/test_file
```


##  Block device & large shared file testing

```
(base) yren@athena:~/git/elbencho/bin$ ./elbencho --help-bdev
Block device & large shared file testing.

Usage: ./elbencho [OPTIONS] PATH [MORE_PATHS]

Basic Options:
  -w [ --write ]        Write to given block device(s) or file(s).
  -r [ --read ]         Read from given block device(s) or file(s).
  -s [ --size ] arg     Block device or file size to use. (Default: 0)
  -b [ --block ] arg    Number of bytes to read/write in a single operation. (Default:
                        1M)
  -t [ --threads ] arg  Number of I/O worker threads. (Default: 1)

Frequently Used Options:
  --direct              Use direct IO to avoid buffering/caching.
  --iodepth arg         Depth of I/O queue per thread for asynchronous read/write.
                        Setting this to 2 or higher turns on async I/O. (Default: 1)
  --rand                Read/write at random offsets.
  --randamount arg      Number of bytes to write/read when using random offsets.
                        (Default: Set to aggregate file size)
  --randalign           Align random offsets to block size.
  --lat                 Show minimum, average and maximum latency for read/write
                        operations.

Miscellaneous Options:
  --zones arg           Comma-separated list of NUMA zones to bind this process to. If
                        multiple zones are given, then worker threads are bound
                        round-robin to the zones. (Hint: See 'lscpu' for available NUMA
                        zones.)
  --latpercent          Show latency percentiles.
  --lathisto            Show latency histogram.
  --allelapsed          Show elapsed time to completion of each I/O worker thread.

Examples:
  Test 4KiB block random read latency of device /dev/nvme0n1:
    $ elbencho -r -b 4K --lat --direct --rand /dev/nvme0n1

  Test 4KiB multi-threaded write IOPS of devices /dev/nvme0n1 & /dev/nvme1n1:
    $ elbencho -w -b 4K -t 16 --iodepth 16 --direct --rand \
        /dev/nvme0n1 /dev/nvme1n1

  Test 1MiB multi-threaded sequential read throughput of device /dev/nvme0n1:
    $ elbencho -r -b 1M -t 8 --iodepth 4 --direct /dev/nvme0n1

  Create large file and test random read IOPS for max 20 seconds:
    $ elbencho -w -b 4M --direct --size 20g /mnt/myfs/file1
    $ elbencho -r -b 4k -t 16 --iodepth 16 --direct --rand --timelimit 20 \
        /mnt/myfs/file1

  Stream data from large file into memory of first 2 GPUs via CUDA:
    $ elbencho -r -b 1M -t 8 --gpuids 0,1 --cuhostbufreg \
        /mnt/myfs/file1

  Stream data from large file into memory of first 2 GPUs via GPUDirect Storage:
    $ elbencho -r -b 1M -t 8 --gpuids 0,1 --cufile --gdsbufreg --direct \
        /mnt/myfs/file1
```
