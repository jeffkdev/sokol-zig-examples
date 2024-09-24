
import os
import subprocess
exe_path = "sokol-shdc.exe"
src_path = "./"
out_path = src_path


def main():
  shaders = ["cube","triangle","instancing"]
  print("Add to build.zig:")
  for shader in shaders:
    # Build shaders for all backends
    config =  " --input " + src_path + shader + ".glsl" +" --output " + out_path + shader +".glsl.h" + " --slang glsl430:metal_macos:hlsl5:glsl300es:wgsl --format sokol_impl"
    # Can also just target specific backend
    #config =  " --input " + src_path + shader + ".glsl" +" --output " + out_path + shader +".glsl.h" + " --slang glsl430 --format sokol_impl"
    cmd = exe_path + config
    subprocess.check_call(cmd)
    cfile = shader + "_compile.c"
    with open(cfile, 'w') as filetowrite:
        filetowrite.write('#define SOKOL_SHDC_IMPL\n')
        filetowrite.write('#include "sokol/sokol_gfx.h"\n')
        filetowrite.write('#include "shaders/' + shader + '.glsl.h"\n')
    print('    exe.addCSourceFile("src/shaders/' + cfile +'", [_][]const u8{"-std=c99"});')

if __name__== "__main__":
  main()