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
-- Key_Pad - SYNTHESIZABLE CODE ONLY
--   80 ms button debounce and detect buttons held for 3 seconds.
-- Key_Pad_tb - test bench verify timing of outputs
--   verify bouncing buttons do not trigger detection
--   verify stable buttons are detected in 80 -85 ms
--	 verify held buttons are detected in 3 sec +257 ms or - 185 ms
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
Use ieee.numeric_std.all;
use IEEE.MATH_REAL.ALL;
use work.Alarm_common.all;
use work.ovb_h.all;

-- Monitor keypad and debounce inputs.  Also provide 3 sec hold detect.
-- Button outputs activate after timeout, hold value until button is released.
-- Spkr outputs are asserted for one clock cycle to trigger speaker sounds,
-- tick on press and boop on hold.
ENTITY Key_Pad IS
  GENERIC (
	CLK_HZ : REAL := FREQUENCY -- 2^25
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
