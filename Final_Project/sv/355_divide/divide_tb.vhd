library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_textio.all;
use ieee.numeric_std.all;
use std.textio.all;
use WORK.divider_const.all;

entity divider_tb is
end entity;

architecture divider_test of divider_tb is

    component divider is
        
        port (
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

    end component divider;
    for all : divider use entity WORK.divider (behavioral_fsm);

    -- Period for clock
    constant PERIOD : time := 10 ns;


    file infile: text open read_mode is "divider16.in";
    file outfile: text open write_mode is "divider16.out";

    signal start_input : std_logic;
    signal rst_input : std_logic;
    signal dividend_input : std_logic_vector (DIVIDEND_WIDTH - 1 downto 0);
    signal divisor_input : std_logic_vector (DIVISOR_WIDTH - 1 downto 0);
    signal quotient_output : std_logic_vector (DIVIDEND_WIDTH - 1 downto 0);
    signal remainder_output : std_logic_vector (DIVISOR_WIDTH - 1 downto 0);
    signal overflow_output : std_logic;
    signal clk_input : std_logic;
    signal hold_clock : std_logic := '0'; -- Signal to halt clock and halt simulation when it's done

    begin

        divider_dut : divider
            port map (
                rst => rst_input,
                clk => clk_input,
                start => start_input,
                dividend => dividend_input,
                divisor => divisor_input,
                quotient => quotient_output,
                remainder => remainder_output,
                overflow => overflow_output
            );

        clk_generate: process is 
        begin
            clk_input <= '0';
            wait for (PERIOD / 2);
            clk_input <= '1';
            wait for (PERIOD / 2);
            if(hold_clock = '1') then
                wait;
            end if;
        end process clk_generate;

        process is

            variable my_line : line;
            variable dividend_term : integer;
            variable divisor_term : integer;
            variable start_term : std_logic;
            variable start_time : time;
            variable end_time : time;

            begin 

                -- toggle reset
                rst_input <= '1';
                wait for (PERIOD);
                rst_input <= '0';
                wait for (PERIOD);
                rst_input <= '1';

                write(my_line, string'("Beginning to test..."));
                writeline(outfile, my_line);

                while not (endfile(infile)) loop

                    start_time := NOW;

                    -- Reading in dividend term
                    readline(infile, my_line);
                    read(my_line, dividend_term);
                    -- Reading in divisor term
                    readline(infile, my_line);
                    read(my_line, divisor_term);

                    -- Feeding in inputs into divider
                    dividend_input <= std_logic_vector(to_signed(dividend_term,DIVIDEND_WIDTH));
                    divisor_input <= std_logic_vector(to_signed(divisor_term,DIVISOR_WIDTH));

                    -- Toggle start to low to start division
                    start_input <= '0';
                    wait until (clk_input = '0');
                    wait until (clk_input = '1');
                    start_input <= '1';

                    -- Wait for a change of outputs
                    wait on quotient_output;
                    
                    wait for 10 ns;

                    -- Writing back into output file
                    write(my_line, to_integer(signed(dividend_input)));
                    write(my_line, string'(" "));
                    write(my_line, string'("/"));
                    write(my_line, string'(" "));
                    write(my_line, to_integer(signed(divisor_input)));
                    write(my_line, string'(" = "));
                    wait until (clk_input = '0');
                    wait until (clk_input = '1');
                    write(my_line, to_integer(signed(quotient_output)));
                    write(my_line, string'(" -- "));
                    write(my_line, to_integer(signed(remainder_output)));
                    write(my_line, string'(" (overflow = "));
                    write(my_line, overflow_output);
                    write(my_line, string'(")"));
                    writeline(outfile, my_line);

                    end_time := NOW;

                    write(my_line, string'("Total cycles: ") );
                    write(my_line, (end_time - start_time) / PERIOD );
                    writeline(outfile, my_line );

                    wait for 10 ns;

                end loop;

                end_time := NOW;
                write(my_line, string'("@ ") );
                write(my_line, end_time );
                write(my_line, string'(": Completed.") );
                writeline(outfile, my_line );

                hold_clock <= '1';

        wait;
    end process;

end architecture divider_test;