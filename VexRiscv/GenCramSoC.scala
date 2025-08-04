package vexriscv

import spinal.core._
import spinal.core.internals.{ExpressionContainer, PhaseAllocateNames, PhaseContext, MemTopology}
import spinal.lib._
import vexriscv.ip.{DataCacheConfig, InstructionCacheConfig}
import vexriscv.plugin.CsrAccess.WRITE_ONLY
import vexriscv.plugin._
import spinal.lib.com.jtag.Jtag
import spinal.lib.bus.amba4.axi.Axi4ReadOnly
import spinal.lib.eda.altera.{InterruptReceiverTag, ResetEmitterTag}

import scala.collection.mutable.ArrayBuffer

import spinal.core.internals._

// questions:
//  - MMUplugin - iorange specifier. How are the IO treated differently? Does this control the caching behavior?


object CramSoCSpinalConfig extends spinal.core.SpinalConfig(
  defaultConfigForClockDomains = ClockDomainConfig(
    resetKind = spinal.core.SYNC
  )
){
  //Insert a compilation phase which will add a  (* ram_style = "block" *) on all synchronous rams.
  phasesInserters += {(array) => array.insert(array.indexWhere(_.isInstanceOf[PhaseAllocateNames]) + 1, new CramSoCForceRamBlockPhase)}
}


case class CramSoCArgConfig(
  externalInterruptArray : Boolean = true,
  prediction : BranchPrediction = STATIC,
  outputFile : String = "VexRiscv",
  hardwareBreakpointCount : Int = 4
)

object blackboxSyncOnly extends MemBlackboxingPolicy {
  override def translationInterest(topology: MemTopology): Boolean = {
    if(topology.readsAsync.exists(_.readUnderWrite != writeFirst))                 return false
    return true
  }

  override def onUnblackboxable(topology: MemTopology, who: Any, message: String): Unit = {}
}

