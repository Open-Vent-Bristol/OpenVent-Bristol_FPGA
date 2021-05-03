

library IEEE;
use IEEE.std_logic_1164.all;
-- THIS MODULE CONNECTS ALL THE OTHER MODULES TOGETHER IN LIEU OF TOP LEVEL SCHEMATIC FOR PORTABLITY
	ENTITY lps25h_baro_spi_format IS

	PORT(
		rst_L,mstrclk, baro_out, BARO_INTR				: IN	STD_LOGIC;
		baro_din, baro_serclk, BARO_CSN			: OUT	STD_LOGIC;
		Press 													: out 	STD_LOGIC_VECTOR(23 downto 0);
		--RPress 													: out 	STD_LOGIC_VECTOR(23 downto 0);
		Temp 													: out 	STD_LOGIC_VECTOR(15 downto 0);
		AbsPress 													: out 	STD_LOGIC_VECTOR(17 downto 0));
		--AbsRPress 													: out 	STD_LOGIC_VECTOR(17 downto 0));
	
	END lps25h_baro_spi_format;

	ARCHITECTURE ctrl OF lps25h_baro_spi_format IS
	SIGNAL TP_SERCLK,TP_FIN, TP_FINCK,TM_OUT,TP_CS,TP_ACLR 	: STD_LOGIC;--
	SIGNAL TP_MSEC,TP_BARO_OUT						: STD_LOGIC;
	SIGNAL TP_DIN,TP_SPICLK							: STD_LOGIC;
	SIGNAL TP_ADD									: STD_LOGIC_VECTOR(8 downto 0);
	SIGNAL TP_SPIDATA, TP_DINV						: STD_LOGIC_VECTOR(7 downto 0);
	signal  TP_PRESSH					:STD_LOGIC_VECTOR(7 downto 0);--TP_RFPRESSH,
	signal TP_TEMPH									:STD_LOGIC_VECTOR(7 downto 0);
	signal  TP_PRESSL					:STD_LOGIC_VECTOR(7 downto 0);--TP_RFPRESSL,
	signal TP_TEMPL, TP_PRESSXL		:STD_LOGIC_VECTOR(7 downto 0);--TP_RFPRESSXL,
	--SIGNAL __signal_name : STD_LOGIC;
				
				component lps25h_BARO_ADD_sync
					PORT(
						CLK, FIN, INTR, RST_L, TMR 	: IN	STD_LOGIC;
							ADD							: OUT	STD_LOGIC_VECTOR(8 downto 0);
							DIN							: OUT	STD_LOGIC_VECTOR(7 downto 0);
							ACLR						: OUT	STD_LOGIC);
			 	END component;


				component LPS25H_TIMER
					PORT(
						MSTR_CLK, RST_L,ACLR, SYNC 		: IN	STD_LOGIC;
						TMR 						: OUT	STD_LOGIC);
				END component;


				component lps25h_CLKGEN_ONE_MSEC
					PORT(
					MSTR_CLK, RST_L 					: IN	STD_LOGIC;
						CLKEN_OUT, SPI_CK, T001					: OUT	STD_LOGIC);
				END component;


				component lps25h_BARO_RDWR 
					PORT(
						 BARO_OUT,SER_CLK, RST_L 			: IN	STD_LOGIC;
							ADD								: IN	STD_LOGIC_VECTOR(8 downto 0);
							DIN								: IN	STD_LOGIC_VECTOR(7 downto 0);
						BARO_SER_CLK, FIN, CS_L					: OUT	STD_LOGIC;
						SPI_DATA, BARO_DIN					: OUT	STD_LOGIC_VECTOR(7 downto 0));
				END component;



				component LPS25H_CLK_BARO_SPI
					PORT(
						SPICLK, FIN, CS_L, DIN 					: IN	STD_LOGIC;
					 	CLK,RST_L								: IN	STD_LOGIC;
						DIN_CK,SPICLK_CK, CSL_CK, FIN_CK	: OUT	STD_LOGIC);

				END  component;


		component lps25h_spi_demux
					PORT(
						FIN, RST_L 							: IN	STD_LOGIC;
						ADD									: IN	STD_LOGIC_VECTOR(8 downto 0);
						SPI_DATA								: IN	STD_LOGIC_VECTOR(7 downto 0);
						PRSH_DATA,PRSL_DATA,TMPH_DATA,PRSXL_DATA,TMPL_DATA		: OUT	STD_LOGIC_VECTOR(7 downto 0));--RPRSH_DATA,RPRSL_DATA,RPRSXL_DATA,
				END  component;

			

		component lps25h_reformat IS
					PORT(
						PRSH_data										: in	STD_LOGIC_VECTOR(7 downto 0);--RPRSH_data,
						PRSL_data, TMPH_data 							: in	STD_LOGIC_VECTOR(7 downto 0);--RPRSL_data,
						PRSXL_data, TMPL_data							: in	STD_LOGIC_VECTOR(7 downto 0);--RPRSXL_data,
						Press 													: out 	STD_LOGIC_VECTOR(23 downto 0);
						--RPress 													: out 	STD_LOGIC_VECTOR(23 downto 0);
						Temp 													: out 	STD_LOGIC_VECTOR(15 downto 0);
						AbsPress 													: out 	STD_LOGIC_VECTOR(17 downto 0));
						--AbsRPress 													: out 	STD_LOGIC_VECTOR(17 downto 0));
				END component;	
