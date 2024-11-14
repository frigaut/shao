require,"yao_util.i"; // for zernike.
require,"img.i";
require,"yao.i";
require,"svipc.i";
require,"plvp.i";
require,"shao_disp.i";

my_shmid = 0x78080000 | getpid();
shm_init,my_shmid,slots=4;
zoom = 64;

write,format="%s\n","2024 AO simulation demo";
write,format="%s\n","New WFS model (with MLA, global)";
write,format="%s\n","New DM (spline)";
write,format="%s\n","Adjust flength (prop to focal length) in parfile, then";
write,format="%s\n","> #include \"sh40.par\"";
write,format="%s\n","> wfscalib,wfs";
write,format="%s\n","> aocalib,wfs,dm";
write,format="%s\n\n","> aoloop,wfs,dm,0.5,100,0.5,1.,disp=1;";

/******************** STRUCTURES ******************/
include,"structures.i",1;

/********************* FUNCTIONS *******************/
func aoall(parfile,nit=,disp=,verb=)
{
	aoread,parfile;
	animate,1;
	aocalib,wfs,dm;
	aoloop,wfs,dm,0.5,(nit?nit:100),0.9,0.,disp=(disp?disp:0),verb=(verb?verb:0);
	animate,0;
}

func aoread(parfile)
{
	extern wfs,dm,sim,pup,debug;
	include,parfile,1;
	// fill default values
	pup = float(dist(sim.dim,xc=sim.dim/2+0.5,yc=sim.dim/2+0.5)<(sim.pupd/2));

	wfs.lambda = ( wfs.lambda ? wfs.lambda : 0.5e-6 );
	wfs.ppsub = ( wfs.ppsub ? wfs.ppsub : sim.dim/wfs.nxsub ); // # pixel/sub in pupil plane
	wfs.threshresp = ( wfs.threshresp ? wfs.threshresp : 0.25 );

	dm.upsamp = ( dm.upsamp ? dm.upsamp : wfs.ppsub );
	dm.nxact  = ( dm.nxact ? dm.nxact : wfs.nxsub+1 );
	dm.push4imat = ( dm.push4imat ? dm.push4imat : 1. );
	dm.coupling = ( dm.coupling ? dm.coupling : 1.4 );

	debug = ( debug ? debug : 0 );
	prepzernike,sim.dim,sim.pupd+1;
}

/********************* FRESNEL *********************/
func prep_fresnel(foc,d,lambda)
{
	extern pkern;
	pkern = roll(exp(1i*(2*pi/lambda)*d) * exp(-1i*pi*lambda*d*foc)); 
}

func fresnel(obj) {
	tdim = dimsof(obj)(2);
	tmp = fft(obj,1);
	tmp *= pkern;
	res = fft(tmp,-1)/tdim^2.;
	return res;
}

/*********************** WFS  **********************/
func cgwfs(im) 
// Computes the cendroid of image sim
{
	sumim = sum(im);
	if (sumim<=0.) return [0.,0.];
	gx = sum(im*(*wfs.xyc)(,,1))/sumim;
	gy = sum(im*(*wfs.xyc)(,,2))/sumim;
	return [gx,gy];
}

func prep_wfs(wfs)
// prep the wfs, precompute some generic arrays
{
	one = dist(wfs.ppsub,xc=wfs.ppsub/2+0.5,yc=wfs.ppsub/2+0.5)^2./ \
	        ((wfs.ppsub)^2.)*(2000./wfs.flength);
	// replicate	
	mla = pup*0;
	for (i=1;i<=wfs.nxsub;i++) {
		for (j=1;j<=wfs.nxsub;j++) {
			mla(1+(i-1)*wfs.ppsub:i*wfs.ppsub,1+(j-1)*wfs.ppsub:j*wfs.ppsub) = one;
		}	
	}
	wfs.mla = &(roll(mla,[1,1]*(sim.dim-sim.pupd)/2));
	wfs.emla = &(exp(-1i*(*wfs.mla)*0.35));
	// valid subaps:
	rad = wfs.nxsub/2.+wfs.margin;
	wfs.valid2 = &(dist(wfs.nxsub,xc=wfs.nxsub/2+0.5,yc=wfs.nxsub/2+0.5)<rad);
	wfs.nsub = long(sum(*wfs.valid2));
	wfs.xyc = &(indices(wfs.ppsub)-(wfs.ppsub/2.+0.5));
	wfs.foc = &((1./wfs.lambda)*(dist(sim.dim)/(sim.dim/(wfs.ppsub/32.)))^2.);
	status = prep_fresnel(*wfs.foc,wfs._fl,wfs.lambda);
	return wfs;
}

