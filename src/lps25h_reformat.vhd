--module REFORMATS THE data from the STM barometer sensor, lps25h INTO CONTIGIOUS REGISTER

library IEEE;
use IEEE.std_logic_1164.all;

ENTITY lps25h_reformat IS

	PORT(

		PRSH_data										: in	STD_LOGIC_VECTOR(7 downto 0);--RPRSH_data,
		PRSL_data, TMPH_data 							: in	STD_LOGIC_VECTOR(7 downto 0);--RPRSL_data,
		PRSXL_data, TMPL_data							: in	STD_LOGIC_VECTOR(7 downto 0);--RPRSXL_data,
		Press 													: out 	STD_LOGIC_VECTOR(23 downto 0);
		--RPress 													: out 	STD_LOGIC_VECTOR(23 downto 0);
		Temp 													: out 	STD_LOGIC_VECTOR(15 downto 0);
		AbsPress 													: out 	STD_LOGIC_VECTOR(17 downto 0));
		--AbsRPress 													: out 	STD_LOGIC_VECTOR(17 downto 0));

END lps25h_reformat;

ARCHITECTURE format OF lps25h_reformat IS
BEGIN
format: process(	PRSH_data, PRSL_data, TMPH_data	, PRSXL_data, TMPL_data	 )--RPRSH_data,RPRSL_data,RPRSXL_data,
begin 
Press <= PRSH_data&PRSL_data&PRSXL_data;
--RPress <= RPRSH_data&RPRSL_data&RPRSXL_data;
TEMP <= TMPH_data&TMPL_data;

AbsPress <= PRSH_data(6)&PRSH_data(5)&PRSH_data(4)&PRSH_data(3)&PRSH_data(2)&PRSH_data(1)&PRSH_data(0)&PRSL_data&PRSXL_data(7)&PRSXL_data(6)&PRSXL_data(5);
--AbsRPress <= RPRSH_data(6)&RPRSH_data(5)&RPRSH_data(4)&RPRSH_data(3)&RPRSH_data(2)&RPRSH_data(1)&RPRSH_data(0)&RPRSL_data&RPRSXL_data(7)&RPRSXL_data(6)&RPRSXL_data(5);

end process format;
end;


