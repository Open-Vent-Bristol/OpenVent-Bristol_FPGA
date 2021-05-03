-- MODULE COUNTS mSEC PULSEs TO GENERATE TIME OUT DISCRETE


library IEEE;
use IEEE.std_logic_1164.all;


ENTITY lps25h_timer IS
	PORT(
		mstr_clk, RST_L, ACLR, SYNC : IN	STD_LOGIC;
		--CNT 						: OUT STD_LOGIC;
		TMR			: OUT	STD_LOGIC);
END lps25h_timer;

ARCHITECTURE CNTR OF lps25h_timer IS
	SIGNAL  CNT5000	 : STD_LOGIC;

	SIGNAL FC : STD_LOGIC_VECTOR( 5 DOWNTO 0);

BEGIN
COUNTER: PROCESS(RST_L,mstr_clk,aclr,cnt5000)
begin
	if ( RST_L = '0' OR ACLR = '1') THEN

		FC(0) <= '0';
		FC(1) <= '0';
		FC(2) <= '0';
		FC(3) <= '0';--SET TO TIME OUT FOR SIMULATION ,1 mSec
		FC(4) <= '0';
		FC(5) <= '0';


	ELSIF(mstr_clk'EVENT AND mstr_clk ='1' )THEN


FC(5) <= (FC(0) and SYNC AND (NOT CNT5000) and FC(1) and FC(2) and FC(3) and FC(4) 
and (not FC(5))	)
      or ( (not FC(4)) and FC(5)
     ) or ( (not FC(3)) and FC(5)
     ) or ( (not FC(2)) and FC(5)
     ) or ( (not FC(1)) and FC(5)
     ) or ( (not FC(0)) and FC(5)
     ) or ( ((not SYNC) OR CNT5000) and FC(5));

FC(4) <= (FC(0) and SYNC AND (NOT CNT5000) and FC(1) and FC(2) and FC(3) and (not FC(4))	)
     or ( (not FC(3)) and FC(4)
     ) or ( (not FC(2)) and FC(4)
     ) or ( (not FC(1)) and FC(4)
     ) or ( (not FC(0)) and FC(4)
     ) or ( ((not SYNC) OR CNT5000) and FC(4)) ;

FC(3) <= (FC(0) and SYNC AND (NOT CNT5000) and FC(1) and FC(2) and (not FC(3))	)
      or ( (not FC(2)) and FC(3)
     ) or ( (not FC(1)) and FC(3)
     ) or ( (not FC(0)) and FC(3)
     ) or ( ((not SYNC) OR CNT5000) and FC(3));

FC(2) <= (FC(0) and SYNC AND (NOT CNT5000) and FC(1) and (not FC(2))	)
     or ( (not FC(1)) and FC(2)
    ) or ( (not FC(0)) and FC(2)
     ) or ( ((not SYNC) OR CNT5000) and FC(2));

FC(1) <= (FC(0) and SYNC AND (NOT CNT5000) and (not FC(1))	) or ( (not FC(0)) and FC(1)) or ( ((not SYNC) OR CNT5000) and FC(1));

FC(0) <= (FC(0) and ((not SYNC) OR CNT5000)) or  ((not FC(0) and SYNC AND (NOT CNT5000)));

CNT5000 <= (	(not FC(0)) and (FC(1)) and (not FC(2)) and (NOT FC(3)) and (FC(4)) and (FC(5)) ); --SET TO 50 COUNTS


END IF;
TMR <= CNT5000;
--TIME_OUT <= CON;
END PROCESS COUNTER;

END CNTR;


