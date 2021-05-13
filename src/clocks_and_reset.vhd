library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;


entity clocks_and_reset is
    generic (
        BOARD   : string := "OVB"   -- OVB/EVAL
    );
    port (
        clkin   : in    std_logic;
        srst    : in    std_logic;  -- Soft Reset
        clk     : out   std_logic;
        rst     : out   std_logic;
        hb      : out   std_logic
    );
end entity;

architecture rtl of clocks_and_reset is
    signal rst_cnt  : natural range 0 to 15 := 0;
    signal locked   : std_logic;
    signal arst     : std_logic;
    signal hb_cnt   : natural range 0 to 2**25-1;
begin

    p_rst: process(clk)
    begin
        if rising_edge(clk) then
            if locked = '0' or srst = '1' then
                rst <= '1';
                rst_cnt <= 0;
            else
                if rst_cnt = 15 then
                    rst <= '0';
                else
                    rst <= '1';
                    rst_cnt <= rst_cnt + 1;
                end if;
            end if;
        end if;
    end process;

    g_pll: if BOARD = OVB generate

        i_pll: PLL
        generic map (
            FCLKIN => "33.554",
            DEVICE => "GW1N-9",
            DYN_IDIV_SEL => "false",
            IDIV_SEL => 0,
            DYN_FBDIV_SEL => "false",
            FBDIV_SEL => 0,
            DYN_ODIV_SEL => "false",
            ODIV_SEL => 8,
            PSDA_SEL => "0000",
            DYN_DA_EN => "false",
            DUTYDA_SEL => "1000",
            CLKOUT_FT_DIR => '1',
            CLKOUTP_FT_DIR => '1',
            CLKOUT_DLY_STEP => 0,
            CLKOUTP_DLY_STEP => 0,
            CLKFB_SEL => "internal",
            CLKOUT_BYPASS => "false",
            CLKOUTP_BYPASS => "false",
            CLKOUTD_BYPASS => "false",
            DYN_SDIV_SEL => 2,
            CLKOUTD_SRC => "CLKOUT",
            CLKOUTD3_SRC => "CLKOUT"
        )
        port map (
            CLKOUT => clk,
            LOCK => locked,
            CLKOUTP => open,
            CLKOUTD => open,
            CLKOUTD3 => open,
            RESET => '0',
            RESET_P => '0',
            CLKIN => clkin,
            CLKFB => '0',
            FBDSEL => 6x"00",
            IDSEL => 6x"00",
            ODSEL => 6x"00",
            PSDA => 4x"0",
            DUTYDA => 4x"0",
            FDLY => 4x"0"
        );

        p_hb: process(clk)
        begin
            if rising_edge(clk) then
                if rst = '1' then
                    hb <= '0';
                else
                    if hb_cnt = 2**25-1 then
                        hb_cnt <= 0;
                        hb <= not hb;
                    else
                        hb_cnt <= hb_cnt + 1;
                    end if;
                end if;
            end if;
        end process;

    else generate
        i_pll: PLL
        generic map (
            FCLKIN => "50",
            DEVICE => "GW1N-9",
            DYN_IDIV_SEL => "false",
            IDIV_SEL => 2,
            DYN_FBDIV_SEL => "false",
            FBDIV_SEL => 1,
            DYN_ODIV_SEL => "false",
            ODIV_SEL => 16,
            PSDA_SEL => "0000",
            DYN_DA_EN => "true",
            DUTYDA_SEL => "1000",
            CLKOUT_FT_DIR => '1',
            CLKOUTP_FT_DIR => '1',
            CLKOUT_DLY_STEP => 0,
            CLKOUTP_DLY_STEP => 0,
            CLKFB_SEL => "internal",
            CLKOUT_BYPASS => "false",
            CLKOUTP_BYPASS => "false",
            CLKOUTD_BYPASS => "false",
            DYN_SDIV_SEL => 2,
            CLKOUTD_SRC => "CLKOUT",
            CLKOUTD3_SRC => "CLKOUT"
        )
        port map (
            CLKOUT => clk,
            LOCK => locked,
            CLKOUTP => open,
            CLKOUTD => open,
            CLKOUTD3 => open,
            RESET => '0',
            RESET_P => '0',
            CLKIN => clkin,
            CLKFB => '0',
            FBDSEL => 6x"00",
            IDSEL => 6x"00",
            ODSEL => 6x"00",
            PSDA => 4x"0",
            DUTYDA => 4x"0",
            FDLY => 4x"0"
        );

        p_hb: process(clk)
        begin
            if rising_edge(clk) then
                if rst = '1' then
                    hb <= '0';
                else
                    if hb_cnt = 33333333-1 then
                        hb_cnt <= 0;
                        hb <= not hb;
                    else
                        hb_cnt <= hb_cnt + 1;
                    end if;
                end if;
            end if;
        end process;

    end generate;

end architecture;