func wfsim(wfs,pup,pha)
// Compute WFS image given WFS, pup and phase.
{
	obj = pup*(*wfs.emla)*exp(-1i*pha);
	im  = fresnel(obj);
	wfs.im = &(im.re*im.re+im.im*im.im);
	return *wfs.im;
}

func shwfs(wfs,pup,pha)
// returns wfs signal given WFS, pup and phase.
{
	wfssig = array(0.,[2,wfs.nsub,2]);
	im = wfsim(wfs,pup,pha);
	k = 0;
	for (i=1;i<=wfs.nxsub;i++) {
		for (j=1;j<=wfs.nxsub;j++) {
			if ((*wfs.valid2)(i,j)) {
				imlet = im(1+(i-1)*wfs.ppsub:i*wfs.ppsub,1+(j-1)*wfs.ppsub:j*wfs.ppsub);
				wfssig(++k,) = cgwfs(imlet);
			}
		}	
	}
	wfs.signal = &wfssig;
	return wfssig(*);
}

/************************ DM ***********************/
func prep_dm(dm)
// Prepare the dm
{
	rad = dm.nxact/2+1+dm.margin;
	dm.valid2 = &(dist(dm.nxact,xc=dm.nxact/2.+0.5,yc=dm.nxact/2.+0.5)<rad);
	dm.ashape = &(dist(dm.nxact)*0);
	dm.wval   = &(where(*dm.valid2));
	dm.nact   = numberof(*dm.wval);
	dm.ker    = &(makegaussian(3,dm.coupling));
	dm.xyups  = &(span(1.,dm.nxact,(dm.nxact-1)*dm.upsamp));
	return dm;
}

func dm_shape(dm)
// compute the dm shape
{
	(*dm.ashape)(*dm.wval) = *dm.com;
	dms = convol2d(*dm.ashape,*dm.ker);
	dm.shape = &(spline2(dms,*dm.xyups,*dm.xyups,grid=1));
	return dm;
}

/***************** CALIB AND AO LOOP ***************/
func wfscalib(wfs)
// find the best WFS MLA focal length
{
	write,format="%s\n","Finding best focal length";
	de = wfs.flength; step = wfs.flength/20.; maxmax = 0.;
	while (1) {
		de+=step;
		wfs._fl = de;
		prep_wfs,wfs;
		im = wfsim(wfs,pup,pup*0.);
		if (debug>1) { tv,im; pause,10; }
		tmax = max(im);
		if (tmax>maxmax) { maxmax=tmax; bde = de; }
		if (tmax<(maxmax*0.8)) break;
	}
	wfs._fl = bde;
	write,format="Best focal length [AU] = %.1f\n",wfs._fl;
	write,format="max(abs(grad(mla)))=%f\n",max(abs(*wfs.mla-roll(*wfs.mla,[0,1])));
	prep_wfs,wfs;
	if (debug) tv,wfsim(wfs,pup,pup*0.);
}

