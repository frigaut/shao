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

```ad-note
v0.3.6 (on old main branch)
sh6.par: 3223.4 it/s, tur=14.2μs, wfs=279.2μs, shm=14.6μs (3246.6)
sh8.par: 2061.6 it/s, tur=15.4μs, wfs=450.8μs, shm=16.6μs (2071.2)
test.par: 1022.7 it/s, tur=20.0μs, wfs=937.2μs, shm=18.3μs (1025.0)
sh16.par: 778.8 it/s, tur=21.8μs, wfs=1240.1μs, shm=19.9μs (780.1)
sh32.par: 183.8 it/s, tur=73.8μs, wfs=5314.0μs, shm=50.4μs (183.9)
sh40.par: 145.4 it/s, tur=63.2μs, wfs=5330.7μs, shm=1479.1μs (145.5)
sh64.par: 20.9 it/s, tur=255.9μs, wfs=24888.3μs, shm=22613.3μs (20.9)
```
^^ Performance regression for large systems, probably due to structure
pointers to explicit arrays. Creating branch fix_perf_regression_of_0.3.6

```ad-note
0.3.5 + fix shm etc
sh6.par: 3275.6 it/s, tur=13.7μs, wfs=268.6μs, shm=20.7μs (3300.8)
sh8.par: 2231.5 it/s, tur=14.8μs, wfs=415.1μs, shm=16.1μs (2242.4)
test.par: 1115.3 it/s, tur=19.8μs, wfs=854.7μs, shm=20.1μs (1117.9)
sh16.par: 848.6 it/s, tur=19.3μs, wfs=1135.3μs, shm=21.7μs (850.1)
sh32.par: 198.9 it/s, tur=81.6μs, wfs=4900.7μs, shm=43.9μs (199.0)
sh40.par: 199.8 it/s, tur=70.5μs, wfs=4888.3μs, shm=43.4μs (199.9)
sh64.par: 34.5 it/s, tur=245.1μs, wfs=23623.9μs, shm=5129.2μs (34.5)
```
OK we're more or less back to max performance. Now let's fold back some
of the structure changes - if not the save/restore is screwed.

```ad-note
v0.3.7 "fixed shm and save+restore bugs - maintained performance"
sh6.par: 3336.8 it/s, tur=13.9μs, wfs=259.0μs, shm=24.6μs (3361.3)
sh8.par: 2177.1 it/s, tur=16.6μs, wfs=424.9μs, shm=15.5μs (2187.9)
test.par: 1082.3 it/s, tur=20.9μs, wfs=881.8μs, shm=19.1μs (1084.8)
sh16.par: 825.8 it/s, tur=20.7μs, wfs=1168.3μs, shm=19.9μs (827.3)
sh32.par: 199.2 it/s, tur=75.3μs, wfs=4901.3μs, shm=41.9μs (199.3)
sh40.par: 201.0 it/s, tur=63.5μs, wfs=4859.8μs, shm=49.7μs (201.1)
sh64.par: 33.8 it/s, tur=244.9μs, wfs=23541.2μs, shm=5824.7μs (33.8)
```
OK, decently fast.

```ad-note
v0.3.8 (make use of yeti's mvmult)
sh6.par: 3371.2 it/s, tur=14.6μs, wfs=261.5μs, shm=18.4μs (3396.9)
sh8.par: 2241.2 it/s, tur=16.0μs, wfs=412.6μs, shm=15.5μs (2252.0)
test.par: 1091.1 it/s, tur=21.8μs, wfs=875.0μs, shm=17.5μs (1093.7)
sh16.par: 826.5 it/s, tur=20.3μs, wfs=1166.6μs, shm=20.8μs (828.0)
sh32.par: 201.5 it/s, tur=58.6μs, wfs=4862.3μs, shm=39.1μs (201.6)
sh40.par: 199.8 it/s, tur=63.5μs, wfs=4894.5μs, shm=44.4μs (199.9)
sh64.par: 42.0 it/s, tur=272.2μs, wfs=23401.6μs, shm=151.1μs (42.0)
```
Significant difference on the large system in which time(mmul) is
larger than time(wfsing).
