import nake

const
  ExeName = "client"
  Features = ""

task "debug-build", "Debug build":
    shell(nimExe, "c", Features, "-d:debug", ExeName)
