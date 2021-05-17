--module demultiplexes serial data from the STM barometer sensor, lps25h and stores in the
--separate registers depending on the type of data which is based on the decoded addresses listed below.
-- The output data is segregated into high and low bytes depnding on the format

library IEEE;
use IEEE.std_logic_1164.all;

ENTITY lps25h_spi_demux IS

	PORT(
		fin, rst_l						: IN	STD_LOGIC;
		add								: IN	STD_LOGIC_VECTOR(8 downto 0);
		spi_data							: IN	STD_LOGIC_VECTOR(7 downto 0);
		PRSH_data,	PRSL_data	,PRSXL_data									: out	STD_LOGIC_VECTOR(7 downto 0);
		 TMPH_data 							: out	STD_LOGIC_VECTOR(7 downto 0);
		 TMPL_data							: out	STD_LOGIC_VECTOR(7 downto 0));

END lps25h_spi_demux;

ARCHITECTURE demux OF lps25h_spi_demux IS
	signal  PRSHdata, PRSLdata, PRSXLdata,TMPHdata,TMPLdata : std_logic_vector(7 downto 0);--,RPRSHdata
	signal RPRSLdata: std_logic_vector(7 downto 0);
	signal RPRSXLdata : std_logic_vector(7 downto 0);
   --	signal padcldata,tadcldata : std_logic_vector(1 downto 0);
	--SIGNAL __signal_name : STD_LOGIC;
	CONSTANT PRSH : std_logic_vector(8 downto 0) := O"252";
	CONSTANT PRSL : std_logic_vector(8 downto 0) := O"251";
	CONSTANT PRSXL : std_logic_vector(8 downto 0) := O"250";
	CONSTANT TMPH : std_logic_vector(8 downto 0) := O"254";
	CONSTANT TMPL : std_logic_vector(8 downto 0) := O"253";
	--CONSTANT RPRSH : std_logic_vector(8 downto 0) := O"212";
	--CONSTANT RPRSL : std_logic_vector(8 downto 0) := O"211";
	--CONSTANT RPRSXL : std_logic_vector(8 downto 0) := O"210";
BEGIN
unencode: process( fin, rst_l)--,rprshdata,rprsldata,rprsxldata
begin
if (RST_L = '0') THEN
	 PRSHdata <= (others => '0'); PRSLdata <= (others => '0'); PRSXLdata <= (others => '0');TMPHdata <= (others => '0');
	TMPLdata <= (others => '0');--RPRSHdata <= (others => '0');--RPRSLdata <= (others => '0');
	--RPRSXLdata <= (others => '0');
	elsif (fin = '1' and fin'event) then

				case add is
				when PRSH =>  PRSHdata <= spi_data ;
				when PRSL =>  PRSLdata <= spi_data ;
				when PRSXL =>  PRSXLdata <= spi_data;
				when TMPH =>  TMPHdata <= spi_data;
				when TMPL =>  TMPLdata <= spi_data;
			--	when RPRSH =>  RPRSHdata <= spi_data;
			--	when RPRSL =>  RPRSLdata <= spi_data;
			--	when RPRSXL =>  RPRSXLdata <= spi_data;
				when others => PRSHdata <= PRSHdata ;PRSLdata <= PRSLdata;PRSXLdata <= PRSXLdata;TMPHdata <= TMPHdata;TMPLdata <= TMPLdata;
				--RPRSLdata <= RPRSLdata;RPRSXLdata <= RPRSXLdata;

				end case;

		end if;
end process unencode;
				PRSH_data <= PRSHdata ;PRSL_data <= PRSLdata;PRSXL_data <= PRSXLdata;TMPH_data <= TMPHdata;TMPL_data <= TMPLdata;--RPRSH_data <= RPRSHdata;
				--RPRSL_data <= RPRSLdata;RPRSXL_data <= RPRSXLdata;

end demux;
