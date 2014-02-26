library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

entity U232C_SEND is
	generic (
		WTIME : std_logic_vector(15 downto 0) := x"1ADB");
	port (
		CLK : in std_logic;
		GO : in std_logic;
		DATA : in std_logic_vector (7 downto 0);
		TX : out std_logic;
		SENT : out std_logic);
end U232C_SEND;

architecture blackbox of U232C_SEND is
	signal countdown : std_logic_vector(15 downto 0) := WTIME;
	signal sendbuf : std_logic_vector(8 downto 0) := (others => '1');
	signal state : integer range 0 to 10 := 10;
	signal sig_sent : std_logic := '1';
begin
	SENT <= sig_sent;
	TX <= sendbuf(0);

	statemachine : process(CLK)
	begin
		if rising_edge(CLK) then
			case state is
				when 10 =>
					if GO = '1' then
						sendbuf <= DATA&"0";
						sig_sent <= '0';
						countdown <= WTIME;
						state <= state-1;
					end if;
				when 0 =>
					if countdown = 0 then
						sig_sent <= '1';
						state <= 10;
					else
						countdown <= countdown-1;
					end if;
				when others =>
					if countdown = 0 then
						sendbuf <= "1"&sendbuf(8 downto 1);
						countdown <= WTIME;
						state <= state-1;
					else
						countdown <= countdown-1;
					end if;
			end case;
		end if;
	end process;
end blackbox;
