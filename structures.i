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
	float   pup(dim,dim);
	complex emla(dim,dim);
	complex pkern(dim,dim);
	float   mla(dim,dim);
	float   foc(dim,dim);
	float   im(dim,dim);
	pointer valid2;
	pointer xyc;
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
	pointer shape;
	pointer valid2;
	pointer wval;
	pointer ker;
	pointer xyups;
	pointer com;
	pointer ashape;
}
