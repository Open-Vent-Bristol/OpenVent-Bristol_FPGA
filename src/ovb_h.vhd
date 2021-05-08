library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;


package ovb_h is

    constant FREQUENCY                          : real := 50.0e6;
    constant CLOCK_PERIOD                       : real := 1.0/FREQUENCY;

    constant DISPLAY_MIN_PERIOD                 : real := 1.2e-6;
    constant DISPLAY_MIN_PERIOD_CYCLES          : integer := integer((2.0*1.2e-6)/CLOCK_PERIOD);
    constant DISPLAY_WAIT_STARTUP_CYCLES        : integer := integer(40.0e-3/DISPLAY_MIN_PERIOD);
    constant DISPLAY_CLEAR_DISPLAY_CYCLES       : integer := integer(1.52e-3/DISPLAY_MIN_PERIOD);
    constant DISPLAY_RETURN_HOME_CYCLES         : integer := integer(1.52e-3/DISPLAY_MIN_PERIOD);
    constant DISPLAY_ENTRY_MODE_SET_CYCLES      : integer := integer(37.0e-6/DISPLAY_MIN_PERIOD);
    constant DISPLAY_DISPLAY_ON_CONTROL_CYCLES  : integer := integer(37.0e-6/DISPLAY_MIN_PERIOD);
    constant DISPLAY_FUNCTION_SET_CYCLES        : integer := integer(37.0e-6/DISPLAY_MIN_PERIOD);
    constant DISPLAY_ENABLE_CYCLES              : integer := integer(1.2e-6/CLOCK_PERIOD);

    --                                       00000000001111111111222222222233
    --                                       01234567890123456789012345678901
    constant PCV_STANDBY        : string := "MODE: PCV       Standby         ";
    --                                       00000000001111111111222222222233
    --                                       01234567890123456789012345678901
    constant SPLASH             : string := "OpenVent-Bristol                ";
    --                                       00000000001111111111222222222233
    --                                       01234567890123456789012345678901
    constant QUICK_CAL_STANDBY  : string := "QuickCalibrationStandby         ";
    --                                       00000000001111111111222222222233
    --                                       01234567890123456789012345678901
    constant FULL_CALL_STANDBY  : string := "Full CalibrationStandby         ";

    function char_to_lcd_hex(char: character) return std_logic_vector;
    function lcd_hex_to_char(slv: std_logic_vector(7 downto 0)) return character;

    type display_out_t is record
        -- Operation enable signal, falling edge triggered
        e   : std_logic_vector(1 downto 0);
        -- Read not write (0 := write, 1:= read)
        rnw : std_logic;
        -- Register select (0 := command, 1:= data)
        rs  : std_logic;
        -- Bidirectional data bus
        db  : std_logic_vector(3 downto 0);
        -- Tristate control
        t   : std_logic_vector(3 downto 0);
    end record;

    constant DISPLAY_CLEAR_DISPLAY      : std_logic_vector(15 downto 0) := x"0001";
    constant DISPLAY_RETURN_HOME        : std_logic_vector(15 downto 0) := x"0002";
    constant DISPLAY_ENTRY_MODE_SET     : std_logic_vector(15 downto 0) := x"0006";
    constant DISPLAY_DISPLAY_ON_CONTROL : std_logic_vector(15 downto 0) := x"000C";
    constant DISPLAY_FUNCTION_SET       : std_logic_vector(15 downto 0) := x"0028";
    --constant DISPLAY_READ_BUSY_FLAG   : std_logic_vector(15 downto 0) := x"";

    -- Button Inputs
    constant BUTTON_SELECT              : integer := 0;
    constant BUTTON_MINUS               : integer := 1;
    constant BUTTON_PLUS                : integer := 2;
    constant BUTTON_MUTE_STANDBY        : integer := 3;

    constant BUTTON_CE_CYCLES           : integer := integer(50.0e-3/CLOCK_PERIOD);

    -- UI
    constant OFF_ST     : std_logic_vector(3 downto 0) := x"0";
    constant PCV_ST     : std_logic_vector(3 downto 0) := x"1";
    constant PSV_ST     : std_logic_vector(3 downto 0) := x"2";
    constant QCAL_ST    : std_logic_vector(3 downto 0) := x"3";
    constant FCAL_ST    : std_logic_vector(3 downto 0) := x"4";

    type vent_mode_list_t is array(0 to 2) of std_logic_vector(3 downto 0);
    type vent_mode_array_t is array(0 to 4) of vent_mode_list_t;

    constant VENT_MODE_TABLE: vent_mode_array_t := (
    --   Current    Next        Previous
        (OFF_ST,    PCV_ST,     FCAL_ST),
        (PCV_ST,    PSV_ST,     OFF_ST),
        (PSV_ST,    QCAL_ST,    PCV_ST),
        (QCAL_ST,   FCAL_ST,    PSV_ST),
        (FCAL_ST,   OFF_ST,     QCAL_ST)
    );

    constant SET_PRESS              : std_logic_vector(3 downto 0) := x"0";
    constant SET_RESP               : std_logic_vector(3 downto 0) := x"1";
    constant SET_IE_RATIO           : std_logic_vector(3 downto 0) := x"2";
    constant SET_TIDAL_U            : std_logic_vector(3 downto 0) := x"3";
    constant SET_TIDAL_L            : std_logic_vector(3 downto 0) := x"4";
    constant SET_APNEA_T            : std_logic_vector(3 downto 0) := x"5";
    constant SET_FIO2               : std_logic_vector(3 downto 0) := x"6";
    constant SET_VENT               : std_logic_vector(3 downto 0) := x"7";

    type sel_list_t is array (0 to 2) of std_logic_vector(3 downto 0);

    type pcv_sel_array_t is array(0 to 6) of sel_list_t;
    constant PCV_SEL_TABLE: pcv_sel_array_t := (
    --   Current        Next            Previous
        (SET_PRESS,     SET_RESP,       SET_VENT),
        (SET_RESP,      SET_IE_RATIO,   SET_PRESS),
        (SET_IE_RATIO,  SET_TIDAL_U,    SET_RESP),
        (SET_TIDAL_U,   SET_TIDAL_L,    SET_IE_RATIO),
        (SET_TIDAL_L,   SET_FIO2,       SET_TIDAL_U),
        (SET_FIO2,      SET_VENT,       SET_TIDAL_L),
        (SET_VENT,      SET_PRESS,      SET_FIO2)
    );

    type psv_sel_array_t is array(0 to 5) of sel_list_t;
    constant PSV_SEL_TABLE: psv_sel_array_t := (
    --   Current        Next            Previous
        (SET_PRESS,     SET_TIDAL_U,    SET_VENT),
        (SET_TIDAL_U,   SET_TIDAL_L,    SET_PRESS),
        (SET_TIDAL_L,   SET_APNEA_T,    SET_TIDAL_U),
        (SET_APNEA_T,   SET_FIO2,       SET_TIDAL_L),
        (SET_FIO2,      SET_VENT,       SET_APNEA_T),
        (SET_VENT,      SET_PRESS,      SET_FIO2)
    );

    constant PRESSURE_MIN           : natural := 1;
    constant PRESSURE_MAX           : natural := 35;
    constant PRESSURE_NOM           : natural := 20;
    constant PRESSURE_INC           : natural := 1;

    constant RESPIRATORY_MIN        : natural := 10;
    constant RESPIRATORY_MAX        : natural := 30;
    constant RESPIRATORY_NOM        : natural := 20;
    constant RESPIRATORY_INC        : natural := 2;

    constant IE_RATIO_MIN           : natural := 10;
    constant IE_RATIO_MAX           : natural := 30;
    constant IE_RATIO_NOM           : natural := 20;
    constant IE_RATIO_INC           : natural := 1;

    constant TIDAL_VOL_UPPER_MIN    : natural := 200;
    constant TIDAL_VOL_UPPER_MAX    : natural := 800;
    constant TIDAL_VOL_UPPER_NOM    : natural := 550;
    constant TIDAL_VOL_UPPER_INC    : natural := 50;

    constant TIDAL_VOL_LOWER_MIN    : natural := 200;
    constant TIDAL_VOL_LOWER_MAX    : natural := 800;
    constant TIDAL_VOL_LOWER_NOM    : natural := 300;
    constant TIDAL_VOL_LOWER_INC    : natural := 50;

    constant APNEA_TIME_MIN         : natural := 20;
    constant APNEA_TIME_MAX         : natural := 60;
    constant APNEA_TIME_NOM         : natural := 30;    -- TODO: Made up value - determine real default
    constant APNEA_TIME_INC         : natural := 1;

    constant FIO2_MIN               : natural := 0;
    constant FIO2_MAX               : natural := 100;
    constant FIO2_NOM               : natural := 21;
    constant FIO2_INC               : natural := 1;

