## T22 (SUT) Calibration Data

**$ cat /proc/cmdline**
```
BOOT_IMAGE=/vmlinuz-4.15.0-23-generic root=UUID=10184ffc-8723-4c9f-b547-bcbc367bf8f1 ro isolcpus=1-27,29-55,57-83,85-111 nohz_full=1-27,29-55,57-83,85-111 rcu_nocbs=1-27,29-55,57-83,85-111 numa_balancing=disable intel_pstate=disable intel_iommu=on iommu=pt nmi_watchdog=0 audit=0 nosoftlockup processor.max_cstate=1 intel_idle.max_cstate=1 hpet=disable tsc=reliable mce=off console=tty0 console=ttyS0,115200n8
```

**$ uname -a**
```
Linux s5-t22-sut1 4.15.0-23-generic #25-Ubuntu SMP Wed May 23 18:02:16 UTC 2018 x86_64 x86_64 x86_64 GNU/Linux
```

**$ sudo taskset -c 3 /home/testuser/pma_tools/jitter/jitter -i 30**
```
Linux Jitter testing program version 1.8
Iterations=30
The pragram will execute a dummy function 80000 times
Display is updated every 20000 displayUpdate intervals
Timings are in CPU Core cycles
Inst_Min:    Minimum Excution time during the display update interval(default is ~1 second)
Inst_Max:    Maximum Excution time during the display update interval(default is ~1 second)
Inst_jitter: Jitter in the Excution time during rhe display update interval. This is the value of interest
last_Exec:   The Excution time of last iteration just before the display update
Abs_Min:     Absolute Minimum Excution time since the program started or statistics were reset
Abs_Max:     Absolute Maximum Excution time since the program started or statistics were reset
tmp:         Cumulative value calcualted by the dummy function
Interval:    Time interval between the display updates in Core Cycles
Sample No:   Sample number

   Inst_Min   Inst_Max   Inst_jitter last_Exec  Abs_min    Abs_max      tmp       Interval     Sample No
    160022     167604       7582     160024     160022     167604    3407806464 3203844494          1
    160022     167602       7580     160024     160022     167604     771686400 3203833904          2
    160022     166516       6494     160024     160022     167604    2430533632 3203849416          3
    160022     171496      11474     160026     160022     171496    4089380864 3204039176          4
    160022     168570       8548     160024     160022     171496    1453260800 3203856832          5
    160022     166428       6406     160026     160022     171496    3112108032 3203837584          6
    160022     166256       6234     160024     160022     171496     475987968 3203819802          7
    160022     166530       6508     160030     160022     171496    2134835200 3203837160          8
    160022     166142       6120     160024     160022     171496    3793682432 3203820096          9
    160022     166514       6492     164362     160022     171496    1157562368 3203827416         10
    160022     166050       6028     160028     160022     171496    2816409600 3203817976         11
    160022     169874       9852     160026     160022     171496     180289536 3204035456         12
    160022     165928       5906     160024     160022     171496    1839136768 3203831980         13
    160022     167020       6998     160032     160022     171496    3497984000 3203837756         14
    160022     165902       5880     160026     160022     171496     861863936 3203833442         15
    160022     167026       7004     160024     160022     171496    2520711168 3203853768         16
    160022     166872       6850     160024     160022     171496    4179558400 3203837030         17
    160022     167306       7284     160024     160022     171496    1543438336 3203836572         18
    160022     166632       6610     160026     160022     171496    3202285568 3203833210         19
    160022     170836      10814     160028     160022     171496     566165504 3204061726         20
    160022     166172       6150     160024     160022     171496    2225012736 3203836012         21
    160022     166994       6972     160024     160022     171496    3883859968 3203836684         22
    160022     165954       5932     160024     160022     171496    1247739904 3203836942         23
    160022     167906       7884     160026     160022     171496    2906587136 3203853232         24
    160022     166144       6122     160026     160022     171496     270467072 3203833164         25
    160022     166526       6504     160024     160022     171496    1929314304 3203849058         26
    160022     166358       6336     160030     160022     171496    3588161536 3203833452         27
    160022     170362      10340     160024     160022     171496     952041472 3204016582         28
    160022     167682       7660     160026     160022     171496    2610888704 3203855008         29
    160022     167346       7324     160024     160022     171496    4269735936 3203854998         30
```