func aocalib(wfs,dm)
{
	extern wref,cmat,imat;
	write,format="%s\n","Calibrating AO system"
	if (wfs._fl==0) { wfscalib,wfs; pause,50; }
	prep_wfs,wfs;
	prep_dm,dm;
	// do imat:
	write,format="%s\n","Measuring iMat"	
	dm.com = &(array(0.,dm.nact));
	imat = array(0.,[2,wfs.nsub*2,dm.nact]);
	wfs.refmes = &(shwfs(wfs,pup,pup*0));
	for (na=1;na<=dm.nact;na++) {
		*dm.com *= 0.; 
		(*dm.com)(na) = dm.push4imat;
		pha = *dm_shape(dm).shape;
		imat(,na) = shwfs(wfs,pup,pha)-(*wfs.refmes);
		if (debug>5) { tv,*wfs.im; pause,5; }
	}
	imat /= dm.push4imat;
	write,format="%s\n","Computing cMat";
	// find actuator with low response, to extrapolate:
	aresp = imat(rms,); // actuator response
	ival = where(aresp>=(max(aresp)*wfs.threshresp)); // valid actuator idx based on response
	iext = where(aresp<(max(aresp)*wfs.threshresp)); // idx of actuators to extrapolate
	write,format="%d actuators filtered out of %d\n",numberof(iext),dm.nact;
	imatval = imat(,ival); // imat for valid actuators
	ev = SVdec(imatval,u,vt);
	w = where((ev/max(ev))>sim.cond);
	write,format="%d eigenmodes filtered out of %d\n",numberof(ival)-numberof(w),numberof(ival);
	evi = ev*0.; evi(w) = 1./ev(w); evi = diag(evi);
	cmatval = (vt(+,)*evi(,+))(,+)*u(,+); // cmat for valid actuators
	cmat = transpose(imat);
	cmat(ival,) = cmatval;
	return cmat;
}

// func calpsf(pup,pha)
// // 305 it/s (aoall,"examples/test.par",nit=100,disp=1)
// {
// 	bpup = bpha = array(0.,[2,2*sim.dim,2*sim.dim]);	
// 	bpup(1:sim.dim,1:sim.dim) = pup;
// 	bpha(1:sim.dim,1:sim.dim) = pha;
// 	im = abs(fft(bpup*exp(1i*bpha)))^2.;
// 	return roll(im);
// }

func calpsf(pup,pha)
// 394 it/s (aoall,"examples/test.par",nit=100,disp=1)
{
	bpup = bpha = array(0.0f,[2,2*sim.dim,2*sim.dim]);	
	bpup(1:sim.dim,1:sim.dim) = float(pup);
	bpha(1:sim.dim,1:sim.dim) = float(pha);
	return calc_psf_fast(bpup,bpha,scale=1,noswap=0);
}

func aoloop(wfs,dm,gain,nit,sturb,noise,disp=,verb=)
{
	if (disp==[]) disp=0;
	leak = 0.99;
	ps = fits_read("~/.yorick/data/bigs1.fits")*sturb;
	dmshape = pup*0.;
	dm.com = &(array(0.,dm.nact));
	imav = calpsf(pup,0); maxim = max(imav);
	strehlv = array(0.0f,nit);
	itv = array(0n,nit);
	k = off = 0; avgstrehl = 0.;
	tic;
	winkill; pause,200;
	if (fork()==0) {
		// I am the child for display
		if (disp!=0) status=aodisp();
		quit;
	}
	// else I am the parent process, main loop
	for (n=1;n<=nit;n++) {
		off += 0.1; if ((off+sim.dim)>dimsof(ps)(2)) off=0;
		turb = bilinear(ps,indgen(sim.dim)+off,indgen(sim.dim),grid=1)/5.;
		pha = turb-dmshape; // total phase after correction
		sig = shwfs(wfs,pup,pha); // WFSing
		sig += random_n(wfs.nsub*2)*noise; // WFS noise.
		*dm.com = leak * (*dm.com) + gain * (cmat(,+)*sig(+)); // Update DM command.
		*dm.com -= avg(*dm.com);
		dmshape = *dm_shape(dm).shape;
		if (disp) {
			data = float(*wfs.im); shm_write,my_shmid,"wfsim",&data;
			data = float(turb); shm_write,my_shmid,"turb",&data;
			data = float(dmshape); shm_write,my_shmid,"dmshape",&data;
			iteration=[n]; shm_write,my_shmid,"iteration",&iteration,publish=1;
		}
	}
	if (verb) write,"";
	write,format="%.1f it/s\n",nit/tac();
	if (disp) {
		// this triggers a warning, but it seems it's a bug:
		shm_free,my_shmid,"wfsim"; 
		shm_free,my_shmid,"turb";
		shm_free,my_shmid,"dmshape";
	}
}