object GenCramSoC{
  def main(args: Array[String]) {

    // Allow arguments to be passed ex:
    // sbt compile "run-main vexriscv.GenCoreDefault -d --iCacheSize=1024"
    val parser = new scopt.OptionParser[CramSoCArgConfig]("VexRiscvGen") {
      //  ex :-d    or   --debug
      opt[String]("outputFile")    action { (v, c) => c.copy(outputFile = v) } text("output file name")
    }
    val argConfig = parser.parse(args, CramSoCArgConfig()).get

    val config = CramSoCSpinalConfig
    .copy(netlistFileName = argConfig.outputFile + ".v")
    .addStandardMemBlackboxing(blackboxSyncOnly)
    config.memBlackBoxers += new PhaseNetlist {
      override def impl(pc: PhaseContext): Unit = {
        val topPatch = pc.topLevel rework new AreaRoot{
          val CMBIST, CMATPG = in Bool()
          val sramtrm = in UInt(3 bits)
        }
        pc.walkComponents{
          case c : Ram_1w_1rs => {
            c.rework {
              topPatch.CMBIST.pull(propagateName = true)
              topPatch.CMATPG.pull(propagateName = true)
              topPatch.sramtrm.pull(propagateName = true)
            }
            // c.genericElements.clear()
            c.addGeneric("ramname", s"RAM_DP_${c.wordCount}_${c.wordWidth}")
            // c.addGeneric("ramname", "test")
          }
          case _ =>
        }
      }
    }
    config
    .generateVerilog {
      // Generate CPU plugin list
      val cpuConfig = VexRiscvConfig(
        plugins = List(
          new IBusCachedPlugin(
            prediction = STATIC,
            resetVector = null,
            compressedGen = true,
            injectorStage = false,
            config = InstructionCacheConfig(
              cacheSize = 4096*4,
              bytePerLine = 32,
              wayCount = 4,
              addressWidth = 32,
              cpuDataWidth = 32,
              memDataWidth = 64,
              catchIllegalAccess = true,
              catchAccessFault = true,
              asyncTagMemory = false,
              twoCycleRam = false,
              twoCycleCache = true // ASK: what is the tradeoff here
            ),
            memoryTranslatorPortConfig = true generate MmuPortConfig(
              portTlbSize = 8 // TWEAK: 4, 6, or 8
            )
          ),
          new DBusCachedPlugin(
            dBusCmdMasterPipe = true,
            dBusCmdSlavePipe = true,
            dBusRspSlavePipe = true,
            config = new DataCacheConfig(
              cacheSize         = 4096*4,
              bytePerLine       = 32,
              wayCount          = 4,
              addressWidth      = 32,
              cpuDataWidth      = 32,
              memDataWidth      = 32,
              catchAccessError  = true,
              catchIllegal      = true,
              catchUnaligned    = true,
              withExclusive = false,
              withInvalidate = false,
              withLrSc = true,
              withAmo = true
            ),
            memoryTranslatorPortConfig = true generate MmuPortConfig(
              portTlbSize = 8
            ),
            csrInfo = true
          ),

          new DecoderSimplePlugin(
            catchIllegalInstruction = true
          ),
          new RegFilePlugin(
            regFileReadyKind = plugin.ASYNC,
            x0Init = true, // required to avoid FPGA-specific initializations
            zeroBoot = false
          ),
          new IntAluPlugin,
          new SrcPlugin(
            separatedAddSub = false,
            executeInsertion = true
          ),
          new FullBarrelShifterPlugin(earlyInjection = false),
          new HazardSimplePlugin(
            bypassExecute           = true,
            bypassMemory            = true,
            bypassWriteBack         = true,
            bypassWriteBackBuffer   = true,
            pessimisticUseSrc       = false,
            pessimisticWriteRegFile = false,
            pessimisticAddressMatch = false
          ),
          new MulPlugin,
          new DivPlugin,
          new AesZknPlugin,
          new CsrPlugin(
              CsrPluginConfig.linuxFull(mtVecInit = 0x60000000)
              .copy(ebreakGen = true)
              .copy(pipelineCsrRead = true)
              .copy(wfiOutput = true)
              .copy(exportPrivilege = true)
          ),
          new BranchPlugin(
            earlyBranch = false,
            catchAddressMisaligned = true
          ),
          new MmuPlugin( // sets non-cacheable regions
              ioRange = (
                x => x(31 downto 28) === 0x4
                || x(31 downto 28) === 0x5
                || x(31 downto 28) === 0xA
                || x(31 downto 28) === 0xB
                || x(31 downto 28) === 0xC
                || x(31 downto 28) === 0xD
                || x(31 downto 28) === 0xE
                || x(31 downto 28) === 0xF
                ),
              exportSatp = true
          ),
          new ExternalInterruptArrayPlugin(
            machineMaskCsrId = 0xBC0,
            machinePendingsCsrId = 0xFC0,
            supervisorMaskCsrId = 0x9C0,
            supervisorPendingsCsrId = 0xDC0
          ),
          new YamlPlugin(argConfig.outputFile.concat(".yaml")),
          new DebugPlugin(
            ClockDomain.current.clone(reset = Bool().setName("debugReset")),
            hardwareBreakpointCount = 4
          )
        )
      )

      // CPU instantiation
      val cpu = new VexRiscv(cpuConfig)

      // CPU modifications
      cpu.setDefinitionName("VexRiscvAxi4")
      cpu.rework {
        var iBus : Axi4ReadOnly = null
        for (plugin <- cpuConfig.plugins) plugin match {
          case plugin: IBusSimplePlugin => {
            plugin.iBus.setAsDirectionLess() //Unset IO properties of iBus
            iBus = master(plugin.iBus.toAxi4ReadOnly().toFullConfig())
              .setName("iBusAxi")
              .addTag(ClockDomainTag(ClockDomain.current)) //Specify a clock domain to the iBus (used by QSysify)
          }
          case plugin: IBusCachedPlugin => {
            plugin.iBus.setAsDirectionLess() //Unset IO properties of iBus
            iBus = master(plugin.iBus.toAxi4ReadOnly().toFullConfig())
              .setName("iBusAxi")
              .addTag(ClockDomainTag(ClockDomain.current)) //Specify a clock domain to the iBus (used by QSysify)
          }
          case plugin: DBusSimplePlugin => {
            plugin.dBus.setAsDirectionLess()
            master(plugin.dBus.toAxi4Shared().toAxi4().toFullConfig())
              .setName("dBusAxi")
              .addTag(ClockDomainTag(ClockDomain.current))
          }
          case plugin: DBusCachedPlugin => {
            plugin.dBus.setAsDirectionLess()
            master(plugin.dBus.toAxi4Shared().toAxi4().toFullConfig())
              .setName("dBusAxi")
              .addTag(ClockDomainTag(ClockDomain.current))
          }
          case plugin: DebugPlugin => plugin.debugClockDomain {
            plugin.io.bus.setAsDirectionLess()
            val jtag = slave(new Jtag())
              .setName("jtag")
            jtag <> plugin.io.bus.fromJtag()
          }
          case plugin: CsrPlugin => {
            // plugin.printCsr()
          }
          case _ =>
        }
      }
      cpu
    }
  }
}

class CramSoCForceRamBlockPhase() extends spinal.core.internals.Phase{
  override def impl(pc: PhaseContext): Unit = {
    pc.walkBaseNodes{
      case mem: Mem[_] => {
        var asyncRead = false
        mem.dlcForeach[MemPortStatement]{
          case _ : MemReadAsync => asyncRead = true
          case _ =>
        }
        if(!asyncRead) mem.addAttribute("ram_style", "block")
      }
      case _ =>
    }
  }
  override def hasNetlistImpact: Boolean = false
}
