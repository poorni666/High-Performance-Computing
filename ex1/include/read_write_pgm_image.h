#ifndef READ_WRITE_PGM_IMAGE_H
#define READ_WRITE_PGM_IMAGE_H

void write_pgm_image_wrapper(unsigned char *image, int maxval, int xsize, int ysize, const char *image_name);
void read_pgm_image_wrapper(unsigned char **image, int *maxval, int *xsize, int *ysize, const char *image_name);

#endif
