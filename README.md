# Procesador MIPS segmentado

A continuacion se detallan algunos aspectos de la implementación del procesador MIPS segmentado pedido por la cátedra Arquitectura de Computadoras I, el trabajo fue colaborativo y realizado con Valentin Rubare. La herramienta utilizada para llevar a cabo la implementación fue EDA Playground.

## Decisiones de diseño

* Al adelantar el salto a la etapa decode, la suma del PC y el registro con signo extendido desplazado 2 lugares va directo al multiplexor de la etapa fetch.
* Para saber el valor del selector del multiplexor de la etapa fetch utilizamos un proceso. En este pregunta si hay un branch y los registros son iguales, devolviendo como resultado 1. En el resto de los casos, el valor del selector es 0 (seguiria con el proximo PC).
* Cuando hay un branch efectivo debemos hacer el flush del pipeline de la etapa IF/ID. Lo implementamos con un multiplexor, donde si hay un salto la siguiente instruccion sera 0, sino sigue el curso normal.