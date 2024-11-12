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
    
    clk <= not clk after 10 ns;
    rst <= '0'     after 40 ns;

    a <= std_logic_vector(to_signed( 3, 8));
    b <= std_logic_vector(to_signed(-4, 8));
    a_b_valid <= '1';

end architecture;
