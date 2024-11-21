func aodisp(void)
// normally handled by the child.
{   winkill;
    pltitle_height = 7;
    dy = 0.005;
	window,style="4vp-2.gs",dpi=180,wait=1; pause,200;
	plsys,1; animate,1; k=0;
    tic;
	while (1) {
		k++;
		s = sem_take(my_semid, 2, wait = 0);
        if (s == 0) break;
		iter = shm_read(my_shmid,"iteration",subscribe=2)(1);
		if (iter==-1) break;
		wfsim = shm_read(my_shmid,"wfsim");
		turb = shm_read(my_shmid,"turb");
		dmshape = shm_read(my_shmid,"dmshape");
		pha = turb-dmshape;
		if (numberof(wfsim)==1) { break; }
		fma;
		//WFS IM and others
		plsys,3;
		pli,wfsim;
		pltitle_vp,swrite(format="WFS, it=%d, it/s=%.1f",iter,iter/tac()),dy;
		// PSF
		im = calpsf(pup,pha);
		plsys,4;
		pli,sqrt(im(1+sim.dim-zoom:sim.dim+zoom,1+sim.dim-zoom:sim.dim+zoom));
		strehl = max(im)/maxim*100.;
        itv(k) = iter;
        strehlv(k) = strehl;
		avgstrehl += strehl;
		pltitle_vp,swrite(format="S=%.1f%%, Savg=%.1f%%",strehl,avgstrehl/k),dy;
        // Residual phase
		plsys,1;
		mp = max(pha(where(pup)));
		pli,(pha-mp)*pup;
		pltitle_vp,"Residual phase",dy;
        // Strehl vs iteration
        plsys,2;
        plg,strehlv(1:k),itv(1:k);
        range,0;
		pltitle_vp,"Strehl vs iteration",2*dy;
        xytitles_vp,"Iteration","",[0.,0.025];
	}
	plsys,1;
	animate,0;
}
