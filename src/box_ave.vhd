library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity box_ave is
    generic
    (
        ADC_WIDTH      : INTEGER := 14; -- ADC Convertor Bit Precision
        LPF_DEPTH_BITS : INTEGER := 3   -- 2^LPF_DEPTH_BITS is decimation rate of averager
    );

    port
    (
        clk            : in STD_LOGIC;                                 -- sample rate clock
        rst            : in STD_LOGIC;                                 -- async reset, asserted low
        sample         : in STD_LOGIC;                                 -- raw_data_in is good on rising edge,
        raw_data_in    : in UNSIGNED(ADC_WIDTH - 1 downto 0);          -- raw_data input

        ave_data_out   : out UNSIGNED(ADC_WIDTH - 1 downto 0); -- ave data output
        data_out_valid : out STD_LOGIC                                 -- ave_data_out is valid, single pulse
    );
end box_ave;

architecture rtl of box_ave is
    constant ZERO       : UNSIGNED(LPF_DEPTH_BITS - 1 downto 0) := (others => '0'); -- to compare count

    signal accum        : UNSIGNED(ADC_WIDTH + LPF_DEPTH_BITS - 1 downto 0);-- accumulator
    signal count        : UNSIGNED(LPF_DEPTH_BITS - 1 downto 0); -- decimation count
    signal raw_data_d1  : UNSIGNED(ADC_WIDTH - 1 downto 0);      -- pipeline register

    signal sample_d1    : STD_LOGIC;
    signal sample_d2    : STD_LOGIC; -- pipeline registers
    signal result_valid : STD_LOGIC; -- accumulator result 'valid'
    signal accumulate   : STD_LOGIC; -- sample rising edge detected
    signal latch_result : STD_LOGIC; -- latch accumulator result

begin

    P_RISING_EDGE_DETECTION : process (clk)
    begin
        if rising_edge(clk) then
            if rst = '1' then
                sample_d1    <= '0';
                raw_data_d1  <= (others => '0');
                sample_d2    <= '0';
                result_valid <= '0';
            else
                sample_d1    <= sample;       -- capture 'sample' input
                raw_data_d1  <= raw_data_in;  -- pipeline
                sample_d2    <= sample_d1;    -- delay for edge detection
                result_valid <= latch_result; -- pipeline for alignment with result
            end if;
        end if;
    end process P_RISING_EDGE_DETECTION;

    accumulate <= sample_d1 and not sample_d2; -- 'sample' rising_edge detect

    P_ACCUMULATOR : process (clk)
    begin
        if rising_edge(clk) then
            if rst = '1' then
                count <= (others => '0');
                accum <= (others => '0');
            else
                if (accumulate = '1') then
                    count <= count + '1';  -- incr. count per each sample

                    if (count = ZERO) then -- reset accumulator
                        accum                         <= (others => '0');
                        accum(ADC_WIDTH - 1 downto 0) <= raw_data_d1;
                    else
                        accum <= accum + raw_data_d1; -- accumulate
                    end if;
                end if;
            end if;
        end if;
    end process P_ACCUMULATOR;

    latch_result <= '1' when ((accumulate = '1') and (count = ZERO)) else
        '0'; -- latch accum. per decimation count

    --  Latch Result
    --  ave = (summation of 'n' samples)/'n'  is right shift when 'n' is power of two
    P_LATCH_RESULT : process (clk)
    begin
        if rising_edge(clk) then
            if rst = '1' then
                ave_data_out <= (others => '0');
            else
                if (latch_result = '1') then                                                 -- at end of decimation period...
                    ave_data_out <= accum(ADC_WIDTH + LPF_DEPTH_BITS - 1 downto LPF_DEPTH_BITS); -- ... save accumulator/n result
                end if;
            end if;
        end if;
    end process P_LATCH_RESULT;

    data_out_valid <= result_valid; -- output assignment

end rtl;
