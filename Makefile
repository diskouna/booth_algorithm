SRC = rtl/utils.vhd 
SRC += rtl/booth_algorithm.vhd tb/tb_booth_algorithm.vhd 

all: ${SRC}
	@mkdir -p build && cd build  && rm -rf   && \
	ghdl -a --std=93 $(addprefix ../, $^)    && \
	ghdl -e tb_booth_algorithm               && \
	ghdl -r tb_booth_algorithm --wave=signals.ghw --stop-time=1us
clean:
	@rm -rf build

.PHONY: all clean
