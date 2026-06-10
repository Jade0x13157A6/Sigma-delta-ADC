#include <neorv32.h>

int main(void) {

  // UART0 initialisieren (115200 Baud)
  neorv32_uart0_setup(115200, 0);

  neorv32_uart0_print("UART ready\r\n");

  while (1) {

    // Warten bis Zeichen empfangen wurde
    if (neorv32_uart0_available()) {

      char c = neorv32_uart0_getc();

      // Echo zurück senden
      neorv32_uart0_putc(c);
    }
  }

  return 0;
}
