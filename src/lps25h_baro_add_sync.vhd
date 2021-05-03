-- MODULE WRITTEN TO GENERATE SEQUENTIAL add byes required to read and command the stm lps25h
-- barometer sensor. Currently designed to read coefficients first and repeatily read the barometer
-- and temperature after each convert time out indicated by the INTR discrete input. It increments the
-- addresses after each finish input from the SPI modules.

library IEEE;
use IEEE.std_logic_1164.all;

ENTITY lps25h_BARO_ADD_SYNC IS

		PORT(
			CLK,FIN,INTR,RST_L,TMR	: IN	STD_LOGIC;
			ADD						: OUT	STD_LOGIC_VECTOR(8 downto 0);
			DIN						: OUT	STD_LOGIC_VECTOR(7 downto 0);
		 	ACLR				: OUT	STD_LOGIC);
			
	END lps25h_BARO_ADD_SYNC;

	ARCHITECTURE ADD_SM OF lps25h_BARO_ADD_SYNC IS
		
type state_TYPE is (S0, ICR2A, IRC2B ,RSCNFA ,RSCNFB ,CR1A ,CR1B ,CR2A ,CR2B ,CR3A,CR3B ,CR4A ,CR4B ,TOOLGA ,TOOLGB ,INCFA ,INCFB ,FFCTLA ,FFCTLB ,PRXLA ,PRXLB,
	PRLA ,PRLB ,PRHA ,PRHB ,TMLA ,TMLB ,TMHA, TMHB ,RFPXLA ,RFPXLB , SWAITA, SWAITB ,RFPLA ,RFPLB ,RFPHA ,RFPHB);
	signal pres_state, next_state	:state_TYPE;

		--SIGNAL 	CS_SeL		: STD_LOGIC;
		--SIGNAL __signal_name : STD_LOGIC;
	BEGIN
	SYNC: PROCESS(RST_L,CLK)
	--ST.clk = CLK;
	--ST.reset = RST_L;
