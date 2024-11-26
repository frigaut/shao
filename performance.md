# SHAO Performance

## Script

```C
aoread,"examples/sh6.par"; aocalib,wfs,dm; aoloop,wfs,dm,0.5,2000,0.8,0.3,disp=0;
aoread,"examples/sh8.par"; aocalib,wfs,dm; aoloop,wfs,dm,0.5,2000,0.8,0.3,disp=0;
aoread,"examples/sh16.par"; aocalib,wfs,dm; aoloop,wfs,dm,0.5,2000,0.8,0.3,disp=0;
aoread,"examples/test.par"; aocalib,wfs,dm; aoloop,wfs,dm,0.5,2000,0.8,0.3,disp=0;
aoread,"examples/sh32.par"; aocalib,wfs,dm; aoloop,wfs,dm,0.5,2000,0.8,0.3,disp=0;
aoread,"examples/sh40.par"; aocalib,wfs,dm; aoloop,wfs,dm,0.5,2000,0.8,0.3,disp=0;
aoread,"examples/sh64.par"; aocalib,wfs,dm; aoloop,wfs,dm,0.5,2000,0.8,0.3,disp=0;
```
Also in `perf.i`.

## Results

```ad-note
v0.2.2
sh6.par: 2649.1 it/s, tur=18.1μs, wfs=246.4μs, mmul=109.6μs, shm=0.6μs (2672.7)
sh8.par: 1710.1 it/s, tur=29.7μs, wfs=412.4μs, mmul=139.3μs, shm=0.6μs (1720.0)
test.par: 839.0 it/s, tur=61.3μs, wfs=890.0μs, mmul=237.1μs, shm=0.6μs (841.5)
sh16.par: 649.7 it/s, tur=68.7μs, wfs=1161.9μs, mmul=305.3μs, shm=0.6μs (651.1)
sh32.par: 142.5 it/s, tur=271.8μs, wfs=5060.3μs, mmul=1680.3μs, shm=0.7μs (142.6)
sh40.par: 121.4 it/s, tur=254.7μs, wfs=5007.6μs, mmul=2968.9μs, shm=0.7μs (121.5)
sh64.par: 20.0 it/s, tur=1070.0μs, wfs=22580.7μs, mmul=26267.9μs, shm=0.8μs (20.0)
```

```ad-note
v0.3
sh6.par: 2505.9 it/s, tur=18.2μs, wfs=267.1μs, mmul=110.4μs, shm=0.7μs (2527.7)
sh8.par: 1648.6 it/s, tur=30.1μs, wfs=434.8μs, mmul=138.1μs, shm=0.6μs (1658.4)
test.par: 851.3 it/s, tur=62.2μs, wfs=891.9μs, mmul=217.1μs, shm=0.6μs (853.8)
sh16.par: 652.9 it/s, tur=69.4μs, wfs=1202.5μs, mmul=256.2μs, shm=0.6μs (654.4)
sh32.par: 159.6 it/s, tur=274.5μs, wfs=5119.2μs, mmul=867.1μs, shm=0.7μs (159.7)
sh40.par: 156.2 it/s, tur=286.5μs, wfs=5124.6μs, mmul=987.5μs, shm=0.8μs (156.3)
sh64.par: 34.2 it/s, tur=1200.2μs, wfs=24467.7μs, mmul=3597.6μs, shm=0.9μs (34.2)
```

```ad-note
v0.3.1
sh6.par: 3458.1 it/s, tur=18.5μs, wfs=266.5μs, mmul=0.7μs, shm=0.6μs (3499.6)
sh8.par: 2170.1 it/s, tur=30.2μs, wfs=426.6μs, mmul=0.7μs, shm=0.6μs (2185.8)
test.par: 1042.2 it/s, tur=61.9μs, wfs=893.6μs, mmul=0.6μs, shm=0.6μs (1045.9)
sh16.par: 793.9 it/s, tur=71.3μs, wfs=1184.3μs, mmul=0.7μs, shm=0.6μs (796.1)
sh32.par: 187.3 it/s, tur=296.5μs, wfs=5039.1μs, mmul=0.7μs, shm=0.6μs (187.4)
sh40.par: 185.9 it/s, tur=271.6μs, wfs=5102.9μs, mmul=0.7μs, shm=0.6μs (186.0)
sh64.par: 35.7 it/s, tur=1156.4μs, wfs=26816.6μs, mmul=1.1μs, shm=0.7μs (35.7)
```

```ad-note
v0.3.5
sh6.par: 3254.6 it/s, tur=14.9μs, wfs=263.7μs, shm=26.4μs (3278.9)
sh8.par: 2142.3 it/s, tur=16.5μs, wfs=430.4μs, shm=17.6μs (2152.7)
test.par: 1100.6 it/s, tur=20.8μs, wfs=865.1μs, shm=20.6μs (1103.2)
sh16.par: 816.2 it/s, tur=22.4μs, wfs=1175.6μs, shm=25.1μs (817.6)
sh32.par: 191.5 it/s, tur=70.1μs, wfs=5106.1μs, shm=43.5μs (191.6)
sh40.par: 194.1 it/s, tur=69.2μs, wfs=5034.2μs, shm=44.9μs (194.2)
sh64.par: 36.0 it/s, tur=256.8μs, wfs=24381.9μs, shm=3132.3μs (36.0)
```
