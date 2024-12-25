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
            prod_ready_o    : out std_logic;
            a_i             : in  std_logic_vector(A_BITS-1 downto 0);        
            b_i             : in  std_logic_vector(B_BITS-1 downto 0); 
            c_valid_o       : out std_logic;
            cons_ready_i    : in  std_logic;
            c_o             : out std_logic_vector(A_BITS+B_BITS-1 downto 0) 
        );
    end component;
    
    signal clk   : std_logic := '0';
    signal rst   : std_logic := '1';
	signal a_b_valid   : std_logic;
	signal prod_ready  : std_logic;
	signal a, b        : std_logic_vector (7 downto 0);        
	signal c_valid     : std_logic;
	signal cons_ready  : std_logic := '1'; -- output consumer is always ready
	signal c           : std_logic_vector (15 downto 0); 

    -- TODO: use booth_algorithm core interface
    type booth_if_t is record
        clk_i, rst_i    : std_logic;
        a_b_valid_i     : std_logic;
        prod_ready_o    : std_logic;
        a_i, b_i        : std_logic_vector (7 downto 0);        
        c_valid_o       : std_logic;
        cons_ready_i    : std_logic;
        c_o             : std_logic_vector (15 downto 0); 
    end record;
    signal  booth_if : booth_if_t;

    -- BFM procedures    
    procedure set_operands(signal clk : in std_logic;
                           signal a, b : out std_logic_vector;
                           signal a_b_valid : out std_logic;
                           signal pro_ready : in std_logic;
                           constant a_value, b_value : in    integer) is
    begin
        a <= std_logic_vector(to_signed(a_value, a'length));
        b <= std_logic_vector(to_signed(b_value, b'length));
        a_b_valid <= '1';
        wait until rising_edge(clk) and prod_ready = '1'; 
        wait until rising_edge(clk);
        a_b_valid <= '0';
        report "Set a=" & integer'image(a_value) & " and b=" & integer'image(b_value)
               severity note; 
    end procedure; 

    procedure get_result(signal clk : in std_logic;
                         signal c : in std_logic_vector;
                         signal c_valid    : in std_logic;
                         signal cons_ready : in std_logic;
                         variable c_value  : out integer) is
    begin
        wait until rising_edge(clk)  and c_valid = '1' and 
                   cons_ready = '1' ;
        c_value := to_integer(signed(c));
        report "Got c=" & integer'image(to_integer(signed(c))) severity note; 
    end procedure; 

    -- Checking procedure
    procedure check_result(constant result, expected_result : in integer;
                           constant test_case_id : in natural) is
    begin
        assert result = expected_result
            report "Test Case " & integer'image(test_case_id) & " Failed: Expected=" 
                   & integer'image(expected_result) & ", Got=" & integer'image(result)
            severity error;
    end procedure;

begin

    UUT : booth_algorithm generic map (A_BITS => 8, B_BITS => 8)
                          port    map (
                                clk_i        => clk,
                                rst_i        => rst,
                                a_b_valid_i  => a_b_valid,
                                prod_ready_o => prod_ready,   
                                a_i          => a,
                                b_i          => b,
                                c_valid_o    => c_valid,
                                cons_ready_i => cons_ready,
                                c_o          => c
                          );

    -- clock generation
    clk <= not clk after 1 ns;
 
    process
        variable actual_c : integer;
    begin
        report "Simulation started" severity note;
        
        rst <= '1';
        wait for 4 ns;
        rst <= '0';  
        report "Reset generation done" severity note;
        
        -- Test case 1 : Two positive numbers    
        set_operands(clk, a, b, a_b_valid, prod_ready, 30, 42);
        get_result  (clk, c, c_valid, cons_ready, actual_c);
        check_result(result => actual_c, expected_result => 1260, test_case_id => 1);
        
        -- Test case 2 : Two negative numbers
        set_operands(clk, a, b, a_b_valid, prod_ready, -3, -4);
        get_result  (clk, c, c_valid, cons_ready, actual_c);
        check_result(result => actual_c, expected_result => 12, test_case_id => 2);

        -- Test case 3 : Two negative numbers (bis)
        set_operands(clk, a, b, a_b_valid, prod_ready, -30, -42);
        get_result  (clk, c, c_valid, cons_ready, actual_c);
        check_result(result => actual_c, expected_result => 1260, test_case_id => 3);
        
        -- Test case 4 : Positive and Negative numbers
        set_operands(clk, a, b, a_b_valid, prod_ready, -30, 42);
        get_result  (clk, c, c_valid, cons_ready, actual_c);
        check_result(result => actual_c, expected_result => -1260, test_case_id => 4);

        -- Test case 5 : Zeros
        set_operands(clk, a, b, a_b_valid, prod_ready, 0, 0);
        get_result  (clk, c, c_valid, cons_ready, actual_c);
        check_result(result => actual_c, expected_result => 0, test_case_id => 5);
        
        -- Test case 6 : Min and Max
        set_operands(clk, a, b, a_b_valid, prod_ready, 127, -128);
        get_result  (clk, c, c_valid, cons_ready, actual_c);
        check_result(result => actual_c, expected_result => -16256, test_case_id => 6);
        
        -- Test case 7 : Min and Min
        set_operands(clk, a, b, a_b_valid, prod_ready, -128, -128);
        get_result  (clk, c, c_valid, cons_ready, actual_c);
        check_result(result => actual_c, expected_result => 16384 , test_case_id => 7);

        -- Test case 8 : Max and Max
        set_operands(clk, a, b, a_b_valid, prod_ready, 127, 127);
        get_result  (clk, c, c_valid, cons_ready, actual_c);
        check_result(result => actual_c, expected_result => 16129, test_case_id => 8);
        
        -- Test case 9 : Zero and Max
        set_operands(clk, a, b, a_b_valid, prod_ready, 0, 127);
        get_result  (clk, c, c_valid, cons_ready, actual_c);
        check_result(result => actual_c, expected_result => 0, test_case_id => 9);

        -- Test case 10 : Zero and Min
        set_operands(clk, a, b, a_b_valid, prod_ready, 0, -128);
        get_result  (clk, c, c_valid, cons_ready, actual_c);
        check_result(result => actual_c, expected_result => 0, test_case_id => 10);

        report "Simulation completed" severity note;
        wait;

    end process;

end architecture;
