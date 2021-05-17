library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.ovb_h.all;

entity ovb is
    generic (
        REV : STD_LOGIC_VECTOR(31 downto 0) := 32x"0";
        UTC : STD_LOGIC_VECTOR(31 downto 0) := 32x"0"
    );
    port (
        CLCK                   : in    STD_LOGIC;
        Vref_DRV               : out   STD_LOGIC;
        AD_VREF_O2_SENS        : in    STD_LOGIC;
        Vcap_O2_SENS           : in    STD_LOGIC;
        DRV_O2_SENS            : out   STD_LOGIC;
        AD_VREF_PRES_SENS_VENT : in    STD_LOGIC;
        Vcap_PRES_SENS_VENT    : in    STD_LOGIC;
        DRV_PRES_SENS_VENT     : out   STD_LOGIC;
        AD_VREF_PRES_SENS_PAT  : in    STD_LOGIC;
        Vcap_PRES_SENS_PAT     : in    STD_LOGIC;
        DRV_PRES_SENS_PAT      : out   STD_LOGIC;
        AD_VREF_FLOW_SENS_DRCT : in    STD_LOGIC;
        Vcap_FLOW_SENS_DRCT    : in    STD_LOGIC;
        DRV_FLOW_SENS          : out   STD_LOGIC;
        AD_VREF_FLOW_SENS_GAIN : in    STD_LOGIC;
        Vcap_FLOW_SENS_GAIN    : in    STD_LOGIC;
        DRV_FLOW_SENS_GAIN     : out   STD_LOGIC;
        SPK1_HIGH_REF          : in    STD_LOGIC;
        SPK1_HIGH_SENS         : in    STD_LOGIC;
        SPK1_LOW_REF           : in    STD_LOGIC;
        SPK1_LOW_SENS          : in    STD_LOGIC;
        SPK2_HIGH_REF          : in    STD_LOGIC;
        SPK2_HIGH_SENS         : in    STD_LOGIC;
        SPK2_LOW_REF           : in    STD_LOGIC;
        SPK2_LOW_SENS          : in    STD_LOGIC;
        -- PB_MINUS               : in    STD_LOGIC;
        -- PB_MUTE                : in    STD_LOGIC;
        -- PB_PLUS                : in    STD_LOGIC;
        -- PB_SEL                 : in    STD_LOGIC;
        SPI2_MISO              : in    STD_LOGIC;
        SPI2_MOSI              : out   STD_LOGIC;
        SPI_SCLK               : out   STD_LOGIC;
        SPI2_PRES_CS           : out   STD_LOGIC;
        -- SPI1_MISO              : out   STD_LOGIC;
        -- SPI1_MOSI              : in    STD_LOGIC;
        -- SPI1_SCLK              : in    STD_LOGIC;
        -- SPI1_FPGA_CS           : in    STD_LOGIC;
        -- VIN_FAIL_F             : in    STD_LOGIC;
        I2C_SCL                : inout STD_LOGIC;
        I2C_SDA                : inout STD_LOGIC;
        -- F_DRV                  : out   STD_LOGIC;
        -- G_DRV                  : out   STD_LOGIC;
        -- LED_SERIAL_DRV         : out   STD_LOGIC;
        -- MOTOR_OFF              : in    STD_LOGIC;
        -- FPGA_READY             : in    STD_LOGIC;
        -- SPK1_FLT_N             : in    STD_LOGIC;
        -- SPK2_FLT_N             : in    STD_LOGIC;
        SPK1_EN                : out   STD_LOGIC;
        SPK2_EN                : out   STD_LOGIC;
        SPK1_IN1               : out   STD_LOGIC;
        SPK1_IN2               : out   STD_LOGIC;
        SPK2_IN1               : out   STD_LOGIC;
        SPK2_IN2               : out   STD_LOGIC
        -- RESET_I2C              : out   STD_LOGIC;
        -- UART_RX                : in    STD_LOGIC;
        -- UART_TX                : out   STD_LOGIC;
        -- LCD_A_ENABLE           : out   STD_LOGIC;
        -- LCD_B_ENABLE           : out   STD_LOGIC;
        -- LCD_RW                 : out   STD_LOGIC;
        -- LCD_RS                 : out   STD_LOGIC;
        -- LCD_DB                 : inout STD_LOGIC_VECTOR(7 downto 0)
    );
