#include "v4l2.h"
#include "unistd.h"

int main() {

  v4l2_open("/dev/video0");
  v4l2_init();
  v4l2_stream_on();
  for (int i = 0; i < 100; i++) {
    usleep(30000);
    v4l2_read_frame();
  }
  v4l2_stream_off();

  v4l2_close();
}
