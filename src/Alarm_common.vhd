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
-- Create Date:   2020/09/13 18:46z
-- Design Name:   Alarm
-- Module Name:   Alarm_common
-- Project Name:  OVB_Alarm
--
-- Revision:
-- Revision 0.01 - File Created
--
-- Additional Comments:
--
-- Notes:  -  SYNTHESIZABLE CODE ONLY
-- Library of constants and functions commonly used across entities
--
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
Use ieee.numeric_std.all;
use IEEE.MATH_REAL.ALL;

-- Library Alarm_Common;

PACKAGE Common IS

  -- Alarm LED related constants
  constant Tidal_Vol_LED		: natural := 0;
  constant Insp_Prss_Hi_LED		: natural := Tidal_Vol_LED+1;
  constant Insp_Prss_Lo_LED		: natural := Insp_Prss_Hi_LED+1;
  constant PEEP_Short_LED		: natural := Insp_Prss_Lo_LED+1;

  constant FiO2_Short_LED		: natural := PEEP_Short_LED+1;
  constant Apnea_LED			: natural := FiO2_Short_LED+1;
  constant Tech_LED				: natural := Apnea_LED+1;
  constant Power_LED			: natural := Tech_LED+1;

  -- Alarm_src related constants
  constant Tidal_Vol_Sel		: natural := 0;
  constant Insp_Prss_Hi_Sel		: natural := Tidal_Vol_Sel+1;
  constant Insp_Prss_Lo_Sel		: natural := Insp_Prss_Hi_Sel+1;
  constant PEEP_Short_Sel		: natural := Insp_Prss_Lo_Sel+1;

  constant FiO2_Short_Sel		: natural := PEEP_Short_Sel+1;
  constant Apnea_Sel			: natural := FiO2_Short_Sel+1;
  constant Tech_High_Sel		: natural := Apnea_Sel+1;
  constant Tech_Med_Sel			: natural := Tech_High_Sel+1;

  constant Tech_Low_Sel			: natural := Tech_Med_Sel+1;
  constant Power_Low_Sel		: natural := Tech_Low_Sel+1;
  constant Power_Med_Sel		: natural := Power_Low_Sel+1;
  constant Power_High_Sel		: natural := Power_Med_Sel+1;

  constant Alarm_Sel_Max		: natural := Power_High_Sel;

  constant Tone_Width_Max		: natural := 13; -- pulse width, 31.25 ms steps
  constant Seq_Max				: natural := 11; -- 12 steps to alarm tones

  type Vol_Level			is (MUTE, MINUS6dB, MINUS3dB, ZEROdB);
  type Alarm_Level			is (NO_ALRM, LOW_ALRM, MID_ALRM, HIGH_ALRM);
  subtype Alarm_Type		is unsigned (Alarm_Sel_Max downto Tidal_Vol_Sel);
  subtype Tone_Seq_Type		is natural range 0 to Seq_Max;
  subtype Tone_Width_Type	is natural range 0 to Tone_Width_Max;
  type ColorButton			is (OFF, CYAN, YELLOW, RED, WHITE);

  -- Alarm groups by priority
  constant HighPriAlarms		: Alarm_Type :=
  	  (Tidal_Vol_Sel to Tech_High_Sel | Power_High_Sel => '1', others => '0');
  constant MidPriAlarms			: Alarm_Type :=
  	  (Tech_Med_Sel | Power_Med_Sel => '1', others => '0');
  constant LowPriAlarms			: Alarm_Type :=
  	  (Tech_Low_Sel | Power_Low_Sel => '1', others => '0');

  -- Alarm groups by audible alerts
  constant VentTones			: Alarm_Type :=
  	  (Tidal_Vol_Sel to PEEP_Short_Sel | Apnea_Sel => '1', others => '0');
  constant OxygenTones			: Alarm_Type :=
  	  (FiO2_Short_Sel => '1', others => '0');
  constant PowerTones			: Alarm_Type :=
  	  (Power_Med_Sel | Power_High_Sel => '1', others => '0');
  constant GeneralTones			: Alarm_Type :=
  	  (Tech_High_Sel | Tech_Med_Sel => '1', others => '0');
  constant LowPriTones			: Alarm_Type :=
  	  (Tech_Low_Sel | Power_Low_Sel => '1', others => '0');

  constant CLK_HZ			: real := 33554432.0; -- 2^25 MHz, 50 ppm
  constant I2C_Clk_MAX_Cnt	: integer := integer(CLK_HZ/524000.0)-1; -- 524 kHz
  constant Five_ms_MAX_Cnt	: integer := -1 +   -- 2,620
  					integer(CLK_HZ/real(200 * (I2C_Clk_MAX_Cnt + 1))); -- 5 ms
  constant Debounce_MS	: integer := 9;  -- 50 ms bounce time by 5ms, 0 based
  constant Hold_ms		: integer := 49; -- 250 ms hold enable by 5ms, 0 based
  constant Hold_Max		: integer := integer(3000.0/250.0)-1;  -- 3 second hold

  constant Sample_Rate	: Real := 32768.0;  -- Sample rate in Hz
  constant NCO_Mod		: natural := integer(Sample_Rate * 8.0); -- resolution

  -- step size = frequency * modulus / samp rate
  constant A4_real : real	 := 440.0 * real(NCO_Mod) / Sample_Rate;
  constant G3_step : natural := integer(round(A4_real * 2**(-14.0/12.0)));
  constant C4_step : natural := integer(round(A4_real * 2**(-9.0/12.0)));
  constant E4_step : natural := integer(round(A4_real * 2**(-5.0/12.0)));
  constant F4_step : natural := integer(round(A4_real * 2**(-4.0/12.0)));
  constant G4_step : natural := integer(round(A4_real * 2**(-2.0/12.0)));
  constant A4_step : natural := integer(round(A4_real));
  constant B4_step : natural := integer(round(A4_real * 2**(2.0/12.0)));
  constant C5_step : natural := integer(round(A4_real * 2**(3.0/12.0)));
  constant Step_Max : natural := C5_step;
  subtype  Freq_Step_Type is natural range 0 to Step_Max;

  constant LED_Data_Max		: natural := 23;
  subtype LED_Data_Type		is unsigned (LED_Data_Max downto 0);
  type LED_RED_rng			is range 23 downto 16;
  type LED_GRN_rng			is range 15 downto 8;
  type LED_BLU_rng			is range 7 downto 0;
  constant OFF_COLOR		: LED_Data_Type := x"000000";
  constant RED_COLOR		: LED_Data_Type := x"FF0000";
  constant YEL_COLOR		: LED_Data_Type := x"FFFF00";
  constant GRN_COLOR		: LED_Data_Type := x"00FF00";
  constant CYN_COLOR		: LED_Data_Type := x"00FFFF";
  constant BLU_COLOR		: LED_Data_Type := x"0000FF";
  constant MAG_COLOR		: LED_Data_Type := x"FF00FF";
  constant WHT_COLOR		: LED_Data_Type := x"FFFFFF";

  subtype t_Disp_CGRAM_byte	is unsigned (7 downto 0);
  type t_Disp_CGRAM			is array (0 to 7) of t_Disp_CGRAM_byte;
  constant c_Batt_Blank		: t_Disp_CGRAM_byte := "00000000";
  constant c_Batt_Top		: t_Disp_CGRAM_byte := "00001110";
  constant c_Batt_Body		: t_Disp_CGRAM_byte := "00011111";

  -- Pressure thermometer needs 0 to 5 pixels
  constant c_Pres_0			: t_Disp_CGRAM_byte := "00000000";
  constant c_Pres_1			: t_Disp_CGRAM_byte := "00010000";
  constant c_Pres_2			: t_Disp_CGRAM_byte := "00011000";
  constant c_Pres_3			: t_Disp_CGRAM_byte := "00011100";
  constant c_Pres_4			: t_Disp_CGRAM_byte := "00011110";
  constant c_Pres_5			: t_Disp_CGRAM_byte := "00011111";

  function PosEdge (Val, Val_D : STD_LOGIC) return Boolean;

  function PosEdge (Val, Val_D : STD_LOGIC) return STD_LOGIC;

  function NegEdge (Val, Val_D : STD_LOGIC) return Boolean;

  function NegEdge (Val, Val_D : STD_LOGIC) return STD_LOGIC;

  function EdgeDet (Val, Val_D : STD_LOGIC) return Boolean;

  function EdgeDet (Val, Val_D : STD_LOGIC) return STD_LOGIC;

  function sl2int (x: std_logic) return integer;

  function log2ceil (x : positive) return natural;

  function log2floor (x : positive) return natural;

  function log2 (x : positive) return natural; -- same as log2floor, deprecated

