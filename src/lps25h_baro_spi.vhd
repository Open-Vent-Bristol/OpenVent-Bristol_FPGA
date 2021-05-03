

library IEEE;
use IEEE.std_logic_1164.all;
-- THIS MODULE CONNECTS ALL THE OTHER MODULES TOGETHER IN LIEU OF TOP LEVEL SCHEMATIC FOR PORTABLITY
	ENTITY lps25h_baro_spi IS

	PORT(
		sync, rst_L,mstrclk, baro_out, CONV_INTR				: IN	STD_LOGIC;
		RFPRESSH, PRESSH								: out	STD_LOGIC_VECTOR(7 downto 0);
		TEMPH												: out	STD_LOGIC_VECTOR(7 downto 0);
		RFPRESSL, PRESSL								: out	STD_LOGIC_VECTOR(7 downto 0);
		TEMPL,RFPRESSXL, PRESSXL					: out	STD_LOGIC_VECTOR(7 downto 0);
		baro_din, baro_serclk, SPI_CSN, fin		: OUT	STD_LOGIC);
	END lps25h_baro_spi;

	ARCHITECTURE ctrl OF lps25h_baro_spi IS
	SIGNAL  TP_SERCLK,TP_FIN, TM_OUT,TP_CS,TP_ACLR,TP_FIN3 					: STD_LOGIC;--
	SIGNAL	TP_MSEC,TP_CLKEN,TP_BARO_OUT,TP_FIN2					: STD_LOGIC; --,TP_RST,TP_SPI_CLK
	SIGNAL TP_SPIDIN2,TP_SPIDIN1,TP_FIN1,TP_SPICLK1,TP_SPICLK2	: STD_LOGIC;--TP_MSTRCLK,
	SIGNAL			TP_ADD										: STD_LOGIC_VECTOR(8 downto 0);
	SIGNAL			TP_SPIDATA										: STD_LOGIC_VECTOR(7 downto 0);
	--SIGNAL __signal_name : STD_LOGIC;
				
				component lps25h_BARO_ADD_sync
					PORT(
						CLK, GO, FIN, TMR, RST_L 	: IN	STD_LOGIC;
							ADD							: OUT	STD_LOGIC_VECTOR(7 downto 0);
						CS_L, ACLR						: OUT	STD_LOGIC);
			 	END component;


				component LPS25H_TIMER
					PORT(
						MSTR_CLK, RST_L,ACLR, SYNC 		: IN	STD_LOGIC;
						--CNT								: OUT	STD_LOGIC_VECTOR(2 downto 0);
						TMR 						: OUT	STD_LOGIC);
				END component;


				component lps25h_CLK_GEN_ONE_MSEC
					PORT(
					MSTR_CLK, RST_L, CNTEN 					: IN	STD_LOGIC;
						CLKEN_OUT, STRB, T001					: OUT	STD_LOGIC);
				END component;


				component lps25h_SERIO_READS 
					PORT(
						 BARO_OUT,SER_CLK, RST_L 			: IN	STD_LOGIC;
							ADD								: IN	STD_LOGIC_VECTOR(7 downto 0);
						BARO_SER_CLK, FIN					: OUT	STD_LOGIC;
						SPI_DATA, BARO_DIN					: OUT	STD_LOGIC_VECTOR(7 downto 0));
				END component;


				--component lps25h_BARO_NCMD
				--PORT(
				--		SER_CLK, RST_L 					: IN	STD_LOGIC;
				--			ADD							: IN	STD_LOGIC_VECTOR(7 downto 0);
				--		BARO_SER_CLK, FIN				: OUT	STD_LOGIC);
				--END component;


				component lps25h_BARO_WRT
					PORT(
						SER_CLK, RST_L 					: IN	STD_LOGIC;
							ADD							: IN	STD_LOGIC_VECTOR(8 downto 0);
						BARO_SER_CLK, FIN, BARO_DIN		: OUT	STD_LOGIC);
				END component;


				component CLK_BARO_SPI
					PORT(
						CS_L,DIN1, DIN2 					: IN	STD_LOGIC;
						SPICLK1,SPICLK2,SPICLK3 			: IN	STD_LOGIC;
						FIN1,FIN2,FIN3 						: IN	STD_LOGIC;
					 	RST_L,CLK,CLK_EN 					: IN	STD_LOGIC;
						DIN_CK,SPICLK_CK, CSL_CK, FIN_CK	: OUT	STD_LOGIC);

				END  component;


		component lps25h_spi_demux
					PORT(
						FIN, RST_L 							: IN	STD_LOGIC;
						ADD, SPI_DATA						: IN	STD_LOGIC_VECTOR(7 downto 0);
						A0H_DATA, B1H_DATA,B2H_DATA			: OUT	STD_LOGIC_VECTOR(15 downto 8);
						A0L_DATA, B1L_DATA, B2L_DATA		: OUT	STD_LOGIC_VECTOR(7 downto 0);
						C12H_DATA							: OUT	STD_LOGIC_VECTOR(13 downto 6);
						C12L_DATA							: OUT	STD_LOGIC_VECTOR(5 downto 0);
						PADCH_DATA, TADCH_DATA				: OUT	STD_LOGIC_VECTOR(9 downto 2);
						PADCL_DATA, TADCL_DATA				: OUT	STD_LOGIC_VECTOR(1 downto 0));
				END  component;

				