begin
	if (RST_L = '0') THEN
		PRES_STATE <= S0;
	ELSE
	IF(CLK='1'and clk'event)THEN
		PRES_STATE <= NEXT_STATE;

	END IF;
END IF;
END PROCESS SYNC;	
COMB: PROCESS(pres_state,fin,intr,tmr)
BEGIN



CASE PRES_STATE IS
		WHEN S0 => NEXT_STATE <= ICR2A;

		WHEN ICR2A =>
		If (FIN  = '1') then NEXT_STATE <= IRC2B;
			else NEXT_STATE <=ICR2A;
		end if;
		WHEN IRC2B =>
		If (FIN = '1')then NEXT_STATE <= IRC2B;
		else NEXT_STATE <= RSCNFA;
		end if;
		
		WHEN RSCNFA =>
		If (FIN  = '1') then NEXT_STATE <= RSCNFB;
			else NEXT_STATE <=RSCNFA;
		end if;
		WHEN RSCNFB =>
		If (FIN  = '1') then NEXT_STATE <= RSCNFB;
			else NEXT_STATE <=CR1A;
			end if;
	

		WHEN CR1A =>
		If (FIN  = '1') then NEXT_STATE <= CR1B;
			else NEXT_STATE <=CR1A;
		end if;

		WHEN CR1B =>
		If (FIN  = '1') then NEXT_STATE <= CR1B;
			else NEXT_STATE <=CR2A;
		end if;
		
	
		WHEN CR2A =>
		If (FIN  = '1') then NEXT_STATE <= CR2B;
			else NEXT_STATE <=CR2A;
		end if;
		WHEN CR2B =>
		If (FIN  = '1') then NEXT_STATE <= CR2B;
			else NEXT_STATE <=CR3A;
		end if;
		WHEN CR3A =>
		If (FIN  = '1') then NEXT_STATE <= CR3B;
			else NEXT_STATE <=CR3A;
		end if;

		WHEN CR3B =>
		If (FIN  = '1') then NEXT_STATE <= CR3B; 
			else NEXT_STATE <=CR4A;
		end if;
		WHEN CR4A =>
		If (FIN  = '1') then NEXT_STATE <= CR4B;
		ELSE NEXT_STATE <= CR4A;
		END IF;
		WHEN CR4B =>
		If (FIN  = '1') then NEXT_STATE <= CR4B;
		ELSE NEXT_STATE <= INCFA;
		END IF;
		
		WHEN INCFA =>
		If (FIN  = '1') then NEXT_STATE <= INCFB;
			else NEXT_STATE <= INCFA;
		end if;

		WHEN INCFB =>
		If (FIN  = '1') then NEXT_STATE <= INCFB;
			else NEXT_STATE <=FFCTLA;
		end if;	


		WHEN FFCTLA =>
		If (FIN  = '1') then NEXT_STATE <= FFCTLB;
			else NEXT_STATE <=FFCTLA;
		end if;
		WHEN FFCTLB =>
		If (FIN  = '1') then NEXT_STATE <= FFCTLB;
			else NEXT_STATE <= SWAITA;
		end if;		


		WHEN SWAITA => NEXT_STATE <= SWAITB; --ADDED FOR ACLR
		WHEN SWAITB =>
		If ((INTR = '0') AND (TMR = '0') ) then NEXT_STATE <= SWAITB;
			ELSIF
			((INTR = '1') AND (TMR = '0') ) then NEXT_STATE <= PRXLA;	
			ELSIF
			((INTR = '1') AND (TMR = '1') ) then NEXT_STATE <= PRXLA;	
			ELSE
			NEXT_STATE <= TOOLGA;--		((INTR = '0') AND (TMR = '1') )
		end if;


		WHEN PRXLA =>
		If (FIN  = '1') then NEXT_STATE <= PRXLB;
			else NEXT_STATE <=PRXLA;
		end if;
		WHEN PRXLB =>
		If (FIN  = '1') then NEXT_STATE <= PRXLB;
			else NEXT_STATE <=PRLA;
		end if;
		WHEN PRLA =>
		If (FIN  = '1') then NEXT_STATE <= PRLB;
			else NEXT_STATE <=PRLA;
		end if;
		WHEN PRLB =>
		If (FIN  = '1') then NEXT_STATE <= PRLB;
			else NEXT_STATE <=PRHA;
		end if;
		WHEN PRHA =>
		If (FIN  = '1') then NEXT_STATE <= PRHB;
			else NEXT_STATE <=PRHA;
		end if;
		WHEN PRHB =>
		If (FIN  = '1') then NEXT_STATE <= PRHB;
			else NEXT_STATE <=TMLA;
		end if;
		WHEN TMLA =>
		If (FIN  = '1') then NEXT_STATE <= TMLB;
			else NEXT_STATE <=TMLA;
		end if;
		WHEN TMLB =>
		If (FIN  = '1') then NEXT_STATE <= TMLB;
			else NEXT_STATE <=TMHA;
		end if;
		WHEN TMHA =>
		If (FIN  = '1') then NEXT_STATE <= TMHB;
			else NEXT_STATE <=TMHA;
		end if;
		WHEN TMHB =>
		If (FIN  = '1') then NEXT_STATE <= TMHB;
		--	else NEXT_STATE <=RFPXLA; DON'T READ REFERENCE PRESSURE AND SKIP WRITING EXCEPT FOR FAULT
			else NEXT_STATE <=SWAITA;
		end if;

		WHEN RFPXLA =>
		If (FIN  = '1') then NEXT_STATE <= RFPXLB;
			else NEXT_STATE <=RFPXLA;
		end if;
		WHEN RFPXLB =>
		If (FIN  = '1') then NEXT_STATE <= RFPXLB;
			else NEXT_STATE <=RFPLA;
		end if;
		WHEN RFPLA =>
		If (FIN  = '1') then NEXT_STATE <= RFPLB;
		ELSE NEXT_STATE <= RFPLA; 
		END IF;
		WHEN RFPLB =>
		If (FIN  = '1') then NEXT_STATE <= RFPLB; 
		ELSE NEXT_STATE <= RSCNFA;
		END IF;
	

		WHEN TOOLGA => NEXT_STATE <= TOOLGB;
		--If (FIN  = '1') then NEXT_STATE <= TOOLGB;
		--ELSE NEXT_STATE <= TOOLGA;
		--END IF;
		WHEN TOOLGB => NEXT_STATE <= ICR2A;
		--If (FIN  = '1') then NEXT_STATE <= TOOLGB; --set FAULT FLAG
		--ELSE NEXT_STATE <= ICR2A; -- DO POR
		--END IF;

		WHEN OTHERS => NEXT_STATE <= S0;

	--WHEN S => ST = S;

	END CASE; 
	END PROCESS COMB;


outputs: process (pres_state,next_state)
VARIABLE  CS, CLR	:std_ulogic;
VARIABLE AD: STD_LOGIC_VECTOR(8 downto 0);
VARIABLE DN: STD_LOGIC_VECTOR(7 downto 0);
begin 
  state_driven_outputs: case pres_state is 
	when S0 => AD := O"000";DN := X"00"; CLR := '1';
	when ICR2A => AD := O"041";DN := X"80"; CLR := '1';
	WHEN IRC2B => AD := O"441";DN := X"80"; CLR := '0';
	WHEN RSCNFA => AD := O"020";DN := X"0F"; CLR := '0';
	WHEN RSCNFB => AD := O"420";DN := X"0F"; CLR := '0';
	WHEN CR1A => AD := O"040";DN := X"04"; CLR := '0';-- AD change 3/8
	WHEN CR1B => AD := O"440";DN := X"04"; CLR := '0';-- AD change 3/8
	WHEN CR2A => AD := O"041";DN := X"E0"; CLR := '0';
	WHEN CR2B => AD := O"441";DN := X"E0"; CLR := '0';
	WHEN CR3A => AD := O"042";DN := X"80"; CLR := '0';
	WHEN CR3B => AD := O"442";DN := X"80"; CLR := '0';
	WHEN CR4A => AD := O"043";DN := X"01"; CLR := '0';-- DN change 3/8
	WHEN CR4B => AD := O"443";DN := X"01"; CLR := '0';-- DN change 3/8
	--WHEN TOOLGA => AD :="00011000"; CLR := '0';
	--WHEN TOOLGB => AD :="00011001"; CLR := '0';
	WHEN INCFA => AD := O"044";DN := X"00"; CLR := '0';
	WHEN INCFB => AD := O"444";DN := X"00"; CLR := '0';
	WHEN FFCTLA => AD := O"056";DN := X"DF"; CLR := '0';
	WHEN FFCTLB => AD := O"456";DN := X"DF"; CLR := '1';
	WHEN PRXLA => AD := O"250";DN := X"00"; CLR := '0';
	WHEN PRXLB => AD := O"650";DN := X"00"; CLR := '0';
	WHEN PRLA => AD := O"251";DN := X"00"; CLR := '0';
	WHEN PRLB => AD := O"651";DN := X"00"; CLR := '0';
	WHEN PRHA => AD := O"252";DN := X"00"; CLR := '0';
	WHEN PRHB => AD := O"652";DN := X"00"; CLR := '0';
	WHEN TMLA => AD := O"253";DN := X"00"; CLR := '0';
	WHEN TMLB => AD := O"653";DN := X"00"; CLR := '0';
	WHEN TMHA => AD := O"254";DN := X"00"; CLR := '0';
	WHEN TMHB => AD := O"654";DN := X"00"; CLR := '0';
	WHEN RFPXLA => AD := O"210"; CLR := '0';
	WHEN RFPXLB => AD := O"610"; CLR := '0';
	WHEN SWAITA  => AD := O"075";DN := X"00"; CLR := '1';
	WHEN SWAITB  => AD := O"475";DN := X"00"; CLR := '0';
	WHEN RFPLA => AD := O"211";DN := X"00"; CLR := '0';
	WHEN RFPLB => AD := O"611";DN := X"00"; CLR := '0';
	WHEN RFPHA => AD := O"212";DN := X"00"; CLR := '0';
	WHEN RFPHB => AD := O"612";DN := X"00"; CLR := '0';
	WHEN TOOLGA => AD := O"074";DN := X"00"; CLR := '0';
	WHEN TOOLGB => AD := O"474";DN := X"00"; CLR := '0';
	WHEN OTHERS => AD := O"000";DN := X"00"; CLR := '0';
 	end case state_driven_outputs; 
	ADD <= AD;
	DIN <= DN;
ACLR <= CLR;

END PROCESS OUTPUTS;

	END ADD_SM;

