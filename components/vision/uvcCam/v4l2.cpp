// C++ routines to access V4L2 camera

#include <stdio.h>
#include <stdlib.h>
#include <fcntl.h>
#include <errno.h>
#include <assert.h>
#include <sys/ioctl.h>
#include <sys/mman.h>
#include <cctype>
#include <algorithm>
#include "v4l2.h"
#include <string.h>

static int xioctl(int fd, int request, void *arg) {
  int r;
  do{
    r = ioctl(fd, request, arg); 
  }
  while (r == -1 && errno == EINTR);
  return r;
}

void string_tolower(std::string &str) {
  std::transform(str.begin(), 
                 str.end(), 
                 str.begin(),
                 (int(*)(int)) std::tolower);
}

int V4l2::v4l2_error(const char *error_msg) {
  if (video_fd >= 0)
    close(video_fd);
  video_fd = 0;
  fprintf(stderr, "V4L2 error: %s\n", error_msg);
  return -1;
}

int V4l2::v4l2_query_menu(struct v4l2_queryctrl &queryctrl) {
  struct v4l2_querymenu querymenu;
  querymenu.id = queryctrl.id;
  for (querymenu.index = queryctrl.minimum;
       querymenu.index <= queryctrl.maximum;
       querymenu.index++) {
    if (ioctl(video_fd, VIDIOC_QUERYMENU, &querymenu) == 0) {
      fprintf(stdout, "querymenu: %s\n", querymenu.name);
      menuMap[(char *)querymenu.name] = querymenu;
    }
    else {
      // error
    }
  }
  return 0;
}

int V4l2::v4l2_query_ctrl(unsigned int addr_begin, unsigned int addr_end) {
  struct v4l2_queryctrl queryctrl;
  std::string key;

  for (queryctrl.id = addr_begin;
       queryctrl.id < addr_end;
       queryctrl.id++) {
    if (ioctl(video_fd, VIDIOC_QUERYCTRL, &queryctrl) == -1) {
      if (errno == EINVAL)
	continue;
      else
	return v4l2_error("Could not query control");
    }
    fprintf(stdout, "queryctrl: \"%s\" 0x%x\n",
	    queryctrl.name, queryctrl.id);

    switch (queryctrl.type) {
    case V4L2_CTRL_TYPE_MENU:
      v4l2_query_menu(queryctrl);
      // fall throught
    case V4L2_CTRL_TYPE_INTEGER:
    case V4L2_CTRL_TYPE_BOOLEAN:
    case V4L2_CTRL_TYPE_BUTTON:
      key = (char *)queryctrl.name;
      string_tolower(key);
      ctrlMap[key] = queryctrl;
      break;
    default:
      break;
    }
  }
}

int V4l2::v4l2_set_ctrl(const char *name, int value) {
  if(!init) return v4l2_error("v4l2 is not initialized"); 
  std::string key(name);
  string_tolower(key);
  std::map<std::string, struct v4l2_queryctrl>::iterator ictrl
    = ctrlMap.find(name);
  if (ictrl == ctrlMap.end()) {
    fprintf(stderr, "Unknown control");
    return -1;
  }

  struct v4l2_control ctrl;
  ctrl.id = (ictrl->second).id;
  ctrl.value = value;
  int ret=xioctl(video_fd, VIDIOC_S_CTRL, &ctrl);
  return ret;
}

int V4l2::v4l2_get_ctrl(const char *name, int *value) {
  if(!init) return v4l2_error("v4l2 is not initialized"); 
  std::string key(name);
  string_tolower(key);
  std::map<std::string, struct v4l2_queryctrl>::iterator ictrl
    = ctrlMap.find(name);
  if (ictrl == ctrlMap.end()) {
    fprintf(stderr, "Unknown control");
    return -1;
  }

  struct v4l2_control ctrl;
  ctrl.id = (ictrl->second).id;
  int ret=xioctl(video_fd, VIDIOC_G_CTRL, &ctrl);
  *value = ctrl.value;
  return ret;
}

