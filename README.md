# Tang Nano 8bit CPU with BSRAM & 8x8 LED Matrix

## About

* Changes <https://github.com/sokoide/tangnano_4bit_cpu_led>
  * 8 bit registers `r0`-`r7`
  * 11 bit address space
  * 11 bit `pc` program counter
  * using BSRAM 2KB between 0x0000 and 0x07FF
  * unlike the 4bit CPU, `r5` is not connected to the buttons, `r6` is not connected to the LED
  * `S1` button works as the reset button

## How to run

### Prereq

* brew install verilator
* clone and build gtkwave at <https://github.com/gtkwave/gtkwave>

### Build and Download

```bash
make clean
make download
```

### Test Bench

* Run tests in DSim Desktop on Linux through vscode remote
* `make wave` on macos to veiw the wave