end entity;

architecture rtl of ovb is

    COMPONENT IOBUF
    PORT (
        O   :OUT   std_logic;
        IO  :INOUT std_logic;
        I   :IN    std_logic;
        OEN :IN    std_logic
    );
    END COMPONENT;

    COMPONENT TLVDS_IBUF
    PORT (
        O  :OUT std_logic;
        I  :IN  std_logic;
        IB :IN  std_logic
    );
    END COMPONENT;

    signal clk                  : STD_LOGIC;
    signal rst                  : STD_LOGIC;
    signal hb                   : STD_LOGIC;

    signal O2_SENS              : STD_LOGIC;
    signal O2_SENS_VALID        : STD_LOGIC;
    signal O2_SENS_DATA         : UNSIGNED(13 downto 0);
    signal PRES_SENS_VENT       : STD_LOGIC;
    signal PRES_SENS_VENT_VALID : STD_LOGIC;
    signal PRES_SENS_VENT_DATA  : UNSIGNED(13 downto 0);
    signal PRES_SENS_PAT        : STD_LOGIC;
    signal PRES_SENS_PAT_VALID  : STD_LOGIC;
    signal PRES_SENS_PAT_DATA   : UNSIGNED(13 downto 0);
    signal FLOW_SENS_DRCT       : STD_LOGIC;
    signal FLOW_SENS_DRCT_VALID : STD_LOGIC;
    signal FLOW_SENS_DRCT_DATA  : UNSIGNED(13 downto 0);
    signal FLOW_SENS_GAIN       : STD_LOGIC;
    signal FLOW_SENS_GAIN_VALID : STD_LOGIC;
    signal FLOW_SENS_GAIN_DATA  : UNSIGNED(13 downto 0);
    signal SPK1_HIGH            : STD_LOGIC;
    signal SPK1_LOW_N           : STD_LOGIC;
    signal SPK2_HIGH            : STD_LOGIC;
    signal SPK2_LOW_N           : STD_LOGIC;

    signal I2C_SCL_o            : STD_LOGIC;
    signal I2C_SCL_i            : STD_LOGIC;
    signal I2C_SCL_oen          : STD_LOGIC;
    signal I2C_SDA_o            : STD_LOGIC;
    signal I2C_SDA_i            : STD_LOGIC;
    signal I2C_SDA_oen          : STD_LOGIC;

    signal lps25h_press         : STD_LOGIC_VECTOR(23 downto 0);
    signal lps25h_temp          : STD_LOGIC_VECTOR(15 downto 0);
    signal lps25h_abspress      : STD_LOGIC_VECTOR(17 downto 0);