int V4l2::v4l2_open(const char *device) {
  if (device == NULL) {
    // Default video device name
    device = "/dev/video0";
  }
   
  // Open video device
  if ((video_fd = open(device, O_RDWR|O_NONBLOCK, 0)) == -1)
    return v4l2_error("Could not open video device");
  fprintf(stdout, "open: %d\n", video_fd);
  printf("Device %s has fd %d\n", device, video_fd); 
  return 0;
}

int V4l2::v4l2_init_mmap() {
  struct v4l2_requestbuffers req;
  req.count = nbuffer;
  req.type = V4L2_BUF_TYPE_VIDEO_CAPTURE;
  req.memory = V4L2_MEMORY_MMAP;
  if (xioctl(video_fd, VIDIOC_REQBUFS, &req))
    return v4l2_error("VIDIOC_REQBUFS");
  if (req.count < 2)
    return v4l2_error("Insufficient buffer memory\n");
  
  buffers.resize(req.count);
  for (int i = 0; i < req.count; i++) {
    struct v4l2_buffer buf;
    buf.type = V4L2_BUF_TYPE_VIDEO_CAPTURE;
    buf.memory = V4L2_MEMORY_MMAP;
    buf.index = i;
    if (xioctl(video_fd, VIDIOC_QUERYBUF, &buf) == -1)
      return v4l2_error("VIDIOC_QUERYBUF");
    buffers[i].length = buf.length;
    buffers[i].start = 
      mmap(NULL, // start anywhere
	   buf.length,
	   PROT_READ | PROT_WRITE, // required
	   MAP_SHARED, // recommended
	   video_fd,
	   buf.m.offset);
    if (buffers[i].start == MAP_FAILED)
      return v4l2_error("mmap");
  }
  return 0;
}

int V4l2::v4l2_uninit_mmap() {
  for (int i = 0; i < buffers.size(); i++) {
    if (munmap(buffers[i].start, buffers[i].length) == -1)
      return v4l2_error("munmap");
  }
  buffers.clear();
}


int V4l2::v4l2_set_framerate()
{
	struct v4l2_streamparm parm;
	int ret;

	memset(&parm, 0, sizeof parm);
	parm.type = V4L2_BUF_TYPE_VIDEO_CAPTURE;

	ret = ioctl(video_fd, VIDIOC_G_PARM, &parm);
	if (ret < 0) {
		printf("Unable to get frame rate: %d.\n", errno);
		return ret;
	}

	printf("Current frame rate: %u/%u\n",
		parm.parm.capture.timeperframe.numerator,
		parm.parm.capture.timeperframe.denominator);

	parm.parm.capture.timeperframe.numerator = 1;
	parm.parm.capture.timeperframe.denominator = 5;

	ret = ioctl(video_fd, VIDIOC_S_PARM, &parm);
	if (ret < 0) {
		printf("Unable to set frame rate: %d.\n", errno);
		return ret;
	}

	ret = ioctl(video_fd, VIDIOC_G_PARM, &parm);
	if (ret < 0) {
		printf("Unable to get frame rate: %d.\n", errno);
		return ret;
	}

	printf("Frame rate set: %u/%u\n",
		parm.parm.capture.timeperframe.numerator,
		parm.parm.capture.timeperframe.denominator);
	return 0;
}

