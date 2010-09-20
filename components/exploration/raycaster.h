#ifndef _RAYCASTER_JMB
#define _RAYCASTER_JMB

struct RAY_TEMPLATE_PT {
int x;
int y;
float angle;

	RAY_TEMPLATE_PT() {
		x = 0;
		y = 0;
		angle = 0.0;
		}

	RAY_TEMPLATE_PT(int a, int b, float c) {
		x = a;
		y = b;
		angle = c;
		}
};

extern std::vector<RAY_TEMPLATE_PT> rayendpts;

int cast_all_rays(int x0, int y0, unsigned char cover_map[], const int16_t elev_map[], int start_vec, int end_vec);

#endif
