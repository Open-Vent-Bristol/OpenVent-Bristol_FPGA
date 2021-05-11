library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity sigmadelta_adc is
    generic
    (
        ADC_WIDTH      : INTEGER := 14; -- ADC Convertor Bit Precision
        ACCUM_BITS     : INTEGER := 14; -- 2^ACCUM_BITS is decimation rate of accumulator
        LPF_DEPTH_BITS : INTEGER := 3   -- 2^LPF_DEPTH_BITS is decimation rate of averager
    );
    port
    (
        clk         : in STD_LOGIC;                         -- sample rate clock
        rst         : in STD_LOGIC;                         -- sync reset, asserted high
        analog_cmp  : in STD_LOGIC;                         -- input from LVDS buffer (comparator)

        digital_out : out UNSIGNED(ADC_WIDTH - 1 downto 0); -- digital output word of ADC
        analog_out  : out STD_LOGIC;                        -- feedback to comparitor input RC circuit
        sample_rdy  : out STD_LOGIC                         -- digital_out is ready
    );
end sigmadelta_adc;

architecture rtl of sigmadelta_adc is

    constant ALL_ONE : UNSIGNED(ACCUM_BITS - 1 downto 0) := (others => '1'); -- to compare sigma & counter

    signal delta     : STD_LOGIC;                                            -- captured comparitor output
    signal sigma     : UNSIGNED(ACCUM_BITS - 1 downto 0);                    -- running accumulator value
    signal accum     : UNSIGNED(ADC_WIDTH - 1 downto 0);                     -- latched accumulator value
    signal counter   : UNSIGNED(ACCUM_BITS - 1 downto 0);                    -- decimation counter for accumulator
    signal rollover  : STD_LOGIC;                                            -- decimation counter terminal count
    signal accum_rdy : STD_LOGIC;                                            -- latched accumulator value 'ready'

begin

    process (clk)
    begin
        if (rising_edge(clk)) then
            delta <= analog_cmp; -- capture comparitor output
        end if;
    end process;

    --	Adds PWM positive pulses over accumulator period
    P_ACCUMULATOR : process (clk)
    begin
        if rising_edge(clk) then
            if rst = '1' then
                counter   <= (others => '0');
                rollover  <= '0';
                sigma     <= (others => '0');
                accum     <= (others => '0');
                accum_rdy <= '0';
            else
                counter <= counter + '1';
                if (counter = ALL_ONE) then
                    rollover <= '1';
                else
                    rollover <= '0';
                end if;

                if (rollover = '1') then
                    -- latch top ADC_WIDTH bits of sigma accumulator (drop LSBs)
                    accum    <= sigma(ACCUM_BITS - 1 downto ACCUM_BITS - ADC_WIDTH);
                    sigma    <= ( others => '0');
                    sigma(0) <= delta;
                else
                    if (sigma /= ALL_ONE) then -- if not saturated
                        sigma <= sigma + delta;    -- accumulate
                    end if;
                end if;
                accum_rdy <= rollover; -- latch 'rdy' (to align with accum)
            end if;
        end if;
    end process P_ACCUMULATOR;

    --  Box filter Average
    --	Acts as simple decimating Low-Pass Filter
    BA_INST : entity work.box_ave
        generic map(
        ADC_WIDTH      => ADC_WIDTH,
        LPF_DEPTH_BITS => LPF_DEPTH_BITS
        )
        port map
        (
            clk            => clk,
            rst            => rst,
            sample         => accum_rdy,
            raw_data_in    => accum,
            ave_data_out   => digital_out,
            data_out_valid => sample_rdy
        );

    analog_out <= delta; -- feedback to comparitor LPF

end rtl;
