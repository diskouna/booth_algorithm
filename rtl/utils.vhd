library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

package utils is 
    -- clog2 ceilling of log2 
    function clog2(number : positive) return positive;
 
    -- Registers interface 
    constant OP_1_ADDR    : std_logic_vector(4 downto 0) := b"000_00";  
    constant OP_2_ADDR    : std_logic_vector(4 downto 0) := b"001_00";  
    constant RESULT_ADDR  : std_logic_vector(4 downto 0) := b"010_00"; 
    constant CTRL_ADDR    : std_logic_vector(4 downto 0) := b"011_00"; 
    constant STAT_ADDR    : std_logic_vector(4 downto 0) := b"100_00"; 
    constant CORE_ID_ADDR : std_logic_vector(4 downto 0) := b"101_00"; 

    constant CTRL_MASK : std_logic_vector(31 downto 0) := x"0000_0001";
    constant STAT_MASK : std_logic_vector(31 downto 0) := x"0000_0003";
    constant CORE_ID   : std_logic_vector(31 downto 0) := x"0000_0001";  

    constant CTRL_RESET_VALUE : std_logic_vector(31 downto 0) := x"0000_0000";

end package;

package body utils is
    function clog2(number : positive) return positive is
    begin
        return positive(ceil(log2(real(number))));
    end function;
end package body;
