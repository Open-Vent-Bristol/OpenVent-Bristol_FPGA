--------------------------------------------------------------------------------
--  Test bench for LCD_Drvr
--
--  Provide Clk, MilliSec_En, Mem_Data, Mem_Addr, Mem_WE, Page_Sel
--  Verify LCD timing and output, flagging changes
--------------------------------------------------------------------------------

library ieee;
use ieee.NUMERIC_STD.all;
use ieee.std_logic_1164.all;
use IEEE.MATH_REAL.all;
use work.Alarm_common.all;

entity LCD_Drvr_tb is
    -- Generic declarations of the tested unit
    generic (
        CLK_HZ : REAL := 33.554432E6);
end LCD_Drvr_tb;

architecture TB_ARCH of LCD_Drvr_tb is
    -- LCD_Drvr I/Os
    constant Clock_Half_Period        : TIME      := 500 ms / CLK_HZ; -- 14901 ps; --
    constant Mem_Depth                : POSITIVE  := 2048;
    signal Clk                        : STD_LOGIC := '1';
    signal Five_ms_En                 : STD_LOGIC;

    signal Mem_Data                   : unsigned(8 downto 0);
    signal Mem_Addr                   : unsigned(10 downto 0) := (others => '0');
    signal Mem_WE                     : STD_LOGIC             := '0';
    signal Page_Sel                   : NATURAL range 0 to 31; -- page to display

    signal LCD_RWn                    : STD_LOGIC;
    signal LCD_RS                     : STD_LOGIC;
    signal LCD_E_Lft                  : STD_LOGIC;
    signal LCD_E_Rgt                  : STD_LOGIC;
    signal LCD_Data                   : unsigned(7 downto 0);

    -- local signals
    signal Disp_Mem_Lft, Disp_Mem_Rgt : integer_vector (0 to 127) := (others => 32);
    signal CG_Mem_Lft, CG_Mem_Rgt     : integer_vector (0 to 63)  := (others => 0);
    signal Script                     : integer_vector (0 to 127) := (others => 0);

