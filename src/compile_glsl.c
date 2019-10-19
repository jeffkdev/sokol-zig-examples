#define SOKOL_GLCORE33
#include "sokol/sokol_gfx.h"
#include "shaders/triangle.glsl.h"
#include "shaders/cube.glsl.h"
// as more tests are added will run into some namespace issues (multiple vs_params_t,etc). might need to make seperate compile*.c files for each one?