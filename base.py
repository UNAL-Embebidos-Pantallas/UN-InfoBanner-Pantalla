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
from litex.soc.cores.bitbang import I2CMaster #Software implementation of I2C.
from litedram.common import LiteDRAMNativePort

# Own
from ios import Led
from rgb_matrix_controller import RGBMatrix_Controller

# IOs ------------------------------------------------------------------------
_serial = [
    ("serial", 0,
        Subsignal("tx", Pins("J17")),  # J1.1
        Subsignal("rx", Pins("H18")),  # J1.2
        IOStandard("LVCMOS33")
     ),
]
_leds = [
    ("user_led", 0, Pins("U17"), IOStandard("LVCMOS33")),  # LED en la placa
    ("user_led", 1, Pins("F3"), IOStandard("LVCMOS33")),  # LED externo
]

_i2c = [("i2c", 0,
            Subsignal("sda",   Pins("C17")),
            Subsignal("scl",   Pins("B18")),
            IOStandard("LVCMOS33"),
        )
]

_rgb_matrix = [
        ("latch", 0, Pins("R17"), IOStandard("LVCMOS33")),
        ("sclk", 0, Pins("T18"), IOStandard("LVCMOS33")),
        ("address_row", 0, Pins("P17"), IOStandard("LVCMOS33")),
        ("address_row", 1, Pins("R18"), IOStandard("LVCMOS33")),
        ("address_row", 2, Pins("C18"), IOStandard("LVCMOS33")),
        ("address_row", 3, Pins("U16"), IOStandard("LVCMOS33")),
        ("R0", 0, Pins("J20"), IOStandard("LVCMOS33")),
        ("G0", 0, Pins("L18"), IOStandard("LVCMOS33")),
        ("B0", 0, Pins("L18"), IOStandard("LVCMOS33")),
        ("R1", 0, Pins("G20"), IOStandard("LVCMOS33")),
        ("G1", 0, Pins("K20"), IOStandard("LVCMOS33")),
        ("B1", 0, Pins("L20"), IOStandard("LVCMOS33")),
        ("blank", 0, Pins("M17"), IOStandard("LVCMOS33")),
]
        
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
        platform.add_source("./rgb_matrix_controller.v")
        sys_clk_freq = int(100e6)
        platform.add_extension(_serial)
        platform.add_extension(_leds)
        platform.add_extension(_i2c)
        platform.add_extension(_rgb_matrix)

        # SoC with CPU ------------------------------------------------------------------------------
        SoCCore.__init__(
            self, platform,
            cpu_type                 = "vexriscv",
            clk_freq                 = sys_clk_freq,
            ident                    = "LiteX CPU RGB Matrix", ident_version=True,
            integrated_rom_size      = 0x10000,
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
        self.ethphy = LiteEthPHYRGMII(
          clock_pads = self.platform.request("eth_clocks", 0),
          pads       = self.platform.request("eth", 0),
          tx_delay = 0)
        self.add_ethernet(phy=self.ethphy)

        # I2C --------------------------------------------------------------------------------------
        self.i2c0 = I2CMaster(pads=platform.request("i2c"))
        
        # Led --------------------------------------------------------------------------------------
        user_leds = Cat(*[platform.request("user_led", i) for i in range(1)])
        self.submodules.leds = Led(user_leds)
        self.add_csr("leds")
        
        # SPI FLASH MEMORY -------------------------------------------------------------------------
        self.add_spi_flash(mode="1x", module=GD25Q16(Codes.READ_1_1_1), with_master=True)  #What is the diference with master=false

        # RGB Matrix Controller
        address_row = Cat(*[platform.request("address_row", i) for i in range(4)])
        self.submodules.rgb_cntrl = RGBMatrix_Controller(platform.request("latch"),
                                                         platform.request("sclk"),
                                                         platform.request("R0"),
                                                         platform.request("G0"),
                                                         platform.request("B0"),
                                                         platform.request("R1"),
                                                         platform.request("G1"),
                                                         platform.request("B1"),
                                                         address_row,
                                                         platform.request("blank"))
        self.add_csr("rgb_cntrl")

# Build -----------------------------------------------------------------------
soc = BaseSoC()
builder = Builder(soc, output_dir="build", csr_csv="csr.csv", csr_svd="csr.svd", csr_json="csr.json")
builder.build()

#https://github.com/litex-hub/litespi/issues/52