begin
    Clk_gen : Clk <= not Clk after Clock_Half_Period;

    Disp_ROM_Init : process is -- run once at start, for initializing the pages
    begin
        for i in Script'range loop
            Script (i) <= 32 + (i mod 96) + (128 * (i / 96));
        end loop;
        wait;
    end process Disp_ROM_Init;

    Timer_p : process (Clk) is -- generate 5 ms enable
        constant ms5cnt_max : INTEGER := INTEGER(CLK_HZ * 0.005);
        variable timer      : INTEGER := - 1;
    begin
        if rising_edge(Clk) then
            Five_ms_En <= '1' when (timer = 0) else
                '0';
            timer := (timer - 1) mod ms5cnt_max;
        end if;
    end process Timer_p;

    -- Stimulus update
    Disp_Stimulus : process is
        function ascii(x : NATURAL) return NATURAL is
        begin
            return (32 + (x mod (128 - 33)));
        end function ascii;

        procedure Wr_UUT_Mem (
            Data : in NATURAL range 0 to 255;
            Addr : in NATURAL range 0 to Mem_Depth) is
        begin
            Mem_Data <= to_unsigned (Data, Mem_Data'length);
            Mem_Addr <= to_unsigned (Addr, Mem_Addr'length);
            wait until rising_edge(Clk);
        end procedure Wr_UUT_Mem;
    begin
        Page_Sel <= 0;
        for j in 0 to 100 loop
            wait until falling_edge(LCD_E_Rgt) for 1 ms;
            if (not LCD_E_Rgt'event) then
                wait until rising_edge(Clk);
                Mem_WE <= '1';
                for i in 0 to 15 loop
                    Wr_UUT_Mem (ascii(j + i), i);                      -- Left, top line
                    Wr_UUT_Mem (ascii(j + i + 1), i + 16);             -- Left, bottom line
                    Wr_UUT_Mem (ascii(j + i + 16), i + (Mem_Depth/2)); -- Right, top line
                    Wr_UUT_Mem (ascii(j + i + 17), i + 16 + 1024);     -- Right, bottom line
                end loop;
                Mem_WE <= '0';
            end if;
        end loop;
        wait;
    end process Disp_Stimulus;

    -- Display data on console
    Disp_Action : process is
        variable Disp_Line_top_Lft, Disp_Line_bot_Lft : STRING (1 to 16) :=
        "FEDCBA9876543210";
        variable Disp_Line_top_Rgt, Disp_Line_bot_Rgt : STRING (1 to 16) :=
        "DEADBEEFbadDECAF";
        type Pixel_t is ('_', '@');
        function pixel (Data : NATURAL) return STRING is
            variable temp        : STRING (1 to 3);
        begin
            temp := Pixel_t'image(Pixel_t'Val(Data));
            -- report "Pixel - temp = """ & temp & """";
            return temp(2 to 2);
        end function pixel;
        function char_row (abyte : NATURAL) return STRING is
            variable temp            : STRING (1 to 5);
        begin
            for i in temp'range loop
                temp(i to i) := pixel((abyte/2**(5 - i)) mod 2);
            end loop;
            return temp;
        end function char_row;
        function row_str (CG_Lft, CG_Rgt : integer_vector; i : INTEGER) return STRING is
        begin
            return
            "  " & char_row(CG_Lft(i)) & "  " & char_row(CG_Lft(i + 8))
            & " -  " & char_row(CG_Rgt(i)) & "  " & char_row(CG_Rgt(i + 8))
            ;
        end function row_str;
    begin
        for i in Disp_Line_top_Lft'range loop -- format data into strings
            -- Addressing string range is 1 based and Disp_Mem is 0 based
            Disp_Line_top_Lft(i) := CHARACTER'val(Disp_Mem_Lft(i - 1));
            Disp_Line_bot_Lft(i) := CHARACTER'val(Disp_Mem_Lft(i + 63));
            Disp_Line_top_Rgt(i) := CHARACTER'val(Disp_Mem_Rgt(i - 1));
            Disp_Line_bot_Rgt(i) := CHARACTER'val(Disp_Mem_Rgt(i + 63));
        end loop;
        report "Left/Right LCD DATA Disp - " & INTEGER'image(now/1 us) & " us" &
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

        wait until falling_edge(LCD_E_Rgt); -- wait until 100 us after E burst
        while falling_edge(LCD_E_Rgt) loop
            wait until falling_edge(LCD_E_Rgt) for 100 us;
        end loop;
    end process Disp_Action;

    -- Verification of timing and execution of commands/data writes
    Disp_time : process (LCD_E_Lft, LCD_E_Rgt, LCD_RS, LCD_RWn, LCD_Data) is
        constant ST7066U_tC   : TIME := 52.6 us; -- tCYC adj to 190 kHz clk
        constant ST7066U_tPW  : TIME := 460 ns;
        constant ST7066U_tAS  : TIME := 0 ns;
        constant ST7066U_tDSW : TIME := 100 ns;
        constant ST7066U_tH   : TIME := 10 ns; -- Data Hold time
        constant ST7066U_tAH  : TIME := 10 ns; -- Addr Hold time

        type OnOff_t is (OFF, O_N);
        type Shift_t is (CURSOR, DISPLAY);
        type IncrDecr_t is (DECREMENT, INCREMENT);
        type LfRgt_t is (LEFT, RIGHT);
        variable LCD_Data_event                             : TIME    := 0 ns;
        variable LCD_RS_event, LCD_RWn_event                : TIME    := 0 ns;
        variable LCD_E_rise_Lft, LCD_E_rise_Rgt             : TIME    := 0 ns;
        variable LCD_E_fall_Lft, LCD_E_fall_Rgt             : TIME    := 0 ns;
        variable Enable_fall_RS_Lft, Enable_fall_RS_Rgt     : BOOLEAN := false;
        variable Enable_fall_RWn_Lft, Enable_fall_RWn_Rgt   : BOOLEAN := false;
        variable Enable_fall_DATA_Lft, Enable_fall_DATA_Rgt : BOOLEAN := false;
        variable DD_flag_Lft, DD_flag_Rgt                   : BOOLEAN := false;
        variable MemAddr_Lft, MemAddr_Rgt                   : NATURAL;

        -- Verify LCD_E falling edge for timing
        procedure LCD_En_Fall_Time (
            signal LCD_RS   : in STD_LOGIC;
            signal LCD_RWn  : in STD_LOGIC;
            signal LCD_Data : in unsigned;
            Rgt_Lft         : in STRING;
            LCD_E_rise      : in TIME;
            LCD_RS_event    : in TIME;
            LCD_RWn_event   : in TIME) is
        begin
            -- Verify E pulse width
            assert ((now - LCD_E_rise) >= ST7066U_tPW)
            report Rgt_Lft & " E pulsewidth time not met, " &
                INTEGER'image((now - LCD_E_rise) / 1 ns) & " ns"
                severity failure;
            -- Verify RS setup time
            assert ((LCD_E_rise - LCD_RS_event) >= ST7066U_tAS)
            or (LCD_RS'Last_event > now)
            report Rgt_Lft & " tAS not met for LCD_RS, "
                & TIME'image(LCD_E_rise - LCD_RS_event)
                & ", LCD_RS'Last_event = " & TIME'image(LCD_RS'Last_event)
                & ", LCD_RS_event = " & TIME'image(LCD_RS_event)
                & Rgt_Lft & ", LCD_E_rise = " & TIME'image(LCD_E_rise)
                severity failure;
            -- Verify RW setup time
            assert ((LCD_E_rise - LCD_RWn_event) >= ST7066U_tAS)
            or (LCD_RWn'Last_event > now)
            report Rgt_Lft & " tAS not met for LCD_RWn, "
                & TIME'image(LCD_E_rise - LCD_RWn_event)
                & ", LCD_RWn'Last_event = " & TIME'image(LCD_RWn'Last_event)
                & ", LCD_RWn_event = " & TIME'image(LCD_RWn_event) & ", "
                & Rgt_Lft & " LCD_E_rise = " & TIME'image(LCD_E_rise)
                severity failure;

            if (LCD_RWn) then -- Reading?
                -- add read timing checks here if needed
            else              -- or writing?
                assert ((now - LCD_Data_event) >= ST7066U_tDSW)
                report "Data to " & Rgt_Lft & " E setup time not met on write, "
                    & INTEGER'image((now - LCD_Data_event) / 1 ns) & " ns";
            end if; -- LCD_RWn
        end procedure LCD_En_Fall_Time;

        -- Handle LCD_E falling edge actions
        procedure LCD_En_Fall_Action (
            LCD_RS          : in STD_LOGIC;
            LCD_RWn         : in STD_LOGIC;
            LCD_Data        : in unsigned;
            Rgt_Lft         : in STRING;
            LCD_E_fall      : in TIME;
            DD_flag         : inout BOOLEAN;
            MemAddr         : inout NATURAL;
            signal Disp_Mem : inout integer_vector (0 to 127);
            signal CG_Mem   : inout integer_vector (0 to 63)) is
        begin
            if (LCD_RWn) then -- Reading?
                -- add read checks here if needed
                assert false report Rgt_Lft & " - READ not implemented";
            elsif (LCD_RS) then -- Write to DD or CG memory
                if (DD_flag) then   -- Display Data write
                    report Rgt_Lft & " - Display DATA write - x" & to_hstring(LCD_Data)
                        & " to addr " & to_hstring(to_unsigned(MemAddr, 12))
                        severity warning;
                    assert ((0 <= MemAddr) and (MemAddr < 16)) or
                    ((64       <= MemAddr) and (MemAddr < 80))
                    report Rgt_Lft & " DDaddr range - " & INTEGER'image(MemAddr);
                    Disp_Mem(MemAddr) <= to_integer(LCD_Data(7 downto 0));
                else -- Character Graphics Data write
                    report Rgt_Lft & " - Char Gen DATA write - x" & to_hstring(LCD_Data)
                        & " to addr " & to_hstring(to_unsigned(MemAddr, 12))
                        severity warning;
                    assert (0 <= MemAddr) and (MemAddr < 16)
                    report Rgt_Lft & " CGaddr range - " & INTEGER'image(MemAddr);
                    CG_Mem(MemAddr) <= to_integer(LCD_Data(7 downto 0));
                end if;
                assert ((now - LCD_E_fall) >= ST7066U_tC)
                report Rgt_Lft & " - DDRAM set addr - command time insufficient";
                MemAddr := (MemAddr + 1) mod 128;

                -- RS low - Commands
            elsif LCD_Data(7) then -- Set address for DDRAM writes
                report Rgt_Lft & " - DDRAM set addr command - x" &
                    to_hstring(LCD_Data(6 downto 0)) severity warning;
                assert ((now - LCD_E_fall) >= ST7066U_tC)
                report Rgt_Lft & " - DDRAM set addr - command time insufficient";
                MemAddr := to_integer(LCD_Data(6 downto 0));
                DD_flag := TRUE;       -- Enable DDRAM data writes

            elsif LCD_Data(6) then -- Set address for CGRAM writes
                report Rgt_Lft & " - CGRAM set addr command - x" &
                    to_hstring(LCD_Data(5 downto 0)) severity warning;
                assert ((now - LCD_E_fall) >= ST7066U_tC)
                report Rgt_Lft & " - CGRAM set addr - command time insufficient";
                MemAddr := to_integer(LCD_Data(5 downto 0));
                DD_flag := FALSE;      -- Enable CGRAM data writes

            elsif LCD_Data(5) then -- Function Set command
                report Rgt_Lft & " - Function set command - b""" &
                    to_bstring(LCD_Data(4 downto 2)) & """, " &
                    INTEGER'image(4 + 4 * sl2int(LCD_Data(4))) & " bit bus, " &
                    INTEGER'image(1 + 1 * sl2int(LCD_Data(3))) & " lines, 5x" &
                    INTEGER'image(8 + 2 * sl2int(LCD_Data(2))) & " char"
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

            else ----------------
                assert false report Rgt_Lft & " - NOP detected - x"
                & to_hstring(LCD_Data);
            end if;
        end procedure LCD_En_Fall_Action;

    begin
        --  Left display enable edges
        if (rising_edge(LCD_E_Lft)) then -- leading edge of enable
            assert ((now - LCD_E_rise_Lft) >= ST7066U_tC)
            report "Left E cycle time not met, " &
                INTEGER'image((now - LCD_E_rise_Lft) / 1 ns) & " ns";
            LCD_E_rise_Lft := now; -- save time to check address setup time
        end if;
        if (falling_edge(LCD_E_Lft)) then -- active edge of enable
            LCD_En_Fall_Time (LCD_RS, LCD_RWn, LCD_Data, "LEFT",
            LCD_E_rise_Lft, LCD_RS_event, LCD_RWn_event);
            LCD_En_Fall_Action (LCD_RS, LCD_RWn, LCD_Data, "LEFT",
            LCD_E_fall_Lft, DD_flag_Lft, MemAddr_Lft, Disp_Mem_Lft, CG_Mem_Lft);
            LCD_E_fall_Lft      := now; -- save time to check address hold
            Enable_fall_RS_Lft  := TRUE;
            Enable_fall_RWn_Lft := TRUE;
        end if;

        --  Right display enable edges
        if (rising_edge(LCD_E_Rgt)) then -- leading edge of enable
            assert ((now - LCD_E_rise_Rgt) >= ST7066U_tC)
            report "Right E cycle time not met, " &
                INTEGER'image((now - LCD_E_rise_Rgt) / 1 ns) & " ns";
            LCD_E_rise_Rgt := now; -- save time to check address setup time
        end if;
        if (falling_edge(LCD_E_Rgt)) then -- active edge of enable
            LCD_En_Fall_Time (LCD_RS, LCD_RWn, LCD_Data, "RIGHT",
            LCD_E_rise_Rgt, LCD_RS_event, LCD_RWn_event);
            LCD_En_Fall_Action (LCD_RS, LCD_RWn, LCD_Data, "RIGHT",
            LCD_E_fall_Rgt, DD_flag_Rgt, MemAddr_Rgt, Disp_Mem_Rgt, CG_Mem_Rgt);
            LCD_E_fall_Rgt      := now; -- save time to check address hold
            Enable_fall_RS_Rgt  := TRUE;
            Enable_fall_RWn_Rgt := TRUE;
        end if;

        -- Check RS hold time against both enables
        if (LCD_RS'event) then -- Check hold time to enable, tAH
            if (Enable_fall_RS_Lft) then
                Enable_fall_RS_Lft := FALSE;
                assert ((now - LCD_E_fall_Lft) >= ST7066U_tAH)
                report "RS to left E hold time not met, " &
                    INTEGER'image((now - LCD_E_fall_Lft) / 1 ns) & " ns";
            end if;
            if (Enable_fall_RS_Rgt) then
                Enable_fall_RS_Rgt := FALSE;
                assert ((now - LCD_E_fall_Rgt) >= ST7066U_tAH)
                report "RS to right E hold time not met, " &
                    INTEGER'image((now - LCD_E_fall_Rgt) / 1 ns) & " ns";
            end if;
            LCD_RS_event := now;
        end if;

        -- Check RW hold time against both enables
        if (LCD_RWn'event) then -- Check hold time to enable, tAH
            if (Enable_fall_RWn_Lft) then
                Enable_fall_RWn_Lft := FALSE;
                assert ((now - LCD_E_fall_Lft) >= ST7066U_tAH)
                report "RW to left E setup/hold time not met, " &
                    INTEGER'image((now - LCD_E_fall_Lft) / 1 ns) & " ns";
            end if;
            if (Enable_fall_RWn_Rgt) then
                Enable_fall_RWn_Rgt := FALSE;
                assert ((now - LCD_E_fall_Rgt) >= ST7066U_tAH)
                report "RW to right E setup/hold time not met, " &
                    INTEGER'image((now - LCD_E_fall_Rgt) / 1 ns) & " ns";
            end if;
            LCD_RWn_event := now;
        end if;

        -- Check Data hold time against enables
        if (LCD_Data'event) then -- Check hold time to enable, tH
            if (Enable_fall_DATA_Lft) then
                Enable_fall_DATA_Lft := FALSE;
                assert ((now - LCD_E_fall_Lft) >= ST7066U_tH)
                report "Data to left E setup/hold time not met, " &
                    INTEGER'image((now - LCD_E_fall_Lft) / 1 ns) & " ns";
            end if;
            if (Enable_fall_DATA_Rgt) then
                Enable_fall_DATA_Rgt := FALSE;
                assert ((now - LCD_E_fall_Rgt) >= ST7066U_tH)
                report "Data to right E setup/hold time not met, " &
                    INTEGER'image((now - LCD_E_fall_Rgt) / 1 ns) & " ns";
            end if;
            LCD_Data_event := now;
        end if;

    end process Disp_time;

    LCD_UUT : entity work.LCD_Drvr
        generic map (
            CLK_HZ    => CLK_HZ,
            Mem_Depth => Mem_Depth
        )
        port map (
            Clk        => Clk,

            Five_ms_En => Five_ms_En,

            Mem_Data   => Mem_Data,
            Mem_Addr   => Mem_Addr,
            Mem_WE     => Mem_WE,
            Page_Sel   => Page_Sel,

            LCD_RW     => LCD_RWn,
            LCD_RS     => LCD_RS,
            LCD_E_Lft  => LCD_E_Lft,
            LCD_E_Rgt  => LCD_E_Rgt,
            LCD_Data   => LCD_Data
        );           -- LCD_UUT : LCD_Drvr_tb

end TB_ARCH; -- LCD_Drvr_tb
