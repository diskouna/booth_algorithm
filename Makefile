
SRC = rtl/utils.vhd 
SRC += rtl/booth_algorithm.vhd tb/tb_booth_algorithm.vhd 
SRC += rtl/reg_booth_algorithm.vhd tb/tb_reg_booth_algorithm.vhd
SRC += rtl/apb4_booth_algorithm.vhd tb/tb_apb4_booth_algorithm.vhd
TOP_LEVEL ?= tb_booth_algorithm

all: ${SRC}
	@mkdir -p build && cd build  && rm -rf   && \
	ghdl -a --std=93 $(addprefix ../, $^)    && \
	ghdl -e ${TOP_LEVEL}                     && \
	ghdl -r ${TOP_LEVEL} --wave=signals.ghw --stop-time=10us
clean:
	@rm -rf build

.PHONY: all clean
