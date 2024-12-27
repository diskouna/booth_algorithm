-- APB4 wrapper for booth_algorithm core

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity apb4_booth_algorithm is
    port (
        PCLK     : in  std_logic; 
        PRESETn  : in  std_logic;
        
        PADDR    : in  std_logic_vector(4 downto 2);
        PSEL     : in  std_logic; 
        PENABLE  : in  std_logic;
        PWRITE   : in  std_logic;
        PWDATA   : in  std_logic_vector(31 downto 0);
        PREADY   : out std_logic;
        PRDATA   : out std_logic_vector(31 downto 0);
        PSLVERR  : out std_logic
    );
end entity;

architecture behavioral of apb4_booth_algorithm is
    component reg_booth_algorithm is
        port (
            clk_i    : in  std_logic; 
            rst_i    : in  std_logic;
            sel_i    : in  std_logic;
            we_i     : in  std_logic; -- 1|0 : write|read
            addr_i   : in  std_logic_vector(4 downto 2); -- 4 bytes aligned addresses
            wdata_i  : in  std_logic_vector(31 downto 0);
            rdata_o  : out std_logic_vector(31 downto 0)
        );
    end component;

    signal reset, we : std_logic;
    
begin

    PREADY  <= '1'; -- RW with no wait states
    PSLVERR <= '0'; 

    reg_booth_algorithm_inst : reg_booth_algorithm port map ( 
                               clk_i   => PCLK,
                               rst_i   => reset,
                               sel_i   => PSEL,
                               we_i    => we,
                               addr_i  => PADDR,
                               wdata_i => PWDATA,
                               rdata_o => PRDATA
                           );

    reset <= not PRESETn;
    we    <= PSEL and (not PENABLE) and PWRITE; -- assert we in SETUP STATE 

end architecture;