BEGIN

--ENTITY lps25h_baro_CONV IS

--	PORT(
--	 	SER_CLK, RST_L		: IN	STD_LOGIC;
--		ADD								: IN	STD_LOGIC_VECTOR(7 downto 0);
	--BARO_SER_CLK,  FIN			: OUT	STD_LOGIC;

	--BARO_DIN						: OUT	STD_LOGIC);
--	END lps25h_baro_CONV;


		--		CONV_CMD: ENTITY WORK.lps25h_BARO_CONV
		--			PORT MAP(SER_CLK  =>  TP_SERCLK,RST_L => RST_L, ADD => TP_ADD, BARO_SER_CLK  =>  TP_SPICLK3,
		--			FIN  => TP_FIN3, BARO_DIN =>  TP_SPIDIN2);



--ENTITY lps25h_baro_NCMD IS

--	PORT(
	--	SER_CLK, RST_L		: IN	STD_LOGIC;
	--	ADD								: IN	STD_LOGIC_VECTOR(7 downto 0);

--	BARO_SER_CLK, FIN			: out	STD_LOGIC);

--	END lps25h_baro_NCMD;

		--		NULL_CMD: ENTITY WORK.lps25h_BARO_NCMD
		--			PORT MAP(SER_CLK =>  TP_SERCLK, RST_L => RST_L, ADD  => TP_ADD,BARO_SER_CLK =>  TP_SPICLK2,
		--			 FIN  => TP_FIN2);


	
--ENTITY lps25h_SERIO_READS IS
	--	BARO_OUT, SER_CLK, RST_L		: IN	STD_LOGIC;
	--	ADD								: IN	STD_LOGIC_VECTOR(8 downto 0);-- FIRST 3 MSB's NOT PART OF BARO ADDRESS ADD(8) = B's ADD(7) = C/S ADD(6) =R/W
	--BARO_SER_CLK, FIN			: OUT	STD_LOGIC;
	--spi_data						: OUT	STD_LOGIC_VECTOR(7 downto 0);
	--BARO_DIN						: OUT	STD_LOGIC);
--	END lps25h_SERIO_READS;

				READS: ENTITY WORK.lps25h_SERIO_READS
					PORT MAP( BARO_OUT => BARO_OUT, SER_CLK  =>TP_SERCLK ,RST_L => RST_L, ADD => TP_ADD ,BARO_SER_CLK  => TP_SPICLK1 ,
					 FIN  => TP_FIN1,SPI_DATA  => TP_SPIDATA, BARO_DIN  => TP_SPIDIN1  );



--ENTITY CLK_GEN_ONE_MSEC IS
	--PORT(
	--	mstr_clk, RST_L, CNTEN : IN	STD_LOGIC;
	--	clken_out, STRB, T001: OUT	STD_LOGIC);
--END CLK_GEN_ONE_MSEC;


				MASTER_CLKS: ENTITY WORK.CLK_GEN_ONE_MSEC
					PORT MAP(MSTR_CLK  => MSTRCLK , RST_L  => RST_L ,CNTEN  => RST_L , CLKEN_OUT  =>TP_CLKEN ,
					STRB =>TP_SERCLK,  T001  => TP_MSEC  );



