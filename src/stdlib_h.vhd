library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package stdlib_h is

    subtype uint1_t  is unsigned( 0 downto 0);
    subtype uint2_t  is unsigned( 1 downto 0);
    subtype uint3_t  is unsigned( 2 downto 0);
    subtype uint4_t  is unsigned( 3 downto 0);
    subtype uint5_t  is unsigned( 4 downto 0);
    subtype uint6_t  is unsigned( 5 downto 0);
    subtype uint7_t  is unsigned( 6 downto 0);
    subtype uint8_t  is unsigned( 7 downto 0);
    subtype uint9_t  is unsigned( 8 downto 0);
    subtype uint10_t is unsigned( 9 downto 0);
    subtype uint11_t is unsigned(10 downto 0);
    subtype uint12_t is unsigned(11 downto 0);
    subtype uint13_t is unsigned(12 downto 0);
    subtype uint14_t is unsigned(13 downto 0);
    subtype uint15_t is unsigned(14 downto 0);
    subtype uint16_t is unsigned(15 downto 0);
    subtype uint17_t is unsigned(16 downto 0);
    subtype uint18_t is unsigned(17 downto 0);
    subtype uint19_t is unsigned(18 downto 0);
    subtype uint20_t is unsigned(19 downto 0);
    subtype uint21_t is unsigned(20 downto 0);
    subtype uint22_t is unsigned(21 downto 0);
    subtype uint23_t is unsigned(22 downto 0);
    subtype uint24_t is unsigned(23 downto 0);
    subtype uint25_t is unsigned(24 downto 0);
    subtype uint26_t is unsigned(25 downto 0);
    subtype uint27_t is unsigned(26 downto 0);
    subtype uint28_t is unsigned(27 downto 0);
    subtype uint29_t is unsigned(28 downto 0);
    subtype uint30_t is unsigned(29 downto 0);
    subtype uint31_t is unsigned(30 downto 0);
    subtype uint32_t is unsigned(31 downto 0);
    subtype uint33_t is unsigned(32 downto 0);
    subtype uint34_t is unsigned(33 downto 0);
    subtype uint35_t is unsigned(34 downto 0);
    subtype uint36_t is unsigned(35 downto 0);
    subtype uint37_t is unsigned(36 downto 0);
    subtype uint38_t is unsigned(37 downto 0);
    subtype uint39_t is unsigned(38 downto 0);
    subtype uint40_t is unsigned(39 downto 0);
    subtype uint41_t is unsigned(40 downto 0);
    subtype uint42_t is unsigned(41 downto 0);
    subtype uint43_t is unsigned(42 downto 0);
    subtype uint44_t is unsigned(43 downto 0);
    subtype uint45_t is unsigned(44 downto 0);
    subtype uint46_t is unsigned(45 downto 0);
    subtype uint47_t is unsigned(46 downto 0);
    subtype uint48_t is unsigned(47 downto 0);
    subtype uint49_t is unsigned(48 downto 0);
    subtype uint50_t is unsigned(49 downto 0);
    subtype uint51_t is unsigned(50 downto 0);
    subtype uint52_t is unsigned(51 downto 0);
    subtype uint53_t is unsigned(52 downto 0);
    subtype uint54_t is unsigned(53 downto 0);
    subtype uint55_t is unsigned(54 downto 0);
    subtype uint56_t is unsigned(55 downto 0);
    subtype uint57_t is unsigned(56 downto 0);
    subtype uint58_t is unsigned(57 downto 0);
    subtype uint59_t is unsigned(58 downto 0);
    subtype uint60_t is unsigned(59 downto 0);
    subtype uint61_t is unsigned(60 downto 0);
    subtype uint62_t is unsigned(61 downto 0);
    subtype uint63_t is unsigned(61 downto 0);
    subtype uint64_t is unsigned(63 downto 0);

    subtype int1_t  is signed( 0 downto 0);
    subtype int2_t  is signed( 1 downto 0);
    subtype int3_t  is signed( 2 downto 0);
    subtype int4_t  is signed( 3 downto 0);
    subtype int5_t  is signed( 4 downto 0);
    subtype int6_t  is signed( 5 downto 0);
    subtype int7_t  is signed( 6 downto 0);
    subtype int8_t  is signed( 7 downto 0);
    subtype int9_t  is signed( 8 downto 0);
    subtype int10_t is signed( 9 downto 0);
    subtype int11_t is signed(10 downto 0);
    subtype int12_t is signed(11 downto 0);
    subtype int13_t is signed(12 downto 0);
    subtype int14_t is signed(13 downto 0);
    subtype int15_t is signed(14 downto 0);
    subtype int16_t is signed(15 downto 0);
    subtype int17_t is signed(16 downto 0);
    subtype int18_t is signed(17 downto 0);
    subtype int19_t is signed(18 downto 0);
    subtype int20_t is signed(19 downto 0);
    subtype int21_t is signed(20 downto 0);
    subtype int22_t is signed(21 downto 0);
    subtype int23_t is signed(22 downto 0);
    subtype int24_t is signed(23 downto 0);
    subtype int25_t is signed(24 downto 0);
    subtype int26_t is signed(25 downto 0);
    subtype int27_t is signed(26 downto 0);
    subtype int28_t is signed(27 downto 0);
    subtype int29_t is signed(28 downto 0);
    subtype int30_t is signed(29 downto 0);
    subtype int31_t is signed(30 downto 0);
    subtype int32_t is signed(31 downto 0);
    subtype int33_t is signed(32 downto 0);
    subtype int34_t is signed(33 downto 0);
    subtype int35_t is signed(34 downto 0);
    subtype int36_t is signed(35 downto 0);
    subtype int37_t is signed(36 downto 0);
    subtype int38_t is signed(37 downto 0);
    subtype int39_t is signed(38 downto 0);
    subtype int40_t is signed(39 downto 0);
    subtype int41_t is signed(40 downto 0);
    subtype int42_t is signed(41 downto 0);
    subtype int43_t is signed(42 downto 0);
    subtype int44_t is signed(43 downto 0);
    subtype int45_t is signed(44 downto 0);
    subtype int46_t is signed(45 downto 0);
    subtype int47_t is signed(46 downto 0);
    subtype int48_t is signed(47 downto 0);
    subtype int49_t is signed(48 downto 0);
    subtype int50_t is signed(49 downto 0);
    subtype int51_t is signed(50 downto 0);
    subtype int52_t is signed(51 downto 0);
    subtype int53_t is signed(52 downto 0);
    subtype int54_t is signed(53 downto 0);
    subtype int55_t is signed(54 downto 0);
    subtype int56_t is signed(55 downto 0);
    subtype int57_t is signed(56 downto 0);
    subtype int58_t is signed(57 downto 0);
    subtype int59_t is signed(58 downto 0);
    subtype int60_t is signed(59 downto 0);
    subtype int61_t is signed(60 downto 0);
    subtype int62_t is signed(61 downto 0);
    subtype int63_t is signed(61 downto 0);
    subtype int64_t is signed(63 downto 0);

    function orReduce (aVector : std_logic_vector) return std_logic;
    function andReduce (aVector : std_logic_vector) return std_logic;
    function repeat (aValue : std_logic; aNum : natural) return std_logic_vector;
    function repeat (aVector : std_logic_vector; aNum : natural) return std_logic_vector;
    function fliplr (aVector : std_logic_vector) return std_logic_vector;
    function swapEndian (aVector : std_logic_vector) return std_logic_vector;
    function clog2 (aNum : natural) return integer;

    function to_uint(aNum: natural; aVectorLength: natural) return unsigned;
    function to_uint(aNum: natural; aVectorLength: natural) return std_logic_vector;

