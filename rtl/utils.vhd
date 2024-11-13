library ieee;
use ieee.math_real.all;

package utils is 
    -- clog2 ceilling of log2 
    function clog2(number : positive) return positive;
end package;

package body utils is
    function clog2(number : positive) return positive is
    begin
        return positive(ceil(log2(real(number))));
    end function;
end package body;
