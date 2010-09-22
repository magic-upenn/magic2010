MATLAB mex file to access UVC cameras on Linux.
Files in this directory:

v4l2.cpp: Low-level Video4Linux2 API routines
uvcCam.cpp: Mex source code that calls v4l2 functions

Usage in MATLAB:

uvcCam('init')

uvcCam('stream_on')

uvcCam('set_ctrl', 'control_name', value);
val = uvcCam('get_ctrl', 'control_name');
...

im = uvcCam('read');  % YUYV integer packed format

uvcCam('stream_off')


