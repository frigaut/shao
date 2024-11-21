require,"shao.i";
disp = 1;
aoread,"examples/sh6.par"; aocalib,wfs,dm; aoloop,wfs,dm,0.5,2000,0.8,0.3,disp=disp;
aoread,"examples/sh8.par"; aocalib,wfs,dm; aoloop,wfs,dm,0.5,2000,0.8,0.3,disp=disp;
aoread,"examples/test.par"; aocalib,wfs,dm; aoloop,wfs,dm,0.5,2000,0.8,0.3,disp=disp;
aoread,"examples/sh16.par"; aocalib,wfs,dm; aoloop,wfs,dm,0.5,2000,0.8,0.3,disp=disp;
aoread,"examples/sh32.par"; aocalib,wfs,dm; aoloop,wfs,dm,0.5,2000,0.8,0.3,disp=disp;
aoread,"examples/sh40.par"; aocalib,wfs,dm; aoloop,wfs,dm,0.5,2000,0.8,0.3,disp=disp;
// aoread,"examples/sh64.par"; aocalib,wfs,dm; aoloop,wfs,dm,0.5,2000,0.8,0.3,disp=disp;

