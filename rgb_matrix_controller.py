from migen import *
from migen.genlib.cdc import MultiReg
from litex.soc.interconnect.csr import *
from litex.soc.interconnect.csr_eventmanager import *

class RGBMatrix_Controller(Module, AutoCSR):
    def __init__(self, latch, sclk, R0, G0, B0, R1, G1, B1, address_row, blank):
        self.clk = ClockSignal() 
        self.wr_enable = CSRStorage(1)
        self.rst = CSRStorage(1)
        self.RGB_data = CSRStatus(12)

        self.sclk = sclk
        self.blank = blank
        self.LATCH = latch
        self.address_row = address_row
        self.R0, self.G0, self.B0 = R0, G0, B0
        self.R1, self.G1, self.B1 = R1, G1, B1

        self.specials += Instance("rgb_matrix_controller",
                            i_clk=self.clk,
                            i_wr_enable=self.wr_enable.storage,
                            i_rst=self.rst.storage,
                            i_RGB_data = self.RGB_data.status,
                            o_sclk = self.sclk,
                            o_latch = self.LATCH,
                            o_blank = self.blank,
                            o_address_row = self.address_row,
                            o_R0= self.R0,
                            o_G0= self.G0, 
                            o_B0 = self.B0,
                            o_R1= self.R1,
                            o_G1= self.G1, 
                            o_B1 = self.B1)