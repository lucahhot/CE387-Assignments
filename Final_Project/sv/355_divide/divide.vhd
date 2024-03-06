library IEEE;
use IEEE.std_logic_1164.all;
use WORK.divider_const.all;
use IEEE.numeric_std.all;


--Additional standard or custom libraries go here

entity divider is port(

    --Inputs
    rst : in std_logic;
    clk : in std_logic;
    start : in std_logic;
    dividend : in std_logic_vector (DIVIDEND_WIDTH - 1 downto 0);
    divisor : in std_logic_vector (DIVISOR_WIDTH - 1 downto 0);
    --Outputs
    quotient : out std_logic_vector (DIVIDEND_WIDTH - 1 downto 0);
    remainder : out std_logic_vector (DIVISOR_WIDTH - 1 downto 0);
    overflow : out std_logic

    );

end entity divider;

architecture behavioral_fsm of divider is 

    function get_msb_pos(signal input_vector : std_logic_vector) return integer is

        variable result : integer := -1;
    
        begin
            for i in input_vector'left downto input_vector'right loop
                if input_vector(i) = '1' then
                    result := i;
                    exit;
                end if;
            end loop;
            return result;
    end function get_msb_pos;

    --Signals and components go here
    signal quotient_c, quotient_temp : std_logic_vector (DIVIDEND_WIDTH - 1 downto 0);
    signal remainder_c, remainder_temp : std_logic_vector (DIVISOR_WIDTH - 1 downto 0);
    signal a, a_c : std_logic_vector (DIVIDEND_WIDTH - 1 downto 0);
    signal b, b_c : std_logic_vector (DIVISOR_WIDTH - 1 downto 0);
    signal state, next_state : std_logic_vector (2 downto 0); -- Going to have 5 states so 3 bits
    signal overflow_c, overflow_temp : std_logic;
    signal one_vector : std_logic_vector (DIVIDEND_WIDTH - 1 downto 0) := (DIVIDEND_WIDTH - 1 downto 1 => '0', others => '1');

    begin

    clocked_process: process (rst, start, clk) is 
        begin
            if (rst = '0') then
                state <= IDLE;
                a <= (others => '0');
                b <= (others => '0');
                overflow_temp <= '0';
                quotient_temp <= (others => '0');
                remainder_temp <= (others => '0');
            elsif (rising_edge(clk)) then
                if (start = '0') then
                    state <= INIT;
                    -- Making dividend/divisor positive if they are negative for calculations
                    if (signed(dividend) < 0) then
                        a <= std_logic_vector(-signed(dividend));
                    else 
                        a <= dividend;
                    end if;
                    if (signed(divisor) < 0) then
                        b <= std_logic_vector(-signed(divisor));
                    else 
                        b <= divisor;
                    end if;
                    overflow_temp <= '0';
                    quotient_temp <= (others => '0');
                    remainder_temp <= (others => '0');
                else    
                    state <= next_state;
                    a <= a_c;
                    b <= b_c;
                    quotient_temp <= quotient_c;
                    remainder_temp <= remainder_c;
                    overflow_temp <= overflow_c;
                    if (next_state = EPILOGUE or next_state = IDLE) then
                        quotient <= quotient_c;
                        remainder <= remainder_c;
                        overflow <= overflow_c;
                    end if;
                end if;
            end if;
    end process clocked_process;

    fsm_process: process (state,a,b,quotient_temp) is
        begin
            a_c <= a;
            b_c <= b;
            quotient_c <= quotient_temp;
            next_state <= state;
            remainder_c <= remainder_temp;
            overflow_c <= overflow_temp;
            case (state) is
                -- During INIT, choosing between BRANCHING or LOOPING for next state
                when INIT =>
                    if (unsigned(b) = 1) then
                        next_state <= BRANCHING;
                    else 
                        next_state <= LOOPING;
                    end if;
                -- in BRANCHING, set quotient_c to a (dividend), and go straight to EPILOGUE
                when BRANCHING =>
                    quotient_c <= a;
                    a_c <= (others => '0');
                    next_state <= EPILOGUE;
                -- check if b != 0 && b < a, if not, go to EPILOGUE. If true, go through the looping algorithm and go back to LOOPING
                when LOOPING =>
                    if ((unsigned(b) /= 0) and (unsigned(b) <= unsigned(a))) then
                        if ((unsigned(b) sll (get_msb_pos(a) - get_msb_pos(b))) > unsigned(a)) then
                            quotient_c <= std_logic_vector(unsigned(quotient_temp) + (unsigned(one_vector) sll (get_msb_pos(a) - get_msb_pos(b) - 1)));
                            a_c <= std_logic_vector(unsigned(a) - (unsigned(b) sll (get_msb_pos(a) - get_msb_pos(b) - 1)));
                        else
                            quotient_c <= std_logic_vector(unsigned(quotient_temp) + (unsigned(one_vector) sll (get_msb_pos(a) - get_msb_pos(b))));
                            a_c <= std_logic_vector(unsigned(a) - (unsigned(b) sll (get_msb_pos(a) - get_msb_pos(b))));
                        end if;
                        next_state <= LOOPING;
                    else 
                        next_state <= EPILOGUE;
                    end if;
                -- in EPILOGUE, finish the division, assigning quotient_c and remainder_c, and go to IDLE
                when EPILOGUE =>
                    if (((dividend(DIVIDEND_WIDTH - 1)) xor (divisor(DIVISOR_WIDTH - 1))) = '1') then
                        quotient_c <= std_logic_vector(-signed(quotient_temp));
                    else 
                        quotient_c <= quotient_temp;
                    end if;
                    if ((dividend(DIVIDEND_WIDTH - 1)) = '1') then
                        remainder_c <= std_logic_vector(resize(-signed(a),DIVISOR_WIDTH));
                    else
                        remainder_c <= std_logic_vector(resize(unsigned(a),DIVISOR_WIDTH));
                    end if;
                     -- Checking for overflow here
                    if (unsigned(b) = 0) then
                        overflow_c <= '1';
                    else 
                        overflow_c <= '0';
                    end if;
                    next_state <= IDLE;
                -- in IDLE, keep looping back to IDLE until the clocked_process is reset and state is set to INIT
                when IDLE =>
                    next_state <= IDLE;
                -- default state of IDLE
                when others =>
                    next_state <= IDLE;
            end case;
    end process fsm_process;

end architecture behavioral_fsm;