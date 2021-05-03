
-- module to clock the spi data into the barometer sensor and THE finish signals,

LIBRARY ieee;
USE ieee.std_logic_1164.all;

ENTITY LPS25H_CLK_BARO_SPI IS

	PORT
	(
		SPICLK						: IN	STD_LOGIC;		
		FIN							: IN	STD_LOGIC;		
		CS_L						: IN	STD_LOGIC; -- ACTIVE LOW
		DIN							: IN	STD_LOGIC;
		CLK							: IN	STD_LOGIC;
		RST_L						: IN	STD_LOGIC;
		DIN_CK						: OUT 	STD_LOGIC;
		SPICLK_CK					: OUT 	STD_LOGIC;
		CSL_CK						: OUT 	STD_LOGIC;
		FIN_CK						: OUT 	STD_LOGIC
	);
	
END LPS25H_CLK_BARO_SPI;

ARCHITECTURE BEHAV OF LPS25H_CLK_BARO_SPI IS

	SIGNAL	SDIN	: STD_LOGIC;
	SIGNAL	SSPICLK	: STD_LOGIC;
	SIGNAL	SFIN	: STD_LOGIC;
	SIGNAL	CSL	: STD_LOGIC;
BEGIN

	data:PROCESS (CLK, RST_L,sdin,sfin,csl,sspiclk)
	BEGIN
	
		IF RST_L = '0' THEN
		
			SDIN <= '0';SFIN <= '0';CSL <= '1';
			
		ELSIF (CLK 'EVENT AND CLK = '1') THEN
		
			
				SDIN <= DIN;SFIN <= FIN;CSL <= CS_L;
			
			ELSE
			
				SDIN <= SDIN; SFIN <= SFIN;CSL <= CSL;
				
			
		END IF;
		
	END PROCESS data;
	clok:PROCESS (CLK, RST_L,sspiclk)
	BEGIN
	
		IF RST_L = '0' THEN
		
			SSPICLK <= '0';
			
		ELSIF (CLK 'EVENT AND CLK = '1') THEN
		
			SSPICLK <= SPICLK;
			
			ELSE
			
			SSPICLK <= SSPICLK; 
				
			END IF;
			
		
	END PROCESS clok;		
	SPICLK_CK <= SSPICLK;DIN_CK <= SDIN;FIN_CK <= SFIN; CSL_CK <= CSL;
	
END BEHAV;

