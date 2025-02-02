-- Compute c_i = a_i * b_i using Booth's algorithm
-- Note : Numbers a_i, b_i and c_i are encoded in 2's complement
--

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.utils.all;

entity booth_algorithm is
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
end entity;

architecture behavioral of booth_algorithm is 
    type state_t is (IDLE, START, ONES_START, ONES_OR_ZEROS_STREAM, ZEROS_START, DONE); 
    signal cur_state, nxt_state : state_t;

    signal ext_pos_a : std_logic_vector(A_BITS+B_BITS+1 downto 0); 
    signal ext_neg_a : std_logic_vector(A_BITS+B_BITS+1 downto 0); 
    
    -- Accumulator
    signal accumulator : std_logic_vector(A_BITS+B_BITS+1 downto 0); 
    signal load_accumulator  : std_logic := '0';
    signal shift_accumulator : std_logic := '0';
    signal add_multiplicand  : std_logic := '0';
    signal sub_multiplicand  : std_logic := '0';

    -- Counter
    signal init_counter, incr_counter : std_logic := '0';
    signal counter     : std_logic_vector(clog2(B_BITS+1)-1 downto 0)  := (others => '0');
    signal end_of_loop : std_logic := '0';

    signal start_of_ones, start_of_zeros : std_logic := '0';

begin

    -- DATAPATH

    ext_pos_a(A_BITS+B_BITS+1 downto B_BITS+1) <= a_i(a_i'left) & a_i;
    ext_pos_a(B_BITS downto 0) <= (others => '0');

    ext_neg_a(A_BITS+B_BITS+1 downto B_BITS+1) <= std_logic_vector(-signed(a_i(a_i'left) & a_i));
    ext_neg_a(B_BITS downto 0) <= (others => '0');
 
    c_o <= accumulator(A_BITS+B_BITS downto 1);

    ACCUMULATOR_PROCESS : process (clk_i)
        variable accumulator_tmp : std_logic_vector(A_BITS+B_BITS+1 downto 0) 
                                 := (others => '0');
    begin
        if (rising_edge(clk_i)) then
            if (rst_i = '1') then
                accumulator <= (others => '0');
            elsif (load_accumulator = '1') then
                accumulator(B_BITS downto 0) <= b_i & '0';
                accumulator(A_BITS+B_BITS+1 downto B_BITS+1) <= (others => '0'); 
            elsif (shift_accumulator = '1') then
                if   (add_multiplicand = '1') then
                    accumulator_tmp := std_logic_vector(unsigned(accumulator) 
                                                       + unsigned(ext_pos_a));
                elsif(sub_multiplicand = '1') then
                    accumulator_tmp := std_logic_vector(unsigned(accumulator) 
                                                       + unsigned(ext_neg_a));
                else
                    accumulator_tmp := accumulator;
                end if;
                -- Right arithmetic shifting
                accumulator <= std_logic_vector(shift_right(signed(accumulator_tmp), 1));
            end if;
        end if;
    end process;

    COUNTER_PROCESS : process (clk_i)
    begin
        if (rising_edge(clk_i)) then
            if (rst_i = '1') then
               counter <= (others => '0');
            elsif (init_counter = '1') then
               counter <= (others => '0');
            elsif (incr_counter = '1') then
               counter <= std_logic_vector(unsigned(counter) + 1);
            end if;
        end if;
    end process;

    end_of_loop <= '1' when (unsigned(counter) = B_BITS-1) else
                   '0';

    start_of_ones  <= '1' when (accumulator(1 downto 0) = "10") else
                      '0';
    start_of_zeros <= '1' when (accumulator(1 downto 0) = "01") else
                      '0';
    -- FSM
    
    STATE_TRAN_PROCESS : process (cur_state, a_b_valid_i, end_of_loop, 
                                  start_of_ones, start_of_zeros, cons_ready_i)
    begin
        load_accumulator  <= '0'; 
        shift_accumulator <= '0';
        add_multiplicand  <= '0';
        sub_multiplicand  <= '0';
        init_counter      <= '0';
        incr_counter      <= '0';
        c_valid_o         <= '0';
        prod_ready_o      <= '0';

        nxt_state <= cur_state;
        case (cur_state) is
            when IDLE =>
                load_accumulator <= '1';
                init_counter     <= '1';
                prod_ready_o     <= '1';
                if (a_b_valid_i = '1') then -- inputs handshake
                    nxt_state <= ONES_OR_ZEROS_STREAM; 
                end if;
            
            when ONES_OR_ZEROS_STREAM =>
                incr_counter      <= '1';
                shift_accumulator <= '1';
                if    (start_of_ones  = '1') then -- 10
                    sub_multiplicand <= '1';
                    nxt_state <= ONES_START;
                elsif (start_of_zeros = '1') then -- 01
                    add_multiplicand <= '1';
                    nxt_state <= ZEROS_START;
                else                              -- 00 / 11
                    nxt_state <= ONES_OR_ZEROS_STREAM;
                end if; 
                
                if (end_of_loop = '1') then
                    nxt_state <= DONE; -- overwrite nxt_state
                end if;

            when ONES_START =>
                incr_counter      <= '1';
                shift_accumulator <= '1';
                if (start_of_zeros = '1') then  -- 01
                    add_multiplicand <= '1';
                    nxt_state <= ZEROS_START;
                else                            -- 11
                    nxt_state <= ONES_OR_ZEROS_STREAM;
                end if;
                
                if (end_of_loop = '1') then
                    nxt_state <= DONE; -- overwrite nxt_state
                end if;

            when ZEROS_START =>
                incr_counter      <= '1';
                shift_accumulator <= '1';
                if (start_of_ones = '1') then   -- 10
                    sub_multiplicand <= '1';
                    nxt_state <= ONES_START;
                else                            -- 00
                    nxt_state <= ONES_OR_ZEROS_STREAM;
                end if; 

                if (end_of_loop = '1') then
                    nxt_state <= DONE; -- overwrite nxt_state
                end if;
            
            when DONE =>
                c_valid_o <= '1';
                if (cons_ready_i = '1') then -- outputs  handshake
                    nxt_state <= IDLE; 
                end if;

            when others =>
                nxt_state <= IDLE;
        end case;
    end process; 

    STATE_REG_PROCESS : process (clk_i)
    begin
        if (rising_edge(clk_i)) then
            if (rst_i = '1') then
               cur_state <= IDLE;
            else
               cur_state <= nxt_state;
            end if;
        end if;
    end process;

end architecture;
