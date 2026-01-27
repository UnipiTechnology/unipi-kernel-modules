# Unipi kernel modules v2

Unipi PLCs require those modules in order to access I/O.
You need the Linux kernel source to compile these modules.
Tested for kernel versions 6.12


- Cross-compiling modules:

`CROSS_COMPILE=aarch64-linux-gnu- ARCH=arm64 make LINUX_DIR_PATH=<path to linux src tree>`

- Using these kernel modules requires proper device tree.
You can find them in their appropriate OSC data repository:
  - [Unipi Neuron](https://github.com/UniPiTechnology/os-configurator-data-neuron)
  - [Unipi Patron](https://github.com/UniPiTechnology/os-configurator-data-patron)
  - [Unipi Iris](https://github.com/UniPiTechnology/os-configurator-data-iris)
  - [Unipi Edge](https://github.com/UniPiTechnology/os-configurator-data-edge)
