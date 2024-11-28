require, "shao.i";
window, wait = 1;


func demo(void) {
  aoread, "examples/demo.par";
  debug = 10;
  // dm.push4imat = 5.;
  animate, 1;
  write, "Scanning focal length for the MLA";
  wfscalib, wfs;
  // animate, 0;
  fma;
  pause,3000; //hitReturn;
  write, "MicroLens Array";
  tv, -*wfs.mla;
  pltitle, "MLA";
  fma;
  pause,3000; //hitReturn;
  // DM
  write, "Initialising DM";
  prep_dm, dm;
  com = array(0.0f, dm.nact);
  com(dm.nact / 2) = 1;
  dm.com = &com;
  dm_shape, dm;
  tv, *dm.shape;
  pltitle, "Example Influence function";
  fma;
  print_struct, "wfs";
  print_struct, "dm";
  print_struct, "sim";
  aocalib, wfs, dm;
  animate,0;
  pause,3000; //hitReturn;
  write, "Loop, 1000it";
  aoloop, wfs, dm, 0.5, 1000, 0.5, 0., disp = 1, wait = 2;
}

demo;
