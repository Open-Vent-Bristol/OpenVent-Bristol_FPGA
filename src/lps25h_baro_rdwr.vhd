library IEEE;
use IEEE.std_logic_1164.all;
-- MODULE SPECIFIC TO  STM BAROMETER SENSOR, LPS25H WHICH GENERATES THE WRITE REGISTER COMMANDS


ENTITY LPS25H_baro_RDWR IS

	PORT(
	 	BARO_OUT,SER_CLK, RST_L		: IN	STD_LOGIC;
		ADD								: IN	STD_LOGIC_VECTOR(8 downto 0);
		DIN								: IN	STD_LOGIC_VECTOR(7 downto 0);
		--__bidir_name, __bidir_name		: INOUT	STD_LOGIC;
	BARO_SER_CLK,  FIN	,CS_L		: OUT	STD_LOGIC;
	spi_data						: OUT	STD_LOGIC_VECTOR(7 downto 0);
	BARO_DIN						: OUT	STD_LOGIC);
	END LPS25H_baro_RDWR;


architecture SPI_SM of LPS25h_baro_RDWR is
	type state_TYPE is (S0, S1 ,S2 ,S3 ,Y0 ,Y1 ,Y2 ,Y3 ,Y4 ,Y5 ,Y6 ,Y7,
	Y8 ,Y9 ,Y10 ,Y11 ,Y12 ,Y13 ,Y14 ,Y15 ,Y16 ,Y17 ,Y18);
	
	CONSTANT ICR2 : std_logic_vector(8 downto 0) := O"077";
	CONSTANT RSCNF : std_logic_vector(8 downto 0) := O"020";
	CONSTANT CR1 : std_logic_vector(8 downto 0) := O"040";
	CONSTANT CR2 : std_logic_vector(8 downto 0) := O"041";
	CONSTANT CR3 : std_logic_vector(8 downto 0) := O"042";
	CONSTANT CR4 : std_logic_vector(8 downto 0) := O"043";
	CONSTANT ICNFG : std_logic_vector(8 downto 0) := O"044";
	CONSTANT FFCTL : std_logic_vector(8 downto 0) := O"056";
	CONSTANT PRSH : std_logic_vector(8 downto 0) := O"252";
	CONSTANT PRSL : std_logic_vector(8 downto 0) := O"251";
	CONSTANT PRSXL : std_logic_vector(8 downto 0) := O"250";
	CONSTANT TMPH : std_logic_vector(8 downto 0) := O"254";
	CONSTANT TMPL : std_logic_vector(8 downto 0) := O"253";
	CONSTANT RPRSH : std_logic_vector(8 downto 0) := O"212";
	CONSTANT RPRSL : std_logic_vector(8 downto 0) := O"211";
	CONSTANT RPRSXL : std_logic_vector(8 downto 0) := O"210";
--	CONSTANT TBD : std_logic_vector(8 downto 0) := "00100100";
	SIGNAL RD							:std_logic_vector(7 downto 0);
	signal pres_state, next_state		:state_TYPE;
	signal INVCLK, DATA_EN, BD, BCLK, FN, CS	:std_logic;						
	SIGNAL A7:BOOLEAN;
BEGIN



SYNC: PROCESS(RST_L,SER_CLK,add)

