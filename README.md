# Tang Nano 8bit CPU with BSRAM & 8x8 LED Matrix

## About

* Changes https://github.com/sokoide/tangnano_4bit_cpu_led
  * 8 bit registers
  * 16 bit address space
  * using BSRAM

## How to run

### Prereq

* brew install verilator
* clone and build gtkwave at https://github.com/gtkwave/gtkwave

### Build and Download

```bash
make clean
make download
```

### Test Bench

```bash
make clean
make run
make wave
```
