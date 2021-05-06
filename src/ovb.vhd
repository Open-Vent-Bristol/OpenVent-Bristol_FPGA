library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.ovb_h.all;


entity ovb is
    generic (
        REV         : std_logic_vector(31 downto 0) := 32x"0";
        UTC         : std_logic_vector(31 downto 0) := 32x"0"
    );
    port (
        CLCK                : in    std_logic;
        AD_VREF             : in    std_logic;
        Vref_DRV            : out   std_logic;
        Vcap_O2_SENS        : in    std_logic;
        DRV_O2_SENS         : out   std_logic;
        Vcap_PRES_SENS_VENT : in    std_logic;
        DRV_PRES_SENS_VENT  : out   std_logic;
        Vcap_PRES_SENS_PAT  : in    std_logic;
        DRV_PRES_SENS_PAT   : out   std_logic;
        Vcap_FLOW_SENS_DRCT : in    std_logic;
        DRV_FLOW_SENS       : out   std_logic;
        Vcap_FLOW_SENS_GAIN : in    std_logic;
        DRV_FLOW_SENS_GAIN  : out   std_logic;
        SPK1_SENS           : in    std_logic;
        SPK2_SENS           : in    std_logic;
        SPK_HIGH_REF        : in    std_logic;
        SPK_LOW_REF         : in    std_logic;
        PB_MINUS            : in    std_logic;
        PB_MUTE             : in    std_logic;
        PB_PLUS             : in    std_logic;
        PB_SEL              : in    std_logic;
        SPI2_MISO           : in    std_logic;
        SPI2_MOSI           : out   std_logic;
        SPI_SCLK            : out   std_logic;
        SPI2_PRES_CS        : out   std_logic;
        SPI1_MISO           : out   std_logic;
        SPI1_MOSI           : in    std_logic;
        SPI1_SCLK           : in    std_logic;
        SPI1_FPGA_CS        : in    std_logic;
        VIN_FAIL_F          : in    std_logic;
        I2C_SCL             : out   std_logic;
        I2C_SDA             : inout std_logic;
        F_DRV               : out   std_logic;
        G_DRV               : out   std_logic;
        LED_SERIAL_DRV      : out   std_logic;
        MOTOR_OFF           : in    std_logic;
        FPGA_READY          : in    std_logic;
        SPK1_FLT_N          : in    std_logic;
        SPK2_FLT_N          : in    std_logic;
        SPK1_EN             : out   std_logic;
        SPK2_EN             : out   std_logic;
        SPK1_IN1            : out   std_logic;
        SPK1_IN2            : out   std_logic;
        SPK2_IN1            : out   std_logic;
        SPK2_IN2            : out   std_logic;
        RESET_I2C           : out   std_logic;
        UART_RX             : in    std_logic;
        UART_TX             : out   std_logic;
        LCD_A_ENABLE        : out   std_logic;
        LCD_B_ENABLE        : out   std_logic;
        LCD_RW              : out   std_logic;
        LCD_RS              : out   std_logic;
        LCD_DB              : inout std_logic_vector(7 downto 0)
    );
end entity;


architecture rtl of ovb is
begin
end architecture;