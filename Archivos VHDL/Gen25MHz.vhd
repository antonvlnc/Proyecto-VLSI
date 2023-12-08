LIBRARY ieee;
USE ieee.std_logic_1164.all;

Entity Gen25MHz is
port(i_clk50MHz: in std_logic;
     io_clk25MHz: inout std_logic:='0');
end entity Gen25MHz;

architecture behavior of Gen25MHz is
begin
  process(i_clk50MHz)
  begin
    if i_clk50MHz'event and i_clk50MHz='1' then
      io_clk25MHz <= not io_clk25MHz;
    end if;
  end process;
end architecture behavior;
