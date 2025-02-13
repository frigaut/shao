/********************* DEPENDENCIES **********************/
require, "yao_util.i"; // for zernike
require, "img.i";
require, "yao.i";
require, "svipc.i";
require, "plvp.i";

/******************* SHARED MEMORY TIPS *****************/
// MACOS:
// make sure you do:
// sudo sysctl -w kern.sysv.shmmax=4294967296 kern.sysv.shmmni=256 kern.sysv.shmseg=128
// kern.sysv.shmall=1048576 this should work for at least 64x64 systems
// to clean up the shared memory and semaphores left open in case the process exited badly:
// ipcs; ipcrm `ipcs | egrep '0x7809|0x0bad|0x7808' | awk '{print "-m " $2}'`; ipcrm `ipcs | egrep '0x7809|0x7dcb|0x0bad|0x7808' | awk '{print "-s " $2}'`; ipcs

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
  dm.coupling_ext = (dm.coupling_ext ? dm.coupling_ext : 2.0);

  sim.imlambda = (sim.imlambda ? sim.imlambda : wfs.lambda);
  sim.leak = (sim.leak ? sim.leak : 1.0);

  debug = (debug ? debug : 0);
  prepzernike, sim.dim, sim.pupd + 1;
}

func shaosave(fname) {
  /* DOCUMENT
  Saves all session variables in file (extension ".shao").
  */
  if (fname == []) fname = strip_file_extension(sim.parname);
  if (!strmatch(fname, ".shao")) fname += ".shao";
  // unfortunately, because we can't save pointer to complex arrays:
  wfs.emla_re = &((*wfs.emla).re);
  wfs.emla_im = &((*wfs.emla).im);
  emla = *wfs.emla * 1;
  wfs.emla = &([]);
  // wfs.pkern_re = &((*wfs.pkern).re);
  // wfs.pkern_im = &((*wfs.pkern).im);
  // pkern = *wfs.pkern * 1;
  // wfs.pkern = &([]);
  vsave, createb(fname), wfs, dm, sim, pup, pkern;
  wfs.emla = &emla;
  // wfs.pkern = &pkern;
}

