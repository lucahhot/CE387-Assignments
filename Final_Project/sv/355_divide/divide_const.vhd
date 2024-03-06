library IEEE;

use IEEE.std_logic_1164.all;

--Additional standard or custom libraries go here

package divider_const is

	constant DIVIDEND_WIDTH : natural := 16; 
	constant DIVISOR_WIDTH : natural := 8;

	--Other constants, types, subroutines, components go here
	-- Creating constants for the states
	constant IDLE : std_logic_vector (2 downto 0) := "000";
	constant INIT : std_logic_vector (2 downto 0) := "001";
	constant LOOPING : std_logic_vector (2 downto 0) := "010";
	constant BRANCHING : std_logic_vector (2 downto 0) := "011";
	constant EPILOGUE : std_logic_vector (2 downto 0) := "100";
	
end package divider_const; package body divider_const is

--Subroutine declarations go here
-- you will not have any need for it now, this package is only for defining - -- some useful constants
end package body divider_const;