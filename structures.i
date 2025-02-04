// STRUCTURES
struct sims {
	string  parname;
	long    dim;
	float   pupd;
	float   cond;
	long    nfilt;
	float   imlambda;
	float   leak;
	pointer imat;
	pointer cmat;
	pointer ev;
};

struct wfss {
	float   lambda;
	float   flength;
	float   margin;
	float   threshresp;
	float   pos(2); // position in arcsec in the FoV
	long    nxsub; // number of sub on side
	long    nsub;  // total number of sub
	long    ppsub; // pixel per sub
	float   _fl;
	pointer mla;
	pointer emla;
	pointer emla_re;
	pointer emla_im;
	pointer foc;
	pointer pkern;
	pointer pkern_re;
	pointer pkern_im;
	pointer valid2;
	pointer xyc;
	pointer im;
	pointer signal;
	pointer refmes;
};

struct dms {
	long    nxact;
	long    nact;
	long    upsamp;
	float   push4imat;
	float   coupling;
	float   coupling_ext;
	float   margin;
	float   alt;
	pointer valid2;
	pointer wval;
	pointer ker;
	pointer ker4ext;
	pointer xyups;
	pointer com;
	pointer shape;
	pointer ashape;
	pointer iaok;
	pointer iext;
}

struct ress {
  float avstrehl;
  pointer strehlv;
  pointer imav;
}
