--para sensor ultrasónico

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
entity sonicos is
 Port (i_clk: in STD_LOGIC;
	o_sensor_disp: out STD_LOGIC;
	i_sensor_eco: in STD_LOGIC;
	--anodos: out STD_LOGIC_VECTOR (3 downto 0);
	o_display1,o_display2: out STD_LOGIC_VECTOR (6 downto 0));
 end sonicos;
 
 
 
architecture Behavioral of sonicos is
 signal cuenta: unsigned(16 downto 0) := (others => '0');
 signal centimetros: unsigned(15 downto 0) := (others => '0');
 signal centimetros_unid: unsigned(3 downto 0) := (others => '0');
 signal centimetros_dece: unsigned(3 downto 0) := (others => '0');
 signal sal_unid: unsigned(3 downto 0) := (others => '0');
 signal sal_dece: unsigned(3 downto 0) := (others => '0');
 signal digito: unsigned(3 downto 0) := (others => '0');
 signal eco_pasado: std_logic := '0';
 signal eco_sinc: std_logic := '0';
 signal eco_nsinc: std_logic := '0';
 signal espera: std_logic:= '0';
 signal siete_seg_cuenta: unsigned(15 downto 0) := (others => '0');
begin
	--anodos(1 downto 0)<= "11";
	siete_seg: process(i_clk)
	begin
	if rising_edge(i_clk) then
		if siete_seg_cuenta(siete_seg_cuenta'high) = '1' then 
			digito <= sal_unid;
			--anodos(3 downto 2) <= "01";
	else
		digito <= sal_dece;
		--anodos(3 downto 2) <= "10";
	end if;
		siete_seg_cuenta <= siete_seg_cuenta +1;
 end if;
 end process;

 
 Trigger:process(i_clk)
 begin
	if rising_edge(i_clk) then
		if espera = '0' then
			if cuenta = 500 then 
				o_sensor_disp <= '0';
				espera <= '1'; 
				cuenta <= (others => '0');
			else
				o_sensor_disp <= '1'; 
				cuenta <= cuenta+1;
	end if;
	
elsif eco_pasado = '0' and eco_sinc = '1' then 
	cuenta <= (others => '0');
	centimetros <= (others => '0');
	centimetros_unid <= (others => '0');
	centimetros_dece <= (others => '0');
elsif eco_pasado = '1' and eco_sinc = '0' then 
	sal_unid <= centimetros_unid;
	sal_dece <= centimetros_dece;
elsif cuenta = 2900-1 then
	if centimetros_unid = 9 then 
		centimetros_unid <= (others => '0');
		centimetros_dece <= centimetros_dece + 1;
	else
		centimetros_unid <= centimetros_unid + 1;
	end if;
		centimetros <= centimetros + 1;
		cuenta<= (others => '0');
 if centimetros = 3448 then
	espera <= '0';
end if;
	else
		cuenta <= cuenta + 1;
 end if;
	eco_pasado<= eco_sinc;
	eco_sinc <= eco_nsinc;
	eco_nsinc <= i_sensor_eco;
 end if;
 end process;

 with sal_unid select
		o_display1 <= "1000000" when "0000", --0
				"1111001" when "0001", --1
				"0100100" when "0010", --2
				"0110000" when "0011", --3
				"0011001" when "0100", --4
				"0010010" when "0101", --5
				"0000010" when "0110", --6
				"1111000" when "0111", --7
				"0000000" when "1000", --8
				"0010000" when "1001", --9
				"1000000" when others;
	with sal_dece select
			o_display2 <= "1000000" when "0000", --0
					"1111001" when "0001", --1
					"0100100" when "0010", --2
					"0110000" when "0011", --3
					"0011001" when "0100", --4
					"0010010" when "0101", --5
					"0000010" when "0110", --6
					"1111000" when "0111", --7
					"0000000" when "1000", --8
					"0010000" when "1001", --9			
					"1000000" when others;

 

end Behavioral;