end package stdlib_h;


package body stdlib_h is

    function orReduce (aVector : std_logic_vector) return std_logic is
        variable theResult : std_logic := '0';
    begin
        for i in aVector'range loop
            theResult := theResult or aVector(i);
        end loop;
        return theResult;
    end function;

    function andReduce (aVector : std_logic_vector) return std_logic is
        variable theResult : std_logic := '1';
    begin
        for i in aVector'range loop
            theResult := theResult and aVector(i);
        end loop;
        return theResult;
    end function;

    function repeat (aValue : std_logic; aNum : natural) return std_logic_vector is
        variable theResult : std_logic_vector(aNum-1 downto 0);
    begin
        for i in 0 to aNum-1 loop
            theResult(i) := aValue;
        end loop;
        return theResult;
    end function;

    function repeat (aVector : std_logic_vector; aNum : natural) return std_logic_vector is
        variable theResult : std_logic_vector(aVector'length*aNum-1 downto 0);
    begin
        for i in 0 to aNum-1 loop
            theResult(i*aVector'length+aVector'length-1 downto i*aVector'length) := aVector;
        end loop;
        return theResult;
    end function;

    function fliplr (aVector : std_logic_vector) return std_logic_vector is
        variable theResult : std_logic_vector(aVector'length-1 downto 0);
    begin
        for i in 0 to aVector'length-1 loop
            theResult(i) := aVector(aVector'length-1-i);
        end loop;
        return theResult;
    end function;

    function swapEndian (aVector : std_logic_vector) return std_logic_vector is
        variable m : integer;
        variable theResult : std_logic_vector(aVector'range);
    begin
        assert aVector'length mod 8 = 0
            report "Vector must be divisble 8 with no remainder"
            severity failure;
        m := aVector'length/8;
        for i in 0 to m-1 loop
            theResult(i*8-1 downto i*8) := aVector((m-i)*8-1 downto (m-i-1)*8);
        end loop;
        return theResult;
    end function;

    function clog2 (aNum : natural) return integer is
        variable theResult  : integer := 0;
        variable theDividend: integer := 1;
    begin
        if aNum = 0 then return 0;
        else
            for j in 0 to 29 loop -- for loop for XST
                if theDividend >= aNum then
                    null;
                else
                    theResult := theResult+1;
                    theDividend := theDividend*2;
                end if;
            end loop;
            -- Fix per CR520627 - XST was ignoring this anyway and printing a
            -- warning in SRP file. This will get rid of the warning and not
            -- impact simulation.
            -- synthesis transtd_logicate_off
            assert theDividend >= aNum
                report "Function log2 received argument larger than its capability of 2^30. "
                severity failure;
            -- synthesis transtd_logicate_on
            return theResult;
        end if;
    end function;

    function to_uint(aNum: natural; aVectorLength: natural) return unsigned is
        variable theVector : unsigned(aVectorLength-1 downto 0) := to_unsigned(aNum, aVectorLength);
    begin
        return theVector;
    end function;

    function to_uint(aNum: natural; aVectorLength: natural) return std_logic_vector is
        variable theVector : std_logic_vector(aVectorLength-1 downto 0) := std_logic_vector(to_unsigned(aNum, aVectorLength));
    begin
        return theVector;
    end function;

end package body stdlib_h;