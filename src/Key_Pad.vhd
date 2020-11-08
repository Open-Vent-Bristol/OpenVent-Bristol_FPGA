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
-- Create Date:   2020/11/07 10:54z
-- Design Name:   Alarm
-- Module Name:   Key_Pad
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
use work.Common.all;

-- Monitor keypad and debounce inputs.  Also provide 3 sec hold detect
-- Button outputs activate after timeout, hold value until button is released 
-- Spkr outputs are asserted for one clock cycle to trigger speaker sounds
ENTITY Key_Pad IS
  GENERIC (
	CLK_HZ : REAL := 33.554432E6 -- 2^25
  );
  port(
	Clk				: in  std_logic;
	Five_ms_En		: in  std_logic;
	Four_Hz_En     	: in  std_logic;
	Buttons			: in  unsigned(3 downto 0); -- async neg logic, pressed low
	Button_Press	: out unsigned(3 downto 0) := (others => '0');
	Button_Hold		: out unsigned(3 downto 0) := (others => '0');
	Spkr_Tick		: out std_logic := '0';
	Spkr_Boop		: out std_logic := '0'
  );
end Key_Pad;

ARCHITECTURE behav OF Key_Pad IS
  type ColorButton is (OFF, RED, YELLOW, CYAN, WHITE);
  type Debounce_type is array (3 downto 0) of integer range 0 to Debounce_MS;
  type Hold_type is array (3 downto 0) of natural range 0 to Hold_Max;
  -- Internal logic is positive, button inputs are negative (low true)
  signal Buttons_d		: unsigned(3 downto 0)	:= (others => '0');
  signal Buttons_Hist	: unsigned(3 downto 0)	:= (others => '0');
  signal Debounce_Cnt	: Debounce_type			:= (others => 0);
  signal Hold_Timer     : Hold_type				:= (others => Hold_Max);
begin

  Debounce: process(Clk) is
  begin		 -- Look for rising and falling button edges with debounce
	if (rising_edge(Clk)) then
	  Spkr_Tick	<= '0';			-- Spkr blip is only high for one clock cycle
	  Buttons_d	<= not Buttons;	-- Sync button inputs to clk
	  if (Five_ms_En) then
		for I in Buttons_d'range loop
		  if (Buttons_Hist(I) /= Buttons_d(I)) then	-- Initial change
			if (Button_Press(I) = Buttons_Hist(I)) then -- new press?
			  Debounce_Cnt(I) <= Debounce_MS;		-- start debounce timer
		  	end if;
		  elsif (Button_Press(I) /= Buttons_Hist(I)) then -- while button change
		  	if (Debounce_Cnt(I) = 0) then			-- If cnt down complete
			  Spkr_Tick	<= Button_Press(I) ?/= Buttons_Hist(I);
			  Button_Press(I) <= Buttons_Hist(I);	-- Update button value
			else
			  Debounce_Cnt(I) <= Debounce_Cnt(I) - 1;
		  	end if;
		  end if;
		  Buttons_Hist(I) <= Buttons_d(I);	-- Save button history every cycle
		end loop;
	  end if;
	end if;
  end process Debounce;

  Hold: process(Clk) is -- Look for buttons held down
  begin
	if (rising_edge(Clk)) then
	  Spkr_Boop <= '0';
      if (Four_Hz_En) then
		for I in Buttons'range loop
          if (not Button_Press(I)) then
            Hold_Timer(I)   <= Hold_Max;
            Button_Hold(I)  <= '0';
          elsif (Hold_Timer(I) = 0) then -- assert Button_hold until released 
            Button_Hold(I)  <= '1';
			Spkr_Boop		<= not Button_Hold(I); -- One enable period
          else
            Hold_Timer(I)   <= Hold_Timer(I) - 1;
          end if;
		end loop;
      end if;
	end if;
  end process Hold;

END behav;  -- Key_Pad

--------------------------------------------------------------------------------
--  Test bench for Key_Pad
--
--  Provide clock and Buttons - Five_ms_En and Hold_En from MilliSec component
--  Verify debounce of each button independently, 50 ms bounce window
--	Verify 3 sec hold time of each button
--------------------------------------------------------------------------------

library ieee;
use ieee.NUMERIC_STD.all;
use ieee.std_logic_1164.all;
use work.Common.all;

entity Key_Pad_tb is
	-- Generic declarations of the tested unit
		generic(
		CLK_HZ : REAL := 33.554432E6 );
end Key_Pad_tb;

