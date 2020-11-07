-- VHDL created by Arius, Inc  copyright 2020
-- Permission is hereby granted, free of charge, to any person obtaining a 
-- copy of this software and associated documentation files (the "Software"), 
-- to deal in the Software without restriction, including without limitation 
-- the rights to use, copy, modify, merge, publish, distribute, sublicense, 
-- and/or sell copies of the Software, and to permit persons to whom the 
-- Software is furnished to do so, subject to the following conditions:
-- The above copyright notice and this permission notice shall be included in 
-- all copies or substantial portions of the Software.
-- THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR 
-- IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, 
-- FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL 
-- THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER 
-- LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING 
-- FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER 
-- DEALINGS IN THE SOFTWARE.
--------------------------------------------------------------------------------
-- Company: Arius, Inc
-- Engineer: Rick Collins
--
-- Create Date:   2020/11/04 01:00z
-- Design Name:   Alarm
-- Module Name:   MilliSec
-- Project Name:  OVB_Alarm
--
-- Revision:
-- Revision 0.01 - File Created
--
-- Additional Comments:
--
-- Notes:  
-- MilliSec - SYNTHESIZABLE CODE ONLY
--   Common module to provide time based enables across the design. 
-- MilliSec_tb - test bench verify timing of outputs 
--   verify each enable period
--   verify each enable pulse width
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
Use ieee.numeric_std.all;
use IEEE.MATH_REAL.ALL;
-- Library Alarm_Common;
use work.Common.all;

-- Provide 5 ms and 256 ms (quarter second) enables
ENTITY MilliSec IS
  port (
	Clk			: in  std_logic;
	MHz4_En		: out std_logic := '0'; -- output enable 1 clk at 4.19 MHz
	I2C_Clk_En	: out std_logic := '0'; -- output enable 1 clk at 524 kHz
	Five_ms_En	: out std_logic := '0'; -- output enable 1 clk every 5 ms
	FourHz_En	: out std_logic := '0'  -- output enable 1 clk every 250 ms
  );
end MilliSec;

ARCHITECTURE behav OF MilliSec IS  -- initial values assist reset startup
  signal I2C_Clk_Cntr	: unsigned(log2ceil(I2C_Clk_MAX_Cnt)-1 downto 0) := ("110", others => '0');
  signal I2C_Clk_Nxt	: unsigned(log2ceil(I2C_Clk_MAX_Cnt) downto 0) := ("110", others => '0');
  signal Five_ms_Cntr	: unsigned(log2ceil(Five_ms_MAX_Cnt)-1 downto 0) := ("110", others => '0');
  signal Five_ms_Nxt	: unsigned(log2ceil(Five_ms_MAX_Cnt) downto 0) := ("110", others => '0');
  signal Hold_Cntr		: unsigned(log2ceil(Hold_ms)-1 downto 0) := ("11", others => '0');
  signal Hold_Nxt		: unsigned(log2ceil(Hold_ms) downto 0) := ("11", others => '0');
  signal Five_ms_Carry, Hold_Carry	: std_logic := '0';
  signal MHz4_Carry, I2C_Clk_Carry	: std_logic := '0';
