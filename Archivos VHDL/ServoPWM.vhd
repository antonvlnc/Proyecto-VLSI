--Los cálculos están hechos para el reloj de 100MHz, ajustarlos al de 50MHz
LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;

ENTITY ServoPWM is
	PORT (
		i_clock : IN STD_LOGIC; --recibe el reloj normal de la fpga
		o_pwm : OUT STD_LOGIC; -- va al servo por el pin planner
		o_position : OUT INTEGER RANGE 45 TO 135 -- Esta salida va al vga  //Va desde pi/4 hasta 3pi/4 (45 grados a 135)
	); --Facilmente modificable de 0 a 180

END ENTITY ServoPWM;

ARCHITECTURE RTL OF ServoPWM IS

	CONSTANT c_incremento : INTEGER := 1666666; --3333333 //1666666 o 1666667  //1500000// 2000000		--Contamos hasta aqui para actualizar el servo cada 33 mS // cambiar esto a 20ms [por las especificaciones]??
	CONSTANT c_aumentopw : INTEGER := 20000; --	  1111//740.66 		--Aumentamos el pw 1111 para contar; //subir para que el barrido sea más lento
	CONSTANT c_pwm_freq : INTEGER := 1000000; --2000000  /  1000000  	--2 millones de ciclos de reloj para el periodo de 50 hz// 1M de ciclos para de10 lite?
	CONSTANT c_3pi_over4 : INTEGER := 200000; --200000       		--Anchura de pulso de 2 mS lo pone a la posicion 3 pi cuartos (135 grados)// 90 grados = 2ms
	SIGNAL pw_counter : INTEGER RANGE 0 TO c_3pi_over4 - 1 := 0; --Contador Anchura de pulso (de 0 a 199,999)
	SIGNAL freq_counter : INTEGER RANGE 0 TO c_pwm_freq - 1 := 0; --contador frecuencia (de 0 a 1 999 999)
	SIGNAL incrementos : INTEGER RANGE 0 TO 180 := 0; -- 180 incrementos (ida y vuelta?)
	SIGNAL increment_counter : INTEGER RANGE 0 TO c_incremento - 1 := 0; --contador del incremento (de 0 a 3,333,332)
	SIGNAL r_posicion : INTEGER RANGE 45 TO 135; --los grados de apertura, para manejar las posiciones

	TYPE t_rom IS ARRAY (0 TO 89) OF INTEGER RANGE 100000 TO 200000; -- de 1ms a 2ms (duty cycle del sg90)

	--Rom con los valores que hay que tomar cuando se va incrementando el pulse width (ancho de pulso), en 1 mS lo ponemos en pi/4 (45 grados)
	CONSTANT rom_cont : t_rom := (
		100000, 101111, 102222, 103333, 104444, 105555, 106666, 107777, 108888,
		109999, 111110, 112221, 113332, 114443, 115554, 116665, 117776, 118887,
		119998, 121109, 122220, 123331, 124442, 125553, 126664, 127775, 128886,
		129997, 131108, 132219, 133330, 134441, 135552, 136663, 137774, 138885,
		139996, 141107, 142218, 143329, 144440, 145551, 146662, 147773, 148884,
		149995, 151106, 152217, 153328, 154439, 155550, 156661, 157772, 158883,
		159994, 161105, 162216, 163327, 164438, 165549, 166660, 167771, 168882,
		169993, 171104, 172215, 173326, 174437, 175548, 176659, 177770, 178881,
		179992, 181103, 182214, 183325, 184436, 185547, 186658, 187769, 188880,
		189991, 191102, 192213, 193324, 194435, 195546, 196657, 197768, 198879
	);
	--Va de 1ms a 2ms, son los 90 valores que usaremos para controlar el ángulo del servo
BEGIN
	main : PROCESS (i_clock) IS --recibe el clk normal
		VARIABLE address : INTEGER RANGE 0 TO 89 := 0; -- los 90 grados de apertura
	BEGIN

		IF (rising_edge(i_clock)) THEN

			--Hacemos 1 grados a la derecha en 90 incrementos 
			IF (incrementos < 90) THEN --mientras no se haya abierto los 90 grados:

				IF (increment_counter < c_incremento - 1) THEN --por qué se le resta solo 1??
					increment_counter <= increment_counter + 1; --se incrementa el contador que debe llegar a 90

					IF (freq_counter < c_pwm_freq - 1) THEN --ahora checa si el contador de la frecuencia (el que va de 0 a 2M -1) es menor a los 2M (siempre se cumplirá? por la resta de 1)
						freq_counter <= freq_counter + 1; -- se incrementa este contador

						IF (pw_counter < rom_cont(address)) THEN-- checar si el contador de 0 a 200K-1 es menor a el valor de la rom (inicia en el address 0)
							pw_counter <= pw_counter + 1; -- incrementa el contador del pulse width (ancho de pulso)
							o_pwm <= '1'; --asigna la salida pwm a 1 (que avance?)
						ELSE
							o_pwm <= '0'; --si no, la salida a pwm es 0 (que no funcione si no hay rising_edge?)
						END IF;

					ELSE
						freq_counter <= 0; --reiniciar el contador de la frecuencia
						pw_counter <= 0; --reiniciar el contador del pulse width (ancho de pulso)
					END IF;
				ELSE
					increment_counter <= 0; --reinicia el contador del incremento
					incrementos <= incrementos + 1; --Aumentamos de grado en grado
					r_posicion <= r_posicion + 1; -- la posicion se incrementa también
					address := address + 1; -- la dirección de la rom se actualiza para el siguiente ángulo dado el duty cycle (1 a 2ms)
					pw_counter <= pw_counter + c_aumentopw; --Aumentamos para que no vuelva a contar(y poner o_pwm = '1' durante ese incremento solo de tiempo), aumento_pw=1111
				END IF;
-- _________________________________________________________________ VUELTA __________________________________________________________________________________________

				--Hacemos 180 grados a la izquierda en 90 incrementos (regreso)
			ELSIF (incrementos >= 90 AND incrementos < 180) THEN --incrementos = no. de pasos? 90 de ida y 90 de vuelta

				IF (increment_counter < c_incremento - 1) THEN --si el contador de incrementos sigue siendo menor al c_incremento
					increment_counter <= increment_counter + 1; --aumentar el contador del incremento

					IF (freq_counter < c_pwm_freq - 1) THEN --siempre se cumplirá
						freq_counter <= freq_counter + 1; --aumentar el contador de la frecuencia

						IF (pw_counter < rom_cont(address)) THEN --Anchura pwm
							pw_counter <= pw_counter + 1;
							o_pwm <= '1';
						ELSE
							o_pwm <= '0';
						END IF;

					ELSE
						freq_counter <= 0;
						pw_counter <= 0;
					END IF;
				ELSE
					increment_counter <= 0;
					incrementos <= incrementos + 1; --Aumentamos de dos en dos grados(ahora hacia el otro lado por disminuir el ancho de pulso)
					r_posicion <= r_posicion - 1;
					address := address - 1; --se va disminuyendo el address de la rom porque vamos regresando
				END IF;

			ELSE --Ya estamos otra vez en el punto inicial pues reseteamos
				incrementos <= 0; --Ponemos los incrementos a 0
				r_posicion <= 45; --
				address := 0; --la posición 0 de la rom
			END IF;

		END IF;

	END PROCESS main;

	o_position <= r_posicion; --se asigna la posicion a lo que se mandará al vga

END ARCHITECTURE RTL;



--copiar a comp(original), en comp(original) usar las señales intermedias del vga para ver si solucionan los problemas de sincronización, si no, hacer por tanteo y cálculo de la velocidad