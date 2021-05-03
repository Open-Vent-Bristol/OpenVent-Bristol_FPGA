-- MODULE TAKES THE MASTER INPUT CLOCK AND GENERATES A DIVIDE FOUR FOR THE SPI SERCLK 
--REFERENCE, A CLK_EN AND A 1 mSEC TIMER REFERENCE, ASSUMMING 16.777216 mHZ REFERENCE CLOCK DIVIDED BY 4

library IEEE;
use IEEE.std_logic_1164.all;


ENTITY LPS25H_CLKGEN_ONE_MSEC IS
	PORT(
		mstr_clk, RST_L		 : IN	STD_LOGIC;
		 spi_ck, T001: OUT	STD_LOGIC);--clken_out,
END LPS25H_CLKGEN_ONE_MSEC;

ARCHITECTURE TIMER OF LPS25H_CLKGEN_ONE_MSEC IS
	SIGNAL 	F5MHZ, CNT5000	,ACLR, DLY	 : STD_LOGIC;-- ACTUALLY 4.125Mhz
	SIGNAL FC : STD_LOGIC_VECTOR( 12 DOWNTO 0);
	SIGNAL PC : STD_LOGIC_VECTOR( 1 DOWNTO 0);
	SIGNAL FS : STD_LOGIC_VECTOR(1 DOWNTO 0);
	--SIGNAL __signal_name : STD_LOGIC_VECTOR( DOWNTO 0);
	--SIGNAL __signal_name : STD_LOGIC_VECTOR( DOWNTO 0);
