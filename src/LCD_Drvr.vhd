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
-- LCD_Drvr - SYNTHESIZABLE CODE ONLY
--   Refresh the LCD every 5 ms 
-- LCD_Drvr_tb - test bench verify  
--   verify 
--   verify 
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
Use ieee.numeric_std.all;
use IEEE.MATH_REAL.ALL;
use work.Common.all;

ENTITY LCD_Drvr IS
  GENERIC (
      CLK_HZ	: REAL := 33.554432E6; -- 2^25
	  Mem_Depth	: positive	:= 2048
	);
  port(
	Clk				: in	std_logic;

	Five_ms_En		: in	std_logic; -- 5 ms enable

    Mem_Data		: in	unsigned(8 downto 0);
    Mem_Addr		: in	unsigned(10 downto 0);
	Mem_WE			: in 	std_logic;
	Page_Sel		: in	natural range 0 to 31; -- selects page to display

	LCD_RW			: out	std_logic := '0';
	LCD_RS			: out	std_logic := '1';
	LCD_E_Lft		: out	std_logic := '0';
	LCD_E_Rgt		: out	std_logic := '0';
    LCD_Data		: inout	unsigned(7 downto 0)
	);
  end LCD_Drvr;

-- LCD timing - Newhaven NHD-0216K1Z-FL-YBW data sheet, page 7 - write
-- Controller - Sitronix ST7066U data sheet, page 32
--       ___ ______________________________ ________________________
-- RS    ___X______________________________X________________________
--       ___|--tAS--|              |--tAH--|________________________
-- RW       \_______|______________|_______/
--                  |-----tPW------|--------------tC--------------|
--                  |______________|                ______________
-- E     ___________/              \_______________/              \__
--                        |--tDSW--|--tH--|
--       _________________ _______________ __________________________
-- DB0:7 _________________X_______________X__________________________
-- tAS	- 0 ns
-- tAH	- 10 ns
-- tPW	- 480 ns ** LCD data sheet differs from controller data sheet
-- tC	- 1200 ns
-- tDSW	- 80 ns  ** LCD data sheet differs from controller data sheet
-- tH	- 10 ns
-- Main clock = 29.8 ns > 40 clocks in 1200 ns best case.
-- Each command requires > 37 us delay before next command
-- Worst case @190 kHz, 52.6us, round up to 61.0 us, 2048 clocks 800h, 16384Hz
-- Worst case 1ms/61us = 16 bus cycles per ms
-- @3*16+8 = 57 commands per refresh = 3.477 ms, 287.6 refresh per second
--               512          512          512          512
-- Down  ___ ____________ ____________ ____________ ____________ ____________
-- Cnt   ___X__000-1ffh__X__200-3ffh__X__400-5ffh__X__600-7ffh__X__000h...___
--       ___|___________________________________________________ ____________
-- RS    ___X___________________________________________________X____________
--       ___|-- 15.3us --|-- 15.3us --|-- 15.3us --|-- 15.3us --|____________
-- RW       \____________|____________|____________|____________/
--          |            |____________|            |                  _____
-- E_L   ___|____________/            \____________|_________________/     \_
--          |            |            |____________|                 |
-- E_R   ___|____________|____________/            \_________________|_______
--          |            |--------------- 61.04 us ------------------|
--       ___|_ _________________________ ____________________________________
-- DB0:7 ___|_X________D0-Left__________X______D1-Right_______X______________
-- Mem_  ___|_ _________________________ _________________________ __________
-- Data  ___|_X_________D0-Left_________X________D1-Right_________X__________
-- Mem_  ___|_________________________ _________________________ ____________
-- Addr  ___X__________0______________X____________1____________X____________
-- LCD_    _|                                                  _
-- Start _| |_________________________________________________| |____________
--
-- Power on initialization commands
--   wait 40 ms after power up
--   Function set - write IR	0 0 1 1 N F X X (N = 1, F = 0) 0x38 << sync
--   Function set - write IR	0 0 1 1 N F X X (N = 1, F = 0) 0x38 << sync
--   Function set - write IR	0 0 1 1 N F X X (N = 1, F = 0) 0x38 << sync
--   Function set - write IR	0 0 1 1 N F X X (N = 1, F = 0) 0x38 << effective
--   Display ON/OFF - write IR	0 0 0 0 1 D C B (D = 1, C = 0, B = 0) 0x0c
--   Display Clear - write IR	0 0 0 0 0 0 0 1 0x01
--   wait 1.52 mS (41 I/O cycles)
--   Entry Mode set - write IR	0 0 0 0 0 1 I/D S (I/D = 1, S = 0) 0x06
-- Recurring commands
--   Set DDRAM address, top row - write IR - 1 AC6 AC5 AC4 AC3 AC2 AC1 AC0  0x80
--   Write DDRAM Data, top row - write data - x x x x x x x x  (16x)
--   Set DDRAM address, btm row - write IR - 1 AC6 AC5 AC4 AC3 AC2 AC1 AC0  0xc0
--   Write DDRAM Data, btm row - write data - x x x x x x x x  (16x)
--   Set CGRAM Address - write IR - 0 1 AC5 AC4 AC3 AC2 AC1 AC0  0x40
--   Write CGRAM Data - write data - x x x x x x x x  (16x)
-- Duplicate all data for left and right displays.
-- Decode NOP instruction (0x00) to supress the Enable signal
-- Decode Display Clear instruction to use 42 I/O cycles with one enable pulse
-- Decode Set DDRAM instruction to set BRAM addr for reading display data
-- Decode Set CGRAM address instruction to set BRAM addr for reading char data