begin
  MHz4_Carry	<= '1' when I2C_Clk_Cntr(1 downto 0) = "11" else '0';
  I2C_Clk_Nxt	<= ("0" & I2C_Clk_Cntr) - 1;
  I2C_Clk_Carry <= I2C_Clk_Nxt(I2C_Clk_Nxt'high);
  Five_ms_Nxt	<= ("0" & Five_ms_Cntr) - 1;
  Five_ms_Carry	<= Five_ms_Nxt(Five_ms_Nxt'high);
  Hold_Nxt		<= ("0" & Hold_Cntr) - 1;
  Hold_Carry	<= Hold_Nxt(Hold_Nxt'high);
  
  Enables: process(Clk) is -- Time the 5 ms and quarter second enables
  begin
	if (rising_edge(Clk)) then
	  MHz4_En			<= MHz4_Carry;
	  I2C_Clk_En		<= '0'; -- each enable is high for 1 clock
	  Five_ms_En		<= '0';
      FourHz_En			<= '0';
	  I2C_Clk_Cntr		<= I2C_Clk_Nxt(I2C_Clk_Cntr'range); -- binary modulus 
	  
	  if (I2C_Clk_Carry) then
		I2C_Clk_En		<= '1';
		
		if (not Five_ms_Carry) then
		  Five_ms_Cntr	<= Five_ms_Nxt(Five_ms_Cntr'range);
		else
		  Five_ms_Cntr	<= to_unsigned(Five_ms_MAX_Cnt, Five_ms_Cntr'length);
		  Five_ms_En	<= '1';
		  
	      if (not Hold_Carry) then
	        Hold_Cntr	<= Hold_Nxt(Hold_Cntr'range);
	      else
	        Hold_Cntr	<= to_unsigned(Hold_ms, Hold_Cntr'length);
	    	FourHz_En	<= '1';
	      end if;
        end if;
	  end if;
	end if;
  end process Enables;
END behav;	-- MilliSec

-- synthesis translate_off
--------------------------------------------------------------------------------
--  Test bench for MilliSec - not synthesized
--
--  Provide system clock, verify timing of strobes
--  MHz4_En    is 4 clock periods ±15 ns, 29.8 ns clock
--  I2C_Clk_En is 64 ms periods ±15 ns, 29.8 ns clock
--  Five_ms_En is 5 ms period ±15 ns, 29.8 ns clock
--  FourHz_En  is 250 ms period ±15 ns, 29.8 ns clock
--------------------------------------------------------------------------------

library ieee;
use ieee.NUMERIC_STD.all;
use ieee.std_logic_1164.all;
use work.Common.all;

entity MilliSec_tb is
end MilliSec_tb;

architecture TB_ARCH of MilliSec_tb is
  constant CLK_Hz_tb		: real := 33554432.0; -- 2^25 MHz
  constant Clk_Half_Per		: time := 500 ms / CLK_Hz_tb;  -- 14901 ps; --
  constant Clk_Period		: time := (1 sec / CLK_Hz_tb); -- 2^25 MHz clock
  signal Clk				: std_logic := '1';
  signal MHz4_En			: std_logic;
  signal I2C_Clk_En			: std_logic;
  signal Five_ms_En			: std_logic;
  signal FourHz_En    		: std_logic;

  -- Check period and pulse width of enables
  procedure TestEn (signal Pulse : in std_logic; 
  					Period, Window : in time; 
	  				Pulse_Name	: in String;
					Prev_Edge : inout time) is 
  	variable test : time := 0 ns;
  begin
  	if rising_edge(Pulse) then
	  test := now - Prev_Edge; -- get period, compare to window
	  -- report Pulse_Name & " Prev_Edge = " & time'image(Prev_Edge);
	  assert (Prev_Edge = 0 sec) OR (abs(test - Period) <= Window) -- ignore 1st
	  	report Pulse_Name & " period failed " & time'image(test) & 
			", LAST_EVENT = " & time'image(Pulse'LAST_EVENT) &
			", Prev_Edge = " & time'image(Prev_Edge);
	  Prev_Edge := now;
	elsif falling_edge(Pulse) then  -- compare pulse width to one clock
	  test := (now - Prev_Edge);
	  assert (abs(test - Clk_Period) < 1 ps) 
	  	report Pulse_Name & " width failed " & time'image(test)
		  & ", start " & time'image(Prev_Edge) & ", end " & time'image(now);
	end if;
  end procedure TestEn;
begin

  Clk_gen: Clk <= not Clk after Clk_Half_Per;

  test_MHz4: process (MHz4_En) is
  	variable Prev_Edge : time := 0 ns;
  begin -- 8 clocks period, 4.194,304 MHz, 238.419 ns
  	TestEn (MHz4_En, (Clk_Period * 4), 15 ns, MHz4_En'Simple_name, Prev_Edge); 
  end process test_MHz4;

  test_I2C: process (I2C_Clk_En) is
  	variable Prev_Edge : time := 0 ns;
  begin -- 64 clocks period, 524,288 Hz, 1.907,348,632 us, window of half clock
  	TestEn (I2C_Clk_En, (Clk_Period * 64), 
				Clk_Half_Per, "I2C_Clk_En", Prev_Edge); 
  end process test_I2C;

  test_ms: process (Five_ms_En) is
  	variable Prev_Edge : time := 0 ns;
  begin -- 5 ms period, 200 Hz, window 64 x I2C window
  	TestEn (Five_ms_En, 5 ms, (64 * Clk_Half_Per), "Five_ms_En", Prev_Edge); 
  end process test_ms;

  test_hold: process (FourHz_En) is
  	variable Prev_Edge : time := 0 ns;
  begin -- 250 ms period, 4 Hz, 
  	TestEn (FourHz_En, 250 ms, (3200 * Clk_Half_Per), "FourHz_En", Prev_Edge); 
  end process test_hold;

  MS_UUT:ENTITY MilliSec
	port map (
	  Clk				=> Clk,
	  MHz4_En			=> MHz4_En,
	  I2C_Clk_En		=> I2C_Clk_En,
	  Five_ms_En		=> Five_ms_En,
      FourHz_En			=> FourHz_En
	);

end TB_ARCH;  -- MilliSec_tb

-- synthesis translate_on
