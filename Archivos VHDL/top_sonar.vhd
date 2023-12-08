
library ieee;
use ieee.std_logic_1164.all;


entity top_sonar is

    port(
         i_clock 	  : in std_logic;
         i_clear 	  : in std_logic;
         o_hsync 	  : out std_logic;
         o_vsync 	  : out std_logic;
         o_vga_red    : out std_logic_vector(2 downto 0);
         o_vga_blue   : out std_logic_vector(2 downto 0);
         o_vga_green  : out std_logic_vector(2 downto 0);
         o_pwm   	  : out std_logic
         );
         
end top_sonar;

architecture behavioral of top_sonar is
	
	
	component servopwm
		port(
			i_clock    : in  std_logic;
			o_pwm      : out std_logic;
			o_position : out integer range 45 to 135   	  --con esto podemos hablar a el radar de vga pra hacer una linea que se vaya moviendo.
			);                                            
	end component servopwm;
	
	
	
	component reloj
		port(
			i_clk    : in  std_logic;
			o_reloj_salida   : buffer std_logic:='0'
			);                                            
	end component reloj;
	
	
	
	component gen25mhz
		port(
			i_clk50MHz: in std_logic;
			io_clk25MHz: inout std_logic:='0');                                     
	end component gen25mhz;
	
	
	component vga_ctrl
	    GENERIC(
        h_pulse   : INTEGER := 96;  --horizontal sync pulse width in pixels
        h_bp      : INTEGER := 48;  --horizontal back porch width in pixels
        h_pixels  : INTEGER := 640; --horizontal display width in pixels
        h_fp      : INTEGER := 16;  --horizontal front porch width in pixels
        h_pol     : STD_LOGIC := '1'; --horizontal sync pulse polarity (1 = positive, 0 = negative)
        v_pulse   : INTEGER := 2;   --vertical sync pulse width in rows
        v_bp      : INTEGER := 33;  --vertical back porch width in rows
        v_pixels  : INTEGER := 480; --vertical display width in rows
        v_fp      : INTEGER := 10;  --vertical front porch width in rows
        v_pol     : STD_LOGIC := '0'); --vertical sync pulse polarity (1 = positive, 0 = negative)
    PORT(
        i_pixel_clk : IN  STD_LOGIC;   --pixel clock at frequency of VGA mode being used
        i_reset_n   : IN  STD_LOGIC;   --active low asynchronous reset
        o_h_sync    : OUT STD_LOGIC;   --horizontal sync pulse
        o_v_sync    : OUT STD_LOGIC;   --vertical sync pulse
        o_disp_ena  : OUT STD_LOGIC;   --display enable ('1' = display time, '0' = blanking time)
        o_column    : OUT INTEGER;     --horizontal pixel coordinate
        o_row       : OUT INTEGER);     --vertical pixel coordinate    --vertical pixel coordinate
	end component vga_ctrl;
    
    component draw_vga
    	port(
    		i_clk25      : in  std_logic;
    		i_filaactiva : in  integer ;
    		i_colactiva  : in  integer;
    		i_disp_ena   : in  std_logic;
    		i_servo_pos  : in  integer range 45 to 135;
    		o_vga_red    : out std_logic_vector(2 downto 0);
    		o_vga_green  : out std_logic_vector(2 downto 0);
    		o_vga_blue   : out std_logic_vector(2 downto 0)
			
    	);
    end component draw_vga;
	 
	 
--	 component sonicos is
-- Port (i_clk: in STD_LOGIC;
--	o_sensor_disp: out STD_LOGIC;
--	i_sensor_eco: in STD_LOGIC;
--	--anodos: out STD_LOGIC_VECTOR (3 downto 0);
--	o_display1,o_display2: out STD_LOGIC_VECTOR (6 downto 0));
-- end component sonicos;
	 
	 --declaración de señales
     
    signal w_pos_servo : integer range 45 to 135; 
    signal w_colactiva : integer; --range 0  to 640;
    signal w_filactiva : integer; --range 0  to 480;
    signal w_disp_en   : std_logic;
	 signal w_clk50MHz  : std_logic;
	 signal w_clk25Mhz  : std_logic;
	 signal w_clk25_vgactrl : std_logic;
	 signal w_reloj_salida_reloj25: std_logic;
	
										

begin 

--si es salida a pin o_, si es salida a otro módulo w_, si entra 


   --controla el servo   
   servo_ctrl : servopwm port map( i_clock    => i_clock,
   								   o_pwm      => o_pwm, -- salida, o_
   								   o_position => w_pos_servo --salida a otro módulo w_
   								  );
	
----controla el sensor ultrasónico 
--   sensor_ctrl : sonicos port map( i_clk    => i_clock,
--   								   o_sensor_disp      => o_sensor_display,
--   								   i_sensor_eco => i_sens_echo,
--										o_display1 => o_disp1,
--										o_display2 =>o_disp2
--   								  );	
									  

  --Para el reloj de 25MHz   
   reloj25 : reloj port map( i_clk    => i_clock,
   								   o_reloj_salida    => w_reloj_salida_reloj25
   								  );             									  
    
    --controlador vga
    vga_controller : vga_ctrl port map(	i_pixel_clk      => w_clk25MHz, 
						    			i_reset_n      => i_clear,
										--o_clk25      => w_clk25_vgactrl,
						    			o_h_sync      => o_hsync,
						    			o_v_sync      => o_vsync,
						    			o_disp_ena   => w_disp_en,
						    			o_row => w_filactiva,
						    			o_column  => w_colactiva
						    			);
						    
	--dibujador de simbolos
	symbol_gen : draw_vga	port  map( i_clk25      => w_reloj_salida_reloj25,
									   i_filaactiva => w_filactiva,
									   i_colactiva  => w_colactiva,
									   i_disp_ena   => w_disp_en,
									   i_servo_pos  => w_pos_servo,
									   o_vga_red    => o_vga_red,
									   o_vga_green  => o_vga_green,
									   o_vga_blue   => o_vga_blue
									);
									
	--divisor de reloj
	
	clk_25 : gen25mhz	port  map( i_clk50MHz => i_clock,
										io_clk25MHz => w_clk25MHz
									);
	

end behavioral;