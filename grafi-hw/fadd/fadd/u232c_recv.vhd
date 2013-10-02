library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

entity U232C_RECV is
	generic (
		WTIME : std_logic_vector(15 downto 0) := x"1B17");
	port (
		CLK : in std_logic;
		OK : in std_logic;
		RX : in std_logic;
		DATA : out std_logic_vector (7 downto 0);
		RECVED : out std_logic);
end U232C_RECV;

architecture blackbox of U232C_RECV is
	signal countdown : std_logic_vector(15 downto 0);
	signal recvbuf : std_logic_vector(8 downto 0) := (others => '0');
	signal state : integer range 0 to 11 := 11;
	signal sig_recved : std_logic := '0';
begin
	RECVED <= sig_recved;
	recvbuf(8) <= RX;

	statemachine : process(CLK)
	begin
		if rising_edge(CLK) then
			case state is
				when 11 =>
					if recvbuf(8) = '1' then
						-- read start bit at half of wtime
						countdown <= "0"&WTIME(15 downto 1);
						state <= 10;
					end if;
				when 10 =>
					if recvbuf(8) = '0' then
						if countdown = 0 then
							countdown <= WTIME;
							state <= state-1;
						else
							countdown <= countdown-1;
						end if;
					else
						countdown <= "0"&WTIME(15 downto 1);
					end if;
				when 1 =>
					if countdown = 0 then
						if recvbuf(8) = '1' then
							sig_recved <= '1';
							state <= 0;
						else
							state <= 11;
						end if;
					else
						countdown <= countdown-1;
					end if;
				when 0 =>
					if OK = '1' then
						DATA <= recvbuf(7 downto 0);
						sig_recved <= '0';
						state <= 11;
					end if;
				when others =>
					if countdown = 0 then
						recvbuf(7 downto 0) <= recvbuf(8 downto 1);
						countdown <= WTIME;
						state <= state-1;
					else
						countdown <= countdown-1;
					end if;
			end case;
		end if;
	end process;
end blackbox;
