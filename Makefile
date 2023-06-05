TARGET       = colorlight_i5
TOP          = cain_test
GATE_DIR     = build/gateware
SOFT_DIR     = build/software
LITEX_DIR    = /home/xhapa/Documents/EMBEDDED/Litex/
#RTL_CPU_DIR = ${LITEX_DIR}/pythondata-cpu-vexriscv/pythondata_cpu_vexriscv/verilog
RTL_CPU_DIR  = ${LITEX_DIR}/pythondata-cpu-lm32/pythondata_cpu_lm32/verilog/rtl/
ZEPHYR_DIR   = /home/xhapa/zephyrproject/
LITEX_DIR    = /home/xhapa/Documents/EMBEDDED/Litex/
WORK_DIR     = /home/xhapa/Documents/EMBEDDED/Zephyr_Litex/
SERIAL       = /dev/ttyACM0

SERIAL?=/dev/ttyUSB0

# Poner la dirección ip de la omega2 para poder conectarse a ella desde ssh
# o agregarlo en la línea de comandos ejemplo: make IP=x.x.x.x
IP_OMEGA?=192.168.3.1

# Poner el directorio destino de la omega2 para subir el bitstream, el lugar ideal es aquel donde tenga el script program.sh
# o agregarlo en la línea de comandos ejemplo: make IP=/root/
PATH_DEST?=/root/

NEXTPNR=nextpnr-ecp5
CC=riscv32-unknown-elf-gcc

all: gateware firmware

gateware:
	./base.py

firmware: 
	$(MAKE) -C firmware/ -f Makefile all

overlay:
	${LITEX_DIR}/litex/litex/tools/litex_json2dts_zephyr.py --dts overlay.dts --config overlay.config csr.json
app_zephyr: overlay
	west build -b litex_vexriscv ${ZEPHYR_DIR}/zephyr/samples/subsys/shell/shell_module/  -DDTC_OVERLAY_FILE=${WORK_DIR}overlay.dts	

configure: app_zephyr
	sudo openFPGALoader -b colorlight-i5 -m ${GATE_DIR}/${TARGET}.bit 

load_zephyr_app:
	litex_term ${SERIAL} --kernel ${WORK_DIR}/build/zephyr/zephyr.bin
	
litex_term: configure
	litex_term ${SERIAL} --kernel firmware/firmware.bin

${TARGET}.svg: 
	#yosys -p "prep -top ${TOP}; write_json ${GATE_DIR}/${TARGET}_LOGIC_svg.json" ${GATE_DIR}/${TOP}.v ${RTL_CPU_DIR}/VexRiscv.v   #TOP_LEVEL_DIAGRAM
	yosys -p "prep -top ${TOP}; write_json ${GATE_DIR}/${TARGET}_LOGIC_svg.json" ${GATE_DIR}/${TOP}.v ${RTL_CPU_DIR}/lm32_top.v
	netlistsvg ${GATE_DIR}/${TARGET}.json -o ${TARGET}.svg  #--skin default.svg
	#yosys -p "prep -top ${TOP} -flatten; write_json ${GATE_DIR}/${TARGET}_LOGIC_svg.json" ${GATE_DIR}/${TOP}.v ${RTL_CPU_DIR}/VexRiscv.v    #TOP_LEVEL_DIAGRAM
	#netlistsvg ${GATE_DIR}/${TARGET}_LOGIC_svg.json -o ${TARGET}_LOGIC.svg  #--skin default.svg	

gateware-clean:
	rm -f ${GATE_DIR}/*.svf ${GATE_DIR}/*.bit ${GATE_DIR}/*.config ${GATE_DIR}/*.json ${GATE_DIR}/*.ys *svg

firmware-clean:
	make -C firmware -f Makefile clean
	
zephyr-clean:
	rm -rf build __pycache__ overlay.* csr.* *.json 

clean: firmware-clean gateware-clean

.PHONY: clean

# conda activate fpga
# source ${ZEPHYR_DIR}/zephyr/zephyr-env.sh 



