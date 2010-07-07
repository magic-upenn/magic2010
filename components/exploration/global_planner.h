#ifndef _GLOBAL_PLANNER_JMB
#define _GLOBAL_PLANNER_JMB

class frontier_pts {
	public:
		int x;
		int y;
		unsigned int IG;
		int cost;
		double weight;
		double total;

		frontier_pts() {
			x = -1;
			y = -1;
			IG = 0;
			cost = 0;
			total = 0;
			weight = 0.0;
		}
		frontier_pts(int a, int b, unsigned int c, int d, double e) {
			x = a;
			y = b;
			IG = c;
			cost =  d;
			weight = e;
			total = ((c*e)+1.0)/ (d*(1.0-e)+1.0);
		}
};

class fp_compare {
	public:
		bool operator () (const frontier_pts& lhs, const frontier_pts& rhs) const
		{
			return (lhs.total<rhs.total); 
		}
};



#endif
