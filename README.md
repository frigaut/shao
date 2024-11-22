# SHAO

Shack-Hartmann AO simulation package. Using yorick, but not directly based on yao, although I am obviously drawing experience from the development of yao. I started *shao* to implement two new concepts I originally wanted to test (a) A Fresnel-based SH implementation and (b) a spline2 DM implementation. To date, the success of these new methods pushed me to work on performance. After a shared memory implementation, I get anywhere from 3458 it/s (6x6) to 794 it/s (16x16 on 128x128 arrays) to 186 it/s (40x40 on 256x256 arrays), which is roughly 2-3 times *faster* than yao.

## Description and features

SHAO is not supposed to grow to the size of yao, with all the features etc. Instead, it is meant to stay compact and concise. Initially, I started developing shao as a prototype of a rust version. Right now (v0.3.3), I am still working on the yorick version as I got disappointed by the complexity and lack of performance of the rust tests I did (although I might go back to it later).

SHAO only offers Shack-Hartmann WFS, and classical continuous phasesheet DMs with actuators on a cartesian grid. The SH Fresnel implementation offers realistic propagation, with interference between subapertures, and fully flexible micro-lens array focal length. One of the interesting side effect and advantage is that execution time is for WFSing is really driven by the array size (i.e. SH detector size) and not the number of subapertures. The full loop time does depend on the number of subapertures and actuator of course - just for matrix multiplies - but this is still an interesting approach for large systems. For instance (v0.3.3) a 12x12 system on a 120x120 array runs at 1042 it/s, and a 40x40 on a 240x240 arrays at 186 it/s.

## Future plans

- work on speed, upgrade to FFTW (yao's implementation in yao_fast)
- Use threaded FFTW
- Proper normalisation/calibration of focal length in fresnel SH
- Try out and test a rust implementation
