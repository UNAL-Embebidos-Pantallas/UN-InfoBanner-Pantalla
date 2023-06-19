#!/usr/bin/env python3
# Python
import os
import argparse
import sys
import subprocess

# Migen
from migen import * #Python toolbox for building digital hardware
from migen.genlib.resetsync import AsyncResetSynchronizer #For synchronizing asynchronous resets to a clock domain.

#Litex
from litex.build.generic_platform import IOStandard, Subsignal, Pins #Generic interface for connecting peripherals to FPGA pins.
from litex.build.io import DDROutput #Utility functions for working with IO pins on FPGA boards.
from litex_boards.platforms import colorlight_i5 #Platform object for the Colorlight i5 board.
from litex.build.lattice.trellis import trellis_args, trellis_argdict #Lattice Semiconductor Trellis toolchain for FPGA synthesis.
from litex.soc.cores.clock import * #For generating clock signals on the FPGA.
from litex.soc.integration.soc_core import * #Classes for building SoCs with LiteX.
from litex.soc.integration.builder import * #Classes for building SoCs with LiteX.
from litedram.modules import M12L64322A # DRAM memory module compatible with EM638325-6H.
from litedram.phy import GENSDRPHY, HalfRateGENSDRPHY #Physical interface for communicating with DRAM memory.
from litespi.modules import GD25Q16 #For various SPI flash memory modules.
from litespi.opcodes import SpiNorFlashOpCodes as Codes #SPI opcodes for communicating with SPI flash memory.
from liteeth.phy.ecp5rgmii import LiteEthPHYRGMII #Physical interface for communicating with Ethernet PHYs.
from liteeth.phy.rmii import LiteEthPHYRMII
from litex.soc.cores.bitbang import I2CMaster #Software implementation of I2C.
from litedram.common import LiteDRAMNativePort
from litescope import LiteScopeAnalyzer

# Own
from modules.ios import Led
from modules.rgb_display import RGBDisplay

# IOs ------------------------------------------------------------------------
_serial = [
    ("serial", 0,
        Subsignal("tx", Pins("J17")),  # J1.1
        Subsignal("rx", Pins("H18")),  # J1.2
        IOStandard("LVCMOS33")
     ),
]
# _leds = [
#     ("user_led", 0, Pins("U17"), IOStandard("LVCMOS33")),  # LED en la placa
#     ("user_led", 1, Pins("F3"), IOStandard("LVCMOS33")),  # LED externo
# ]

# _i2c = [("i2c", 0,
#             Subsignal("sda",   Pins("C17")),
#             Subsignal("scl",   Pins("B18")),
#             IOStandard("LVCMOS33"),
#         )
# ]

_rgb_matrix = [
        ("lat", 0, Pins("R17"), IOStandard("LVCMOS33")),
        ("sclk", 0, Pins("T18"), IOStandard("LVCMOS33")),
        ("r0", 0, Pins("J20"), IOStandard("LVCMOS33")),
        ("g0", 0, Pins("L18"), IOStandard("LVCMOS33")),
        ("b0", 0, Pins("M18"), IOStandard("LVCMOS33")),
        ("r1", 0, Pins("G20"), IOStandard("LVCMOS33")),
        ("g1", 0, Pins("K20"), IOStandard("LVCMOS33")),
        ("b1", 0, Pins("L20"), IOStandard("LVCMOS33")),
        ("row", 0, Pins("P17"), IOStandard("LVCMOS33")),
        ("row", 1, Pins("R18"), IOStandard("LVCMOS33")),
        ("row", 2, Pins("C18"), IOStandard("LVCMOS33")),
        ("row", 3, Pins("U16"), IOStandard("LVCMOS33")),
        ("row", 4, Pins("U18"), IOStandard("LVCMOS33")),
        ("oe", 0, Pins("M17"), IOStandard("LVCMOS33")),
]

# _serial_debug = [("serial_debug", 0,
#             Subsignal("tx",   Pins("C4")),
#             Subsignal("rx",   Pins("A18")),
#             IOStandard("LVCMOS33"),
#         )
# ]

# CRG -----------------------------------------------------------------------------------------
class _CRG(Module):
    def __init__(
            self, 
            platform, sys_clk_freq, 
            use_internal_osc=False, 
            with_usb_pll=False, 
            with_rst=True, 
            sdram_rate="1:1"):
        self.rst = Signal()
        self.clock_domains.cd_sys = ClockDomain()
        self.clock_domains.cd_sys2x = ClockDomain()
        self.clock_domains.cd_sys2x_ps = ClockDomain()
        clk = platform.request("clk25")
        clk_freq = 25e6
        rst_n = platform.request("cpu_reset_n", 0)
        # PLL (Phase Locked Loop)
        self.submodules.pll = pll = ECP5PLL()
        self.comb += pll.reset.eq(~rst_n | self.rst)
        pll.register_clkin(clk, clk_freq)
        pll.create_clkout(self.cd_sys,    sys_clk_freq)
        pll.create_clkout(self.cd_sys2x,    2*sys_clk_freq)
        pll.create_clkout(self.cd_sys2x_ps, 2*sys_clk_freq, phase=180) # Idealy 90° but needs to be increased.
        # SDRAM clock
        sdram_clk = ClockSignal("sys2x_ps")
        self.specials += DDROutput(1, 0, platform.request("sdram_clock"), sdram_clk)
        
