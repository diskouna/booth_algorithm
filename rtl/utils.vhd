library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

package utils is 
    -- clog2 ceilling of log2 
    function clog2(number : positive) return positive;
 
    -- Registers interface 
    constant OP_1_ADDR    : std_logic_vector(4 downto 2) := b"000";  
    constant OP_2_ADDR    : std_logic_vector(4 downto 2) := b"001";  
    constant RESULT_ADDR  : std_logic_vector(4 downto 2) := b"010"; 
    constant CTRL_ADDR    : std_logic_vector(4 downto 2) := b"011"; 
    constant STAT_ADDR    : std_logic_vector(4 downto 2) := b"100"; 
    constant CORE_ID_ADDR : std_logic_vector(4 downto 2) := b"101"; 
    
    constant CTRL_MASK : std_logic_vector(31 downto 0) := x"0000_0001";
    constant STAT_MASK : std_logic_vector(31 downto 0) := x"0000_0003";
    constant CORE_ID   : std_logic_vector(31 downto 0) := x"0000_0001";  

end package;

package body utils is
    function clog2(number : positive) return positive is
    begin
        return positive(ceil(log2(real(number))));
    end function;
end package body;