BEGIN
COUNTER: PROCESS(RST_L,mstr_clk,aclr,fs,pc,fc,f5mhz)
begin
	if ( RST_L = '0' OR ACLR = '1') THEN
 		PC <= (others => '0');
		FC <= (others => '0');
 		FS <= (others => '0');

	ELSIF(mstr_clk'EVENT AND mstr_clk ='1')THEN


PC(1) <= 		PC(0);-- DIVIDE BY 4 

PC(0) <= 		(not PC(1));



--FS(0) <= ((not FS(0)) and CNT5000);

FC(12) <= (		FC(0) and F5MHZ and FC(1) and FC(2) and FC(3) and FC(4) 
	and FC(5) and FC(6) and FC(7) and FC(8) and FC(9) and FC(10) and FC(11) and (not FC(12))	)
or  ((not FC(11)) and FC(12)) or ((not FC(10)) and FC(12)) or ( (not FC(9)) and FC(12)) 
or  ((not FC(8)) and FC(12)) or ( (not FC(7)) and FC(12)) or ( (not FC(6)) and FC(12)) 
or  ((not FC(5)) and FC(12)) or ( (not FC(4)) and FC(12)
    ) or ( (not FC(3)) and FC(12)
    ) or ( (not FC(2)) and FC(12)
    ) or ( (not FC(1)) and FC(12)
    ) or ( (not FC(0)) and FC(12)
    ) or ( (not F5MHZ) and FC(12));

FC(11) <= (FC(0) and F5MHZ and FC(1) and FC(2) and FC(3) and FC(4) 
	and FC(5) and FC(6) and FC(7) and FC(8) and FC(9) and FC(10) and (not FC(11))	)
      or ( (not FC(10)) and FC(11)
     ) or ( (not FC(9)) and FC(11)
     ) or ( (not FC(8)) and FC(11)
     ) or ( (not FC(7)) and FC(11)
     ) or ( (not FC(6)) and FC(11)
     ) or ( (not FC(5)) and FC(11)
     ) or ( (not FC(4)) and FC(11)
     ) or ( (not FC(3)) and FC(11)
     ) or ( (not FC(2)) and FC(11)
     ) or ( (not FC(1)) and FC(11)
     ) or ( (not FC(0)) and FC(11)
     ) or ( (not F5MHZ) and FC(11));

FC(10) <= (FC(0) and F5MHZ and FC(1) and FC(2) and FC(3) and FC(4) 
and FC(5) and FC(6) and FC(7) and FC(8) and FC(9) and (not FC(10))	)
      or ( (not FC(9)) and FC(10)
     ) or ( (not FC(8)) and FC(10)
     ) or ( (not FC(7)) and FC(10)
     ) or ( (not FC(6)) and FC(10)
     ) or ( (not FC(5)) and FC(10)
     ) or ( (not FC(4)) and FC(10)
     ) or ( (not FC(3)) and FC(10)
     ) or ( (not FC(2)) and FC(10)
     ) or ( (not FC(1)) and FC(10)
     ) or ( (not FC(0)) and FC(10)
     ) or ( (not F5MHZ) and FC(10));


FC(9) <= (FC(0) and F5MHZ and FC(1) and FC(2) and FC(3) and FC(4) 
and FC(5) and FC(6) and FC(7) and FC(8) and (not FC(9))	)
      or ( (not FC(8)) and FC(9)
     ) or ( (not FC(7)) and FC(9)
     ) or ( (not FC(6)) and FC(9)
     ) or ( (not FC(5)) and FC(9)
     ) or ( (not FC(4)) and FC(9)
     ) or ( (not FC(3)) and FC(9)
     ) or ( (not FC(2)) and FC(9)
     ) or ( (not FC(1)) and FC(9)
     ) or ( (not FC(0)) and FC(9)
     ) or ( (not F5MHZ) and FC(9));

FC(8) <= (FC(0) and F5MHZ and FC(1) and FC(2) and FC(3) and FC(4)
 and FC(5) and FC(6) and FC(7) and (not FC(8))	)
      or ( (not FC(7)) and FC(8)	
     ) or ( (not FC(6)) and FC(8)
     ) or ( (not FC(5)) and FC(8)
     ) or ( (not FC(4)) and FC(8)
     ) or ( (not FC(3)) and FC(8)
     ) or ( (not FC(2)) and FC(8)
     ) or ( (not FC(1)) and FC(8)
     ) or ( (not FC(0)) and FC(8)
     ) or ( (not F5MHZ) and FC(8));

FC(7) <= (FC(0) and F5MHZ and FC(1) and FC(2) and FC(3) and FC(4) 
and FC(5) and FC(6) and (not FC(7))	)
     or ( (not FC(6)) and FC(7)	
     ) or ( (not FC(5)) and FC(7)
     ) or ( (not FC(4)) and FC(7)
     ) or ( (not FC(3)) and FC(7)
     ) or ( (not FC(2)) and FC(7)
     ) or ( (not FC(1)) and FC(7)
     ) or ( (not FC(0)) and FC(7)
     ) or ( (not F5MHZ) and FC(7));


FC(6) <= (FC(0) and F5MHZ and FC(1) and FC(2) and FC(3) and FC(4) 
and FC(5) and (not FC(6))	)
     or ( (not FC(5)) and FC(6)
     ) or ( (not FC(4)) and FC(6)
     ) or ( (not FC(3)) and FC(6)
     ) or ( (not FC(2)) and FC(6)
     ) or ( (not FC(1)) and FC(6)
     ) or ( (not FC(0)) and FC(6)
     ) or ( (not F5MHZ) and FC(6));

FC(5) <= (FC(0) and F5MHZ and FC(1) and FC(2) and FC(3) and FC(4) 
and (not FC(5))	)
      or ( (not FC(4)) and FC(5)
     ) or ( (not FC(3)) and FC(5)
     ) or ( (not FC(2)) and FC(5)
     ) or ( (not FC(1)) and FC(5)
     ) or ( (not FC(0)) and FC(5)
     ) or ( (not F5MHZ) and FC(5));

FC(4) <= (FC(0) and F5MHZ and FC(1) and FC(2) and FC(3) and (not FC(4))	)
     or ( (not FC(3)) and FC(4)
     ) or ( (not FC(2)) and FC(4)
     ) or ( (not FC(1)) and FC(4)
     ) or ( (not FC(0)) and FC(4)
     ) or ( (not F5MHZ) and FC(4)) ;

FC(3) <= (FC(0) and F5MHZ and FC(1) and FC(2) and (not FC(3))	)
      or ( (not FC(2)) and FC(3)
     ) or ( (not FC(1)) and FC(3)
     ) or ( (not FC(0)) and FC(3)
     ) or ( (not F5MHZ) and FC(3));

FC(2) <= (FC(0) and F5MHZ and FC(1) and (not FC(2))	)
     or ( (not FC(1)) and FC(2)
     ) or ( (not FC(0)) and FC(2)
     ) or ( (not F5MHZ) and FC(2));

FC(1) <= (FC(0) and F5MHZ and (not FC(1))	)
      or ( (not FC(0)) and FC(1)
     ) or ( (not F5MHZ) and FC(1));

FC(0) <= (FC(0) and (not F5MHZ)) or ( (not FC(0)) and F5MHZ);

CNT5000 <= (	(NOT FC(0)) and (FC(1)) and (NOT FC(2)) and (NOT FC(3)) and (NOT FC(4)) -- ACTUALLY SET TO 4194 TO PROVIDE 1 mSec REFERENCE
		and (FC(5)) and (FC(6)) and (NOT FC(7)) and (NOT FC(8)) and (NOT FC(9)) and (not FC(10)) 
		and (not FC(11)) and FC(12)	);


FS(0) <= (	(NOT FC(0)) and (FC(1)) and (NOT FC(2)) and (NOT FC(3)) and (NOT FC(4)) -- ACTUALLY SET TO 4194 TO PROVIDE 1 mSec REFERENCE
		and (FC(5)) and (FC(6)) and (NOT FC(7)) and (NOT FC(8)) and (NOT FC(9)) and (not FC(10)) 
		and (not FC(11)) and FC(12)	);
FS(1) <= FS(0);
		END IF;
ACLR <= FS(0) AND NOT FS(1);

T001 <=  PC(1) and PC(0) AND ((FC(0)) and (NOT FC(1)) and (NOT FC(2)) and (NOT FC(3)) and (NOT FC(4)) -- ACTUALLY SET TO 4193 TO PROVIDE 1 mSec REFERENCE
		and (FC(5)) and (FC(6)) and (NOT FC(7)) and (NOT FC(8)) and (NOT FC(9)) and (not FC(10)) 
		and (not FC(11)) and FC(12)	);
F5MHZ <= 	PC(1) and PC(0)	;
--clken_out <= 	F5MHZ	;
--END IF;
--FSO <= FS;
END PROCESS COUNTER;

--DLY.CLK = !REF20MHZ;

SYNC: PROCESS(RST_L,mstr_clk,aclr,dly)
begin
	if (RST_L = '0' or aclr = '1') THEN
 		DLY <= '0';
	ELSE
		IF(mstr_clk'EVENT AND mstr_clk ='0')THEN

		DLY <= PC(1);
		END IF;

	END IF;
		spi_ck <= DLY;-- NEED SOME TIMING MARGIN BETWEEN spi_ck AND T001

END PROCESS SYNC;

END TIMER;


