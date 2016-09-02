import nake

const
  ExeName = "client"
  Features = ""

task "debug-build", "Debug build":
    shell(nimExe, "c", Features, "-d:debug", ExeName)

task "release-build", "Debug build":
  shell(nimExe, "c", Features, "-d:release", ExeName)
