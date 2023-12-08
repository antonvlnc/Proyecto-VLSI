LIBRARY ieee;
USE ieee.std_logic_1164.all;

ENTITY vga_ctrl IS
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
        o_row       : OUT INTEGER);     --vertical pixel coordinate
END vga_ctrl;

ARCHITECTURE behavior OF vga_ctrl IS
    CONSTANT h_period : INTEGER := h_pulse + h_bp + h_pixels + h_fp;  --total number of pixel clocks in a row
    CONSTANT v_period : INTEGER := v_pulse + v_bp + v_pixels + v_fp;  --total number of rows in column
BEGIN

PROCESS(i_pixel_clk, i_reset_n)
    VARIABLE h_count : INTEGER RANGE 0 TO h_period - 1 := 0;  --horizontal counter (counts the columns)
    VARIABLE v_count : INTEGER RANGE 0 TO v_period - 1 := 0;  --vertical counter (counts the rows)
BEGIN

    IF(i_reset_n = '0') THEN          --reset asserted
        h_count := 0;               --reset horizontal counter
        v_count := 0;               --reset vertical counter
        o_h_sync  <= NOT h_pol;       --deassert horizontal sync
        o_v_sync  <= NOT v_pol;       --deassert vertical sync
        o_disp_ena <= '0';            --disable display, se pone todo en negro
        o_column   <= 0;              --reset column pixel coordinate
        o_row      <= 0;              --reset row pixel coordinate

	 ELSIF(i_pixel_clk'EVENT AND i_pixel_clk = '1') THEN
		--counters
		IF(h_count < h_period - 1) THEN    --horizontal counter (pixels)
			h_count := h_count + 1;	
		ELSE
			h_count := 0;
			IF(v_count < v_period - 1) THEN   --vertical counter (rows)
			  v_count := v_count + 1;
			ELSE
			  v_count := 0;
			END IF;
		END IF;

		--horizontal sync signal
		IF(h_count < h_pixels + h_fp OR h_count >= h_pixels + h_fp + h_pulse) THEN
			 o_h_sync <= NOT h_pol;  --deassert horizontal sync pulse
		ELSE
			 o_h_sync <= h_pol;  --assert horizontal sync pulse
		END IF;

		--vertical sync signal
		IF(v_count < v_pixels + v_fp OR v_count >= v_pixels + v_fp + v_pulse) THEN
			 o_v_sync <= NOT v_pol;  --deassert vertical sync pulse
		ELSE
			 o_v_sync <= v_pol;  --assert vertical sync pulse
		END IF;

		--set pixel coordinates
		IF(h_count < h_pixels) THEN   --horizontal display time
			 o_column <= h_count;   --set horizontal pixel coordinate
		END IF;
		IF(v_count < v_pixels) THEN   --vertical display time
			 o_row <= v_count;     --set vertical pixel coordinate
		END IF;

		--set display enable output
		IF(h_count < h_pixels AND v_count < v_pixels) THEN   --display time
			 o_disp_ena <= '1';   --enable display
		ELSE
			 o_disp_ena <= '0';   --blanking time   --disable display
		END IF;

		END IF;
		END PROCESS;

		END behavior;

				
			
			
			
