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
        CLCK                : in    STD_LOGIC;
        AD_VREF             : in    STD_LOGIC;
        Vref_DRV            : out   STD_LOGIC;
        Vcap_O2_SENS        : in    STD_LOGIC;
        DRV_O2_SENS         : out   STD_LOGIC;
        Vcap_PRES_SENS_VENT : in    STD_LOGIC;
        DRV_PRES_SENS_VENT  : out   STD_LOGIC;
        Vcap_PRES_SENS_PAT  : in    STD_LOGIC;
        DRV_PRES_SENS_PAT   : out   STD_LOGIC;
        Vcap_FLOW_SENS_DRCT : in    STD_LOGIC;
        DRV_FLOW_SENS       : out   STD_LOGIC;
        Vcap_FLOW_SENS_GAIN : in    STD_LOGIC;
        DRV_FLOW_SENS_GAIN  : out   STD_LOGIC;
        SPK1_SENS           : in    STD_LOGIC;
        SPK2_SENS           : in    STD_LOGIC;
        SPK_HIGH_REF        : in    STD_LOGIC;
        SPK_LOW_REF         : in    STD_LOGIC;
        PB_MINUS            : in    STD_LOGIC;
        PB_MUTE             : in    STD_LOGIC;
        PB_PLUS             : in    STD_LOGIC;
        PB_SEL              : in    STD_LOGIC;
        SPI2_MISO           : in    STD_LOGIC;
        SPI2_MOSI           : out   STD_LOGIC;
        SPI_SCLK            : out   STD_LOGIC;
        SPI2_PRES_CS        : out   STD_LOGIC;
        SPI1_MISO           : out   STD_LOGIC;
        SPI1_MOSI           : in    STD_LOGIC;
        SPI1_SCLK           : in    STD_LOGIC;
        SPI1_FPGA_CS        : in    STD_LOGIC;
        VIN_FAIL_F          : in    STD_LOGIC;
        I2C_SCL             : out   STD_LOGIC;
        I2C_SDA             : inout STD_LOGIC;
        F_DRV               : out   STD_LOGIC;
        G_DRV               : out   STD_LOGIC;
        LED_SERIAL_DRV      : out   STD_LOGIC;
        MOTOR_OFF           : in    STD_LOGIC;
        FPGA_READY          : in    STD_LOGIC;
        SPK1_FLT_N          : in    STD_LOGIC;
        SPK2_FLT_N          : in    STD_LOGIC;
        SPK1_EN             : out   STD_LOGIC;
        SPK2_EN             : out   STD_LOGIC;
        SPK1_IN1            : out   STD_LOGIC;
        SPK1_IN2            : out   STD_LOGIC;
        SPK2_IN1            : out   STD_LOGIC;
        SPK2_IN2            : out   STD_LOGIC;
        RESET_I2C           : out   STD_LOGIC;
        UART_RX             : in    STD_LOGIC;
        UART_TX             : out   STD_LOGIC;
        LCD_A_ENABLE        : out   STD_LOGIC;
        LCD_B_ENABLE        : out   STD_LOGIC;
        LCD_RW              : out   STD_LOGIC;
        LCD_RS              : out   STD_LOGIC;
        LCD_DB              : inout STD_LOGIC_VECTOR(7 downto 0)
    );
end entity;

architecture rtl of ovb is
    signal clk                  : STD_LOGIC;
    signal rst                  : STD_LOGIC;
    signal hb                   : STD_LOGIC;

    signal O2_SENS_VALID        : STD_LOGIC;
    signal O2_SENS_DATA         : STD_LOGIC_VECTOR(13 downto 0);
    signal PRES_SENS_VENT_VALID : STD_LOGIC;
    signal PRES_SENS_VENT_DATA  : STD_LOGIC_VECTOR(13 downto 0);
    signal PRES_SENS_PAT_VALID  : STD_LOGIC;
    signal PRES_SENS_PAT_DATA   : STD_LOGIC_VECTOR(13 downto 0);
    signal FLOW_SENS_DRCT_VALID : STD_LOGIC;
    signal FLOW_SENS_DRCT_DATA  : STD_LOGIC_VECTOR(13 downto 0);
    signal FLOW_SENS_GAIN_VALID : STD_LOGIC;
    signal FLOW_SENS_GAIN_DATA  : STD_LOGIC_VECTOR(13 downto 0);
begin

    clocks_and_reset_i : entity work.clocks_and_reset
        generic map (
            BOARD => "OVB"
        )
        port map (
            clkin => CLCK,
            srst  => '0', -- todo, add soft reset signal
            clk   => clk,
            rst   => rst,
            hb    => hb
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
            analog_cmp  => Vcap_O2_SENS, -- input from LVDS buffer (comparator)

            digital_out => O2_SENS_DATA, -- digital output word of ADC
            analog_out  => DRV_O2_SENS,  -- feedback to comparitor input RC circuit
            sample_rdy  => O2_SENS_VALID -- digital_out is ready
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
            analog_cmp  => Vcap_PRES_SENS_VENT, -- input from LVDS buffer (comparator)

            digital_out => PRES_SENS_VENT_DATA, -- digital output word of ADC
            analog_out  => DRV_PRES_SENS_VENT,  -- feedback to comparitor input RC circuit
            sample_rdy  => PRES_SENS_VENT_VALID -- digital_out is ready
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
            analog_cmp  => Vcap_PRES_SENS_PAT, -- input from LVDS buffer (comparator)

            digital_out => PRES_SENS_PAT_DATA, -- digital output word of ADC
            analog_out  => DRV_PRES_SENS_PAT,  -- feedback to comparitor input RC circuit
            sample_rdy  => PRES_SENS_PAT_VALID -- digital_out is ready
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
            analog_cmp  => Vcap_FLOW_SENS_DRCT, -- input from LVDS buffer (comparator)

            digital_out => FLOW_SENS_DRCT_DATA, -- digital output word of ADC
            analog_out  => DRV_FLOW_SENS,       -- feedback to comparitor input RC circuit
            sample_rdy  => FLOW_SENS_DRCT_VALID -- digital_out is ready
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
            analog_cmp  => Vcap_FLOW_SENS_GAIN, -- input from LVDS buffer (comparator)

            digital_out => FLOW_SENS_GAIN_DATA, -- digital output word of ADC
            analog_out  => DRV_FLOW_SENS_GAIN,  -- feedback to comparitor input RC circuit
            sample_rdy  => FLOW_SENS_GAIN_VALID -- digital_out is ready
        );

end architecture;
