/********************* DEPENDENCIES **********************/
require, "yao_util.i"; // for zernike
require, "img.i";
require, "yao.i";
require, "svipc.i";
require, "plvp.i";

/******************* SHARED MEMORY INITS *****************/
// Done when needed, e.g. aoloop()

zoom = 64;
/************************* INTRO  ************************/
write, format = "%s\n", "2024 AO simulation demo";
write, format = "%s\n", "New WFS model (with MLA, global)";
write, format = "%s\n", "New DM (spline)";
write, format = "%s\n", "Adjust flength (prop to focal length) in parfile, then";
write, format = "%s\n", "> aoread,\"examples/test.par\"";
write, format = "%s\n", "> aocalib,wfs,dm";
write, format = "%s\n", "> aoloop,wfs,dm,0.5,1000,0.5,0.1,disp=1;";
write, format = "%s\n\n", "or\n> shaorestore,\"test\"; aoloop,wfs,dm,0.5,1000,0.5,0.1,disp=1;";

/********************** STRUCTURES ***********************/
include, "structures.i", 1;

/********************** FUNCTIONS ************************/
func aoall(parfile, nit =, disp =, verb =) {
  // integrated routine, read parfile, does calib and loop.
  aoread, parfile;
  animate, 1;
  aocalib, wfs, dm;
  aoloop, wfs, dm, 0.5, (nit ? nit : 100), 0.9, 0., disp = (disp ? disp : 0),
                                                    verb = (verb ? verb : 0);
  animate, 0;
}

func aoread(parfile) {
  // read parfile and prep some variable.
  extern wfs, dm, sim, pup, debug;
  include, parfile, 1;
  write, format = "\nReading \"%s\"\n", parfile;
  // fill default values
  sim.parname = pathsplit(parfile, delim = "/")(0);
  pup = float(dist(sim.dim, xc = sim.dim / 2 + 0.5, yc = sim.dim / 2 + 0.5) < (sim.pupd / 2));

  wfs.lambda = (wfs.lambda ? wfs.lambda : 0.5e-6);
  wfs.ppsub = (wfs.ppsub ? wfs.ppsub : sim.dim / wfs.nxsub); // # pixel/sub in pupil plane
  wfs.threshresp = (wfs.threshresp ? wfs.threshresp : 0.25);

  dm.upsamp = (dm.upsamp ? dm.upsamp : wfs.ppsub);
  dm.nxact = (dm.nxact ? dm.nxact : wfs.nxsub + 1);
  dm.push4imat = (dm.push4imat ? dm.push4imat : 1.);
  dm.coupling = (dm.coupling ? dm.coupling : 1.4);

  debug = (debug ? debug : 0);
  prepzernike, sim.dim, sim.pupd + 1;
}

func shaosave(fname) {
  /* DOCUMENT
  Saves all session variables in file (extension ".shao").
  */
  if (fname == []) fname = strip_file_extension(sim.parname);
  if (!strmatch(fname, ".shao")) fname += ".shao";
  save, createb(fname);
}

func shaorestore(fname) {
  /* DOCUMENT
  Restore all session variables from file (extension ".shao").
  */
  if (fname == []) error, "shaorestore,filename";
  if (!strmatch(fname, ".shao")) fname += ".shao";
  restore, openb(fname);
}

/************************ FRESNEL ************************/
func prep_fresnel(foc, d, lambda) {
  // prep Fresnel propagation kernel
  extern pkern;
  pkern = roll(exp(1i * (2 * pi / lambda) * d) * exp(-1i * pi * lambda * d * foc));
}

func fresnel(obj) {
  // Actual Fresnel propagation
  tdim = dimsof(obj)(2);
  tmp = fft(obj, 1);
  tmp *= pkern;
  res = fft(tmp, -1) / tdim ^ 2.;
  return res;
}

