library ieee;
use ieee.std_logic_1164.all;


entity reloj is

port (i_clk: in std_logic;
		o_reloj_salida: buffer std_logic:='0'); --led?
end;

architecture a of reloj is
signal conteo: integer range 0 to 25000000;-- 25 millones, lo vi en un video creo (25Mhz?? SI)
begin
	process(i_clk)
	begin
		if (i_clk'event and i_clk='1') then
			conteo<=conteo+1;
			if(conteo=25000000) then	
				conteo<= 0;
				o_reloj_salida<=not o_reloj_salida;
			end if;
		end if;
	end process;
end;