from migen import *
from migen.genlib.cdc import MultiReg
from litex.soc.interconnect.csr import *
from litex.soc.interconnect.csr_eventmanager import *

class RGBDisplay(Module, AutoCSR):
    def __init__(self, lat, sclk, r0, g0, b0, r1, g1, b1, oe, a, b, c, d, e):

        self.clk = ClockSignal()
        self.rst = ResetSignal()

        self.addr_a = CSRStorage(12, name='addr_a')
        self.rgb_indat_a = CSRStorage(32, name='rgb_indat_a')
        self.wr_en = CSRStorage(name='wr_en')
        self.rd_en = CSRStorage(name='rd_en')

        self.sclk, self.lat, self.oe, self.a, self.b, self.c, self.d, self.e = sclk, lat, oe, a, b, c, d, e,
        self.r0, self.g0, self.b0, self.r1, self.g1, self.b1 = r0, g0, b0, r1, g1, b1

        self.specials += Instance("rgb_display",
                            i_clk=self.clk,
                            i_rst=self.rst,
                            i_addr_a = self.addr_a.storage,
                            i_data_in_a = self.rgb_indat_a.storage,
                            i_wr_en=self.wr_en.storage,
                            i_rd_en=self.rd_en.storage,
                            o_sclk = self.sclk,
                            o_lat = self.lat,
                            o_oe = self.oe,
                            o_a = self.a,
                            o_b = self.b,
                            o_c = self.c,
                            o_d = self.d,
                            o_e = self.e,
                            o_r0= self.r0,
                            o_g0= self.g0, 
                            o_b0 = self.b0,
                            o_r1= self.r1,
                            o_g1= self.g1, 
                            o_b1 = self.b1)
        self.submodules.ev = EventManager()
        self.ev.ok = EventSourceProcess()
        self.ev.finalize()