--ENTITY MSEC_CNTR_VHD IS
--	PORT(
--		mstr_clk, RST_L, ACLR, SYNC : IN	STD_LOGIC;
--		CNT 						: OUT STD_LOGIC_VECTOR( 2 DOWNTO 0);
--		TMR			: OUT	STD_LOGIC);
-- END MSEC_CNTR_VHD;
	

				MSECS: ENTITY WORK.LPS25H_TIMER
					PORT MAP( MSTR_CLK  => MSTRCLK  , RST_L => RST_L , ACLR  => TP_ACLR , SYNC => TP_MSEC ,
					TMR => TM_OUT );


--ENTITY lps25h_BARO_ADD_SYNC IS

		--PORT(
		--	CLK,go, FIN,INTR,RST_L,TMR	: IN	STD_LOGIC;
		--	ADD						: OUT	STD_LOGIC_VECTOR(8 downto 0);
		--	DIN						: OUT	STD_LOGIC_VECTOR(7 downto 0);
		--	CS_L, ACLR				: OUT	STD_LOGIC);
			
	--END lps25h_BARO_ADD_SYNC;


				ADD_GEN: ENTITY WORK.lps25h_BARO_ADD_SYNC
					PORT MAP( CLK =>TP_SERCLK, GO => SYNC ,FIN  =>TP_FIN, INTR => CONV_INTR,  TMR =>TM_OUT ,
					RST_L  =>RST_L, ADD =>TP_ADD ,CS_L =>TP_CS  ,ACLR  => TP_ACLR   );

--ENTITY CLK_BARO_SPI IS

--	PORT
--	(
--		CS_L						: IN	STD_LOGIC;
--		DIN1,DIN2					: IN	STD_LOGIC;
--		SPICLK1,SPICLK2,SPICLK3		: IN	STD_LOGIC;
--		FIN1,FIN2,FIN3				: IN	STD_LOGIC;
--		CLK							: IN	STD_LOGIC;
--		RST_L						: IN	STD_LOGIC;
--		CLK_EN						: IN	STD_LOGIC;
--		DIN_CK						: OUT 	STD_LOGIC;
--		SPICLK_CK					: OUT 	STD_LOGIC;
--		CSL_CK						: OUT 	STD_LOGIC;
--		FIN_CK						: OUT 	STD_LOGIC
--	);
	
-- END CLK_BARO_SPI;
	
		
				CLK_SPI: ENTITY WORK.LPS25H_CLK_BARO_SPI
					PORT MAP(CS_L => TP_CS, DIN1 => TP_SPIDIN1, DIN2 => TP_SPIDIN2, SPICLK1 => TP_SPICLK1, SPICLK2 => TP_SPICLK2,
							  FIN1 => TP_FIN1, FIN2 => TP_FIN2, CLK => MSTRCLK, RST_L => RST_L,
								CLK_EN => TP_CLKEN, SPICLK_CK => BARO_SERCLK, CSL_CK => SPI_CSN, FIN_CK  => TP_FIN);
--
--ENTITY lps25h_spi_demux IS

--	PORT(
--		fin, rst_l						: IN	STD_LOGIC;
--		add								: IN	STD_LOGIC_VECTOR(8 downto 0);
--		spi_data							: IN	STD_LOGIC_VECTOR(7 downto 0);
--		RPRSH_data,	PRSH_data											: out	STD_LOGIC_VECTOR(7 downto 0);
--		RPRSL_data, PRSL_data, TMPH_data 							: out	STD_LOGIC_VECTOR(7 downto 0);
--		RPRSXL_data, PRSXL_data, TMPL_data							: out	STD_LOGIC_VECTOR(7 downto 0));

--END lps25h_spi_demux;
	
	SPI_DEMUX: ENTITY WORK.lps25h_spi_demux
					PORT MAP( FIN  => TP_FIN , RST_L => RST_L , ADD => TP_ADD, SPI_DATA => TP_SPIDATA, 
					RPRSH_data=> RFPRESSH, RPRSL_data=> RFPRESSL, RPRSXL_data => RFPRESSXL, PRSH_data=> PRESSH, PRSL_data=> PRESSL, PRSXL_data => PRESSXL,
					TMPH_data=> TEMPH,TMPL_data => TEMPL);

END ctrl;




