val spinalVersion = "dev"

lazy val root = (project in file(".")).
  settings(
    inThisBuild(List(
      organization := "com.github.spinalhdl",
      scalaVersion := "2.11.12",
      version      := "2.0.0"
    )),
    scalacOptions +=  s"-Xplugin:${new File(baseDirectory.value + s"/../deps/SpinalHDL/idslplugin/target/scala-2.11/spinalhdl-idsl-plugin_2.11-$spinalVersion.jar")}",
    scalacOptions += s"-Xplugin-require:idsl-plugin",
    libraryDependencies ++= Seq(
      "org.scalatest" %% "scalatest" % "3.2.5",
      "org.yaml" % "snakeyaml" % "1.8"
    ),
    name := "VexRiscv"
  ).dependsOn(spinalHdlIdslPlugin, spinalHdlSim,spinalHdlCore,spinalHdlLib,vexRiscv)
lazy val spinalHdlIdslPlugin = ProjectRef(file("../deps/SpinalHDL"), "idslplugin")
lazy val spinalHdlSim = ProjectRef(file("../deps/SpinalHDL"), "sim")
lazy val spinalHdlCore = ProjectRef(file("../deps/SpinalHDL"), "core")
lazy val spinalHdlLib = ProjectRef(file("../deps/SpinalHDL"), "lib")
lazy val vexRiscv = RootProject(file("../deps/VexRiscv"))

fork := true