end package;


package body ovb_h is

    function char_to_lcd_hex(char: character) return std_logic_vector is
    begin
        case char is
            when ' ' => return x"20";
            when '!' => return x"21";
            when '"' => return x"22";
            when '#' => return x"23";
            when '$' => return x"24";
            when '%' => return x"25";
            when '&' => return x"26";
            when ''' => return x"27";
            when '(' => return x"28";
            when ')' => return x"29";
            when '*' => return x"2A";
            when '+' => return x"2B";
            when ',' => return x"2C";
            when '-' => return x"2D";
            when '.' => return x"2E";
            when '/' => return x"2F";
            when '0' => return x"30";
            when '1' => return x"31";
            when '2' => return x"32";
            when '3' => return x"33";
            when '4' => return x"34";
            when '5' => return x"35";
            when '6' => return x"36";
            when '7' => return x"37";
            when '8' => return x"38";
            when '9' => return x"39";
            when ':' => return x"3A";
            when ';' => return x"3B";
            when '<' => return x"3C";
            when '=' => return x"3D";
            when '>' => return x"3E";
            when '?' => return x"3F";
            when '@' => return x"40";
            when 'A' => return x"41";
            when 'B' => return x"42";
            when 'C' => return x"43";
            when 'D' => return x"44";
            when 'E' => return x"45";
            when 'F' => return x"46";
            when 'G' => return x"47";
            when 'H' => return x"48";
            when 'I' => return x"49";
            when 'J' => return x"4A";
            when 'K' => return x"4B";
            when 'L' => return x"4C";
            when 'M' => return x"4D";
            when 'N' => return x"4E";
            when 'O' => return x"4F";
            when 'P' => return x"50";
            when 'Q' => return x"51";
            when 'R' => return x"52";
            when 'S' => return x"53";
            when 'T' => return x"54";
            when 'U' => return x"55";
            when 'V' => return x"56";
            when 'W' => return x"57";
            when 'X' => return x"58";
            when 'Y' => return x"59";
            when 'Z' => return x"5A";
            when '[' => return x"5B";
            when ']' => return x"5D";
            when '^' => return x"5E";
            when '_' => return x"5F";
            when '`' => return x"60";
            when 'a' => return x"61";
            when 'b' => return x"62";
            when 'c' => return x"63";
            when 'd' => return x"64";
            when 'e' => return x"65";
            when 'f' => return x"66";
            when 'g' => return x"67";
            when 'h' => return x"68";
            when 'i' => return x"69";
            when 'j' => return x"6A";
            when 'k' => return x"6B";
            when 'l' => return x"6C";
            when 'm' => return x"6D";
            when 'n' => return x"6E";
            when 'o' => return x"6F";
            when 'p' => return x"70";
            when 'q' => return x"71";
            when 'r' => return x"72";
            when 's' => return x"73";
            when 't' => return x"74";
            when 'u' => return x"75";
            when 'v' => return x"76";
            when 'w' => return x"77";
            when 'x' => return x"78";
            when 'y' => return x"79";
            when 'z' => return x"7A";
            when others => return x"00";
        end case;
    end function;

    function lcd_hex_to_char(slv: std_logic_vector(7 downto 0)) return character is
    begin
        case slv is
            when x"20" => return ' ';
            when x"21" => return '!';
            when x"22" => return '"';
            when x"23" => return '#';
            when x"24" => return '$';
            when x"25" => return '%';
            when x"26" => return '&';
            when x"27" => return ''';
            when x"28" => return '(';
            when x"29" => return ')';
            when x"2A" => return '*';
            when x"2B" => return '+';
            when x"2C" => return ',';
            when x"2D" => return '-';
            when x"2E" => return '.';
            when x"2F" => return '/';
            when x"30" => return '0';
            when x"31" => return '1';
            when x"32" => return '2';
            when x"33" => return '3';
            when x"34" => return '4';
            when x"35" => return '5';
            when x"36" => return '6';
            when x"37" => return '7';
            when x"38" => return '8';
            when x"39" => return '9';
            when x"3A" => return ':';
            when x"3B" => return ';';
            when x"3C" => return '<';
            when x"3D" => return '=';
            when x"3E" => return '>';
            when x"3F" => return '?';
            when x"40" => return '@';
            when x"41" => return 'A';
            when x"42" => return 'B';
            when x"43" => return 'C';
            when x"44" => return 'D';
            when x"45" => return 'E';
            when x"46" => return 'F';
            when x"47" => return 'G';
            when x"48" => return 'H';
            when x"49" => return 'I';
            when x"4A" => return 'J';
            when x"4B" => return 'K';
            when x"4C" => return 'L';
            when x"4D" => return 'M';
            when x"4E" => return 'N';
            when x"4F" => return 'O';
            when x"50" => return 'P';
            when x"51" => return 'Q';
            when x"52" => return 'R';
            when x"53" => return 'S';
            when x"54" => return 'T';
            when x"55" => return 'U';
            when x"56" => return 'V';
            when x"57" => return 'W';
            when x"58" => return 'X';
            when x"59" => return 'Y';
            when x"5A" => return 'Z';
            when x"5B" => return '[';
            when x"5D" => return ']';
            when x"5E" => return '^';
            when x"5F" => return '_';
            when x"60" => return '`';
            when x"61" => return 'a';
            when x"62" => return 'b';
            when x"63" => return 'c';
            when x"64" => return 'd';
            when x"65" => return 'e';
            when x"66" => return 'f';
            when x"67" => return 'g';
            when x"68" => return 'h';
            when x"69" => return 'i';
            when x"6A" => return 'j';
            when x"6B" => return 'k';
            when x"6C" => return 'l';
            when x"6D" => return 'm';
            when x"6E" => return 'n';
            when x"6F" => return 'o';
            when x"70" => return 'p';
            when x"71" => return 'q';
            when x"72" => return 'r';
            when x"73" => return 's';
            when x"74" => return 't';
            when x"75" => return 'u';
            when x"76" => return 'v';
            when x"77" => return 'w';
            when x"78" => return 'x';
            when x"79" => return 'y';
            when x"7A" => return 'z';
            when others => return '~';
        end case;
    end function;

end package body;
