library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_unsigned.all;
use ieee.math_real.all;
use std.textio.all;
use ieee.std_logic_textio.all;

use work.stdlib_h.all;


package tb_h is

    type int_array_t is array (natural range<>) of integer;
    type real_array_t is array (natural range<>) of real;

    type char_file_t is file of character;

    procedure printf (aString : in string);
    procedure fprintf (file aFid : text; aString : in string);
    procedure fwrite (file aFid : char_file_t; aVector : in std_logic_vector);

    procedure rand (aNum : inout real; aSeed1, aSeed2 : inout positive);
    procedure rand (aNum : inout real; aMin, aMax : in real; aSeed1, aSeed2 : inout positive);
    procedure rand (aNum : inout real; aMin, aMax : in integer; aSeed1, aSeed2 : inout positive);
    procedure rand (aNum : inout natural; aSeed1, aSeed2 : inout positive);
    procedure rand (aNum : inout integer; aMin, aMax : in integer; aSeed1, aSeed2 : inout positive);
    procedure rand (aVector : inout std_logic_vector; aSeed1, aSeed2 : inout positive);
    procedure rand (aVector : inout std_logic_vector; aMin, aMax : in natural; aSeed1, aSeed2 : inout positive);
    procedure rand (aVector : inout unsigned; aSeed1, aSeed2 : inout positive);
    procedure rand (aVector : inout unsigned; aMin, aMax : in natural; aSeed1, aSeed2 : inout positive);

    function to_hex (aVector : in std_logic_vector) return string;

    procedure generateClock (signal aClk : out std_logic; aTpd : in time; aTph : in time);
    procedure generateClock (signal aClk : out std_logic; aTpd : in time);

    procedure EndSimulation;
    procedure EndSimulation (aStopFlag : boolean);
    procedure EndSimulation (anErrorCount : natural);
    procedure EndSimulation (aStopFlag : boolean; anErrorCount : integer);


end package tb_h;


package body tb_h is

    procedure printf (aString : string) is
        variable theLine : line;
    begin
        write (theLine, aString);
        writeline (output, theLine);
    end procedure;


    procedure fprintf (file aFid : text; aString : string) is
        variable theLine : line;
    begin
        write (theLine, aString);
        writeline (output, theLine);
    end procedure;


    procedure fwrite (file aFid : char_file_t; aVector : in std_logic_vector) is
        variable theIdx : integer;
    begin
        assert (aVector'length mod 8) = 0
            report "aVector length must be a multiple of 8 so a character can be used, found " & integer'image(aVector'length)
            severity failure;
        for i in 0 to aVector'length/8-1 loop
            theIdx := conv_integer( aVector(i*8+7 downto i*8) );
            write(aFid, character'val(theIdx));
        end loop;
    end procedure;


    procedure rand (aNum : inout real; aSeed1, aSeed2 : inout positive) is
    begin
        uniform(aSeed1, aSeed2, aNum);
    end procedure;


    procedure rand (aNum : inout real; aMin, aMax : in real; aSeed1, aSeed2 : inout positive) is
    begin
        uniform(aSeed1, aSeed2, aNum);
        aNum := aNum * (aMax - aMin) + aMin;
    end procedure;

    procedure rand (aNum : inout real; aMin, aMax : in integer; aSeed1, aSeed2 : inout positive) is
    begin
        uniform(aSeed1, aSeed2, aNum);
        aNum := aNum * real(aMax - aMin) + real(aMin);
    end procedure;

    procedure rand (aNum : inout natural; aSeed1, aSeed2 : inout positive) is
        variable theReal : real;
    begin
        uniform(aSeed1, aSeed2, theReal);
        theReal := theReal * real(natural'right);
        aNum := natural(round(theReal));
    end procedure;


    procedure rand (aNum : inout integer; aMin, aMax : in integer; aSeed1, aSeed2 : inout positive) is
        variable theReal : real;
    begin
        uniform(aSeed1, aSeed2, theReal);
        theReal := theReal * real(aMax-aMin) + real(aMin);
        aNum := integer(round(theReal));
    end procedure;


    procedure rand (aVector : inout std_logic_vector; aSeed1, aSeed2 : inout positive) is
        variable theVector : unsigned(aVector'range);
    begin
        rand(theVector, aSeed1, aSeed2);
        aVector := std_logic_vector(theVector);
    end procedure;


    procedure rand (aVector : inout std_logic_vector; aMin, aMax : in natural; aSeed1, aSeed2 : inout positive) is
        variable theUnsigned : unsigned(aVector'range);
    begin
        rand(theUnsigned, aMin, aMax, aSeed1, aSeed2);
        aVector := std_logic_vector(theUnsigned);
    end procedure;


    procedure rand (aVector : inout unsigned; aSeed1, aSeed2 : inout positive) is
        variable theReal : real;
        variable theDiv  : natural := aVector'length/31;
        variable theMod  : natural := aVector'length mod 31;
    begin
        if theDiv > 0 then
            for i in 0 to theDiv-1 loop
                uniform(aSeed1, aSeed2, theReal);
                aVector(i*31+30 downto i*31) := to_unsigned(integer(round(theReal*real(natural'right))),31);
            end loop;
        end if;
        if theMod > 0 then
            uniform(aSeed1, aSeed2, theReal);
            aVector(aVector'left downto 31*theDiv) := to_unsigned(integer(round(theReal*real(2**theMod-1))),theMod);
        end if;
    end procedure;


    procedure rand (aVector : inout unsigned; aMin, aMax : in natural; aSeed1, aSeed2 : inout positive) is
        variable theNatural : natural;
    begin
        if aVector'length < 31 then
            assert aMax <= (2**aVector'length-1)
            report "rand: aMax must be less than 2**B-1 where B is the length of the vector"
            severity failure;
        else
            assert aMax <= natural'right
            report "rand: aMax must be less than 2**31-1 for vectors of length 31 or greater"
            severity failure;
        end if;
        rand(theNatural, aMin, aMax, aSeed1, aSeed2);
        aVector := to_unsigned(theNatural, aVector'length);
    end procedure;


    function to_hex (aVector : in std_logic_vector) return string is
        variable L : line;
    begin
        hwrite(L, aVector);
        return L.all;
    end function;


    procedure generateClock (signal aClk : out std_logic; aTpd : in time) is
    begin
        generateClock(aClk, aTpd, 0 ns);
    end procedure;


    procedure generateClock (signal aClk : out std_logic; aTpd : in time; aTph : in time) is
    begin
        aClk <= '0';
        wait for aTph;
        loop
            aClk <= '1', '0' after aTpd/2;
            wait for aTpd;
        end loop;
    end procedure;


    procedure EndSimulation is
    begin
        report "Simulation ends" severity failure;
    end procedure;


    procedure EndSimulation (aStopFlag : boolean) is
    begin
        if aStopFlag then
            printf ("Simulation stop flag asserted.");
        end if;
        EndSimulation;
    end procedure;


    procedure EndSimulation (anErrorCount : natural) is
    begin
        if (anErrorCount > 0) then
            printf ("Simulation SUCCESS");
        else
            printf ("Simulation FAILURE");
        end if;
        printf (integer'image(anErrorCount) & "error(s) found in simulation");
        EndSimulation;
    end procedure;


    procedure EndSimulation (aStopFlag : boolean; anErrorCount : integer) is
    begin
        if aStopFlag then
            printf ("Simulation stop flag asserted.");
        end if;
        EndSimulation(anErrorCount);
    end procedure;


end package body;