**$ sudo /home/testuser/mlc --bandwidth_matrix**
```
Intel(R) Memory Latency Checker - v3.5
Command line parameters: --bandwidth_matrix

Using buffer size of 100.000MB/thread for reads and an additional 100.000MB/thread for writes
Measuring Memory Bandwidths between nodes within system
Bandwidths are in MB/sec (1 MB/sec = 1,000,000 Bytes/sec)
Using all the threads from each core if Hyper-threading is enabled
Using Read-only traffic type
                Numa node
Numa node            0       1
       0        108059.8  50967.8
       1        50838.9   108289.3
```

**$ sudo /home/testuser/mlc --peak_injection_bandwidth**
```
Intel(R) Memory Latency Checker - v3.5
Command line parameters: --peak_injection_bandwidth

Using buffer size of 100.000MB/thread for reads and an additional 100.000MB/thread for writes

Measuring Peak Injection Memory Bandwidths for the system
Bandwidths are in MB/sec (1 MB/sec = 1,000,000 Bytes/sec)
Using all the threads from each core if Hyper-threading is enabled
Using traffic with the following read-write ratios
ALL Reads        :      215639.4
3:1 Reads-Writes :      182678.9
2:1 Reads-Writes :      178667.1
1:1 Reads-Writes :      149532.2
Stream-triad like:      159545.8
```

**$ sudo /home/testuser/mlc --max_bandwidth**
```
Intel(R) Memory Latency Checker - v3.5
Command line parameters: --max_bandwidth

Using buffer size of 100.000MB/thread for reads and an additional 100.000MB/thread for writes

Measuring Maximum Memory Bandwidths for the system
Will take several minutes to complete as multiple injection rates will be tried to get the best bandwidth
Bandwidths are in MB/sec (1 MB/sec = 1,000,000 Bytes/sec)
Using all the threads from each core if Hyper-threading is enabled
Using traffic with the following read-write ratios
ALL Reads        :      216876.52
3:1 Reads-Writes :      182622.49
2:1 Reads-Writes :      178793.35
1:1 Reads-Writes :      149849.03
Stream-triad like:      180049.37
```

**$ sudo /home/testuser/mlc --latency_matrix**
```
testuser@s5-t22-sut1:~$ sudo /home/testuser/mlc --latency_matrix
Intel(R) Memory Latency Checker - v3.5
Command line parameters: --latency_matrix

Using buffer size of 2000.000MB
Measuring idle latencies (in ns)...
                Numa node
Numa node            0       1
       0          81.3   131.1
       1         131.2    81.3
```

**$ sudo /home/testuser/mlc --idle_latency**
```
Intel(R) Memory Latency Checker - v3.5
Command line parameters: --idle_latency

Using buffer size of 2000.000MB
Each iteration took 201.2 core clocks ( 80.5    ns)
```

**$ sudo /home/testuser/mlc --loaded_latency**
```
Intel(R) Memory Latency Checker - v3.5
Command line parameters: --loaded_latency

Using buffer size of 100.000MB/thread for reads and an additional 100.000MB/thread for writes

Measuring Loaded Latencies for the system
Using all the threads from each core if Hyper-threading is enabled
Using Read-only traffic type
Inject  Latency Bandwidth
Delay   (ns)    MB/sec
==========================
 00000  281.66   215759.3
 00002  279.33   215871.8
 00008  279.46   215904.0
 00015  280.29   216366.2
 00050  275.01   216661.5
 00100  227.31   215020.3
 00200  121.90   160264.1
 00300  101.34   111603.7
 00400   95.47    85020.3
 00500   93.99    68719.5
 00700   92.13    49744.8
 01000   90.90    35269.2
 01300   90.17    27395.2
 01700   89.61    21177.2
 02500   90.64    14668.1
 03500   89.03    10714.6
 05000   82.08     7786.6
 09000   81.40     4684.0
 20000   80.95     2546.1
```

**$ sudo /home/testuser/mlc --c2c_latency**
```
Intel(R) Memory Latency Checker - v3.5
Command line parameters: --c2c_latency

Measuring cache-to-cache transfer latency (in ns)...
Local Socket L2->L2 HIT  latency        53.7
Local Socket L2->L2 HITM latency        53.8
Remote Socket L2->L2 HITM latency (data address homed in writer socket)
                        Reader Numa Node
Writer Numa Node     0       1
            0        -   113.9
            1    113.9       -
Remote Socket L2->L2 HITM latency (data address homed in reader socket)
                        Reader Numa Node
Writer Numa Node     0       1
            0        -   175.7
            1    176.0       -
```
