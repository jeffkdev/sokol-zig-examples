
import os
import subprocess
exe_path = "sokol-shdc.exe"
src_path = "./"
out_path = src_path


def main():
  shaders = ["cube","triangle","instancing"]
  print("Add to compile_sokol.c and sokol.h")
  print('#define SOKOL_SHDC_IMPL')
  for shader in shaders:
    # Build shaders for all backends
    config =  " --input " + src_path + shader + ".glsl" +" --output " + out_path + shader +".glsl.h" + " --slang glsl430:metal_macos:hlsl5:glsl300es:wgsl --format sokol_impl"
    config =  " --input " + src_path + shader + ".glsl" +" --output " + out_path + shader +".glsl.h" + " --slang glsl430:glsl300es --format sokol_impl"
    # Can also just target specific backend
    #config =  " --input " + src_path + shader + ".glsl" +" --output " + out_path + shader +".glsl.h" + " --slang glsl430 --format sokol_impl"
    cmd = exe_path + config
    subprocess.check_call(cmd)
    print('#include "shaders/' + shader + '.glsl.h"')

if __name__== "__main__":
  main()