/************************** WFS  *************************/
func prep_wfs(wfs) {
  // prep the wfs, precompute some generic arrays
  one = dist(wfs.ppsub, xc = wfs.ppsub / 2 + 0.5, yc = wfs.ppsub / 2 + 0.5) ^
        2. / ((wfs.ppsub) ^ 2.) * (2000. / wfs.flength);
  // replicate
  mla = pup * 0;
  for (i = 1; i <= wfs.nxsub; i++) {
    for (j = 1; j <= wfs.nxsub; j++) {
      mla(1 + (i - 1) * wfs.ppsub : i * wfs.ppsub, 1 + (j - 1) * wfs.ppsub : j * wfs.ppsub) = one;
    }
  }
  wfs.mla = &(roll(mla, [ 1, 1 ] * (sim.dim - sim.pupd) / 2));
  wfs.emla = &(exp(-1i * (*wfs.mla) * 0.35));
  // valid subaps:
  rad = wfs.nxsub / 2. + wfs.margin;
  wfs.valid2 = &(dist(wfs.nxsub, xc = wfs.nxsub / 2 + 0.5, yc = wfs.nxsub / 2 + 0.5) < rad);
  wfs.nsub = long(sum(*wfs.valid2));
  wfs.xyc = &(indices(wfs.ppsub) - (wfs.ppsub / 2. + 0.5));
  wfs.foc = &((1. / wfs.lambda) * (dist(sim.dim) / (sim.dim / (wfs.ppsub / 32.))) ^ 2.);
  status = prep_fresnel(*wfs.foc, wfs._fl, wfs.lambda);
  return wfs;
}

func cgwfs(im) {
  // Computes the cendroid of image sim
  sumim = sum(im);
  if (sumim <= 0.) return [ 0., 0. ];
  gx = sum(im * (*wfs.xyc)(, , 1)) / sumim;
  gy = sum(im * (*wfs.xyc)(, , 2)) / sumim;
  return [ gx, gy ];
}

func wfsim(wfs, pup, pha) {
  // Compute WFS image given WFS, pup and phase.
  obj = pup * (*wfs.emla) * exp(-1i * pha);
  im = fresnel(obj);
  wfs.im = &(im.re * im.re + im.im * im.im);
  return *wfs.im;
}

func shwfs(wfs, pup, pha) {
  // returns wfs signal given WFS, pup and phase.
  wfssig = array(0., [ 2, wfs.nsub, 2 ]);
  im = wfsim(wfs, pup, pha);
  k = 0;
  for (i = 1; i <= wfs.nxsub; i++) {
    for (j = 1; j <= wfs.nxsub; j++) {
      if ((*wfs.valid2)(i, j)) {
        imlet =
            im(1 + (i - 1) * wfs.ppsub : i * wfs.ppsub, 1 + (j - 1) * wfs.ppsub : j * wfs.ppsub);
        wfssig(++k, ) = cgwfs(imlet);
      }
    }
  }
  wfs.signal = &wfssig;
  return wfssig(*);
}

/************************** DM ***************************/
func prep_dm(dm) {
  // Prepare the dm
  rad = dm.nxact / 2 + 1 + dm.margin;
  dm.valid2 = &(dist(dm.nxact, xc = dm.nxact / 2. + 0.5, yc = dm.nxact / 2. + 0.5) < rad);
  dm.ashape = &(dist(dm.nxact) * 0);
  dm.wval = &(where(*dm.valid2));
  dm.nact = numberof(*dm.wval);
  dm.ker = &(makegaussian(3, dm.coupling));
  dm.xyups = &(span(1., dm.nxact, (dm.nxact - 1) * dm.upsamp));
  return dm;
}

func dm_shape(dm) {
  /* DOCUMENT
  Compute the dm shape
  */
  (*dm.ashape)(*dm.wval) = *dm.com;
  dms = convol2d(*dm.ashape, *dm.ker);
  dm.shape = &(spline2(dms, *dm.xyups, *dm.xyups, grid = 1));
  return dm;
}

