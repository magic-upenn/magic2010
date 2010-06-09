#ifndef _MAP_CONVERTER_H_
#define _MAP_CONVERTER_H_

#include "MagicPlanDataTypes.h"

void convertMap(GP_MAGIC_MAP_PTR msg, bool makeAllMaps, float outRes, 
                unsigned char** costmap, int16_t** elevmap, unsigned char** covmap,
                int* new_size_x, int* new_size_y);

#endif
