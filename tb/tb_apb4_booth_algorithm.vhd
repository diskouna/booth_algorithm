library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.utils.all;

entity tb_apb4_booth_algorithm is 
end entity;

architecture behavioral of tb_apb4_booth_algorithm is
    component apb4_booth_algorithm is
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
    end component;
    
    signal clk   : std_logic := '0';
    signal rstn   : std_logic := '1';
    
    type booth_if_t is record
        PADDR    :  std_logic_vector(4 downto 2);
        PSEL     :  std_logic; 
        PENABLE  :  std_logic;
        PWRITE   :  std_logic;
        PWDATA   :  std_logic_vector(31 downto 0);
        PREADY   :  std_logic;
        PRDATA   :  std_logic_vector(31 downto 0);
        PSLVERR  :  std_logic;
    end record;

    signal  booth_if_in, booth_if_out : booth_if_t;

    -- BFM procedures 
    procedure set_operands(signal clk_p      : in std_logic;
                           signal core_if_out: in booth_if_t;
                           signal core_if_in : out booth_if_t;
                           constant a_value, b_value : in  integer) is
        variable rdata : std_logic_vector(31 downto 0) := (others => '0');
    begin
        core_if_in.PSEL  <= '1';
        -- Polling core ready flag
        while rdata(0) = '0' loop
            wait until rising_edge(clk_p); -- Setup phase
            core_if_in.PENABLE <= '0';
            core_if_in.PADDR   <= STAT_ADDR;
            core_if_in.PWRITE  <= '0';
            wait until rising_edge(clk_p); -- Access phase 
            core_if_in.PENABLE <= '1';
            wait until rising_edge(clk_p) and core_if_out.PREADY = '1';
            rdata := core_if_out.PRDATA;
            
        end loop;

        -- Write operand a
        --  Setup phase
        core_if_in.PENABLE <= '0';
        core_if_in.PADDR   <= OP_1_ADDR;
        core_if_in.PWDATA  <= std_logic_vector(to_signed(a_value, core_if_in.PWDATA'length));
        core_if_in.PWRITE  <= '1';
        wait until rising_edge(clk_p);
        --  Access phase
        core_if_in.PENABLE <= '1';
        wait until rising_edge(clk_p) and core_if_out.PREADY = '1';
        core_if_in.PWRITE  <= '0';
        
        -- Write operand b
        --  Setup phase
        wait until rising_edge(clk_p);
        core_if_in.PENABLE <= '0';
        core_if_in.PADDR   <= OP_2_ADDR;
        core_if_in.PWDATA  <= std_logic_vector(to_signed(b_value, core_if_in.PWDATA'length));
        core_if_in.PWRITE  <= '1';
        wait until rising_edge(clk_p);
        --  Access phase
        core_if_in.PENABLE <= '1';
        wait until rising_edge(clk_p) and core_if_out.PREADY = '1';
        core_if_in.PWRITE  <= '0';

        -- Write operation enable flag
        --  Setup phase
        wait until rising_edge(clk_p);
        core_if_in.PENABLE <= '0';
        core_if_in.PADDR   <= CTRL_ADDR;
        core_if_in.PWDATA  <= x"0000_0001";
        core_if_in.PWRITE  <= '1';
        wait until rising_edge(clk_p);
        --  Access phase
        core_if_in.PENABLE <= '1';
        wait until rising_edge(clk_p) and core_if_out.PREADY = '1';
        core_if_in.PWRITE  <= '0';

        wait until rising_edge(clk_p);
        core_if_in.PSEL    <= '0';
        core_if_in.PENABLE <= '0';
        core_if_in.PWRITE  <= '0';

        report "Set a=" & integer'image(a_value) & " and b=" & integer'image(b_value)
               severity note;
    end procedure;

    procedure get_result(signal clk_p      : in  std_logic;
                         signal core_if_out: in  booth_if_t;
                         signal core_if_in : out booth_if_t;
                         variable c_value  : out integer) is
        variable overflow : boolean;
    begin
        core_if_in.PSEL <= '1';
        -- Polling result valid flag
        while core_if_out.PRDATA(1) = '0' loop
            --  Setup phase
            wait until rising_edge(clk_p);
            core_if_in.PENABLE <= '0';
            core_if_in.PADDR   <= STAT_ADDR;
            core_if_in.PWRITE  <= '0';
            wait until rising_edge(clk_p);
            --  Access phase
            core_if_in.PENABLE <= '1';
            wait until rising_edge(clk_p) and core_if_out.PREADY = '1';
        end loop;
        -- Read overflow flag
        overflow := (core_if_out.PRDATA(2) = '1');
        -- Read result
        --  Setup phase
        wait until rising_edge(clk_p);
        core_if_in.PENABLE <= '0';
        core_if_in.PADDR   <= RESULT_ADDR;
        core_if_in.PWRITE  <= '0';
        wait until rising_edge(clk_p);
        --  Access phase
        core_if_in.PENABLE <= '1';
        wait until rising_edge(clk_p) and core_if_out.PREADY = '1';
        c_value := to_integer(signed(core_if_out.PRDATA));

        wait until rising_edge(clk_p);
        core_if_in.PSEL  <= '0';

        report "Got c=" & integer'image(to_integer(signed(core_if_out.PRDATA))) & 
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

    UUT : apb4_booth_algorithm port map (
                PCLK    => clk, 
                PRESETn => rstn,
                
                PADDR   => booth_if_in.PADDR,
                PSEL    => booth_if_in.PSEL,
                PENABLE => booth_if_in.PENABLE,
                PWRITE  => booth_if_in.PWRITE,
                PWDATA  => booth_if_in.PWDATA,
                PREADY  => booth_if_out.PREADY,
                PRDATA  => booth_if_out.PRDATA,
                PSLVERR => booth_if_out.PSLVERR
          );

    -- clock generation
    clk <= not clk after 1 ns;
 
    process
        variable actual_c : integer;
    begin
        report "Simulation started" severity note;
        
        rstn <= '0';
        wait for 4 ns;
        rstn <= '1';
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

