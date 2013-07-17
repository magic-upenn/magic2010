#include <vector>
#include <stdio.h>
#include <stdlib.h>
#include "string.h"
#include <stdint.h>
#include "jpeglib.h"

std::vector<unsigned char> destBuf;

static void error_exit(j_common_ptr cinfo)
{
  (*cinfo->err->output_message) (cinfo);
  jpeg_destroy_compress((j_compress_ptr) cinfo);
  printf("JPEG compression error");
  exit(1);
}

void init_destination(j_compress_ptr cinfo) {
  const unsigned int size = 65536;
  destBuf.resize(size);
  cinfo->dest->next_output_byte = &(destBuf[0]);
  cinfo->dest->free_in_buffer = size;
}

boolean empty_output_buffer(j_compress_ptr cinfo)
{
  unsigned int size = destBuf.size();
  destBuf.resize(2*size);
  cinfo->dest->next_output_byte = &(destBuf[size]);
  cinfo->dest->free_in_buffer = size;

  return TRUE;
}

void term_destination(j_compress_ptr cinfo) {
  /*
  cinfo->dest->next_output_byte = destBuf;
  cinfo->dest->free_in_buffer = destBufSize;
  */
  int len = destBuf.size() - (cinfo->dest->free_in_buffer);
  while (len % 2 != 0)
    destBuf[len++] = 0xFF;

  destBuf.resize(len);
}

int compress(uint8_t *prRGB, int width, int height)
{
  int quality = 80;

  height = height;

  struct jpeg_compress_struct cinfo;
  struct jpeg_error_mgr jerr;
  cinfo.err = jpeg_std_error(&jerr);
  jerr.error_exit = error_exit;

  jpeg_create_compress(&cinfo);
  if (cinfo.dest == NULL) {
    cinfo.dest = (struct jpeg_destination_mgr *)
      (*cinfo.mem->alloc_small) ((j_common_ptr) &cinfo, JPOOL_PERMANENT,
				 sizeof(struct jpeg_destination_mgr));
  }
  cinfo.dest->init_destination = init_destination;
  cinfo.dest->empty_output_buffer = empty_output_buffer;
  cinfo.dest->term_destination = term_destination;

  cinfo.image_width = width;
  cinfo.image_height = height;
  cinfo.input_components = 1; //3;
  cinfo.in_color_space = JCS_GRAYSCALE; //JCS_RGB;
  jpeg_set_defaults(&cinfo);
  jpeg_set_quality(&cinfo, quality, TRUE);
  cinfo.write_JFIF_header = false;
  cinfo.dct_method = JDCT_IFAST;

  jpeg_start_compress(&cinfo, TRUE);
  JSAMPLE row[width];
  JSAMPROW row_pointer[1];
  *row_pointer = row;

  while (cinfo.next_scanline < cinfo.image_height)
  {
    uint8_t *p = prRGB + cinfo.next_scanline*width;
    //memcpy(&(row[0]),p,width);
    //for (int ii = 0; ii < width; ii++)
    //  row[ii] = *p++;
    *row_pointer = p;
    jpeg_write_scanlines(&cinfo, row_pointer, 1);
  }
  jpeg_finish_compress(&cinfo);
  jpeg_destroy_compress(&cinfo);

  unsigned int destBufSize = destBuf.size();
  printf("compressed size = %d\n",destBufSize);

  return 0;
}
