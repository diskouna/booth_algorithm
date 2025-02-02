library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.utils.all;

entity tb_reg_booth_algorithm is 
end entity;

architecture behavioral of tb_reg_booth_algorithm is
    component reg_booth_algorithm is
        port (
            clk_i    : in  std_logic; 
            rst_i    : in  std_logic;
            sel_i    : in  std_logic;
            we_i     : in  std_logic; -- 1|0 : write|read
            addr_i   : in  std_logic_vector(4 downto 0); -- 4 bytes aligned addresses
            wdata_i  : in  std_logic_vector(31 downto 0);
            rdata_o  : out std_logic_vector(31 downto 0)
        );
    end component;
    
    signal clk   : std_logic := '0';
    signal rst   : std_logic := '1';
    
    type booth_if_t is record
        sel_i    : std_logic;
        we_i     : std_logic;
        addr_i   : std_logic_vector(4 downto 0);
        wdata_i  : std_logic_vector(31 downto 0);
        rdata_o  : std_logic_vector(31 downto 0);
    end record;

    signal  booth_if_in, booth_if_out : booth_if_t;

    -- BFM procedures 


    procedure set_operands(signal clk_p      : in std_logic;
                           signal core_if_out: in booth_if_t;
                           signal core_if_in : out booth_if_t;
                           constant a_value, b_value : in  integer) is
    begin
        core_if_in.sel_i <= '1';
        -- Read core ready flag
        core_if_in.we_i <= '0';
        core_if_in.addr_i <= STAT_ADDR;
        wait until rising_edge(clk_p) and core_if_out.rdata_o(0) = '1';
        -- Write operand a
        core_if_in.addr_i  <= OP_1_ADDR;
        core_if_in.wdata_i <= std_logic_vector(to_signed(a_value, core_if_in.wdata_i'length)); 
        core_if_in.we_i    <= '1';
        wait until rising_edge(clk_p);
        -- Write operand b
        core_if_in.addr_i  <= OP_2_ADDR;
        core_if_in.wdata_i <= std_logic_vector(to_signed(b_value, core_if_in.wdata_i'length)); 
        core_if_in.we_i    <= '1';
        wait until rising_edge(clk_p);
        -- Write operation enable flag
        core_if_in.addr_i  <= CTRL_ADDR;
        core_if_in.wdata_i <= x"0000_0001"; 
        core_if_in.we_i    <= '1';
        wait until rising_edge(clk_p);
        core_if_in.sel_i <= '0';

        report "Set a=" & integer'image(a_value) & " and b=" & integer'image(b_value)
               severity note; 
    end procedure; 

    procedure get_result(signal clk_p      : in  std_logic;
                         signal core_if_out: in  booth_if_t;
                         signal core_if_in : out booth_if_t;
                         variable c_value  : out integer) is
        variable overflow : boolean := false;
    begin
        core_if_in.sel_i <= '1';
        -- Read result valid flag
        core_if_in.we_i <= '0';
        core_if_in.addr_i <= STAT_ADDR;
        wait until rising_edge(clk_p) and core_if_out.rdata_o(1) = '1';
        -- Read overflow flag
        overflow := (core_if_out.rdata_o(2) = '1'); 
        -- Read result
        core_if_in.we_i <= '0';
        core_if_in.addr_i <= RESULT_ADDR;
        wait until rising_edge(clk_p); 
        c_value := to_integer(signed(core_if_out.rdata_o));
        core_if_in.sel_i <= '0';

        report "Got c=" & integer'image(to_integer(signed(core_if_out.rdata_o))) & 
               "    Overflow : " & boolean'image(overflow)  
            severity note; 
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

    UUT : reg_booth_algorithm port    map (
                                clk_i   => clk,
                                rst_i   => rst,
                                sel_i   => booth_if_in.sel_i,
                                we_i    => booth_if_in.we_i,   
                                addr_i  => booth_if_in.addr_i,
                                wdata_i => booth_if_in.wdata_i,
                                rdata_o => booth_if_out.rdata_o
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
        set_operands(clk, booth_if_out, booth_if_in, 30, 42);
        get_result  (clk, booth_if_out, booth_if_in, actual_c);
        check_result(result => actual_c, expected_result => 1260, test_case_id => 1);
        
        -- Test case 2 : Two negative numbers
        set_operands(clk, booth_if_out, booth_if_in, -3, -4);
        get_result  (clk, booth_if_out, booth_if_in, actual_c);
        check_result(result => actual_c, expected_result => 12, test_case_id => 2);

        -- Test case 3 : Two negative numbers (bis)
        set_operands(clk, booth_if_out, booth_if_in, -30, -42);
        get_result  (clk, booth_if_out, booth_if_in, actual_c);
        check_result(result => actual_c, expected_result => 1260, test_case_id => 3);
        
        -- Test case 4 : Positive and Negative numbers
        set_operands(clk, booth_if_out, booth_if_in, -30, 42);
        get_result  (clk, booth_if_out, booth_if_in, actual_c);
        check_result(result => actual_c, expected_result => -1260, test_case_id => 4);

        -- Test case 5 : Zeros
        set_operands(clk, booth_if_out, booth_if_in, 0, 0);
        get_result  (clk, booth_if_out, booth_if_in, actual_c);
        check_result(result => actual_c, expected_result => 0, test_case_id => 5);
        
        -- Test case 6 : Min and Max
        set_operands(clk, booth_if_out, booth_if_in, 127, -128);
        get_result  (clk, booth_if_out, booth_if_in, actual_c);
        check_result(result => actual_c, expected_result => -16256, test_case_id => 6);
        
        -- Test case 7 : Min and Min
        set_operands(clk, booth_if_out, booth_if_in, -128, -128);
        get_result  (clk, booth_if_out, booth_if_in, actual_c);
        check_result(result => actual_c, expected_result => 16384 , test_case_id => 7);

        -- Test case 8 : Max and Max
        set_operands(clk, booth_if_out, booth_if_in, 127, 127);
        get_result  (clk, booth_if_out, booth_if_in, actual_c);
        check_result(result => actual_c, expected_result => 16129, test_case_id => 8);
        
        -- Test case 9 : Zero and Max
        set_operands(clk, booth_if_out, booth_if_in, 0, 127);
        get_result  (clk, booth_if_out, booth_if_in, actual_c);
        check_result(result => actual_c, expected_result => 0, test_case_id => 9);

        -- Test case 10 : Zero and Min
        set_operands(clk, booth_if_out, booth_if_in, 0, -128);
        get_result  (clk, booth_if_out, booth_if_in, actual_c);
        check_result(result => actual_c, expected_result => 0, test_case_id => 10);

        report "Simulation completed" severity note;
        wait;

    end process;

end architecture;
