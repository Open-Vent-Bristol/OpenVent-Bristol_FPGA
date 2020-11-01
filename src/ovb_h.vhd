library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;


package ovb_h is

    constant FREQUENCY                          : real := 50.0e6;
    constant CLOCK_PERIOD                       : real := 1.0/FREQUENCY;

    constant DISPLAY_MIN_PERIOD                 : real := 1.2e-6;
    constant DISPLAY_MIN_PERIOD_CYCLES          : integer := integer((2.0*1.2e-6)/CLOCK_PERIOD);
    constant DISPLAY_WAIT_STARTUP_CYCLES        : integer := integer(40.0e-3/DISPLAY_MIN_PERIOD;
    constant DISPLAY_CLEAR_DISPLAY_CYCLES       : integer := integer(1.52e-3/DISPLAY_MIN_PERIOD;
    constant DISPLAY_RETURN_HOME_CYCLES         : integer := integer(1.52e-3/DISPLAY_MIN_PERIOD;
    constant DISPLAY_ENTRY_MODE_SET_CYCLES      : integer := integer(37.0e-6/DISPLAY_MIN_PERIOD;
    constant DISPLAY_DISPLAY_ON_CONTROL_CYCLES  : integer := integer(37.0e-6/DISPLAY_MIN_PERIOD;
    constant DISPLAY_FUNCTION_SET_CYCLES        : integer := integer(37.0e-6/DISPLAY_MIN_PERIOD;

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
    --                                       00000000001111111111222222222233
    --                                       01234567890123456789012345678901
    constant PCV_STANDBY        : string := "MODE: PCV       Standby         ";

    function char_to_lcd_hex(char: character) return std_logic_vector(7 downto 0);
    function lcd_hex_to_char(slv: std_logic_vector(7 downto 0)) return character;

    record display_out_t is
        -- Operation enable signal, falling edge triggered
        e   : std_logic_vector(1 downto 0);
        -- Read not write (0 := write, 1:= read)
        rnw : std_logic;
        -- Register select (0 := command, 1:= data)
        rs  : std_logic;
        -- Bidirectional data bus
        db  : std_logic_vector(7 downto 0);
        -- Tristate control
        t   : std_logic_vector(7 downto 0);
    end record;

    record sdpram_18x1k_in_t is
        addra   : std_logic_vector(9 downto 0);
        wea     : std_logic;
        dina    : std_logic_vector(17 downto 0);
        addrb   : std_logic_vector(9 downto 0);
    end record;

    constant DISPLAY_CLEAR_DISPLAY      : std_logic_vector(15 downto 0) := x"0001";
    constant DISPLAY_RETURN_HOME        : std_logic_vector(15 downto 0) := x"0002";
    constant DISPLAY_ENTRY_MODE_SET     : std_logic_vector(15 downto 0) := x"0006";
    constant DISPLAY_DISPLAY_ON_CONTROL : std_logic_vector(15 downto 0) := x"000C";
    constant DISPLAY_FUNCTION_SET       : std_logic_vector(15 downto 0) := x"0038";
    --constant DISPLAY_READ_BUSY_FLAG   : std_logic_vector(15 downto 0) := x"";



end package;


package body of ovb_h is

    function char_to_lcd_hex(char: character) return std_logic_vector(7 downto 0) is
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