/******************* CALIB AND AO LOOP *******************/
func wfscalib(wfs) {
  /* DOCUMENT
  Find the best WFS MLA focal length
  */
  write, format = "%s", "Finding best focal length";
  de = wfs.flength;
  step = wfs.flength / 20.;
  maxmax = 0.;
  while (1) {
    de += step;
    wfs._fl = de;
    prep_wfs, wfs;
    im = wfsim(wfs, pup, pup * 0.);
    if (debug > 1) {
      tv, im;
      pause, 10;
    }
    tmax = max(im);
    if (tmax > maxmax) {
      maxmax = tmax;
      bde = de;
    }
    if (tmax < (maxmax * 0.8)) break;
  }
  wfs._fl = bde;
  write, format = " ➜ %.1f [Arbitrary Units]\n", wfs._fl;
  if (debug >= 10)
    write, format = "max(abs(grad(mla)))=%f\n", max(abs(*wfs.mla - roll(*wfs.mla, [ 0, 1 ])));
  prep_wfs, wfs;
  if (debug > 1) tv, wfsim(wfs, pup, pup * 0.);
}

func aocalib(wfs, dm) {
  /* DOCUMENT
  AO calibration, WFS, DM and IMAT
  */
  extern sim;
  write, format = "%s\n", "Calibrating AO system";
  if (wfs._fl == 0) {
    wfscalib, wfs;
    pause, 50;
  }
  prep_wfs, wfs;
  prep_dm, dm;
  // do imat:
  write, format = "%s", "Measuring iMat...";
  dm.com = &(array(0., dm.nact));
  imat = array(0., [ 2, wfs.nsub * 2, dm.nact ]);
  wfs.refmes = &(shwfs(wfs, pup, pup * 0));
  for (na = 1; na <= dm.nact; na++) {
    *dm.com *= 0.;
    (*dm.com)(na) = dm.push4imat;
    pha = *dm_shape(dm).shape;
    imat(, na) = shwfs(wfs, pup, pha) - (*wfs.refmes);
    if (debug > 5) {
      tv, *wfs.im;
      pause, 5;
    }
  }
  imat /= dm.push4imat;
  write, format = "%s\n", "Computing cMat";
  // find actuator with low response, to extrapolate:
  aresp = imat(rms, );                                  // actuator response
  ival = where(aresp >= (max(aresp) * wfs.threshresp)); // valid actuator idx based on response
  iext = where(aresp < (max(aresp) * wfs.threshresp));  // idx of actuators to extrapolate
  write, format = "%d actuators filtered out of %d; ", numberof(iext), dm.nact;
  imatval = imat(, ival); // imat for valid actuators
  ev = SVdec(imatval, u, vt);
  w = where((ev / max(ev)) > sim.cond);
  write, format = "%d eigenmodes filtered out of %d\n", numberof(ival) - numberof(w),
         numberof(ival);
  evi = ev * 0.;
  evi(w) = 1. / ev(w);
  evi = diag(evi);
  cmatval = (vt(+, ) * evi(, +))(, +) * u(, +); // cmat for valid actuators
  cmat = transpose(imat);
  cmat(ival, ) = cmatval;
  // sim.imat = &imat;
  sim.cmat = &cmat;
}

func calpsf(pup, pha) {
  /* DOCUMENT Computes PSF from pup and phase
  394 it/s (aoall,"examples/test.par",nit=100,disp=1)
  */
  bpup = bpha = array(0.0f, [ 2, 2 * sim.dim, 2 * sim.dim ]);
  bpup(1 : sim.dim, 1 : sim.dim) = float(pup);
  bpha(1 : sim.dim, 1 : sim.dim) = float(pha);
  return calc_psf_fast(bpup, bpha, scale = 1, noswap = 0);
}

func bilin(ar, x1, dim) {
  /* DOCUMENT Quick interpolation
   */
  i1 = long(floor(x1));
  i2 = i1 + dim - 1;
  rx1 = float(x1 - i1);
  ar1 = ar(i1 : i2, 1 : dim);
  ar2 = ar(i1 + 1 : i2 + 1, 1 : dim);
  return (1.0f - rx1) * ar1 + rx1 * ar2;
}

