--------------------------------------------------------------------------------
--  Test bench for Key_Pad
--
--  Provide clock and Buttons - Five_ms_En and Hold_En from MilliSec component
--  Verify debounce of each button independently, 50 ms bounce window
--  Verify 3 sec hold time of each button
--------------------------------------------------------------------------------

library ieee;
use ieee.NUMERIC_STD.all;
use ieee.std_logic_1164.all;
use work.Alarm_common.all;

entity Key_Pad_tb is
    -- Generic declarations of the tested unit
    generic (
        CLK_HZ : REAL := 33.554432E6);
end Key_Pad_tb;

architecture TB_ARCH of Key_Pad_tb is
    constant Clock_Half_Period : TIME      := 500 ms / CLK_HZ; -- 14901 ps; --
    -- type Button_rng            is range 3 downto 0;
    -- subtype ButtonSel_type    is natural range Button_rng;
    signal Clk                 : STD_LOGIC := '1';
    signal MHz4_En             : STD_LOGIC;
    signal I2C_Clk_En          : STD_LOGIC;
    signal Five_ms_En          : STD_LOGIC;
    signal Four_Hz_En          : STD_LOGIC;
    signal Hold_En             : STD_LOGIC;
    signal Buttons             : unsigned(3 downto 0) := (others => '1');
    signal Button_Press        : unsigned(3 downto 0) := (others => '0');
    signal Button_Hold         : unsigned(3 downto 0) := (others => '0');
    signal Spkr_Tick           : STD_LOGIC;
    signal Spkr_Boop           : STD_LOGIC;

    procedure Test_Button (
        signal Button_Action : in unsigned;
        DelayA               : in TIME;
        DelayB               : in TIME;
        Index                : INTEGER;
        Sig_name             : STRING) is
        variable Temp        : unsigned (Button_Action'range) := Button_Action;
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
        Temp        := (others => '0');
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

    MS: ENTITY work.MilliSec
        port map (
            Clk        => Clk,
            MHz4_En    => MHz4_En,
            I2C_Clk_En => I2C_Clk_En,
            Five_ms_En => Five_ms_En,
            Four_Hz_En => Four_Hz_En
        );

    Keys_UUT: ENTITY work.Key_Pad
        GENERIC map (
            CLK_HZ => CLK_HZ
        )
        port map (
            Clk          => Clk,
            Five_ms_En   => Five_ms_En,
            Four_Hz_En   => Four_Hz_En,
            Buttons      => Buttons,
            Button_Press => Button_Press,
            Button_Hold  => Button_Hold,
            Spkr_Tick    => Spkr_Tick,
            Spkr_Boop    => Spkr_Boop
        ); -- Keys_UUT : Key_Pad

end TB_ARCH;  -- Key_Pad_tb
