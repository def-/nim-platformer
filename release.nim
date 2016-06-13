import os, strfmt

const
  app = "platformer"
  version = "1.0"

  builds = [
    (name: "linux_x86", os: "linux", cpu: "i386",
     args: "--passC:-m32 --passL:-m32"),
    (name: "linux_x86_64", os: "linux", cpu: "amd64",
     args: "--passC:-Iglibc-hack"),
    (name: "win32", os: "windows", cpu: "i386",
     args: "--gcc.exe:i686-w64-mingw32-gcc --gcc.linkerexe:i686-w64-mingw32-gcc"),
    (name: "win64", os: "windows", cpu: "amd64",
     args: "--gcc.exe:x86_64-w64-mingw32-gcc --gcc.linkerexe:x86_64-w64-mingw32-gcc"),
  ]

removeDir "builds"

for name, os, cpu, args in builds.items:
  let
    dirName = app & "_" & version & "_" & name
    dir = "builds" / dirName
    exeExt = if os == "windows": ".exe" else: ""
    bin = dir / app & exeExt

  createDir dir
  if execShellCmd(interp"nim --cpu:${cpu} --os:${os} ${args} -d:release -o:${bin} c ${app}") != 0: quit 1
  if execShellCmd(interp"strip -s ${bin}") != 0: quit 1
  copyDir("data", dir / "data")
  if os == "windows": copyDir("libs" / name, dir)
  setCurrentDir "builds"
  if os == "windows":
    if execShellCmd(interp"zip -9r ${dirName}.zip ${dirName}") != 0: quit 1
  else:
    if execShellCmd(interp"tar cfz ${dirName}.tar.gz ${dirName}") != 0: quit 1
  setCurrentDir ".."