func aoloop(wfs, dm, gain, nit, sturb, noise, disp =, verb =, wait =) {
  /* DOCUMENT
  The loop
  */
  if (disp == []) disp = 0;
  my_shmid = 0x78080000 | getpid();
  shm_init, my_shmid, slots = 6;
  my_semid = 0x7dcb0000 | getpid();
  sem_init, my_semid, nums = 5;
  // sem 0: WFS signal ready from aoloop()
  // sem 1: DM command / dm shape ready from aommul()
  // sem 2: End of loop (nit reached)
  // sem 3: Turbulence/phase screen ready from aoscreens()
  leak = 0.99;
  ps = float(fits_read("~/.yorick/data/bigs1.fits") * sturb);
  dmshape = pup * 0.;
  dm.com = &(array(0., dm.nact));
  imav = calpsf(pup, 0);
  maxim = max(imav);
  strehlv = array(0.0f, nit);
  itv = array(0n, nit);
  k = off = 0;
  avgstrehl = 0.;
  winkill;
  pause, 200;
  // SHM DISPLAYS:
  if (fork() == 0) {
    // I am the child for display
    if (disp != 0) status = aodisp();
    if (debug) write, format = "%s\n", "Display fork quitting";
    quit;
  }
  // SHM MMUL
  if (fork() == 0) {
    // I am the child for matrix mutiply
    status = aommul();
    if (debug) write, format = "%s\n", "Matrix multiply fork quitting";
    quit;
  }
  // SHM phase screens
  if (fork() == 0) {
    // I am the child for matrix mutiply
    status = aoscreens();
    if (debug) write, format = "%s\n", "Phase screen fork quitting";
    quit;
  }
  // else main aoloop, WFS function
  t2 = t3 = t4 = t5 = 0.;
  tic;
  // else I am the parent process, main loop
  for (n = 1; n <= nit; n++) {
    tic, 2;
    sem_take, my_semid, 3; // wait for aoscreens() to be ready
    turb = shm_read(my_shmid, "turb");
    sem_give, my_semid, 4; // tell aoscreens() to proceed to next step
    pha = turb - dmshape;  // total phase after correction
    t2 += tac(2);
    tic, 3;
    sig = shwfs(wfs, pup, pha);
    if (noise) sig += random_n(wfs.nsub * 2) * noise; // WFS noise.
    t3 += tac(3);                                     // WFSing
    tic, 4;
    // read from aommul the previous dm update commands:
    sem_take, my_semid, 1; // wait for ready signal
    dmshape = shm_read(my_shmid, "dmshape");
    // write signal on shm for aommul to compute the next DM command update
    shm_write, my_shmid, "wfs_signal", &sig;
    sem_give, my_semid, 0;
    if (n == nit) {
      sem_give, my_semid, 2; // for aommul
      sem_give, my_semid, 2; // for aodisp, to exit while(1)
      if (wait) {
        status = hitReturn();
        sem_give, my_semid, 2; // for aodisp, now to exit
      }
    }
    if (disp) {
      data = float(*wfs.im);
      shm_write, my_shmid, "wfsim", &data;
      iteration = [n];
      shm_write, my_shmid, "iteration", &iteration, publish = 1;
    }
    t4 += tac(4);
  }
  extern nitps;
  nitps = nit / tac();
  if (verb) write, "";
  write, format = "%s: %.1f it/s, ", sim.parname, nitps;
  write, format = "tur=%.1fμs, wfs=%.1fμs, shm=%.1fμs (%.1f)\n", t2 * 1e6 / nit, t3 * 1e6 / nit,
         t4 * 1e6 / nit, nit / (t2 + t3 + t4);

  // give some time for child to quit (prompt)
  pause, 100;
  if (disp) {
    shm_free, my_shmid, "wfsim";
    shm_free, my_shmid, "iteration";
  }
  shm_free, my_shmid, "turb";
  shm_free, my_shmid, "dmshape";
  shm_free, my_shmid, "wfs_signal";
  shm_cleanup, my_shmid;
  sem_cleanup, my_semid;
}

