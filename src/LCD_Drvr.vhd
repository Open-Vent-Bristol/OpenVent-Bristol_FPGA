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
use ieee.numeric_std.all;
use IEEE.MATH_REAL.all;
use work.Alarm_common.all;

entity LCD_Drvr is
    generic (
        CLK_HZ    : REAL     := 33.554432E6; -- 2^25
        Mem_Depth : POSITIVE := 2048
	);
    port (
        Clk        : in STD_LOGIC;

        Five_ms_En : in STD_LOGIC; -- 5 ms enable

        Mem_Data   : in unsigned(8 downto 0);
        Mem_Addr   : in unsigned(10 downto 0);
        Mem_WE     : in STD_LOGIC;
        Page_Sel   : in NATURAL range 0 to 31; -- selects page to display

        LCD_RW     : out STD_LOGIC := '0';
        LCD_RS     : out STD_LOGIC := '1';
        LCD_E_Lft  : out STD_LOGIC := '0';
        LCD_E_Rgt  : out STD_LOGIC := '0';
        LCD_Data   : inout unsigned(7 downto 0)
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

architecture behav of LCD_Drvr is
    constant FuncSetCmd         : unsigned (LCD_Data'range) := x"38";
    constant DispOnCmd          : unsigned (LCD_Data'range) := x"0c";
    constant EntryModeCmd       : unsigned (LCD_Data'range) := x"06";
    constant DDRTopAddrCmd      : unsigned (LCD_Data'range) := x"80";
    constant DDRBotAddrCmd      : unsigned (LCD_Data'range) := x"c0";
    constant CGRAddrCmd         : unsigned (LCD_Data'range) := x"40";
    constant DunCareCmd         : unsigned (LCD_Data'range) := 8x"-";
    constant Inst_Cntr_Width    : POSITIVE                  := 11;                   -- 61.04 ms cycle
    constant Inst_Mod           : POSITIVE                  := 2**Inst_Cntr_Width; -- 2048
    signal LCD_MData            : unsigned (LCD_Data'range) := (others => '0');
    signal Inst_Cntr, Inst_Next : unsigned ((Inst_Cntr_Width - 1) downto 0)
    := (others                                             => '0');
    signal Addr_Cntr    : unsigned (3 downto 0) := (others => '0');
    signal LCD_Rd_Addr  : unsigned (log2ceil(Mem_Depth) - 1 downto 0);
    signal LCD_Row      : STD_LOGIC := '0';
    signal Inst_Carry   : STD_LOGIC;
    signal LCD_RS_p     : STD_LOGIC;
    signal LCD_Mem_Data : NATURAL;
  type Cmds_State_t is (Cmd_Idl, F_Set_1, F_Set_2, Disp_ON, Ent_Mod,
						DDAddr_Top, DDData_Top,
						DDAddr_Bot, DDData_Bot,
						CGR_Adr, CGR_Data);
    signal Inst_State   : Cmds_State_t;
    constant Page_Width : POSITIVE := LCD_Rd_Addr'length - Addr_Cntr'length - 2;
begin

    LCD_Timer : (Inst_Carry, Inst_Next) <= ("0" & Inst_Cntr) + 1;
    LCD_Inst : process (Clk) is
  begin
  	if (rising_edge(Clk)) then
	  if (Inst_State /= Cmd_Idl) then
                Inst_Cntr <= Inst_Next;
                LCD_E_Lft <= '1' when (Inst_Next(10 downto 9) = "01") else
                    '0';
                LCD_E_Rgt <= '1' when (Inst_Next(10 downto 9) = "11") else
                    '0';
	  end if;
	end if;
  end process LCD_Inst;

    LCD_Cntrl : process (Clk) is
  begin
  	if (rising_edge(Clk)) then
	  if (Inst_Carry or Five_ms_En) then
		-- LCD_Row		<= '0';
		case Inst_State is
		  when Cmd_Idl => -- equivalent to "if Five_ms_En"
                        Inst_State <= F_Set_1;
                        LCD_RS_p   <= '0';
		  when F_Set_1 =>
                        Inst_State <= F_Set_2;
                        LCD_RS_p   <= '0';
		  when F_Set_2 =>
                        Inst_State <= Disp_ON;
                        LCD_RS_p   <= '0';
		  when Disp_ON =>
                        Inst_State <= Ent_Mod;
                        LCD_RS_p   <= '0';
		  when Ent_Mod =>
                        Inst_State <= DDAddr_Top;
                        LCD_RS_p   <= '0';
		  when DDAddr_Top =>
                        Inst_State <= DDData_Top;
                        LCD_RS_p   <= '1';
		  when DDData_Top =>
                        Inst_State <= DDAddr_Bot when (Addr_Cntr = 15);
                        Addr_Cntr  <= Addr_Cntr + 1;
                        LCD_RS_p   <= '0' when (Addr_Cntr = 15) else
                            '1';
		  when DDAddr_Bot =>
                        Inst_State <= DDData_Bot;
                        LCD_RS_p   <= '1';
			-- LCD_Row		<= '1';  -- LCD address for bottom row
		  when DDData_Bot =>
                        Inst_State <= CGR_Adr when (Addr_Cntr = 15);
                        Addr_Cntr  <= Addr_Cntr + 1;
                        LCD_RS_p   <= '0' when (Addr_Cntr = 15) else
                            '1';
			-- LCD_Row		<= '1';  -- LCD address for bottom row
		  when CGR_Adr =>
                        Inst_State <= CGR_Data;
                        LCD_RS_p   <= '1';
		  when CGR_Data =>
                        Inst_State <= Cmd_Idl when (Addr_Cntr = 15);
                        Addr_Cntr  <= Addr_Cntr + 1;
                        LCD_RS_p   <= '0' when (Addr_Cntr = 15) else
                            '1';
		end case;
	  end if;
	end if;
  end process LCD_Cntrl;

  -- LCD refresh memory address, see memory map above
    LCD_Rd_Addr <= Inst_Cntr(Inst_Cntr'high) & -- Left/Right selection
  					to_unsigned(Page_Sel, Page_Width) & LCD_Row & Addr_Cntr;

    LCD_BMem : process (Clk) is
        variable LCD_Mem : integer_vector(0 to Mem_Depth - 1) :=
        (others => CHARACTER'pos('Ã¿'));
        variable Addr_M_Wr, Addr_M_Rd : NATURAL range 0 to Mem_Depth - 1;
  begin
  	if (rising_edge(Clk)) then
            Addr_M_Wr := to_integer(Mem_Addr); -- capture write address
	  if (Mem_WE) then
                LCD_Mem(Addr_M_Wr) := to_integer(Mem_Data);
	  end if;
            Addr_M_Rd := to_integer(LCD_Rd_Addr); -- capture read address
            LCD_MData <= to_unsigned(LCD_Mem(Addr_M_Rd), LCD_Data'length);
	end if;
  end process LCD_BMem;

    LCD_Out : process (Clk) is
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

end behav; -- LCD_Drvr

--------------------------------------------------------------------------------
--  Test bench for LCD_Drvr
--
--  Provide Clk, MilliSec_En, Mem_Data, Mem_Addr, Mem_WE, Page_Sel
--  Verify LCD timing and output, flagging changes
--------------------------------------------------------------------------------