architecture TB_ARCH of Key_Pad_tb is
  constant Clock_Half_Period : time := 500 ms / CLK_HZ;  -- 14901 ps; --
  -- type Button_rng			is range 3 downto 0;
  -- subtype ButtonSel_type	is natural range Button_rng;
  signal Clk				: std_logic := '1';
  signal MHz4_En			: std_logic;
  signal I2C_Clk_En			: std_logic;
  signal Five_ms_En			: std_logic;
  signal Four_Hz_En			: std_logic;
  signal Hold_En    		: std_logic;
  signal Buttons			: unsigned(3 downto 0)	:= (others => '1');
  signal Button_Press		: unsigned(3 downto 0)	:= (others => '0');
  signal Button_Hold		: unsigned(3 downto 0)	:= (others => '0');
  signal Spkr_Tick			: std_logic;
  signal Spkr_Boop			: std_logic;

  procedure Test_Button (signal Button_Action : in unsigned;
			DelayA : in time;
			DelayB : in time;
			Index : integer;
			Sig_name : string )  is
	variable Temp : unsigned (Button_Action'range) := Button_Action; 
  begin
	wait for DelayA;
	assert (Button_Action(Index) = '0') --  = Temp)
	  report "Unexpected action on " & Sig_name & "(" 
				& integer'image(Index) & "), detected at time "
				& integer'image(integer(now/1 ms)) & "." 
				& integer'image(integer(now/100 us) mod 10) 
				& integer'image(integer(now/10 us) mod 10) 
				& integer'image(integer(now/1 us) mod 10) & " ms";
	wait for DelayB;
	Temp := (others => '0'); 
	Temp(Index) := '1'; 
	assert (Button_Action = Temp)
	  report "Missed action on " & Sig_name & "(" 
				& integer'image(Index) & "), detected at time " 
				& integer'image(integer(now/1 ms)) & "." 
				& integer'image(integer(now/100 us) mod 10) 
				& integer'image(integer(now/10 us) mod 10) 
				& integer'image(integer(now/1 us) mod 10) & " ms";
  end procedure Test_Button;
begin

  Clk_gen: Clk <= not Clk after Clock_Half_Period;

  test_KP: process is --
  	variable Sig_Name : string (1 to 12); 
  begin
	report "Checking debounce of buttons bouncing " severity warning ;
	wait for 5 ms;  -- test each button for presses 80 to 85 ms
	Buttons <= "1110"; wait for 5 ms; Buttons <= "1111"; wait for 5 ms;
	Buttons <= "1110"; wait for 5 ms; Buttons <= "1111"; wait for 5 ms;
	Buttons <= "1110"; wait for 5 ms; Buttons <= "1111"; wait for 5 ms;
	Buttons <= "1110"; wait for 5 ms; Buttons <= "1111"; wait for 5 ms;
	Buttons <= "1110"; wait for 5 ms; Buttons <= "1111"; wait for 5 ms;
	report "Checking debounce of buttons NOT bouncing " severity warning ;
	Sig_Name := Button_Press'Simple_name; 
	Buttons <= "1110"; Test_Button(Button_Press, 79.9 ms, 5.1 ms, 0, Sig_Name);
 	Buttons <= "1101"; Test_Button(Button_Press, 79.9 ms, 5.1 ms, 1, Sig_Name);
 	Buttons <= "1011"; Test_Button(Button_Press, 79.9 ms, 5.1 ms, 2, Sig_Name);
 	Buttons <= "0111"; Test_Button(Button_Press, 79.9 ms, 5.1 ms, 3, Sig_Name);
	-- Test each button for hold, 12 to 13 cycles of 250 ms.
	report "Checking detection of buttons 3 sec hold " severity warning ;
	Sig_Name := (" " & Button_Hold'Simple_name); 
 	Buttons <= "1110"; Test_Button(Button_Hold, 2815 ms, 257 ms, 0, Sig_Name);
 	Buttons <= "1101"; Test_Button(Button_Hold, 2815 ms, 257 ms, 1, Sig_Name);
 	Buttons <= "1011"; Test_Button(Button_Hold, 2815 ms, 257 ms, 2, Sig_Name);
 	Buttons <= "0111"; Test_Button(Button_Hold, 2815 ms, 257 ms, 3, Sig_Name);
 	Buttons <= "1111"; wait for 6 ms; 
	report "Done" severity warning ;
  end process test_KP;

  MS: ENTITY MilliSec
	port map (
	  Clk				=> Clk,
	  MHz4_En			=> MHz4_En,
	  I2C_Clk_En		=> I2C_Clk_En,
	  Five_ms_En		=> Five_ms_En,
      Four_Hz_En		=> Four_Hz_En
	);

  Keys_UUT: ENTITY Key_Pad
	GENERIC map (
      CLK_HZ => CLK_HZ
	)
	port map (
	  Clk				=> Clk,
	  Five_ms_En		=> Five_ms_En,
      Four_Hz_En		=> Four_Hz_En,
	  Buttons			=> Buttons,
	  Button_Press		=> Button_Press,
	  Button_Hold		=> Button_Hold,
	  Spkr_Tick			=> Spkr_Tick,
	  Spkr_Boop			=> Spkr_Boop
	); -- Keys_UUT : Key_Pad

end TB_ARCH;  -- Key_Pad_tb

