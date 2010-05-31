/*
  djpeg.mex

  To compile:
  mex -O djpeg.c /usr/lib/libjpeg.a

  rgb = djpeg(buf);
*/

#include "mex.h"
#include <stdio.h>
#include <setjmp.h>
#include "jpeglib.h"

jmp_buf setjmp_buffer;

static void error_exit(j_common_ptr cinfo)
{
  (*cinfo->err->output_message) (cinfo);
  longjmp(setjmp_buffer, 1);
}
void init_source(j_decompress_ptr cinfo) { }
boolean fill_input_buffer(j_decompress_ptr cinfo)
{
  jpeg_destroy_decompress(cinfo);
  mexWarnMsgTxt("fill_input_buffer");
}
void skip_input_data(j_decompress_ptr cinfo, long num_bytes)
{
  if (num_bytes > 0) {
    while (num_bytes > (long) cinfo->src->bytes_in_buffer) {
      num_bytes -= (long) cinfo->src->bytes_in_buffer;
      (void) fill_input_buffer(cinfo);
    }
    cinfo->src->next_input_byte += (size_t) num_bytes;
    cinfo->src->bytes_in_buffer -= (size_t) num_bytes;
  }
}
void term_source(j_decompress_ptr cinfo) { }

static mxArray *ReadRgbJPEG(j_decompress_ptr cinfoPtr);
static mxArray *ReadGrayJPEG(j_decompress_ptr cinfoPtr);

char *jpegBuf;
unsigned int jpegBufLen;

void mexFunction(int nlhs, mxArray *plhs[],
                 int nrhs, const mxArray *prhs[]) { 
  struct jpeg_decompress_struct cinfo;
  struct jpeg_error_mgr jerr;
  int current_row;
  int nskip, i;

  if (nrhs < 1) {
    mexErrMsgTxt("Not enough input arguments.");
  }      
  if (!(mxIsUint8(prhs[0]) || mxIsInt8(prhs[0])))
    mexErrMsgTxt("Input must be of type uint8 or int8.");

  jpegBuf = (char *) mxGetData(prhs[0]);
  jpegBufLen = mxGetM(prhs[0])*mxGetN(prhs[0]);


  cinfo.err = jpeg_std_error(&jerr);
  jerr.error_exit = error_exit;
  if (setjmp(setjmp_buffer)) {
    mexPrintf("setjmp error!\n");
    jpeg_destroy_decompress(&cinfo);
    return;
  }

  jpeg_create_decompress(&cinfo);
  if (cinfo.src == NULL) {
    cinfo.src = (struct jpeg_source_mgr *)
      (*cinfo.mem->alloc_small) ((j_common_ptr) &cinfo, JPOOL_PERMANENT,
                                  sizeof(struct jpeg_source_mgr));
  }
  cinfo.src->bytes_in_buffer = jpegBufLen;
  cinfo.src->next_input_byte = (JOCTET *)jpegBuf;
  cinfo.src->init_source = init_source;
  cinfo.src->fill_input_buffer = fill_input_buffer;
  cinfo.src->skip_input_data = skip_input_data;
  cinfo.src->resync_to_restart = jpeg_resync_to_restart;
  cinfo.src->term_source = term_source;

  jpeg_read_header(&cinfo, TRUE);
  jpeg_start_decompress(&cinfo);
  if (cinfo.output_components == 1) { /* Grayscale */
      plhs[0] = ReadGrayJPEG(&cinfo);
  }
  else {
      plhs[0] = ReadRgbJPEG(&cinfo);
  }

  jpeg_finish_decompress(&cinfo);
  jpeg_destroy_decompress(&cinfo);
  
  return;		
}


static mxArray *
ReadRgbJPEG(j_decompress_ptr cinfoPtr)
{
    long i,j,k,row_stride;
    int dims[3];                  /* For the call to mxCreateNumericArray */
    mxArray *img;
    JSAMPARRAY buffer;
    int current_row;
    uint8_T *pr_red, *pr_green, *pr_blue;
    
    row_stride = cinfoPtr->output_width * cinfoPtr->output_components;
    buffer = (*cinfoPtr->mem->alloc_sarray)
        ((j_common_ptr) cinfoPtr, JPOOL_IMAGE, row_stride, 1);
    
    /*
     * Create 3 matrices, One each for the Red, Green, and Blue componenet of 
     * the image.
     */
    
    dims[0]  = cinfoPtr->output_height;
    dims[1]  = cinfoPtr->output_width;
    dims[2]  = 3;
    
    img = mxCreateNumericArray(3, dims, mxUINT8_CLASS, mxREAL);
    
    /*
     * Get pointers to the real part of each matrix (data is stored 
     * in a 1 dimensional double array).
     */

    pr_red   = (uint8_T *) mxGetPr(img);
    pr_green = pr_red + (dims[0]*dims[1]);
    pr_blue  = pr_red + (2*dims[0]*dims[1]);
    
    while (cinfoPtr->output_scanline < cinfoPtr->output_height) {
        current_row = cinfoPtr->output_scanline; /* Temp var won't get ++'d */
        jpeg_read_scanlines(cinfoPtr, buffer,1); /*  by jpeg_read_scanlines */
        for (i=0;i<cinfoPtr->output_width;i++) {     
            j=(i)*cinfoPtr->output_height+current_row;       
            pr_red[j]   = buffer[0][i*3+0];
            pr_green[j] = buffer[0][i*3+1];
            pr_blue[j]  = buffer[0][i*3+2];
        }
    }
    return img;
}

static mxArray *
ReadGrayJPEG(j_decompress_ptr cinfoPtr)
{
    long i,j,k,row_stride;
    int dims[3];                  /* For the call to mxCreateNumericArray */
    mxArray *img;
    JSAMPARRAY buffer;
    int current_row;
    uint8_T *pr_gray;
        
    /*
     * Allocate buffer for one scan line
     */
    
    row_stride = cinfoPtr->output_width * cinfoPtr->output_components;
    buffer = (*cinfoPtr->mem->alloc_sarray)
        ((j_common_ptr) cinfoPtr, JPOOL_IMAGE, row_stride, 1);
    
    /*
     * Create 3 matrices, One each for the Red, Green, and Blue componenet of 
     * the image.
     */
    
    dims[0]  = cinfoPtr->output_height;
    dims[1]  = cinfoPtr->output_width;
    dims[2]  = 1;
    
    img = mxCreateNumericArray(2, dims, mxUINT8_CLASS, mxREAL);
    
    
    /*
     * Get pointers to the real part of each matrix (data is stored 
     * in a 1 dimensional double array).
     */
    
    pr_gray   = (uint8_T *) mxGetPr(img);
    
    while (cinfoPtr->output_scanline < cinfoPtr->output_height) {
        current_row=cinfoPtr->output_scanline; /* Temp var won't get ++'d */
        jpeg_read_scanlines(cinfoPtr, buffer,1); /*  by jpeg_read_scanlines */
        for (i=0;i<cinfoPtr->output_width;i++) {     
            j=(i)*cinfoPtr->output_height+current_row;       
            pr_gray[j]   = buffer[0][i];
        }
    }
    return img;
}