begin
if (RST_L = '0') THEN
		PRES_STATE <= S0;
	ELSE
	IF(ser_CLK='1'and ser_clk'event)THEN
		PRES_STATE <= NEXT_STATE;
	END IF;
END IF;
END PROCESS SYNC;

COMB: PROCESS(pres_state,add)
BEGIN


CASE PRES_STATE IS

		WHEN S0 =>	
		  case 	add is
			when ICR2 => next_state <= s1;
			when RSCNF => next_state <= s1;
			when CR1 => next_state <= s1;
			when CR2 => next_state <= s1;
			when CR3 => next_state <= s1;
			when CR4 => next_state <= s1;
			when ICNFG => next_state <= s1;
			when FFCTL => next_state <= s1;
			when PRSH => next_state <= s1;
			when PRSL => next_state <= s1;
			when PRSXL => next_state <= s1;
			when TMPH => next_state <= s1;
			when TMPL => next_state <= s1;
			when RPRSH => next_state <= s1;
			when RPRSL => next_state <= s1;
			when RPRSXL => next_state <= s1;
			--when padch => next_state <= s1;
			--when padcl => next_state <= s1;
			--when tadch => next_state <= s1;
			--when tadcl => next_state <= s1;
			when others => next_state <= S0;
			end case;	
		

		WHEN S1 => NEXT_STATE <= S2;

		WHEN S2 => NEXT_STATE <= S3;

		WHEN S3 => NEXT_STATE <= Y0;

		WHEN Y0 => NEXT_STATE <= Y1;	

		WHEN Y1 => NEXT_STATE <= Y2;	

		WHEN Y2 => NEXT_STATE <= Y3;	

		WHEN Y3 => NEXT_STATE <= Y4;	

		WHEN Y4 => NEXT_STATE <= Y5;	

		WHEN Y5 => NEXT_STATE <= Y6;	

		WHEN Y6 => NEXT_STATE <= Y7;	

		WHEN Y7 => NEXT_STATE <= Y8;	

		WHEN Y8 => NEXT_STATE <= Y9;	

		WHEN Y9 => NEXT_STATE <= Y10;	

		WHEN Y10 => NEXT_STATE <= Y11;	

		WHEN Y11 => NEXT_STATE <= Y12;	

		WHEN Y12 => NEXT_STATE <= Y13;	

		WHEN Y13 => NEXT_STATE <= Y14;	

		WHEN Y14 => NEXT_STATE <= Y15;	

		WHEN Y15 => NEXT_STATE <= Y16;	

		WHEN Y16 => NEXT_STATE <= Y17;	

		WHEN Y17 => NEXT_STATE <= Y18;	

		WHEN Y18 => NEXT_STATE <= S0;	

		END CASE;
	END PROCESS COMB;
latchs: PROCESS(pres_state,ser_clk,ADD(7),rd)

begin

IF ADD(7) = '1' THEN A7 <= TRUE;
ELSE A7 <= FALSE;
END IF;

if (ser_CLK = '0' and ser_clk'event) THEN
	if ((PRES_STATE = Y8) AND A7) then
	RD(7) <= BARO_OUT;
	end if;
	if ((PRES_STATE = Y9) AND A7) then
	RD(6) <= BARO_OUT;
	end if;
	if ((PRES_STATE = Y10) AND A7) then
	RD(5) <= BARO_OUT;
	end if;
	if ((PRES_STATE = Y11) AND A7) then
	RD(4) <= BARO_OUT;
	end if;
	if ((PRES_STATE = Y12) AND A7) then
	RD(3) <= BARO_OUT;
	end if;
	if ((PRES_STATE = Y13) AND A7) then
	RD(2) <= BARO_OUT;
	end if;
	if ((PRES_STATE = Y14) AND A7) then
	RD(1) <= BARO_OUT;
	end if;
	if ((PRES_STATE = Y15) AND A7) then
	RD(0) <= BARO_OUT;
	end if;

end if;
spi_data <= RD;

END PROCESS LATCHS;


outputs: process (pres_state, DATA_EN, BD, BCLK,cs,add,ser_clk,din)
VARIABLE  BARODIN :std_logic;
VARIABLE clken	:std_logic;
VARIABLE FN	:std_logic;

begin 

  state_driven_outputs: case pres_state is 

	when S0 => BARODIN	 :='0';clken := '0'; FN := '0';baro_ser_clk <= '1';FIN <= '0';BARO_DIN <=   '0'; cs <= '1';CS_L <= cs;
	when S1 => BARODIN	 :='0';clken := '0'; FN := '0';baro_ser_clk <= '1';FIN <= '0';BARO_DIN <=   barodin; cs <= '1';CS_L <= cs;

	when S2 => BARODIN	 :='0';clken := '0'; FN := '0';baro_ser_clk <= '1';FIN <= '0';BARO_DIN <=   barodin; cs <= '1';CS_L <= cs;
	
	when S3 => BARODIN	 :='0';clken := '0'; FN := '0';baro_ser_clk <= '1';FIN <= '0';BARO_DIN <=   barodin; cs <= '0';CS_L <= cs;

	when Y0 => BARODIN   := ADD(7);clken := '1'; FN := '0';baro_ser_clk <= not ser_clk and clken;FIN <= FN;BARO_DIN <=   barodin; cs <= '0';CS_L <= cs;

	when Y1 => BARODIN	 := '0';clken := '1'; FN := '0';baro_ser_clk <= not ser_clk and clken;FIN <= FN;BARO_DIN <=   barodin; cs <= '0';CS_L <= cs;

	when Y2 => BARODIN	 := ADD(5);clken := '1'; FN := '0';baro_ser_clk <= not ser_clk and clken;FIN <= FN;BARO_DIN <=   barodin; cs <= '0';CS_L <= cs;

	when Y3 => BARODIN	 := ADD(4);clken := '1'; FN := '0';baro_ser_clk <= not ser_clk and clken;FIN <= FN;BARO_DIN <=   barodin; cs <= '0';CS_L <= cs;

	when Y4 => BARODIN	 := ADD(3);clken := '1'; FN := '0';baro_ser_clk <= not ser_clk and clken;FIN <= FN;BARO_DIN <=   barodin; cs <= '0';CS_L <= cs;

	when Y5 => BARODIN	 := ADD(2);clken := '1'; FN := '0';baro_ser_clk <= not ser_clk and clken;FIN <= FN;BARO_DIN <=   barodin; cs <= '0';CS_L <= cs;

	when Y6 => BARODIN	 := ADD(1);clken := '1'; FN := '0';baro_ser_clk <= not ser_clk and clken;FIN <= FN;BARO_DIN <=   barodin; cs <= '0';CS_L <= cs;

	when Y7 => BARODIN	 := ADD(0);clken := '1'; FN := '0';baro_ser_clk <= not ser_clk and clken;FIN <= FN;BARO_DIN <=   barodin; cs <= '0';CS_L <= cs;

	when Y8 => BARODIN	 := (DIN(7) and not ADD(7)); clken := '1'; FN := '0';baro_ser_clk <= not ser_clk and clken;FIN <= FN;BARO_DIN <=   barodin; cs <= '0';CS_L <= cs;

	when Y9 => BARODIN	 := (DIN(6) and not ADD(7));clken := '1'; FN := '0';baro_ser_clk <= not ser_clk and clken;FIN <= FN;BARO_DIN <=   barodin; cs <= '0';CS_L <= cs;

	when Y10 => BARODIN	 := (DIN(5) and not ADD(7));clken := '1'; FN := '0';baro_ser_clk <= not ser_clk and clken;FIN <= FN;BARO_DIN <=   barodin; cs <= '0';CS_L <= cs;

	when Y11 => BARODIN	 := (DIN(4) and not ADD(7)); clken := '1'; FN := '0';baro_ser_clk <= not ser_clk and clken;FIN <= FN;BARO_DIN <=   barodin; cs <= '0';CS_L <= cs;

	when Y12 => BARODIN	 := (DIN(3) and not ADD(7));clken := '1'; FN := '0';baro_ser_clk <= not ser_clk and clken;FIN <= FN;BARO_DIN <=   barodin; cs <= '0';CS_L <= cs;

	when Y13 => BARODIN	 := (DIN(2) and not ADD(7));clken := '1'; FN := '0';baro_ser_clk <= not ser_clk and clken;FIN <= FN;BARO_DIN <=   barodin; cs <= '0';CS_L <= cs;

	when Y14 => BARODIN	 := (DIN(1) and not ADD(7));clken := '1'; FN := '0';baro_ser_clk <= not ser_clk and clken;FIN <= FN;BARO_DIN <=   barodin; cs <= '0';CS_L <= cs;

	when Y15 => BARODIN	 := (DIN(0) and not ADD(7)); clken := '1'; FN := '0';baro_ser_clk <= not ser_clk and clken;FIN <= FN;BARO_DIN <=   barodin; cs <= '0';CS_L <= cs;
	
	When Y16 => BARODIN	 :='0'; clken := '0'; FN := '0';baro_ser_clk <= '1';FIN <= FN;BARO_DIN <=   barodin; cs <= '0';CS_L <= cs;

	when Y17 => BARODIN	 :='0'; clken := '0'; FN := '1';baro_ser_clk <= '1'; FIN <= FN;BARO_DIN <= '0'; cs <= '1';CS_L <= cs;

	when Y18 => BARODIN	 :='0';clken := '0'; FN := '1';baro_ser_clk <= '1'; FIN <= FN;BARO_DIN <= '0'; cs <= '1';CS_L <= cs;


 	WHEN OTHERS=> clken := '0'; FN := '0';baro_ser_clk <= '1'; FIN <= '0';BARO_DIN <= '0';  cs <= '1';CS_L <= cs;

  end case state_driven_outputs; 
	--BARO_DIN <=   barodin; --baro_ser_clk <= not ser_clk and clken;
	--if (not ser_clk and clken) = "1" then baro_ser_clk <= '1' else baro_ser_clk ,='0';

	--FIN <= FN;

end process OUTPUTS; 




END SPI_SM;