begin

    clocks_and_reset_i : entity work.clocks_and_reset
        generic map (
            BOARD => "OVB"
        )
        port map (
            clkin => CLCK,
            srst  => '0', -- todo, add soft reset signal
            clk   => clk, -- 33.554432 MHz
            rst   => rst,
            hb    => hb
        );

    Vref_DRV <= '1';

    TLVDS_IBUF_O2_SENS_i : TLVDS_IBUF
    port map (
        I  => AD_VREF_O2_SENS,
        IB => Vcap_O2_SENS,
        O  => O2_SENS
    );

    sigmadelta_adc_O2_SENS_i : entity work.sigmadelta_adc
        generic map (
            ADC_WIDTH      => 14, -- ADC Convertor Bit Precision
            ACCUM_BITS     => 14, -- 2^ACCUM_BITS is decimation rate of accumulator
            LPF_DEPTH_BITS => 3   -- 2^LPF_DEPTH_BITS is decimation rate of averager
        )
        port map (
            clk         => clk,          -- sample rate clock
            rst         => rst,          -- sync reset, asserted high
            analog_cmp  => O2_SENS,      -- input from LVDS buffer (comparator)

            digital_out => O2_SENS_DATA, -- digital output word of ADC
            analog_out  => DRV_O2_SENS,  -- feedback to comparitor input RC circuit
            sample_rdy  => O2_SENS_VALID -- digital_out is ready
        );

    TLVDS_IBUF_PRES_SENS_VENT_i : TLVDS_IBUF
        port map (
            I  => AD_VREF_PRES_SENS_VENT,
            IB => Vcap_PRES_SENS_VENT,
            O  => PRES_SENS_VENT
        );

    sigmadelta_adc_PRES_SENS_VENT_i : entity work.sigmadelta_adc
        generic map (
            ADC_WIDTH      => 14, -- ADC Convertor Bit Precision
            ACCUM_BITS     => 14, -- 2^ACCUM_BITS is decimation rate of accumulator
            LPF_DEPTH_BITS => 3   -- 2^LPF_DEPTH_BITS is decimation rate of averager
        )
        port map (
            clk         => clk,                 -- sample rate clock
            rst         => rst,                 -- sync reset, asserted high
            analog_cmp  => PRES_SENS_VENT,      -- input from LVDS buffer (comparator)

            digital_out => PRES_SENS_VENT_DATA, -- digital output word of ADC
            analog_out  => DRV_PRES_SENS_VENT,  -- feedback to comparitor input RC circuit
            sample_rdy  => PRES_SENS_VENT_VALID -- digital_out is ready
        );

    TLVDS_IBUF_PRES_SENS_PAT_i : TLVDS_IBUF
        port map (
            I  => AD_VREF_PRES_SENS_PAT,
            IB => Vcap_PRES_SENS_PAT,
            O  => PRES_SENS_PAT
        );

    sigmadelta_adc_PRES_SENS_PAT_i : entity work.sigmadelta_adc
        generic map (
            ADC_WIDTH      => 14, -- ADC Convertor Bit Precision
            ACCUM_BITS     => 14, -- 2^ACCUM_BITS is decimation rate of accumulator
            LPF_DEPTH_BITS => 3   -- 2^LPF_DEPTH_BITS is decimation rate of averager
        )
        port map (
            clk         => clk,                -- sample rate clock
            rst         => rst,                -- sync reset, asserted high
            analog_cmp  => PRES_SENS_PAT,      -- input from LVDS buffer (comparator)

            digital_out => PRES_SENS_PAT_DATA, -- digital output word of ADC
            analog_out  => DRV_PRES_SENS_PAT,  -- feedback to comparitor input RC circuit
            sample_rdy  => PRES_SENS_PAT_VALID -- digital_out is ready
        );

    TLVDS_IBUF_FLOW_SENS_DRCT_i : TLVDS_IBUF
        port map (
            I  => AD_VREF_FLOW_SENS_DRCT,
            IB => Vcap_FLOW_SENS_DRCT,
            O  => FLOW_SENS_DRCT
        );

    sigmadelta_adc_FLOW_SENS_DRCT_i : entity work.sigmadelta_adc
        generic map (
            ADC_WIDTH      => 14, -- ADC Convertor Bit Precision
            ACCUM_BITS     => 14, -- 2^ACCUM_BITS is decimation rate of accumulator
            LPF_DEPTH_BITS => 3   -- 2^LPF_DEPTH_BITS is decimation rate of averager
        )
        port map (
            clk         => clk,                 -- sample rate clock
            rst         => rst,                 -- sync reset, asserted high
            analog_cmp  => FLOW_SENS_DRCT,      -- input from LVDS buffer (comparator)

            digital_out => FLOW_SENS_DRCT_DATA, -- digital output word of ADC
            analog_out  => DRV_FLOW_SENS,       -- feedback to comparitor input RC circuit
            sample_rdy  => FLOW_SENS_DRCT_VALID -- digital_out is ready
        );

    TLVDS_IBUF_FLOW_SENS_GAIN_i : TLVDS_IBUF
        port map (
            I  => AD_VREF_FLOW_SENS_GAIN,
            IB => Vcap_FLOW_SENS_GAIN,
            O  => FLOW_SENS_GAIN
        );

    sigmadelta_adc_FLOW_SENS_GAIN_i : entity work.sigmadelta_adc
        generic map (
            ADC_WIDTH      => 14, -- ADC Convertor Bit Precision
            ACCUM_BITS     => 14, -- 2^ACCUM_BITS is decimation rate of accumulator
            LPF_DEPTH_BITS => 3   -- 2^LPF_DEPTH_BITS is decimation rate of averager
        )
        port map (
            clk         => clk,                 -- sample rate clock
            rst         => rst,                 -- sync reset, asserted high
            analog_cmp  => FLOW_SENS_GAIN,      -- input from LVDS buffer (comparator)

            digital_out => FLOW_SENS_GAIN_DATA, -- digital output word of ADC
            analog_out  => DRV_FLOW_SENS_GAIN,  -- feedback to comparitor input RC circuit
            sample_rdy  => FLOW_SENS_GAIN_VALID -- digital_out is ready
        );

    TLVDS_IBUF_SPK1_HIGH_i : TLVDS_IBUF
        port map (
            I  => SPK1_HIGH_SENS,
            IB => SPK1_HIGH_REF,
            O  => SPK1_HIGH         -- High if sens above ref
        );

    TLVDS_IBUF_SPK1_LOW_i : TLVDS_IBUF
        port map (
            I  => SPK1_LOW_SENS,
            IB => SPK1_LOW_REF,
            O  => SPK1_LOW_N        -- Low if sens below ref
        );

    TLVDS_IBUF_SPK2_HIGH_i : TLVDS_IBUF
        port map (
            I  => SPK2_HIGH_SENS,
            IB => SPK2_HIGH_REF,
            O  => SPK2_HIGH         -- High if sens above ref
        );

    TLVDS_IBUF_SPK2_LOW_i : TLVDS_IBUF
        port map (
            I  => SPK2_LOW_SENS,
            IB => SPK2_LOW_REF,
            O  => SPK2_LOW_N        -- Low if sens above ref
        );

    IOBUF_SCL_i : IOBUF
        PORT MAP (
            O   => I2C_SCL_o,
            IO  => I2C_SCL,
            I   => I2C_SCL_i,
            OEN => I2C_SCL_oen
        );

    IOBUF_SDA_i : IOBUF
        PORT MAP (
            O   => I2C_SDA_o,
            IO  => I2C_SDA,
            I   => I2C_SDA_i,
            OEN => I2C_SDA_oen
        );

        I2C_SCL_i   <= '1' when I2C_SCL_oen = '1' else I2C_SCL_o;
        I2C_SCL_oen <= '1';
        I2C_SDA_i   <= '1' when I2C_SDA_oen = '1' else I2C_SDA_o;
        I2C_SDA_oen <= '1';

    LPS25H_BARO_SPI_i : ENTITY work.lps25h_baro_spi_format
        PORT MAP
        (
            rst_L       => not rst,
            mstrclk     => clk,
            baro_out    => SPI2_MISO,
            BARO_INTR   => '0', -- todo, check if this is needed
            baro_din    => SPI2_MOSI,
            baro_serclk => SPI_SCLK,
            BARO_CSN    => SPI2_PRES_CS, -- the CS of the chip is low-asserted
            Press       => lps25h_press,
            Temp        => lps25h_temp,
            AbsPress    => lps25h_abspress
        );

    process (clk)
    begin
        if rising_edge(clk) then
            if rst = '1' then
                SPK1_EN <= '0';
                SPK2_EN <= '0';
                SPK1_IN1 <= '0';
                SPK1_IN2 <= '0';
                SPK2_IN1 <= '0';
                SPK2_IN2 <= '0';
            else
                SPK1_EN <= or(O2_SENS_DATA & PRES_SENS_VENT_DATA & PRES_SENS_PAT_DATA & unsigned(lps25h_press) & unsigned(lps25h_abspress));
                SPK2_EN <= or(FLOW_SENS_DRCT_DATA & FLOW_SENS_GAIN_DATA & unsigned(lps25h_temp));
                SPK1_IN1 <= SPK1_HIGH;
                SPK1_IN2 <= SPK1_LOW_N;
                SPK2_IN1 <= SPK2_HIGH;
                SPK2_IN2 <= SPK2_LOW_N;
            end if;
        end if;
    end process;

end architecture;
