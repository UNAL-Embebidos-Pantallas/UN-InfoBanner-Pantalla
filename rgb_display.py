from migen import *
from migen.genlib.cdc import MultiReg
from litex.soc.interconnect.csr import *
from litex.soc.interconnect.csr_eventmanager import *

class RGBDisplay(Module, AutoCSR):
    def __init__(self, lat, sclk, r0, g0, b0, r1, g1, b1, oe, row):

        self.clk = ClockSignal()
        self.rst = ResetSignal()

        self.sclk, self.lat, self.oe, self.row = sclk, lat, oe, row
        self.r0, self.g0, self.b0, self.r1, self.g1, self.b1 = r0, g0, b0, r1, g1, b1

        self.specials += Instance("rgb_display",
                            i_i_clk=self.clk,
                            i_i_rst=self.rst,
                            o_o_data_clock = self.sclk,
                            o_o_data_latch = self.lat,
                            o_o_data_blank = self.oe,
                            o_o_row_select = self.row,
                            o_r0= self.r0,
                            o_g0= self.g0, 
                            o_b0 = self.b0,
                            o_r1= self.r1,
                            o_g1= self.g1, 
                            o_b1 = self.b1)
        self.submodules.ev = EventManager()
        self.ev.ok = EventSourceProcess()
        self.ev.finalize()