int V4l2::v4l2_init(int width, int height) {
  this->width = width; 
  this->height = height; 
  struct v4l2_capability video_cap;
  if (xioctl(video_fd, VIDIOC_QUERYCAP, &video_cap) == -1)
    return v4l2_error("VIDIOC_QUERYCAP");
  if (!(video_cap.capabilities & V4L2_CAP_VIDEO_CAPTURE))
    return v4l2_error("No video capture device");
  if (!(video_cap.capabilities & V4L2_CAP_STREAMING))
    return v4l2_error("No capture streaming");
  
  struct v4l2_format video_fmt;
  video_fmt.type = V4L2_BUF_TYPE_VIDEO_CAPTURE;
  video_fmt.fmt.pix.width       = width;
  video_fmt.fmt.pix.height      = height;
  video_fmt.fmt.pix.pixelformat = V4L2_PIX_FMT_YUYV;
  video_fmt.fmt.pix.field       = V4L2_FIELD_ANY;

  if (xioctl(video_fd, VIDIOC_S_FMT, &video_fmt) == -1)
    v4l2_error("VIDIOC_S_FMT");
  v4l2_set_framerate();    
//    v4l2_error("VIDIOC_G_PARM");
//  printf("Current framerate %u/%u", (unsigned int)params.timeperframe.numerator, (unsigned int)params.timeperframe.denominator); 
 
  // Query V4L2 controls:
  v4l2_query_ctrl(V4L2_CID_BASE,
		  V4L2_CID_LASTP1);
  v4l2_query_ctrl(V4L2_CID_PRIVATE_BASE,
		  V4L2_CID_PRIVATE_BASE+20);
  v4l2_query_ctrl(V4L2_CID_CAMERA_CLASS_BASE+1,
		  V4L2_CID_CAMERA_CLASS_BASE+20);

  // Initialize memory map
  v4l2_init_mmap();
  init = true; 
  return 0;
}

int V4l2::v4l2_stream_on() {
  if(!init) return v4l2_error("v4l2 is not initialized"); 
  for (int i = 0; i < buffers.size(); i++) {
    struct v4l2_buffer buf;
    buf.type = V4L2_BUF_TYPE_VIDEO_CAPTURE;
    buf.memory = V4L2_MEMORY_MMAP;
    buf.index = i;
    if (xioctl(video_fd, VIDIOC_QBUF, &buf) == -1)
      return v4l2_error("VIDIOC_QBUF");
  }

  enum v4l2_buf_type type = V4L2_BUF_TYPE_VIDEO_CAPTURE;
  printf("Stream on for %d\n",video_fd); 
  if (xioctl(video_fd, VIDIOC_STREAMON, &type) == -1)
    return v4l2_error("VIDIOC_STREAMON");

  return 0;
}

int V4l2::v4l2_stream_off() {
  if(!init) return v4l2_error("v4l2 is not initialized"); 
  enum v4l2_buf_type type = V4L2_BUF_TYPE_VIDEO_CAPTURE;
  if (xioctl(video_fd, VIDIOC_STREAMOFF, &type) == -1)
    return v4l2_error("VIDIOC_STREAMOFF");

  return 0;
}

void * V4l2::v4l2_get_buffer(int index, size_t *length) {
  if(!init){
	v4l2_error("v4l2 is not initialized"); 
 	return NULL; 
  }
  if (length != NULL)
    *length = buffers[index].length;

  return buffers[index].start;
}

int V4l2::v4l2_read_frame() {
  if(!init) return v4l2_error("v4l2 is not initialized"); 
  struct v4l2_buffer buf;
  buf.type = V4L2_BUF_TYPE_VIDEO_CAPTURE;
  buf.memory = V4L2_MEMORY_MMAP;
  if (xioctl(video_fd, VIDIOC_DQBUF, &buf) == -1) {
    switch (errno) {
    case EAGAIN:
      fprintf(stdout, "no frame available\n");
      return -1;
    case EIO:
      // Could ignore EIO
      // fall through
    default:
      return v4l2_error("VIDIOC_DQBUF");
    }
  }
  assert(buf.index < buffers.size());

  // process image
  void *ptr = buffers[buf.index].start;
  fprintf(stdout, "read: %d\n", buf.index);

  if (xioctl(video_fd, VIDIOC_QBUF, &buf) == -1)
    return v4l2_error("VIDIOC_QBUF");

  return buf.index;
}

int V4l2::v4l2_close() {
  v4l2_uninit_mmap();
  if (close(video_fd) == -1)
    v4l2_error("Closing video device");
  video_fd = -1;
}
