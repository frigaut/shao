require,"shao.i";
window,wait=1;

func demo(void)
{
	aoread,"examples/demo.par";
	debug = 10;
	animate,1;
	write,"Scanning focal length for the MLA";
	wfscalib,wfs;
	animate,0;
	hitReturn;
	write,"MicroLens Array";
	tv,-*wfs.mla;
	hitReturn;
	// DM
	write,"Initialising DM";
	prep_dm,dm;
	com=array(0.0f,dm.nact); 
	com(dm.nact/2)=1; 
	dm.com=&com; 
	dm_shape,dm; 
	tv,*dm.shape
    print_struct,"wfs";
    print_struct,"dm";
    print_struct,"sim";
    aocalib,wfs,dm;
	pltitle,"Example Influence function";
	hitReturn;
	write,"Loop, 100it, instant image";
	aoloop,wfs,dm,0.5,100,0.9,0.,disp=1;
	hitReturn;
	write,"Loop, 100it, WFS";
	aoloop,wfs,dm,0.5,100,0.9,0.,disp=3;
	hitReturn;
	write,"Loop, 100it, Residual phase";
	aoloop,wfs,dm,0.5,100,0.9,0.,disp=5;
	hitReturn;
	write,"Loop, 100it, no display";
	aoloop,wfs,dm,0.5,100,0.9,0.,disp=0;
}

demo;