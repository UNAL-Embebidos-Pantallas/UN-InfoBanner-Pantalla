from litex import RemoteClient
import time

# Create a new instance of RemoteClient
wb = RemoteClient()

# Open a connection to the SoC
wb.open()

# Access SDRAM
wb.write(0x40000000, 0x12345678)
value = wb.read(0x40000000)

# Access SDRAM (with wb.mems and base address)
wb.write(wb.mems.main_ram.base, 0x12345678)
value = wb.read(wb.mems.main_ram.base)

# Trigger a reset of the SoC
wb.regs.ctrl_reset.write(1)

# Dump all CSR registers of the SoC
for name, reg in wb.regs.dict.items():
    print("0x{:08x}: 0x{:08x} {}".format(reg.addr, reg.read(), name))

# Write some values to a specific memory address
wb.write(0xf0000800, 1)
time.sleep(0.5)
wb.write(0xf0000800, 0)
time.sleep(0.5)
wb.write(0xf0000800, 1)

# Close the connection to the SoC
wb.close()