func shaorestore(fname) {
  /* DOCUMENT
  Restore all session variables from file (extension ".shao").
  */
  if (fname == []) error, "shaorestore,filename";
  if (!strmatch(fname, ".shao")) fname += ".shao";
  restore, openb(fname);
  wfs.emla = &(*wfs.emla_re + 1i * *wfs.emla_im);
  // wfs.pkern = &(*wfs.pkern_re + 1i * *wfs.pkern_im);
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
        imlet = im(1 + (i - 1) * wfs.ppsub
                   : i * wfs.ppsub, 1 + (j - 1) * wfs.ppsub
                   : j * wfs.ppsub);
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
  dm.ker4ext = &(makegaussian(7, dm.coupling));
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
  write, format = "%s\n", "Measuring iMat...";
  dm.com = &(array(0., dm.nact));
  wfs.refmes = &(shwfs(wfs, pup, pup * 0));

  // preparing forks
  tic, 5;
  nforks = clip(dm.nact / 200, 1, nprocs());
  write, format = "Using %d forks for imat\n", nforks;
  my_shmid = 0x78080000 | getpid();
  shm_init, my_shmid, slots = nforks;
  my_semid = 0x7dcb0000 | getpid();
  sem_init, my_semid, nums = nforks;
  // nactperfork = dm.nact / nforks;
  // a1 = indgen(1 : dm.nact : nactperfork)(1 : -1);
  // a2 = _(a1(2 :) - 1, dm.nact);
  a1 = long(span(1, dm.nact, nforks + 1)( : -1));
  a2 = long(span(1, dm.nact, nforks + 1)(2 :) - 1);
  a2(0) = dm.nact;
  nact_per_piece = (a2 - a1 + 1);
  am_child = 0;
  for (nc = 1; nc <= nforks - 1; nc++) {
    if (fork() == 0) am_child = 1;
    if (am_child) break;
    pause, 10;
  }
  write, format = "%d: Calibrating imat for actuators %d to %d (am_child=%d)\n", nc, a1(nc), a2(nc),
         am_child;
  imat_piece = array(0., [ 2, wfs.nsub * 2, nact_per_piece(nc) ]);
  for (i = 1; i <= nact_per_piece(nc); i++) {
    na = i + a1(nc) - 1;
    *dm.com *= 0.;
    (*dm.com)(na) = dm.push4imat;
    pha = *dm_shape(dm).shape;
    imat_piece(, i) = shwfs(wfs, pup, pha) - (*wfs.refmes);
  }
  // write imat piece
  if (am_child) {
    shm_write, my_shmid, "imat_piece" + totxt(nc), &imat_piece;
    sem_give, my_semid, nc;
    quit;
  }
  imat = array(0., [ 2, wfs.nsub * 2, dm.nact ]);
  // fill in the piece calibrated from the main process:
  imat(, a1(0) : a2(0)) = imat_piece;
  // I am the parent, gather imat pieces
  for (nc = 1; nc <= nforks - 1; nc++) {
    sem_take, my_semid, nc;
  }
  for (nc = 1; nc <= nforks - 1; nc++) {
    imat(, a1(nc) : a2(nc)) = shm_read(my_shmid, "imat_piece" + totxt(nc));
  }
  write, format = "iMat acquisition: %f seconds\n", tac(5);
  shm_cleanup, my_shmid;
  sem_cleanup, my_semid;

  imat /= dm.push4imat;
  write, format = "%s\n", "Computing cMat";
  // find actuator with low response, to extrapolate:
  aresp = imat(rms, );                                  // actuator response
  iaok = where(aresp >= (max(aresp) * wfs.threshresp)); // valid actuator idx based on response
  iext = where(aresp < (max(aresp) * wfs.threshresp));  // idx of actuators to extrapolate
  write, format = "%d actuators filtered out of %d;\n", numberof(iext), dm.nact;
  imatval = imat(, iaok); // imat for valid actuators
  tic, 5;
  ev = SVdec(imatval, u, vt);
  write, format = "SVD of %dx%d imat took %.3f seconds\n", dimsof(imat)(2), dimsof(imat)(3), tac(5);
  nev = numberof(ev);
  // error;
  if (sim.nfilt) { // number of filtered mode specified, prefer this.
    w = indgen(nev - sim.nfilt);
  } else {
    w = where((ev / max(ev)) > sim.cond);
  }
  write, format = "%d eigenmodes filtered out of %d\n", numberof(iaok) - numberof(w),
         numberof(iaok);
  evi = ev * 0.;
  evi(w) = 1. / ev(w);
  evi = diag(evi);
  cmatval = (vt(+, ) * evi(, +))(, +) * u(, +); // cmat for valid actuators
  cmat = transpose(imat);
  cmat(iaok, ) = cmatval;
  // manage extrapolated
  for (i = 1; i <= numberof(iext); i++) {
    *dm.com *= 0;
    (*dm.com)(iext(i)) = 1;
    (*dm.ashape)(*dm.wval) = *dm.com;
    dms = convol2d(*dm.ashape, *dm.ker4ext);
    coup = dms(*dm.wval);
    coup(iext) = 0;    // we're not extrapolating from extrapolated
    coup /= sum(coup); // normalise
    cmat(iext(i), ) = cmat(+, ) * coup(+);
  }
  // fill structures
  dm.iaok = &iaok;
  if (numberof(iext)) dm.iext = &iext;
  sim.imat = &imat;
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

func aoloop(wfs, dm, gain, nit, sturb, noise, disp =, dpi =, verb =, wait =) {
  /* DOCUMENT
  The loop
  */
  if (disp == []) disp = 0;
  if (wait == []) wait = 0;
  dpi = (dpi ? dpi : 150);
  my_shmid = 0x78080000 | getpid();
  shm_init, my_shmid, slots = 10;
  my_semid = 0x7dcb0000 | getpid();
  sem_init, my_semid, nums = 10;
  // sem 0: WFS signal ready from aoloop()
  // sem 1: DM command / dm shape ready from aommul()
  // sem 2: End of loop (nit reached)
  // sem 3: Turbulence/phase screen ready from aoscreens()
  // sem 4: Tell aoscreens() to proceed to next step
  // sem 5: "go" signal to aommul()
  // sem 6: "go" signal to aodisp()
  // sem 7: aodisp stat results ready.
  // leak = 0.99;
  ps = float(fits_read("~/.yorick/data/bigs1.fits") / sim.pupd ^ (5. / 6) * sturb);
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
  // SHM phase screens
  if (fork() == 0) {
    // I am the child for matrix mutiply
    wfs = dm = []; // free up some memory
    if (debug) write, format = "%s\n", "forking phase screens";
    status = aoscreens();
    if (debug) {
      // pause, 100;
      write, format = "%s\n", "Phase screen fork quitting";
    }
    quit;
  }
  // SHM MMUL
  if (fork() == 0) {
    // I am the child for matrix mutiply
    wfs = []; // free up some memory
    if (debug) write, format = "%s\n", "forking matrix multiply";
    status = aommul();
    if (debug) {
      // pause, 100;
      write, format = "%s\n", "Matrix multiply fork quitting";
    }
    quit;
  }
  // SHM DISPLAYS:
  if (fork() == 0) {
    // I am the child for display
    dm = []; // free up some memory
    // if (disp != 0) status = aodisp();
    if (debug) write, format = "%s\n", "forking displays + telemetry";
    status = aodisp(disp); // we need this for telemetry + diagnostics anyway
    if (debug) {
      // pause, 500;
      write, format = "%s\n", "Display fork quitting";
    }
    quit;
  }
  // else main aoloop, WFS function
  t2 = t3 = t4 = t5 = 0.;
  tic;
  // else I am the parent process, main loop
  // pause, 500;
  write, format = "Starting loop with %d iterations\n", nit;
  for (n = 1; n <= nit; n++) {
    if ((debug) && ((n % 100) == 0)) write, format = "\r%d out of %d", n, nit;
    iteration = [n];
    shm_write, my_shmid, "iteration", &iteration; //, publish = 1;
    status = sem_give(my_semid, 5);               // "go" signal to aommul()
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
    sem_take, my_semid, 1; // wait for aommul() ready signal
    dmshape = shm_read(my_shmid, "dmshape");
    // write signal on shm for aommul to compute the next DM command update
    shm_write, my_shmid, "wfs_signal", &sig;
    sem_give, my_semid, 0;
    if (n == nit) {
      // if (debug) write, format = "\n%s\n", "n == nit, telling fork to bail";
      // sem_give, my_semid, 5; // for aommul
      // sem_give, my_semid, 2; // for aodisp, to exit while(1)
      if (wait) {
        if (wait < 0) status = hitReturn();
        if (wait > 0) pause, long(wait * 1000);
        sem_give, my_semid, 2; // for aodisp, now to exit
      }
    }
    data = float(*wfs.im);
    shm_write, my_shmid, "wfsim", &data;
    status = sem_give(my_semid, 6); // "go" signal to aodisp()
    t4 += tac(4);
  }
  extern nitps;
  nitps = nit / (tac() - wait);
  if (verb) write, "";
  write, format = "\n%s: %.1f it/s, ", sim.parname, nitps;
  write, format = "tur=%.1fμs, wfs=%.1fμs, shm=%.1fμs (%.1f)\n", t2 * 1e6 / nit, t3 * 1e6 / nit,
         t4 * 1e6 / nit, nit / (t2 + t3 + t4);

  sem_take, my_semid, 7; // stat results ready.
  strehlv = shm_read(my_shmid, "strehlv");
  imav = shm_read(my_shmid, "imav");
  // fill res structure
  res = ress();
  w = where(strehlv != 0);
  if (numberof(w) == 0)
    write, format = "%s\n", "Not enough data points for Strehl estimate";
  else {
    res.strehlv = &strehlv;
    res.avstrehl = avg(strehlv);
  }
  res.imav = &imav;

  shm_free, my_shmid, "iteration";
  shm_free, my_shmid, "turb";
  shm_free, my_shmid, "dmshape";
  shm_free, my_shmid, "wfs_signal";
  shm_free, my_shmid, "wfsim";
  shm_free, my_shmid, "strehlv";
  shm_free, my_shmid, "imav";
  shm_cleanup, my_shmid;
  sem_cleanup, my_semid;

  return res;
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
    if (n < nit) { s2 = sem_take(my_semid, 4); }
    if ((s1 < 0) || (s2 < 0)) return;
  }
}