-- Strategy - omit Display Clear instruction and generate instructions via logic
-- Read display data from shared BRAM, CGRAM data at 0x3c0,
-- DDRAM data at 0x00 for Left display- 1st row, 0x10 for second row,
-- At 0x20, 0x30 for right display 1st and 2nd row, etc...
-- Multiple display pages can be presented at multiples of 0x40.
-- 				BRAM Addresses
-- Page_Sel		Left R1 Left R2 Rght R1 Rght R2
-- 		0		0x000	0x010	0x400	0x410
--		1		0x020	0x030	0x420	0x430
--		2		0x040	0x050	0x440	0x450
--		3		0x060	0x070	0x460	0x470
--		4		0x080	0x090	0x480	0x490
--		5		0x0a0	0x0b0	0x4a0	0x4b0
--		6		0x0c0	0x0d0	0x4c0	0x4d0
--		7		0x0e0	0x0f0	0x4e0	0x4f0
--		8		0x100	0x110	0x500	0x510
--		...
--		30		0x780	0x790	0x7a0	0x7b0
--		31		0x7c0		used for CGRAM
--

ARCHITECTURE behav OF LCD_Drvr IS
  constant FuncSetCmd			: unsigned (LCD_Data'range) := x"38";
  constant DispOnCmd			: unsigned (LCD_Data'range) := x"0c";
  constant EntryModeCmd			: unsigned (LCD_Data'range) := x"06";
  constant DDRTopAddrCmd		: unsigned (LCD_Data'range) := x"80";
  constant DDRBotAddrCmd		: unsigned (LCD_Data'range) := x"c0";
  constant CGRAddrCmd			: unsigned (LCD_Data'range) := x"40";
  constant DunCareCmd			: unsigned (LCD_Data'range) := 8x"-";
  constant Inst_Cntr_Width		: positive := 11; -- 61.04 ms cycle
  constant Inst_Mod				: positive := 2**Inst_Cntr_Width; -- 2048
  signal LCD_MData				: unsigned (LCD_Data'range) := (others => '0');
  signal Inst_Cntr, Inst_Next	: unsigned ((Inst_Cntr_Width - 1) downto 0)
															:= (others => '0');
  signal Addr_Cntr				: unsigned (3 downto 0) := (others => '0');
  signal LCD_Rd_Addr			: unsigned (log2ceil(Mem_Depth)-1 downto 0);
  signal LCD_Row				: std_logic := '0';
  signal Inst_Carry				: std_logic;
  signal LCD_RS_p				: std_logic;
  signal LCD_Mem_Data			: natural;
  type Cmds_State_t is (Cmd_Idl, F_Set_1, F_Set_2, Disp_ON, Ent_Mod,
						DDAddr_Top, DDData_Top,
						DDAddr_Bot, DDData_Bot,
						CGR_Adr, CGR_Data);
  signal Inst_State : Cmds_State_t;
  constant Page_Width : positive := LCD_Rd_Addr'length - Addr_Cntr'length - 2;
begin

  LCD_Timer: (Inst_Carry, Inst_Next) <= ("0" & Inst_Cntr) + 1;
  LCD_Inst: process (Clk) is
  begin
  	if (rising_edge(Clk)) then
	  if (Inst_State /= Cmd_Idl) then
	  	Inst_Cntr	<= Inst_Next;
	  	LCD_E_Lft <= '1' when (Inst_Next(10 downto 9) = "01") else '0';
	  	LCD_E_Rgt <= '1' when (Inst_Next(10 downto 9) = "11") else '0';
	  end if;
	end if;
  end process LCD_Inst;

  LCD_Cntrl: process (Clk) is
  begin
  	if (rising_edge(Clk)) then
	  if (Inst_Carry or Five_ms_En) then
		-- LCD_Row		<= '0';
		case Inst_State is
		  when Cmd_Idl => -- equivalent to "if Five_ms_En"
		  	Inst_State	<= F_Set_1;
			LCD_RS_p	<= '0';
		  when F_Set_1 =>
		  	Inst_State	<= F_Set_2;
			LCD_RS_p	<= '0';
		  when F_Set_2 =>
		  	Inst_State	<= Disp_ON;
			LCD_RS_p	<= '0';
		  when Disp_ON =>
		  	Inst_State	<= Ent_Mod;
			LCD_RS_p	<= '0';
		  when Ent_Mod =>
		  	Inst_State	<= DDAddr_Top;
			LCD_RS_p	<= '0';
		  when DDAddr_Top =>
		  	Inst_State	<= DDData_Top;
			LCD_RS_p	<= '1';
		  when DDData_Top =>
		  	Inst_State	<= DDAddr_Bot when (Addr_Cntr = 15);
			Addr_Cntr	<= Addr_Cntr + 1;
			LCD_RS_p	<= '0' when (Addr_Cntr = 15) else '1';
		  when DDAddr_Bot =>
		  	Inst_State	<= DDData_Bot;
			LCD_RS_p	<= '1';
			-- LCD_Row		<= '1';  -- LCD address for bottom row
		  when DDData_Bot =>
		  	Inst_State	<= CGR_Adr when (Addr_Cntr = 15);
			Addr_Cntr	<= Addr_Cntr + 1;
			LCD_RS_p	<= '0' when (Addr_Cntr = 15) else '1';
			-- LCD_Row		<= '1';  -- LCD address for bottom row
		  when CGR_Adr =>
		  	Inst_State	<= CGR_Data;
			LCD_RS_p	<= '1';
		  when CGR_Data =>
		  	Inst_State	<= Cmd_Idl when (Addr_Cntr = 15);
			Addr_Cntr	<= Addr_Cntr + 1;
			LCD_RS_p	<= '0' when (Addr_Cntr = 15) else '1';
		end case;
	  end if;
	end if;
  end process LCD_Cntrl;

  -- LCD refresh memory address, see memory map above
  LCD_Rd_Addr <=  Inst_Cntr(Inst_Cntr'high) &  -- Left/Right selection
  					to_unsigned(Page_Sel, Page_Width) & LCD_Row & Addr_Cntr;

  LCD_BMem: process (Clk) is
  	variable LCD_Mem : integer_vector(0 to Mem_Depth-1) :=
										(others => character'pos('ÿ'));
	variable Addr_M_Wr, Addr_M_Rd : natural range 0 to Mem_Depth-1;
  begin
  	if (rising_edge(Clk)) then
	  Addr_M_Wr	:= to_integer(Mem_Addr); -- capture write address
	  if (Mem_WE) then
	  	LCD_Mem(Addr_M_Wr)	:= to_integer(Mem_Data);
	  end if;
	  Addr_M_Rd	:= to_integer(LCD_Rd_Addr); -- capture read address
	  LCD_MData	<= to_unsigned(LCD_Mem(Addr_M_Rd), LCD_Data'length);
	end if;
  end process LCD_BMem;

  LCD_Out: process (Clk) is
  begin
  	if (rising_edge(Clk)) then
	  with Inst_State select LCD_RS <= 
	  		'1' when DDData_Top | DDData_Bot | CGR_Data, '0' when others;
	  LCD_Row	<= '1' when (Inst_State = DDData_Bot) else '0';
	  -- Select the commands or data for the LCD data input
	  with Inst_State select LCD_Data <=
  			LCD_MData		when DDData_Top | DDData_Bot | CGR_Data,
			FuncSetCmd		when F_Set_1 | F_Set_2,
			DispOnCmd		when Disp_ON,
			EntryModeCmd	when Ent_Mod, 
			DDRTopAddrCmd	when DDAddr_Top,
			DDRBotAddrCmd	when DDAddr_Bot,
			CGRAddrCmd		when CGR_Adr,
			DunCareCmd		when Cmd_Idl;
	end if;
  end process LCD_Out;

END behav;  -- LCD_Drvr

--------------------------------------------------------------------------------
--  Test bench for LCD_Drvr
--
--  Provide Clk, MilliSec_En, Mem_Data, Mem_Addr, Mem_WE, Page_Sel
--  Verify LCD timing and output, flagging changes
--------------------------------------------------------------------------------

library ieee;
use ieee.NUMERIC_STD.all;
use ieee.std_logic_1164.all;
use IEEE.MATH_REAL.ALL;
use work.Common.all;

entity LCD_Drvr_tb is
	-- Generic declarations of the tested unit
		generic(
		CLK_HZ : REAL := 33.554432E6 );
end LCD_Drvr_tb;

architecture TB_ARCH of LCD_Drvr_tb is
  -- LCD_Drvr I/Os
  constant Clock_Half_Period : time := 500 ms / CLK_HZ;  -- 14901 ps; --
  constant Mem_Depth	: positive := 2048;
  signal Clk			: std_logic := '1';
  signal Five_ms_En		: std_logic;

  signal Mem_Data		: unsigned(8 downto 0);
  signal Mem_Addr		: unsigned(10 downto 0) := (others => '0');
  signal Mem_WE			: std_logic := '0';
  signal Page_Sel		: natural range 0 to 31; -- page to display

  signal LCD_RWn		: std_logic;
  signal LCD_RS			: std_logic;
  signal LCD_E_Lft		: std_logic;
  signal LCD_E_Rgt		: std_logic;
  signal LCD_Data		: unsigned(7 downto 0);

  -- local signals
  signal Disp_Mem_Lft, Disp_Mem_Rgt	: integer_vector (0 to 127) := (others => 32);
  signal CG_Mem_Lft, CG_Mem_Rgt		: integer_vector (0 to 63) := (others => 0);
  signal Script						: integer_vector (0 to 127) := (others => 0);

begin
  Clk_gen: Clk <= not Clk after Clock_Half_Period;

  Disp_ROM_Init: process is -- run once at start, for initializing the pages
  begin
  	for i in Script'range loop
	  Script (i) <= 32 + (i mod 96) + (128 * (i / 96));
	end loop;
	wait;
  end process Disp_ROM_Init;

  Timer: process (Clk) is -- generate 5 ms enable
  	constant ms5cnt_max : integer := integer(CLK_HZ * 0.005);
	variable timer : integer := -1;
  begin
  	if rising_edge(Clk) then
  	  Five_ms_En <= '1' when (timer = 0) else '0';
	  timer := (timer - 1) mod ms5cnt_max;
	end if;
  end process Timer;

  -- Stimulus update
  Disp_Stimulus: process is
  	function ascii(x : natural) return natural is 
	begin
	  return (32 + (x mod (128 - 33)));
	end function ascii; 
	
  	procedure Wr_UUT_Mem (
		Data : in natural range 0 to 255;
		Addr : in natural range 0 to Mem_Depth) is
	begin
  	  Mem_Data	 <= to_unsigned (Data, Mem_Data'length);
  	  Mem_Addr	 <= to_unsigned (Addr, Mem_Addr'length);
	  wait until rising_edge(Clk);
	end procedure Wr_UUT_Mem;
  begin
  	Page_Sel <= 0;
	for j in 0 to 100 loop
  	  wait until falling_edge(LCD_E_Rgt) for 1 ms;
	  if (not LCD_E_Rgt'event) then
	  	wait until rising_edge(Clk);
  	  	Mem_WE	<= '1';
	  	for i in 0 to 15 loop
	  	  Wr_UUT_Mem (ascii(j+i), i);					-- Left, top line
	  	  Wr_UUT_Mem (ascii(j+i+1), i+16);	 			-- Left, bottom line
	  	  Wr_UUT_Mem (ascii(j+i+16), i+(Mem_Depth/2));	-- Right, top line
	  	  Wr_UUT_Mem (ascii(j+i+17), i+16+1024);		-- Right, bottom line
	  	end loop;
  	  	Mem_WE	 <= '0';
	  end if;
	end loop;
	wait;
  end process Disp_Stimulus;

  -- Display data on console
  Disp_Action: process is
  	variable Disp_Line_top_Lft, Disp_Line_bot_Lft : string (1 to 16) := 
													"FEDCBA9876543210";
  	variable Disp_Line_top_Rgt, Disp_Line_bot_Rgt : string (1 to 16) := 
													"DEADBEEFbadDECAF";
  	type Pixel_t is ('_', '@'); 
	function pixel (Data : natural) return string is 
	  variable temp : string (1 to 3);
	begin 
	  temp := Pixel_t'image(Pixel_t'Val(Data)); 
	  report "Pixel - temp = """ & temp & """";
	  return temp(2 to 2); 
	end function pixel; 
	function char_row (abyte : natural) return string is 
	  variable temp : string (1 to 5); 
	begin
	  for i in temp'range loop
	  	temp(i to i) := pixel((abyte/2**(5-i)) mod 2); 
	  end loop; 
	  return temp; 
	end function char_row;
	function row_str (CG_Lft, CG_Rgt : integer_vector; i : integer) return string is 
	begin
	  return  
		  "  "   & char_row(CG_Lft(i)) & "  " & char_row(CG_Lft(i + 8)) 
		& " -  " & char_row(CG_Rgt(i)) & "  " & char_row(CG_Rgt(i + 8)) 
	  ; 
	end function row_str;
  begin
	for i in Disp_Line_top_Lft'range loop  -- format data into strings 
	  -- Addressing string range is 1 based and Disp_Mem is 0 based
	  Disp_Line_top_Lft(i) := character'val(Disp_Mem_Lft(i - 1));
	  Disp_Line_bot_Lft(i) := character'val(Disp_Mem_Lft(i + 63));
	  Disp_Line_top_Rgt(i) := character'val(Disp_Mem_Rgt(i - 1));
	  Disp_Line_bot_Rgt(i) := character'val(Disp_Mem_Rgt(i + 63));
	end loop;
	report "Left/Right LCD DATA Disp - " & integer'image(now/1 us) & " us" &  
	  LF & "|0123456789abcdef - 0123456789abcdef|" &  
	  LF & "|" & Disp_Line_top_Lft & " - " & Disp_Line_top_Rgt & "|" &  
	  LF & "|" & Disp_Line_bot_Lft & " - " & Disp_Line_bot_Rgt & "|" &  
	  LF & "|0123456789abcdef - 0123456789abcdef|" & LF &  
	  LF & "      Left     -     Right     " &  
	  LF & " Char 0 Char 1 - Char 0 Char 1 " &  
	  LF & row_str(CG_Mem_Lft, CG_Mem_Rgt, 0) &  
	  LF & row_str(CG_Mem_Lft, CG_Mem_Rgt, 1) &  
	  LF & row_str(CG_Mem_Lft, CG_Mem_Rgt, 2) &  
	  LF & row_str(CG_Mem_Lft, CG_Mem_Rgt, 3) &  
	  LF & row_str(CG_Mem_Lft, CG_Mem_Rgt, 4) &  
	  LF & row_str(CG_Mem_Lft, CG_Mem_Rgt, 5) &  
	  LF & row_str(CG_Mem_Lft, CG_Mem_Rgt, 6) &  
	  LF & row_str(CG_Mem_Lft, CG_Mem_Rgt, 7) &  
	  LF & "  CG_Mem_Lft(0) = x" & to_hstring(to_unsigned(CG_Mem_Lft(0), 8)) 
	     & ", CG_Mem_Lft(8) = x" & to_hstring(to_unsigned(CG_Mem_Lft(8), 8)) 
	     & ", CG_Mem_Rgt(0) = x" & to_hstring(to_unsigned(CG_Mem_Rgt(0), 8)) 
	     & ", CG_Mem_Rgt(8) = x" & to_hstring(to_unsigned(CG_Mem_Rgt(8), 8))  
		severity warning;
		
  	wait until falling_edge(LCD_E_Rgt);  -- wait until 100 us after E burst 
	while falling_edge(LCD_E_Rgt) loop 
  	  wait until falling_edge(LCD_E_Rgt) for 100 us;
	end loop; 
  end process Disp_Action;

  -- Verification of timing and execution of commands/data writes
  Disp_time: process  (LCD_E_Lft, LCD_E_Rgt, LCD_RS, LCD_RWn, LCD_Data) is
  	constant ST7066U_tC		: time := 52.6 us; -- tCYC adj to 190 kHz clk
  	constant ST7066U_tPW	: time :=  460 ns; 
  	constant ST7066U_tAS	: time :=    0 ns; 
  	constant ST7066U_tDSW	: time :=  100 ns;
  	constant ST7066U_tH		: time :=   10 ns; -- Data Hold time
  	constant ST7066U_tAH	: time :=   10 ns; -- Addr Hold time
  
	type OnOff_t									is (OFF, O_N);
	type Shift_t									is (CURSOR, DISPLAY);
	type IncrDecr_t									is (DECREMENT, INCREMENT);
	type LfRgt_t									is (LEFT, RIGHT);
	variable LCD_Data_event								: time := 0 ns;
	variable LCD_RS_event, LCD_RWn_event				: time := 0 ns;
  	variable LCD_E_rise_Lft, LCD_E_rise_Rgt				: time := 0 ns;
  	variable LCD_E_fall_Lft, LCD_E_fall_Rgt				: time := 0 ns;
	variable Enable_fall_RS_Lft, Enable_fall_RS_Rgt		: boolean := false;
	variable Enable_fall_RWn_Lft, Enable_fall_RWn_Rgt	: boolean := false;
	variable Enable_fall_DATA_Lft, Enable_fall_DATA_Rgt	: boolean := false;
	variable DD_flag_Lft, DD_flag_Rgt					: boolean := false;
	variable MemAddr_Lft, MemAddr_Rgt					: natural;

	-- Verify LCD_E falling edge for timing 
	procedure LCD_En_Fall_Time (
	  	signal LCD_RS	: in	std_logic;
	  	signal LCD_RWn	: in	std_logic;
	  	signal LCD_Data	: in	unsigned;
	  	Rgt_Lft			: in	String;
		LCD_E_rise		: in	time; 
		LCD_RS_event	: in	time; 
		LCD_RWn_event	: in	time ) is
	begin
	  -- Verify E pulse width
	  assert ((now - LCD_E_rise) >= ST7066U_tPW)
		report Rgt_Lft & " E pulsewidth time not met, " &
		  integer'image((now - LCD_E_rise) / 1 ns) & " ns"
		severity failure;
	  -- Verify RS setup time
	  assert ((LCD_E_rise - LCD_RS_event) >= ST7066U_tAS) 
	  			OR (LCD_RS'Last_event > now)
		report Rgt_Lft & " tAS not met for LCD_RS, " 
		  & time'image(LCD_E_rise - LCD_RS_event) 
		  & ", LCD_RS'Last_event = " & time'image(LCD_RS'Last_event)
		  & ", LCD_RS_event = " & time'image(LCD_RS_event)
		  & Rgt_Lft & ", LCD_E_rise = " & time'image(LCD_E_rise) 
		severity failure;
	  -- Verify RW setup time
	  assert ((LCD_E_rise - LCD_RWn_event) >= ST7066U_tAS) 
	  			OR (LCD_RWn'Last_event > now)
		report Rgt_Lft & " tAS not met for LCD_RWn, " 
		  & time'image(LCD_E_rise - LCD_RWn_event) 
		  & ", LCD_RWn'Last_event = " & time'image(LCD_RWn'Last_event)
		  & ", LCD_RWn_event = " & time'image(LCD_RWn_event) & ", "
		  & Rgt_Lft & " LCD_E_rise = " & time'image(LCD_E_rise) 
		severity failure;
			
	  if (LCD_RWn) then	-- Reading?
	  	-- add read timing checks here if needed
	  else				-- or writing?
	  	assert ((now - LCD_Data_event) >= ST7066U_tDSW) 
		  report "Data to " & Rgt_Lft & " E setup time not met on write, " 
					& integer'image((now-LCD_Data_event) / 1 ns) & " ns";
	  end if;  -- LCD_RWn
	end procedure LCD_En_Fall_Time;

	-- Handle LCD_E falling edge actions 
	procedure LCD_En_Fall_Action (
	  	LCD_RS			: in	std_logic;
	  	LCD_RWn			: in	std_logic;
	  	LCD_Data		: in	unsigned;
	  	Rgt_Lft			: in	String;
		LCD_E_fall		: in	time; 
		DD_flag			: inout	boolean;
		MemAddr			: inout	natural;
		signal Disp_Mem	: inout	integer_vector (0 to 127);
		signal CG_Mem	: inout	integer_vector (0 to 63) ) is
	begin
	  if (LCD_RWn) then	-- Reading?
	  	-- add read checks here if needed
	  	assert false report Rgt_Lft & " - READ not implemented";
	  elsif (LCD_RS) then -- Write to DD or CG memory
		if (DD_flag) then -- Display Data write
		  report Rgt_Lft & " - Display DATA write - x" & to_hstring(LCD_Data)
		  				& " to addr " & to_hstring(to_unsigned(MemAddr, 12))
		  	severity warning;
		  assert ((0 <= MemAddr) AND (MemAddr < 16)) OR 
		  		((64 <= MemAddr) AND (MemAddr < 80))
			report Rgt_Lft & " DDaddr range - " & integer'image(MemAddr);
		  Disp_Mem(MemAddr)	<= to_integer(LCD_Data(7 downto 0));
		else  -- Character Graphics Data write
		  report Rgt_Lft & " - Char Gen DATA write - x" & to_hstring(LCD_Data)
		  				& " to addr " & to_hstring(to_unsigned(MemAddr, 12))
		  	severity warning;
		  assert (0 <= MemAddr) AND (MemAddr < 16)
			report Rgt_Lft & " CGaddr range - " & integer'image(MemAddr);
		  CG_Mem(MemAddr)	<= to_integer(LCD_Data(7 downto 0));
		end if;
		assert ((now - LCD_E_fall) >= ST7066U_tC)
		  report Rgt_Lft & " - DDRAM set addr - command time insufficient";
		MemAddr	:= (MemAddr + 1) mod 128;

	  -- RS low - Commands
	  elsif LCD_Data(7) then -- Set address for DDRAM writes
	  	report Rgt_Lft & " - DDRAM set addr command - x" &
		  to_hstring(LCD_Data(6 downto 0)) severity warning;
		assert ((now - LCD_E_fall) >= ST7066U_tC)
		  report Rgt_Lft & " - DDRAM set addr - command time insufficient";
		MemAddr	:= to_integer(LCD_Data(6 downto 0));
		DD_flag	:= TRUE; -- Enable DDRAM data writes

	  elsif LCD_Data(6) then -- Set address for CGRAM writes
	  	report Rgt_Lft & " - CGRAM set addr command - x" &
		  to_hstring(LCD_Data(5 downto 0)) severity warning;
		assert ((now - LCD_E_fall) >= ST7066U_tC)
		  report Rgt_Lft & " - CGRAM set addr - command time insufficient";
		MemAddr	:= to_integer(LCD_Data(5 downto 0));
		DD_flag	:= FALSE; -- Enable CGRAM data writes

	  elsif LCD_Data(5) then -- Function Set command
	  	report Rgt_Lft & " - Function set command - b""" & 
		  to_bstring(LCD_Data(4 downto 2)) & """, " &
		  integer'image(4 + 4 * sl2int(LCD_Data(4))) & " bit bus, " &
		  integer'image(1 + 1 * sl2int(LCD_Data(3))) & " lines, 5x" &
		  integer'image(8 + 2 * sl2int(LCD_Data(2))) & " char"
		   severity warning;
	  	assert LCD_Data(4 downto 2) = "110" 
		  report Rgt_Lft & " - Function Set invalid - x" & to_hstring(LCD_Data);
		assert ((now - LCD_E_fall) >= ST7066U_tC)
		  report Rgt_Lft & " - Function set - command time insufficient";
			  
	  elsif LCD_Data(4) then -- Shift command - error to use
	  	assert false report Rgt_Lft & " - Shift command - x" &  
		  to_hstring(LCD_Data) & " - " &
		  Shift_t'image(Shift_t'Val(sl2int(LCD_Data(3)))) & " shift " &
		  LfRgt_t'image(LfRgt_t'Val(sl2int(LCD_Data(2))));
		assert ((now - LCD_E_fall) >= ST7066U_tC)
		  report Rgt_Lft & " - Shift command - time insufficient";
		  
	  elsif LCD_Data(3) then -- Display on/off command
	  	report Rgt_Lft & " - Display ON/OFF command - b""" & 
		  to_bstring(LCD_Data(2 downto 0)) & """, Display " &
		  OnOff_t'image(OnOff_t'Val(sl2int(LCD_Data(2)))) & ", Cursor " &
		  OnOff_t'image(OnOff_t'Val(sl2int(LCD_Data(1)))) & ", Cur Blink " &
		  OnOff_t'image(OnOff_t'Val(sl2int(LCD_Data(0))))
		   severity warning;
	  	assert LCD_Data(2 downto 0) = "100"
		  report Rgt_Lft & " - Display ON/OFF command invalid - x" & to_hstring(LCD_Data);
		assert ((now - LCD_E_fall) >= ST7066U_tC)
		  report Rgt_Lft & " - Display command - time insufficient";
		  
	  elsif LCD_Data(2) then -- Entry Mode Set command
	  	report Rgt_Lft & " - Entry Mode Set command - b""" & 
		  to_bstring(LCD_Data(1 downto 0)) & """, I/D is move " &
		  IncrDecr_t'image(IncrDecr_t'Val(sl2int(LCD_Data(0)))) & ", SH is " &
		  OnOff_t'image(OnOff_t'Val(sl2int(LCD_Data(0)))) severity warning;
	  	assert LCD_Data(1 downto 0) = "10"
		  report Rgt_Lft & " - Entry Mode Set command invalid x" & to_hstring(LCD_Data);
		assert ((now - LCD_E_fall) >= ST7066U_tC)
		  report Rgt_Lft & " - Entry Mode - command time insufficient";
		  
	  elsif LCD_Data(1) then ----------------
		assert false report Rgt_Lft & " - Return Home command - x" 
			& to_hstring(LCD_Data);
		
	  elsif LCD_Data(0) then ----------------
	  	assert false report Rgt_Lft & " - Clear Display command - x" 
			& to_hstring(LCD_Data);
		
	  else  ----------------
	  	assert false report Rgt_Lft & " - NOP detected - x" 
			& to_hstring(LCD_Data);
	  end if; 
	end procedure LCD_En_Fall_Action;
	
  begin
	--  Left display enable edges
  	if (rising_edge(LCD_E_Lft)) then -- leading edge of enable
	  assert ((now - LCD_E_rise_Lft) >= ST7066U_tC)
		report "Left E cycle time not met, " &
		  integer'image((now - LCD_E_rise_Lft) / 1 ns) & " ns";
	  LCD_E_rise_Lft := now; -- save time to check address setup time
	end if;
  	if (falling_edge(LCD_E_Lft)) then -- active edge of enable
	  LCD_En_Fall_Time (LCD_RS, LCD_RWn, LCD_Data, "LEFT", 
	  	LCD_E_rise_Lft, LCD_RS_event, LCD_RWn_event);
	  LCD_En_Fall_Action (LCD_RS, LCD_RWn, LCD_Data, "LEFT", 
		LCD_E_fall_Lft, DD_flag_Lft, MemAddr_Lft, Disp_Mem_Lft, CG_Mem_Lft); 
	  LCD_E_fall_Lft		:= now; -- save time to check address hold
	  Enable_fall_RS_Lft	:= TRUE;
	  Enable_fall_RWn_Lft	:= TRUE;
	end if;  

	--  Right display enable edges
  	if (rising_edge(LCD_E_Rgt)) then -- leading edge of enable
	  assert ((now - LCD_E_rise_Rgt) >= ST7066U_tC)
		report "Right E cycle time not met, " & 
		  integer'image((now - LCD_E_rise_Rgt) / 1 ns) & " ns";
	  LCD_E_rise_Rgt := now; -- save time to check address setup time
	end if;
  	if (falling_edge(LCD_E_Rgt)) then -- active edge of enable
	  LCD_En_Fall_Time (LCD_RS, LCD_RWn, LCD_Data, "RIGHT", 
	  	LCD_E_rise_Rgt, LCD_RS_event, LCD_RWn_event);
	  LCD_En_Fall_Action (LCD_RS, LCD_RWn, LCD_Data, "RIGHT", 
		LCD_E_fall_Rgt, DD_flag_Rgt, MemAddr_Rgt, Disp_Mem_Rgt, CG_Mem_Rgt);
	  LCD_E_fall_Rgt		:= now; -- save time to check address hold
	  Enable_fall_RS_Rgt	:= TRUE;
	  Enable_fall_RWn_Rgt	:= TRUE;
	end if;  
	
	-- Check RS hold time against both enables
  	if (LCD_RS'event) then -- Check hold time to enable, tAH
	  if (Enable_fall_RS_Lft) then
	  	Enable_fall_RS_Lft := FALSE;
	  	assert ((now - LCD_E_fall_Lft) >= ST7066U_tAH)
		  report "RS to left E hold time not met, " &
		  	integer'image((now - LCD_E_fall_Lft) / 1 ns) & " ns";
	  end if;
	  if (Enable_fall_RS_Rgt) then
	  	Enable_fall_RS_Rgt := FALSE;
	  	assert ((now - LCD_E_fall_Rgt) >= ST7066U_tAH)
		  report "RS to right E hold time not met, " &
		  	integer'image((now - LCD_E_fall_Rgt) / 1 ns) & " ns";
	  end if;
	  LCD_RS_event := now;
	end if;

	-- Check RW hold time against both enables
  	if (LCD_RWn'event) then -- Check hold time to enable, tAH
	  if (Enable_fall_RWn_Lft) then
	  	Enable_fall_RWn_Lft := FALSE;
	  	assert ((now - LCD_E_fall_Lft) >= ST7066U_tAH)
		  report "RW to left E setup/hold time not met, " &
		  	integer'image((now - LCD_E_fall_Lft) / 1 ns) & " ns";
	  end if;
	  if (Enable_fall_RWn_Rgt) then
	  	Enable_fall_RWn_Rgt := FALSE;
	  	assert ((now - LCD_E_fall_Rgt) >= ST7066U_tAH)
		  report "RW to right E setup/hold time not met, " &
		  	integer'image((now - LCD_E_fall_Rgt) / 1 ns) & " ns";
	  end if;
	  LCD_RWn_event := now;
	end if;

	-- Check Data hold time against enables
  	if (LCD_Data'event) then -- Check hold time to enable, tH
	  if (Enable_fall_DATA_Lft) then
	  	Enable_fall_DATA_Lft := FALSE;
	  	assert ((now - LCD_E_fall_Lft) >= ST7066U_tH)
		  report "Data to left E setup/hold time not met, " &
		  	integer'image((now - LCD_E_fall_Lft) / 1 ns) & " ns";
	  end if;
	  if (Enable_fall_DATA_Rgt) then
	  	Enable_fall_DATA_Rgt := FALSE;
	  	assert ((now - LCD_E_fall_Rgt) >= ST7066U_tH)
		  report "Data to right E setup/hold time not met, " &
		  	integer'image((now - LCD_E_fall_Rgt) / 1 ns) & " ns";
	  end if;
	  LCD_Data_event := now;
	end if;

  end process Disp_time;

  LCD_UUT: ENTITY LCD_Drvr
	GENERIC map (
      CLK_HZ		=> CLK_HZ,
	  Mem_Depth		=> Mem_Depth
	)
	port map (
	  Clk				=> Clk,

	  Five_ms_En		=> Five_ms_En,

	  Mem_Data			=> Mem_Data,
	  Mem_Addr			=> Mem_Addr,
	  Mem_WE			=> Mem_WE,
	  Page_Sel			=> Page_Sel,

	  LCD_RW			=> LCD_RWn,
	  LCD_RS			=> LCD_RS,
	  LCD_E_Lft			=> LCD_E_Lft,
	  LCD_E_Rgt			=> LCD_E_Rgt,
	  LCD_Data			=> LCD_Data
	); -- LCD_UUT : LCD_Drvr_tb

end TB_ARCH;  -- LCD_Drvr_tb
