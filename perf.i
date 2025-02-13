calib = 1;

require,"shao.i";
func doit(void) {
  disp = 0; nit = 2000; gain = 0.5; turb = 0.5; noise = 0.1;
  prefix = ["sh6","sh8","test","sh16","sh32","sh40","sh64"];
  for (nn=1;nn<=numberof(prefix);nn++) {
    if (calib) {
      aoread,"examples/"+prefix(nn)+".par";
      aocalib,wfs,dm;
      shaosave,prefix(nn);
      aoloop,wfs,dm,gain,nit,turb,noise,disp=disp;
    } else {
      shaorestore,prefix(nn);
      aoloop,wfs,dm,gain,nit,turb,noise,disp=disp;
    }
  }
}
status = doit();
quit;