BEGIN



				SERIO: ENTITY WORK.lps25h_BARO_RDWR
					PORT MAP( BARO_OUT => BARO_OUT, SER_CLK  =>TP_SERCLK ,RST_L => RST_L, ADD => TP_ADD,DIN => TP_DINV, BARO_SER_CLK  => TP_SPICLK ,
					 FIN  => TP_FIN,CS_L => TP_CS, SPI_DATA  => TP_SPIDATA, BARO_DIN  => TP_DIN  );

				MASTER_CLKS: ENTITY WORK.LPS25H_CLKGEN_ONE_MSEC
					PORT MAP(MSTR_CLK  => MSTRCLK , RST_L  => RST_L , 
					SPI_CK =>TP_SERCLK,  T001  => TP_MSEC  );

				MSECS: ENTITY WORK.LPS25H_TIMER
					PORT MAP( MSTR_CLK  => MSTRCLK  , RST_L => RST_L , ACLR  => TP_ACLR , SYNC => TP_MSEC ,
					TMR => TM_OUT );

				ADD_GEN: ENTITY WORK.lps25h_BARO_ADD_SYNC
					PORT MAP( CLK => MSTRCLK ,FIN  =>TP_FINCK, INTR => BARO_INTR, RST_L  =>RST_L, TMR =>TM_OUT ,
					 ADD =>TP_ADD ,DIN => TP_DINV ,ACLR  => TP_ACLR   );

				CLK_SPI: ENTITY WORK.LPS25H_CLK_BARO_SPI
					PORT MAP( SPICLK => TP_SPICLK,FIN => TP_FIN, CS_L => TP_CS, DIN => TP_DIN,
					 CLK => MSTRCLK, RST_L => RST_L,
					DIN_CK  => baro_din , SPICLK_CK => BARO_SERCLK, CSL_CK => BARO_CSN, FIN_CK  => TP_FINCK);

	
				SPI_DEMUX: ENTITY WORK.lps25h_spi_demux
					PORT MAP( FIN  => TP_FINCK , RST_L => RST_L , ADD => TP_ADD, SPI_DATA => TP_SPIDATA, 
					 PRSH_data=> TP_PRESSH, PRSL_data=> TP_PRESSL,TMPH_data=> TP_TEMPH, 
					 PRSXL_data => TP_PRESSXL,TMPL_data => TP_TEMPL);
					--RPRSH_data=> TP_RFPRESSH,, RPRSXL_data => TP_RFPRESSXL RPRSL_data=> TP_RFPRESSL,


				REFORMAT: ENTITY WORK.lps25h_REFORMAT
					PORT MAP(  PRSH_data=> TP_PRESSH, PRSL_data=> TP_PRESSL, TMPH_data=> TP_TEMPH, 
					PRSXL_data => TP_PRESSXL, TMPL_data => TP_TEMPL,
					PRESS=> PRESS, TEMP=> TEMP);
					--RPRSH_data=> TP_RFPRESSH,RPRSL_data=> TP_RFPRESSL,  RPRESS=> RPRESS,RPRSXL_data => TP_RFPRESSXL, 
END ctrl;