END Common;

PACKAGE BODY Common IS

  function PosEdge (Val, Val_D : STD_LOGIC) return Boolean is
  begin
	return (Val = '1' and Val_D = '0');
  end PosEdge;

  function PosEdge (Val, Val_D : STD_LOGIC) return STD_LOGIC is
  begin
	return (Val and not Val_D);
  end PosEdge;

  function NegEdge (Val, Val_D : STD_LOGIC) return Boolean is
  begin
	return (Val = '0' and Val_D = '1');
  end NegEdge;

  function NegEdge (Val, Val_D : STD_LOGIC) return STD_LOGIC is
  begin
	return (not Val and Val_D);
  end NegEdge;

  function EdgeDet (Val, Val_D : STD_LOGIC) return Boolean is
  begin
	return (Val = '1' xor Val_D = '0');
  end EdgeDet;

  function EdgeDet (Val, Val_D : STD_LOGIC) return STD_LOGIC is
  begin
	return (Val xor Val_D);
  end EdgeDet;

  function sl2int (x: std_logic) return integer is
  begin
	case x is
	  when '1' | 'H'	=> return 1;
	  when others		=> return 0;
	end case;
  end;

  function log2ceil (x : positive) return natural is
	variable log, cmp : natural;
  begin
	log := 0;
	cmp := 1;
	while (cmp < x) loop
	  log := log + 1;
	  cmp := cmp * 2;
	end loop;
	return log;
  end log2ceil;

  function log2floor (x : positive) return natural is
	variable log, cmp : natural;
  begin
	log := 1;
	cmp := 2;
	while (cmp <= x) loop
	  log := log + 1;
	  cmp := cmp * 2;
	end loop;
	return log - 1;
  end log2floor;

  function log2 (x : positive) return natural is
	variable temp, log: natural;
  begin
-- 	temp := x / 2;
-- 	log := 0;
-- 	while (temp /= 0) loop
-- 	  temp := temp/2;
-- 	  log := log + 1;
-- 	  end loop;
-- 	return log;
	return log2floor(x);
  end function log2;

END Common;
