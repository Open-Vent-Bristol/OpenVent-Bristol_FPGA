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
use work.Alarm_Common.all;

entity MilliSec_tb is
end MilliSec_tb;

architecture TB_ARCH of MilliSec_tb is
    constant CLK_Hz_tb    : real      := 33554432.0;          -- 2^25 MHz
    constant Clk_Half_Per : TIME      := 500 ms / CLK_Hz_tb;  -- 14901 ps; --
    constant Clk_Period   : TIME      := (1 sec / CLK_Hz_tb); -- 2^25 MHz clock
    signal Clk            : STD_LOGIC := '1';
    signal MHz4_En        : STD_LOGIC;
    signal I2C_Clk_En     : STD_LOGIC;
    signal Five_ms_En     : STD_LOGIC;
    signal FourHz_En      : STD_LOGIC;

    -- Check period and pulse width of enables
    procedure TestEn (
        signal Pulse   : in STD_LOGIC;
        Period, Window : in TIME;
        Pulse_Name     : in STRING;
        Prev_Edge      : inout TIME) is
        variable test  : TIME := 0 ns;
    begin
        if rising_edge(Pulse) then
            test := now - Prev_Edge;                                     -- get period, compare to window
            -- report Pulse_Name & " Prev_Edge = " & time'image(Prev_Edge);
            assert (Prev_Edge = 0 sec) or (abs(test - Period) <= Window) -- ignore 1st
            report Pulse_Name & " period failed " & TIME'image(test) &
                ", LAST_EVENT = " & TIME'image(Pulse'LAST_EVENT) &
                ", Prev_Edge = " & TIME'image(Prev_Edge);
            Prev_Edge := now;
        elsif falling_edge(Pulse) then -- compare pulse width to one clock
            test := (now - Prev_Edge);
            assert (abs(test - Clk_Period) < 1 ps)
            report Pulse_Name & " width failed " & TIME'image(test)
                & ", start " & TIME'image(Prev_Edge) & ", end " & TIME'image(now);
        end if;
    end procedure TestEn;

begin

    Clk_gen            : Clk <= not Clk after Clk_Half_Per;

    test_MHz4 : process (MHz4_En) is
        variable Prev_Edge : TIME := 0 ns;
    begin -- 8 clocks period, 4.194,304 MHz, 238.419 ns
        TestEn (MHz4_En, (Clk_Period * 4), 15 ns, MHz4_En'Simple_name, Prev_Edge);
    end process test_MHz4;

    test_I2C : process (I2C_Clk_En) is
        variable Prev_Edge : TIME := 0 ns;
    begin -- 64 clocks period, 524,288 Hz, 1.907,348,632 us, window of half clock
        TestEn (I2C_Clk_En, (Clk_Period * 64),
        Clk_Half_Per, "I2C_Clk_En", Prev_Edge);
    end process test_I2C;

    test_ms : process (Five_ms_En) is
        variable Prev_Edge : TIME := 0 ns;
    begin -- 5 ms period, 200 Hz, window 64 x I2C window
        TestEn (Five_ms_En, 5 ms, (64 * Clk_Half_Per), "Five_ms_En", Prev_Edge);
    end process test_ms;

    test_hold : process (FourHz_En) is
        variable Prev_Edge : TIME := 0 ns;
    begin -- 250 ms period, 4 Hz,
        TestEn (FourHz_En, 250 ms, (3200 * Clk_Half_Per), "FourHz_En", Prev_Edge);
    end process test_hold;

    MS_UUT : entity work.MilliSec
        port map (
            Clk        => Clk,
            MHz4_En    => MHz4_En,
            I2C_Clk_En => I2C_Clk_En,
            Five_ms_En => Five_ms_En,
            FourHz_En  => FourHz_En
        );

end TB_ARCH; -- MilliSec_tb