func aoscreens(void) {
  /* DOCUMENT Computes the phase from turbulence for given iteration
  and direction.
  */
  for (n = 1; n <= nit; n++) {
    off += 0.1;
    if ((off + sim.dim) > dimsof(ps)(2)) off = 0;
    turb = bilin(ps, 1 + off, sim.dim) / 5.;
    data = float(turb);
    shm_write, my_shmid, "turb", &data;
    s1 = sem_give(my_semid, 3);
    if (n < nit) {
      s2 = sem_take(my_semid, 4);
    }
    if ((s1 < 0) || (s2 < 0)) return;
  }
}

func aommul(void) {
  /* DOCUMENT
  Normally handled by a child.
  Reconstruction and DM shape calculations
  */
  dmshape = float(pup * 0);
  eq_nocopy,cmat,*sim.cmat;
  while (1) {
    // publish result:
    data = float(dmshape);
    shm_write, my_shmid, "dmshape", &data;
    // and give semaphore:
    sem_give, my_semid, 1;
    s = sem_take(my_semid, 0);
    // slopes ready, fetch them:
    sig = shm_read(my_shmid, "wfs_signal");
    // compute corresponding dm update and shape:
    com_update = cmat(, +) * sig(+);
    *dm.com = leak * *dm.com + gain * com_update; // Update DM command.
    *dm.com -= avg(*dm.com);
    dmshape = float(*dm_shape(dm).shape);
    // check if "end" semaphore has been set
    s = sem_take(my_semid, 2, wait = 0);
    if (s == 0) break;
  }
}

func aodisp(void) {
  /* DOCUMENT normally handled by the child.
  This reads some variable put into SHM by aoloop(), does some
  computation (e.g. PSF) and display things at its own pace.
  At the end we need to destroy the window and exit the process
  as the next call may not be for the same system.
  */
  winkill; // we really don't want window migrating across the fork.
  pltitle_height = 7;
  dy = 0.005;
  window, style = "4vp-2.gs", dpi = 180, wait = 1;
  pause, 20;
  plsys, 1;
  animate, 1;
  k = 0;
  if (zoom > sim.dim) zoom = sim.dim;
  tic;
  while (1) {
    k++;
    // this one will be set to 0 to request exit:
    s = sem_take(my_semid, 2, wait = 0);
    if (s == 0) break;

    // Read some stuff from shm
    iter = shm_read(my_shmid, "iteration", subscribe = 20000)(1);
    if (iter == -1) break;
    wfsim = shm_read(my_shmid, "wfsim");
    turb = shm_read(my_shmid, "turb");
    dmshape = shm_read(my_shmid, "dmshape");
    if (numberof(wfsim) == 1) { break; }
    fma;

    // WFS IM and others
    plsys, 3;
    pli, wfsim;
    pltitle_vp, swrite(format = "WFS, it=%d, it/s=%.1f", iter, iter / tac()), dy;

    // PSF and Strehl
    pha = turb - dmshape;
    im = calpsf(pup, pha);
    plsys, 4;
    pli, sqrt(im(1 + sim.dim - zoom : sim.dim + zoom, 1 + sim.dim - zoom : sim.dim + zoom));
    strehl = max(im) / maxim * 100.;
    itv(k) = iter;
    strehlv(k) = strehl;
    avgstrehl += strehl;
    pltitle_vp, swrite(format = "S=%.1f%%, Savg=%.1f%%", strehl, avgstrehl / k), dy;

    // Residual phase
    plsys, 1;
    mp = max(pha(where(pup)));
    pli, (pha - mp) * pup;
    pltitle_vp, "Residual phase", dy;

    // Strehl vs iteration
    plsys, 2;
    plg, strehlv(1 : k), itv(1 : k);
    range, 0;
    pltitle_vp, "Strehl vs iteration", 2 * dy;
    xytitles_vp, "Iteration", "", [ 0., 0.025 ];
  }
  plsys, 1;
  animate, 0;
  if (wait) sem_take(my_semid, 2);
}