# BaseSoC --------------------------------------------------------------------
class BaseSoC(SoCCore):
    def __init__(self):
        SoCCore.mem_map = {
            "rom":          0x00000000,
            "sram":         0x10000000,
            "main_ram":     0x40000000,
            "csr":          0x82000000,
        }
        platform = colorlight_i5.Platform()
        platform.add_source("./verilog/rgb_display.v")
        sys_clk_freq = int(100e6)
        platform.add_extension(_serial)
        # platform.add_extension(_leds)
        # platform.add_extension(_i2c)
        platform.add_extension(_rgb_matrix)
        # platform.add_extension(_serial_debug)

        # SoC with CPU ------------------------------------------------------------------------------
        SoCCore.__init__(
            self, platform,
            cpu_type                 = "vexriscv",
            clk_freq                 = sys_clk_freq,
            ident                    = "LiteX CPU RGB Matrix", ident_version=True,
            integrated_rom_size      = 0x9000,
            timer_uptime             = True)
        self.submodules.crg = _CRG(
            platform         = platform, 
            sys_clk_freq     = sys_clk_freq,
            use_internal_osc = False,
            with_usb_pll     = False,
            sdram_rate       = "1:1"
        )
        # SDR SDRAM --------------------------------------------------------------------------------
        self.sdrphy = GENSDRPHY(platform.request("sdram"))
        self.add_sdram("sdram",
            phy           = self.sdrphy,
            module        = M12L64322A(sys_clk_freq,  "1:2"),
            origin        = self.mem_map["main_ram"],
            l2_cache_size = 8192,
        )
        # ETHERNET ---------------------------------------------------------------------------------
        self.ethphy = LiteEthPHYRMII(
          clock_pads = self.platform.request("eth_clocks"),
          pads       = self.platform.request("eth"),
          refclk_cd  = None)
        self.add_ethernet(phy=self.ethphy)

        # I2C --------------------------------------------------------------------------------------
        # self.i2c0 = I2CMaster(pads=platform.request("i2c"))
        
        # Led --------------------------------------------------------------------------------------
        # user_leds = Cat(*[platform.request("user_led", i) for i in range(1)])
        # self.submodules.leds = Led(user_leds)
        # self.add_csr("leds")
        
        # SPI FLASH MEMORY -------------------------------------------------------------------------
        # self.add_spi_flash(mode="1x", module=GD25Q16(Codes.READ_1_1_1), with_master=True)  #What is the diference with master=false

        # RGB Matrix Controller --------------------------------------------------------------------
        SoCCore.add_csr(self,"rgb_cntrl")
        row = Cat(*[platform.request("row", i) for i in range(5)])
        self.submodules.rgb_cntrl = RGBDisplay(platform.request("lat"),
                                                         platform.request("sclk"),
                                                         platform.request("r0"),
                                                         platform.request("g0"),
                                                         platform.request("b0"),
                                                         platform.request("r1"),
                                                         platform.request("g1"),
                                                         platform.request("b1"),
                                                         platform.request("oe"),
                                                         row
                                                )
        # Analyze signal of RGBMatrix
        # self.signal_oe = self.rgb_cntrl.oe
        # self.signal_lat = self.rgb_cntrl.lat
        # self.signal_sclk = self.rgb_cntrl.sclk
        # self.signal_r0 = self.rgb_cntrl.r0
        # self.signal_r1 = self.rgb_cntrl.r1
        # self.signal_g0 = self.rgb_cntrl.g0
        # self.signal_g1 = self.rgb_cntrl.g1
        # self.signal_b0 = self.rgb_cntrl.b0
        # self.signal_b1 = self.rgb_cntrl.b1

        # Analyze signal of Ethernet
        # self.signal_tx_eth = self.ethphy.tx.sink
        # self.signal_rx_eth = self.ethphy.rx.source

        # LiteScope Analyzer -----------------------------------------------------------------------
        # analyzer_signals = [
        #   # IBus (could also just added as self.cpu.ibus)
        #   self.cpu.ibus.stb,
        # #   self.cpu.ibus.cyc,
        # #   self.cpu.ibus.adr,
        # #   self.cpu.ibus.we,
        # #   self.cpu.ibus.ack,
        # #   self.cpu.ibus.sel,
        # #   self.cpu.ibus.dat_w,
        # #   self.cpu.ibus.dat_r,
          
        #   # RGB Driver
        #   self.signal_oe,
        #   self.signal_lat,
        #   self.signal_sclk,
        #   self.signal_r0,
        #   self.signal_r1,
        #   self.signal_g0,
        #   self.signal_g1,
        #   self.signal_b0,
        #   self.signal_b1,
        # #   self.signal_tx_eth,
        # #   self.signal_rx_eth,

        #   # DBus (could also just added as self.cpu.dbus)
        # #   self.cpu.dbus.stb,
        # #   self.cpu.dbus.cyc,
        # #   self.cpu.dbus.adr,
        # #   self.cpu.dbus.we,
        # #   self.cpu.dbus.ack,
        # #   self.cpu.dbus.sel,
        # #   self.cpu.dbus.dat_w,
        # #   self.cpu.dbus.dat_r,
        # ]
        # self.submodules.analyzer = LiteScopeAnalyzer(analyzer_signals,
        #     depth        = 1024,
        #     clock_domain = "sys",
        #     samplerate   = sys_clk_freq,
        #     csr_csv      = "analyzer.csv")
        # self.add_csr("analyzer")
        # self.add_uartbone(name="serial_debug", baudrate=115200)
# Build -----------------------------------------------------------------------
soc = BaseSoC()
builder = Builder(soc, output_dir="build", csr_csv="csr.csv", csr_svd="csr.svd", csr_json="csr.json")
builder.build()

#https://github.com/litex-hub/litespi/issues/52