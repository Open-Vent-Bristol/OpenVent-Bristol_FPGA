library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.MATH_REAL.all;

use work.ovb_h.all;

entity adc_tb is
end adc_tb;

architecture Behavioral of adc_tb is

    -- When adjusting output bit resolution, N_bits must be adjusted to match resolution
    constant N_bits     : INTEGER := 12;

    constant A          : real    := 1.5; --Input wave amplitude
    constant C          : real    := 1.65;
    constant fs         : real    := 50.0;        --Sine wave frequency
    constant i          : real    := FREQUENCY/fs;
    constant rad        : real    := math_2_pi/i;
    constant vref       : real    := 1.65;      --Reference voltage for comparator
    constant R          : real    := 10.0E3;    --Input and feedback resistor
    constant Cap        : real    := 3.03E-9; --Capacitor

    constant ratio      : real    := real(2**N_bits)/3.3; --For data display

    --signal vdiff            : std_logic_vector(11 downto 0);
    --signal B                : real := 0.0;              --Input wave angle in radians
    --      Port Signals
    signal clk          : STD_LOGIC;
    signal rst          : STD_LOGIC;
    signal sample_rdy   : STD_LOGIC;
    signal Q            : UNSIGNED(N_bits - 1 downto 0);

    signal vin          : STD_LOGIC := '0'; -- Comparator output.  If vin > vref, '1'
    signal feedback     : STD_LOGIC := '0';

begin

    ADC_UUT : entity work.sigmadelta_adc
        generic map (
        ADC_WIDTH      => N_bits, -- ADC Convertor Bit Precision
        ACCUM_BITS     => 12,     -- 2^ACCUM_BITS is decimation rate of accumulator
        LPF_DEPTH_BITS => 3       -- 2^LPF_DEPTH_BITS is decimation rate of averager
        )
        port map
        (
            clk         => clk,
            rst         => rst,
            analog_cmp  => vin,
            analog_out  => feedback,
            sample_rdy  => sample_rdy,
            digital_out => Q
        );

    CLK_process : process
    begin
        CLK <= '0';
        wait for CLOCK_PERIOD_t;
        CLK <= '1';
        wait for CLOCK_PERIOD_t;
    end process;

    RST_process : process
    begin
        RST <= '1';
        wait for 60 ns;
        RST <= '0';
        wait;
    end process;

    pulse_process : process
        variable vcap            : real := 1.65;
        variable B               : real := 0.0;
        variable I_fb, I_rin, dv : real;
        variable vsin, fb_volt   : real;
        variable u_sin           : unsigned(N_bits - 1 downto 0); -- For displaying input Sin wave
    begin
        vsin  := A * sin(B) + C;
        B     := B + rad;
        u_sin := to_unsigned(INTEGER(ratio * vsin), N_bits);

        if feedback = '1' then
            I_fb := (3.3 - vcap)/R;
            --fb_volt := (I_fb*R)+vcap;
        else
            --fb_volt := 0.0;
            I_fb := - vcap/R;
        end if;

        I_rin := (vsin - vcap)/R;
        dv    := (I_rin + I_fb) * (CLOCK_PERIOD/Cap);
        vcap  := vcap + dv;

        if vcap < vref then
            vin <= '1';
        else
            vin <= '0';
        end if;

        wait until falling_edge(CLK);

    end process;

end Behavioral;
