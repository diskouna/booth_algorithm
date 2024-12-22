library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity tb_booth_algorithm is 
end entity;

architecture behavioral of tb_booth_algorithm is
    component booth_algorithm is
        generic (
            A_BITS       : positive := 8;
            B_BITS       : positive := 8
        );
        port (
            clk_i, rst_i    : in  std_logic;
            a_b_valid_i     : in  std_logic;
            a_i             : in  std_logic_vector(A_BITS-1 downto 0);        
            b_i             : in  std_logic_vector(B_BITS-1 downto 0); 
            c_valid_o       : out std_logic;
            c_o             : out std_logic_vector(A_BITS+B_BITS-1 downto 0) 
        );
    end component;

    signal  clk, rst  : std_logic := '1';
    signal  a_b_valid : std_logic := '0';
    signal  c_valid   : std_logic := '0';
    signal  a, b      : std_logic_vector(7 downto 0) := (others => '0');
    signal  c         : std_logic_vector(15 downto 0) := (others => '0');    
begin

    UUT : booth_algorithm generic map (A_BITS => 8, B_BITS => 8)
                          port    map (
                                clk_i       => clk,
                                rst_i       => rst,
                                a_b_valid_i => a_b_valid,
                                a_i         => a,
                                b_i         => b,
                                c_valid_o   => c_valid,
                                c_o         => c
                          );
    
    clk <= not clk after 1 ns;
    rst <= '0'     after 4 ns;

    process
        variable expected_c : std_logic_vector(15 downto 0);
    begin
        -- Test case 1 : Two positive numbers    
        a <= std_logic_vector(to_signed(30, 8));
        b <= std_logic_vector(to_signed(42, 8));
        a_b_valid <= '1';
        expected_c := std_logic_vector(to_signed(1260, 16)); -- 1260 = 
        wait until c_valid = '1';
       
        assert c = expected_c
            report "Test Case 1 Failed: Expected=" 
                   &integer'image(to_integer(signed(expected_c))) &
                   ", Got=" & integer'image(to_integer(signed(c)))
            severity error;
        
        -- Test case 2 : Two negative numbers
        a <= std_logic_vector(to_signed(-3, 8));
        b <= std_logic_vector(to_signed(-4, 8));
        a_b_valid <= '1';
        expected_c := std_logic_vector(to_signed(12, 16));
        wait until c_valid = '1';

        assert c = expected_c
            report "Test Case 2 Failed: Expected=" 
                   &integer'image(to_integer(signed(expected_c))) &
                   ", Got=" & integer'image(to_integer(signed(c)))
            severity error;
        
        -- Test case 3 : Two negative numbers (bis)
        a <= std_logic_vector(to_signed(-30, 8));
        b <= std_logic_vector(to_signed(-42, 8));
        a_b_valid <= '1';
        expected_c := std_logic_vector(to_signed(1260, 16));
        wait until c_valid = '1';
    
        assert c = expected_c
            report "Test Case 3 Failed: Expected=" 
                   &integer'image(to_integer(signed(expected_c))) &
                   ", Got=" & integer'image(to_integer(signed(c)))
            severity error;
        
        -- Test case 4 : Positive and Negative numbers
        a <= std_logic_vector(to_signed(-30, 8));
        b <= std_logic_vector(to_signed( 42, 8));
        a_b_valid <= '1';
        expected_c := std_logic_vector(to_signed(-1260, 16));
        wait until c_valid = '1';

        assert c = expected_c
            report "Test Case 4 Failed: Expected=" 
                   &integer'image(to_integer(signed(expected_c))) &
                   ", Got=" & integer'image(to_integer(signed(c)))
            severity error;

        -- Test case 5 : Zeros
        a <= std_logic_vector(to_signed(0, 8));
        b <= std_logic_vector(to_signed(0, 8));
        a_b_valid <= '1';
        expected_c := std_logic_vector(to_signed(0, 16));
        wait until c_valid = '1';

        assert c = expected_c
            report "Test Case 5 Failed: Expected=" 
                   &integer'image(to_integer(signed(expected_c))) &
                   ", Got=" & integer'image(to_integer(signed(c)))
            severity error;
        
        -- Test case 6 : Min and Max
        a <= std_logic_vector(to_signed(127, 8));
        b <= std_logic_vector(to_signed(-128, 8));
        a_b_valid <= '1';
        expected_c := std_logic_vector(to_signed(-16256, 16));
        wait until c_valid = '1';

        assert c = expected_c
            report "Test Case 6 Failed: Expected=" 
                   &integer'image(to_integer(signed(expected_c))) &
                   ", Got=" & integer'image(to_integer(signed(c)))
            severity error;
        
        -- Test case 7 : Min and Min
        a <= std_logic_vector(to_signed(-128, 8));
        b <= std_logic_vector(to_signed(-128, 8));
        a_b_valid <= '1';
        expected_c := std_logic_vector(to_signed(16384, 16));
        wait until c_valid = '1';

        assert c = expected_c
            report "Test Case 7 Failed: Expected=" 
                   &integer'image(to_integer(signed(expected_c))) &
                   ", Got=" & integer'image(to_integer(signed(c)))
            severity error;

        -- Test case 8 : Max and Max
        a <= std_logic_vector(to_signed(127, 8));
        b <= std_logic_vector(to_signed(127, 8));
        a_b_valid <= '1';
        expected_c := std_logic_vector(to_signed(16129, 16));
        wait until c_valid = '1';

        assert c = expected_c
            report "Test Case 8 Failed: Expected=" 
                   &integer'image(to_integer(signed(expected_c))) &
                   ", Got=" & integer'image(to_integer(signed(c)))
            severity error;
        
        -- Test case 9 : Zero and Max
        a <= std_logic_vector(to_signed(  0, 8));
        b <= std_logic_vector(to_signed(127, 8));
        a_b_valid <= '1';
        expected_c := std_logic_vector(to_signed(0, 16));
        wait until c_valid = '1';

        assert c = expected_c
            report "Test Case 9 Failed: Expected=" 
                   &integer'image(to_integer(signed(expected_c))) &
                   ", Got=" & integer'image(to_integer(signed(c)))
            severity error;

        -- Test case 10 : Zero and Min
        a <= std_logic_vector(to_signed(   0, 8));
        b <= std_logic_vector(to_signed(-128, 8));
        a_b_valid <= '1';
        expected_c := std_logic_vector(to_signed(0, 16));
        wait until c_valid = '1';

        assert c = expected_c
            report "Test Case 10 Failed: Expected=" 
                   &integer'image(to_integer(signed(expected_c))) &
                   ", Got=" & integer'image(to_integer(signed(c)))
            severity error;

        assert false report "Simulation completed" severity note;

        wait;

    end process;

end architecture;
