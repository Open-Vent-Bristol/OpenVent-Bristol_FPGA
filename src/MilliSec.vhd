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
use ieee.numeric_std.all;
use IEEE.MATH_REAL.all;
-- Library Alarm_Common;
use work.Alarm_common.all;

-- Provide 5 ms and 256 ms (quarter second) enables
entity MilliSec is
    port (
        Clk        : in STD_LOGIC;
        MHz4_En    : out STD_LOGIC := '0'; -- output enable 1 clk at 4.19 MHz
        I2C_Clk_En : out STD_LOGIC := '0'; -- output enable 1 clk at 524 kHz
        Five_ms_En : out STD_LOGIC := '0'; -- output enable 1 clk every 5 ms
        FourHz_En  : out STD_LOGIC := '0'  -- output enable 1 clk every 250 ms
    );
end MilliSec;

architecture behav of MilliSec is -- initial values assist reset startup
    signal I2C_Clk_Cntr              : unsigned(log2ceil(I2C_Clk_MAX_Cnt) - 1 downto 0) := ("110", others => '0');
    signal I2C_Clk_Nxt               : unsigned(log2ceil(I2C_Clk_MAX_Cnt) downto 0)     := ("110", others => '0');
    signal Five_ms_Cntr              : unsigned(log2ceil(Five_ms_MAX_Cnt) - 1 downto 0) := ("110", others => '0');
    signal Five_ms_Nxt               : unsigned(log2ceil(Five_ms_MAX_Cnt) downto 0)     := ("110", others => '0');
    signal Hold_Cntr                 : unsigned(log2ceil(Hold_ms) - 1 downto 0)         := ("11", others  => '0');
    signal Hold_Nxt                  : unsigned(log2ceil(Hold_ms) downto 0)             := ("11", others  => '0');
    signal Five_ms_Carry, Hold_Carry : STD_LOGIC                                        := '0';
    signal MHz4_Carry, I2C_Clk_Carry : STD_LOGIC                                        := '0';
begin
    MHz4_Carry    <= '1' when I2C_Clk_Cntr(1 downto 0) = "11" else '0';
    I2C_Clk_Nxt   <= ("0" & I2C_Clk_Cntr) - 1;
    I2C_Clk_Carry <= I2C_Clk_Nxt(I2C_Clk_Nxt'high);
    Five_ms_Nxt   <= ("0" & Five_ms_Cntr) - 1;
    Five_ms_Carry <= Five_ms_Nxt(Five_ms_Nxt'high);
    Hold_Nxt      <= ("0" & Hold_Cntr) - 1;
    Hold_Carry    <= Hold_Nxt(Hold_Nxt'high);

    Enables : process (Clk) is -- Time the 5 ms and quarter second enables
    begin
        if (rising_edge(Clk)) then
            MHz4_En      <= MHz4_Carry;
            I2C_Clk_En   <= '0'; -- each enable is high for 1 clock
            Five_ms_En   <= '0';
            FourHz_En    <= '0';
            I2C_Clk_Cntr <= I2C_Clk_Nxt(I2C_Clk_Cntr'range); -- binary modulus

            if (I2C_Clk_Carry) then
                I2C_Clk_En <= '1';

                if (not Five_ms_Carry) then
                    Five_ms_Cntr <= Five_ms_Nxt(Five_ms_Cntr'range);
                else
                    Five_ms_Cntr <= to_unsigned(Five_ms_MAX_Cnt, Five_ms_Cntr'length);
                    Five_ms_En   <= '1';

                    if (not Hold_Carry) then
                        Hold_Cntr <= Hold_Nxt(Hold_Cntr'range);
                    else
                        Hold_Cntr <= to_unsigned(Hold_ms, Hold_Cntr'length);
                        FourHz_En <= '1';
                    end if;
                end if;
            end if;
        end if;
    end process Enables;
end behav; -- MilliSec
