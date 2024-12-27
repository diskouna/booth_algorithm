-- Register interface wrapper for booth_algorithm core

-- Programmer model :
--               @[6:0] Mode
-- operand_1_reg : 0x00  RW   a_i[31:0]
-- operand_2_reg : 0x04  RW   b_i[31:0]
-- result_reg    : 0x08  R0   c_o[31:0]
-- control_reg   : 0x0c  RW   ctrl[31:0]
--                                [0] : operation enable  (-> a_b_valid_i) 
--                             [31:1] : unused
-- status_reg    : 0x10  R0   stat[31:0]
--                                [0] : core ready
--                                [1] : result valid 
--                                [2] : result overflow       
--                             [31:3] : unused
-- core_id_reg   : 0x14  R0   core_id[31:0]
--
-- Note : Write to W-registers takes effect iff stat[0] is asserted 
--        Write to R0-registers has no effect
--        result_reg and status_reg are not reset after each operation.
 
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.utils.all;

entity reg_booth_algorithm is
    port (
        clk_i    : in  std_logic; 
        rst_i    : in  std_logic;
        sel_i    : in  std_logic;
        we_i     : in  std_logic; -- 1|0 : write|read
        addr_i   : in  std_logic_vector(4 downto 2); -- 4 bytes aligned addresses
        wdata_i  : in  std_logic_vector(31 downto 0);
        rdata_o  : out std_logic_vector(31 downto 0)
    );
end entity;

architecture behavioral of reg_booth_algorithm is
    component booth_algorithm is
        generic (
            A_BITS      : positive := 8;
            B_BITS      : positive := 8
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
    

    signal op_1_reg   : std_logic_vector(31 downto 0); signal op_1_we   : std_logic;  
    signal op_2_reg   : std_logic_vector(31 downto 0); signal op_2_we   : std_logic;   
    signal result_reg : std_logic_vector(31 downto 0);    
    signal control_reg: std_logic_vector(31 downto 0); signal control_we: std_logic;  
    signal status_reg : std_logic_vector(31 downto 0);   

    signal result : std_logic_vector(63 downto 0);
    signal result_valid : std_logic;
    signal core_ready : std_logic;
    signal overflow : std_logic;
begin

    core_booth_algorithm : booth_algorithm generic map (
                                A_BITS=>32, B_BITS=>32
                           ) port map(
                                clk_i        => clk_i,
                                rst_i        => rst_i,
                                a_b_valid_i  => control_reg(0),   
                                prod_ready_o => core_ready, 
                                a_i          => op_1_reg, 
                                b_i          => op_2_reg, 
                                c_valid_o    => result_valid,
                                cons_ready_i => '1', 
                                c_o          => result 
                           );

    overflow <= '0'; --TODO: Fix me

    -- Addresses decoder 
    process(sel_i, we_i, addr_i, core_ready, 
        op_1_reg, op_2_reg, result_reg, control_reg, status_reg)
    begin
        op_1_we    <= '0'; 
        op_2_we    <= '0';
        control_we <= '0';
        rdata_o    <= (others=>'0');

        if (sel_i = '1') then
            if (we_i = '1') then -- Write
                if (core_ready = '1') then
                    case (addr_i) is
                        when (OP_1_ADDR) => op_1_we    <= '1';
                        when (OP_2_ADDR) => op_2_we    <= '1';
                        when (CTRL_ADDR) => control_we <= '1';
                        when others      => null;
                    end case;
                end if;
            else           -- Read
                case (addr_i) is
                    when (OP_1_ADDR   ) => rdata_o <= op_1_reg;  
                    when (OP_2_ADDR   ) => rdata_o <= op_2_reg;  
                    when (RESULT_ADDR ) => rdata_o <= result_reg; 
                    when (CTRL_ADDR   ) => rdata_o <= control_reg; 
                    when (STAT_ADDR   ) => rdata_o <= status_reg; 
                    when (CORE_ID_ADDR) => rdata_o <= CORE_ID;
                    when others         => null; 
                end case;
            end if;
        end if;
    end process; 
    
    -- Registers update
    process (clk_i)
    begin
        if (rising_edge(clk_i)) then
            if (rst_i = '1') then
                op_1_reg    <= (others => '0'); 
                op_2_reg    <= (others => '0'); 
                result_reg  <= (others => '0'); 
                control_reg <= (others => '0'); 
                status_reg  <= (others => '0');  
            else
                if (op_1_we = '1') then op_1_reg <= wdata_i; end if;
                if (op_2_we = '1') then op_2_reg <= wdata_i; end if; 
                if (control_we = '1') then 
                    control_reg <= wdata_i AND CTRL_MASK; 
                else
                    control_reg <= CTRL_RESET_VALUE;
                end if;
                status_reg <= x"0000_000" & b"0" & overflow & result_valid & core_ready; 
                if (result_valid = '1') then result_reg <= result (31 downto 0); end if;
            end if;
        end if;
    end process;

end architecture;
