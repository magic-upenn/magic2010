#include <stdlib.h>
#include <linux/videodev2.h>
#include <vector>
#include <map>
#include <string>


class V4l2
{
public: 
	V4l2() : video_fd(-1), nbuffer(4), init(false) 
	{}; 
	int v4l2_open(const char *device);
	int v4l2_set_ctrl(const char *name, int value);
	int v4l2_get_ctrl(const char *name, int *value);
	int v4l2_init(int width, int height);
	int v4l2_stream_on();
	int v4l2_read_frame();
	void *v4l2_get_buffer(int index, size_t *length);
	int v4l2_stream_off();
	int v4l2_close();
	int v4l2_error(const char *error_msg);
	int v4l2_query_ctrl(unsigned int addr_begin, unsigned int addr_end); 
	int v4l2_query_menu(struct v4l2_queryctrl &queryctrl); 
	int v4l2_init_mmap(); 
	int v4l2_uninit_mmap();
	int v4l2_set_framerate();
	const int nbuffer;
	bool is_init(){ return init; }
	int get_width(){ return width; }
	int get_height(){ return height; }
	private: 
	int video_fd;
	struct buffer {
	  void * start;
	  size_t length;
	};
	bool init; 
	int width;
	int height;
	std::map<std::string, struct v4l2_queryctrl> ctrlMap;
	std::map<std::string, struct v4l2_querymenu> menuMap;
	std::vector<struct buffer> buffers;
};