func aommul(void) {
  /* DOCUMENT
  Normally handled by a child.
  Reconstruction and DM shape calculations
  */
  dmshape = float(pup * 0);
  eq_nocopy, cmat, *sim.cmat;
  s = sem_take(my_semid, 5); // wait for "go" signal
  iter = 0;
  while (1) {
    // publish result:
    data = float(dmshape);
    shm_write, my_shmid, "dmshape", &data;
    // and give semaphore:
    sem_give, my_semid, 1;
    // wait for signal from aoloop() that next wfs_signal is ready
    if (iter == nit) break;
    s = sem_take(my_semid, 0);
    // slopes ready, fetch them:
    sig = shm_read(my_shmid, "wfs_signal");
    // compute corresponding dm update and shape:
    // com_update = cmat(, +) * sig(+);
    com_update = mvmult(cmat, sig);
    *dm.com = sim.leak * *dm.com + gain * com_update; // Update DM command.
    *dm.com -= avg(*dm.com);
    dmshape = float(*dm_shape(dm).shape);
    iter = shm_read(my_shmid, "iteration")(1); //, subscribe = 20000)(1);
    if (debug > 5) write, format = "iter (aommul) = %d\n", iter;
  }
}

func aodisp(disp) {
  /* DOCUMENT normally handled by the child.
  This reads some variable put into SHM by aoloop(), does some
  computation (e.g. PSF) and display things at its own pace.
  At the end we need to destroy the window and exit the process
  as the next call may not be for the same system.
  */
  if (disp) {
    winkill; // we really don't want window migrating across the fork.
    pltitle_height = 7;
    dy = 0.005;
    window, style = "4vp-2.gs", dpi = dpi, wait = 1;
    // system,"niri msg action focus-column-left";
    plsys, 1;
    animate, 1;
  }
  k = 0;
  imav = array(0., [ 2, 2 * sim.dim, 2 * sim.dim ]);
  if (zoom > sim.dim) zoom = sim.dim;
  tic;
  status = sem_take(my_semid, 6); // wait for "go" signal
  while (1) {
    k++;
    if (k > nit) break;
    if (debug > 5) write, format = "k=%d\n", k;
    // this one will be set to 1 to request exit:
    // s = sem_take(my_semid, 2, wait = 0);
    // write,format="aodisp() s=%d\n",s;
    // if (s == 1) break;

    // Read some stuff from shm
    iter = shm_read(my_shmid, "iteration")(1); //, subscribe = 20000)(1);
    // iter = shm_read(my_shmid, "iteration")(1);
    if (debug > 5) write, format = "iter=%d, k=%d\n", iter, k;
    // write,format="aodisp() iter=%d\n",iter;
    if (iter == nit) break;
    wfsim = shm_read(my_shmid, "wfsim");
    turb = shm_read(my_shmid, "turb");
    dmshape = shm_read(my_shmid, "dmshape");
    if (numberof(wfsim) == 1) { break; }
    if (disp) fma;

    // WFS IM and others
    if (disp) {
      plsys, 3;
      pli, wfsim;
      pltitle_vp,
          swrite(format = "WFS(%.2fum), it=%d, it/s=%.1f", wfs.lambda * 1e6, iter, iter / tac()),
          dy;
    }

    // PSF and Strehl
    pha = turb - dmshape;
    pha *= (wfs.lambda / sim.imlambda);
    im = calpsf(pup, pha);
    imav += im;
    if (disp) {
      plsys, 4;
      pli, sqrt(im(1 + sim.dim - zoom : sim.dim + zoom, 1 + sim.dim - zoom : sim.dim + zoom));
    }
    strehl = max(im) / maxim * 100.;
    itv(k) = iter;
    strehlv(k) = strehl;
    avgstrehl += strehl;
    if (disp)
      pltitle_vp,
          swrite(format = "S(%.2fum)=%.1f%%, Savg=%.1f%%", sim.imlambda * 1e6, strehl,
                 avgstrehl / k),
          dy;

    // Residual phase
    if (disp) {
      plsys, 1;
      mp = max(pha(where(pup)));
      pli, (pha - mp) * pup;
      pltitle_vp, "Residual phase", dy;
    }

    // Strehl vs iteration
    if (disp) {
      plsys, 2;
      plg, strehlv(1 : k), itv(1 : k);
      range, 0;
      pltitle_vp, "Strehl vs iteration", 2 * dy;
      xytitles_vp, "Iteration", "", [ 0., 0.025 ];
    }
  }
  if (disp) {
    plsys, 1;
    animate, 0;
  }
  shm_write, my_shmid, "imav", &imav;
  // write, format = "k=%d\n", k;
  strehlv = strehlv(1 : k - 1);
  shm_write, my_shmid, "strehlv", &strehlv;
  // tell the main aoloop() process that the stat data are ready:
  sem_give, my_semid, 7;
  // and keep the graphic window up if requested:
  if (wait) sem_take(my_semid, 2);
}
