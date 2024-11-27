// STRUCTURES
struct sims {
	string  parname;
	long    dim;
	float   pupd;
	float   cond;
	pointer imat;
	pointer cmat;
	pointer ev;
};

struct wfss {
	float   lambda;
	float   flength;
	float   margin;
	float   threshresp;
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
	float   margin;
	pointer valid2;
	pointer wval;
	pointer ker;
	pointer xyups;
	pointer com;
	pointer shape;
	pointer ashape;
}
