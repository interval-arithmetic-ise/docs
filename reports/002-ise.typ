#import "@preview/rivet:0.1.0": schema, config
#set text(font: "Arial", size: 11pt, lang: "en")
#set par(justify: true)
#show link: text.with(fill: blue)
#set table(inset: 3.5pt) 
#let qt = rect.with(
  inset: 10pt,
  width: 100%,
  stroke: (thickness: 1pt, dash: "dashed")
)

#align(center, text(17pt)[
  *Design Document:\ Interval Arithmetic Instruction Set Extension Family*
])

= Introduction 

This document presents the designs and specifications for a family of interval
arithmetic instruction set extensions based on RISC-V. This family contains 4
tightly coupled extensions--namely, `Zfintf`, `Zhintf`, `Zfintx`, `Zhintx`. These
extensions introduce *the same interval arithmetic operations*, and they only
differ by which register file they use (general purpose or floating point
registers) and by which floating-point precision they use (single-precision or
half-precision).

= Design Overview

The design of each extension adheres to the standard RISC-V specification. The
key design principles are as follows:

1. The extensions are named in *`Z{f,h}int{f,x}`* format. The first letter that
   comes after `Z` determines the precision of that specific extension; `f`
   means single-precision, and `h` means half-precision. The last letter in this
   format determines the register file being used, `f` means floating-point
   registers and `x` means general-purpose registers. For example, `Z-h-int-x`
   is pronounced as "half precision interval arithmetic in general purpose
   registers".

2. The instructions that leverage floating-point registers (`Z*intf`) are
   *incompatible* with the ones that operate on general-purpose registers
   (`Z*intx`), meaning that they can't coexist at the same time.

3. Each member of the family introduces *the same* set of arithmetic,
   statistical, and temporal logic operations, using the exact same encoding
   format, enabling hardware implementations to utilize the familiar format.

4. The extensions do not introduce any new registers, which significantly
   reduces the implementation costs. 
   

= Data Format

1. An interval $#sym.Iota$ is composed of a lower bound $#sym.Alpha$ and an
   upper bound $#sym.Beta$ where $#sym.Alpha <= #sym.Beta$.

2. The lower and upper bounds are IEEE-754 standard floating-point numbers, and
   the precision depends on the extension being used (single-precision or
   half-precision).

3. An interval is represented as two bounds concatenated together (@register)
   inside a register. The extension defines which registers is used to store
   intervals (floating-point or general-purpose registers).

#figure(
  schema.render(
    config: config.config(
      default-font-family: "Arial",
      italic-font-family: "Arial",
    ),
    schema.load(
```yaml
structures:
  main:
    bits: 32
    ranges:
      31-16:
        name: "Upper bound"
      15-0:
        name: "Lower bound"
```
    )
  ),
  caption: "Example of a half-precision interval stored in a 32-bit register."
) <register>

= Instruction Format

The instructions follow a similar format to the standard floating-point
extension "F" as depicted in @format. The instructions are encoded in a 32-bit
*fixed length* format in the 25-bit custom encoding space (bits between `31:7`).

#figure(
  schema.render(
    config: config.config(
      default-font-family: "Arial",
      italic-font-family: "Arial",
    ),
    schema.load(
```yaml
structures:
  main:
    bits: 32
    ranges:
      31-27:
        name: "funct5"
        description: Minor opcode
      26-25:
        name: "fmt"
        description: Floating-point format
      24-15:
        description: "Source registers"
        name: ""
      24-20:
        name: "rs2"
      19-15:
        name: "rs1"
      14-12:
        name: "rm"
        description: "Rounding mode"
      11-7:
        name: "rd"
        description: "Destination register"
      6-0:
        description: "Major opcode"
        name: ""
      6:
        name: 0
      5:
        name: 0
      4:
        name: 0
      3:
        name: 1
      2:
        name: 0
      1:
        name: 1
      0:
        name: 1
```
    ),
  ),
  caption: "The instruction format."
) <format>

1. *Major Opcode:* Defines the custom encoding space dedicated to the interval
   arithmetic extension. This field is constant, and encoded as `0001011`.

2. *Destination Register:* Specifies the register where the result of the
   interval arithmetic operation will be stored. Can be one of the
   floating-point registers (`f0-f31`) or general purpose `x0-x31` depending on
   the instruction (not the extension).

3. *Rounding Mode*: This segment indicates the rounding mode to be applied in
   computations, similar to standard floating-point arithmetic defined in the
   standard "F" extension (@rounding-mode).

#figure(
  table(
    columns: (auto, auto, auto),
    stroke: 0.5pt,
    table.header(
      [*rm*], [*Mnemonic*], [*Meaning*],
    ),
    `000`,"RNE","Round to Nearest",
    `001`,"RTZ","Round towards Zero",
    `010`,"RDN","Round Down",
    `011`,"RUP","Round Up",
    `100`,"RMM","Round to Nearest",
    `111`,"DYN","Dynamic Rounding",
  ),
  caption: "Rounding modes used in the standard floating-point extension (F).",
) <rounding-mode>

4. *Source Registers:* Represents the two source registers containing the
   operands for the interval arithmetic operation. These registers are either
   floating-point registers `f0-f31` or general-purpose registers depending on
   the extension (not the instruction).

5. *Floating-point Format:* Defines which floating-point precision is
   going to be used. The list of values for this field can be found in @fmt.

#figure(
  table(
    columns: (auto, auto, auto),
    stroke: 0.5pt,
    table.header(
      [*fmt field*], [*Mnemonic*], [*Meaning*],
    ),
    `00`,"H","half-precision",
    `01`,"S","single-precision",
    `1X`,"-","Reserved",
  ),
  caption: "Format field encoding",
) <fmt>

6. *Minor Opcode:* Differentiates specific interval arithmetic operations within
   the extension. Since multiple instructions share the same major opcode, this
   minor opcode helps identify the operation intended. 

= Arithmetic Instructions

The instructions implementing arithmetic operations;

- Read two input *intervals* from the source registers.
- Write an *interval* output to the destination register.

The list of arithmetic instructions is shown in @arithmetic-instructions.

#figure(
  table(
    columns: (1fr, 1fr, 1fr, 1fr, 1fr, 1fr, 2fr, 1.5fr),
    stroke: 0.5pt,
    table.header(
      [*funct5*], [*fmt*], [*rs2*], [*rs1*], [*rm*], [*rd*], [*Major Opcode*],
      [*Mnemonic*]
    ),
    `00000`, `fmt`, `rs2`, `rs1`, `rm`, `rd`, `0001011`, `INTADD`,
    `00001`, `fmt`, `rs2`, `rs1`, `rm`, `rd`, `0001011`, `INTSUB`,
    `00010`, `fmt`, `rs2`, `rs1`, `rm`, `rd`, `0001011`, `INTMUL`,
    `00011`, `fmt`, `rs2`, `rs1`, `rm`, `rd`, `0001011`, `INTDIV`
  ),
  caption: "The encoding of arithmetic instructions",
) <arithmetic-instructions>

=== INTADD
#table(
  columns: (auto, 1fr),
  stroke: 0.5pt,
 [*Half-precision Format:*], `intadd.h rd, rs1, rs2`,
 [*Single-precision Format:*], `intadd.s rd, rs1, rs2`,
 [*F-Register Implementation:*], `f[rd] = IEEE1788.1IntervalAdd(f[rs1], f[rs2])`,
 [*X-Register Implementation:*], `x[rd] = IEEE1788.1IntervalAddition(x[rs1], x[rs2])`,
 [*Description:*], [Performs interval addition according to the IEEE 1788.1-2017 standard.]
)

=== INTSUB
#table(
  columns: (auto, 1fr),
  stroke: 0.5pt,
 [*Half-precision Format:*], `intsub.h rd, rs1, rs2`,
 [*Single-precision Format:*], `intsub.s rd, rs1, rs2`,
 [*F-Register Implementation:*], `f[rd] = IEEE1788.1IntervalSubtract(f[rs1], f[rs2])`,
 [*X-Register Implementation:*], `x[rd] = IEEE1788.1IntervalSubtract(x[rs1], x[rs2])`,
 [*Description:*], [Performs interval subtraction following the IEEE 1788.1-2017 standard.]
)

=== INTMUL
#table(
  columns: (auto, 1fr),
  stroke: 0.5pt,
  [*Half-precision Format:*], `intmul.h rd, rs1, rs2`,
  [*Single-precision Format:*], `intmul.s rd, rs1, rs2`,
  [*F-Register Implementation:*], `f[rd] = IEEE1788.1IntervalMultiply(f[rs1], f[rs2])`,
  [*X-Register Implementation:*], `x[rd] = IEEE1788.1IntervalMultiply(x[rs1], x[rs2])`,
  [*Description:*], [Performs interval multiplication as specified by the IEEE 1788.1-2017 standard.]
)

=== INTDIV
#table(
  columns: (auto, 1fr),
  stroke: 0.5pt,
 [*Half-precision Format:*], `intdiv.h rd, rs1, rs2`,
 [*Single-precision Format:*], `intdiv.s rd, rs1, rs2`,
 [*F-Register Implementation:*], `f[rd] = IEEE1788.1IntervalDivision(f[rs1], f[rs2])`,
 [*X-Register Implementation:*], `x[rd] = IEEE1788.1IntervalDivision(x[rs1], x[rs2])`,
 [*Description:*], [Performs interval division in compliance with the IEEE 1788.1-2017 standard. Division by an interval containing zero raises an exception.]
)

= Statistical Instructions

The instructions implementing statistical functions;

- Read one *interval* from the source register.
- Write a *floating-point* output to the destination register.

The list of statistical instructions is shown in @statistical-instructions.

#figure(
  table(
    columns: (1fr, 1fr, 1fr, 1fr, 1fr, 1fr, 2fr, 1.5fr),
    stroke: 0.5pt,
    table.header(
      [*funct5*], [*fmt*], [*rs2*], [*rs1*], [*rm*], [*rd*], [*Major Opcode*],
      [*Mnemonic*]
    ),
    `01000`, `fmt`, `00000`, `rs1`, `rm`, `rd`, `0001011`, `INTMID`,
    `01001`, `fmt`, `00000`, `rs1`, `rm`, `rd`, `0001011`, `INTWDT`,
    `01010`, `fmt`, `00000`, `rs1`, `rm`, `rd`, `0001011`, `INTRAD`,
    `01011`, `fmt`, `00000`, `rs1`, `rm`, `rd`, `0001011`, `INTMIN`,
    `01100`, `fmt`, `00000`, `rs1`, `rm`, `rd`, `0001011`, `INTMAX`
  ),
  caption: "The encoding of statistical instructions",
) <statistical-instructions>

=== INTMID
#table(
  columns: (auto, 1fr),
  stroke: 0.5pt,
 [*Half-precision Format:*], `intmid.h rd, rs1`,
 [*Single-precision Format:*], `intmid.s rd, rs1`,
 [*F-Register Implementation:*], `f[rd] = (upperBound(f[rs1]) + lowerBound(f[rs1])) / 2`,
 [*X-Register Implementation:*], `x[rd] = (upperBound(x[rs1]) + lowerBound(x[rs1])) / 2`,
 [*Description:*], [Computes the midpoint of an interval.]
)

=== INTWDT
#box[
  #table(
    columns: (auto, 1fr),
    stroke: 0.5pt,
    [*Half-precision Format:*], `intwdt.h rd, rs1`,
    [*Single-precision Format:*], `intwdt.s rd, rs1`,
    [*F-Register Implementation:*], `f[rd] = upperBound(f[rs1]) - lowerBound(f[rs1])`,
    [*X-Register Implementation:*], `x[rd] = upperBound(x[rs1]) - lowerBound(x[rs1])`,
    [*Description:*], [Computes the width of an interval.]
  )
]

=== INTRAD
#table(
  columns: (auto, 1fr),
  stroke: 0.5pt,
 [*Half-precision Format:*], `intrad.h rd, rs1`,
 [*Single-precision Format:*], `intrad.s rd, rs1`,
 [*F-Register Implementation:*], `f[rd] = (upperBound(f[rs1]) - lowerBound(f[rs1])) / 2`,
 [*X-Register Implementation:*], `x[rd] = (upperBound(x[rs1]) - lowerBound(x[rs1])) / 2`,
 [*Description:*], [Computes the radius (half-width) of an interval.]
)

=== INTMIN
#table(
  columns: (auto, 1fr),
  stroke: 0.5pt,
 [*Half-precision Format:*], `intmin.h rd, rs1`,
 [*Single-precision Format:*], `intmin.s rd, rs1`,
 [*F-Register Implementation:*], `f[rd] = lowerBound(f[rs1])`,
 [*X-Register Implementation:*], `x[rd] = lowerBound(x[rs1])`,
 [*Description:*], [Extracts the lower bound of an interval.]
)

#pagebreak()

=== INTMAX
#table(
  columns: (auto, 1fr),
  stroke: 0.5pt,
 [*Half-precision Format:*], `intmax.h rd, rs1`,
 [*Single-precision Format:*], `intmax.s rd, rs1`,
 [*F-Register Implementation:*], `f[rd] = upperBound(f[rs1])`,
 [*X-Register Implementation:*], `x[rd] = upperBound(x[rs1])`,
 [*Description:*], [Extracts the upper bound of an interval.]
)

// #pagebreak()

= Temporal Logic Instructions

The instructions implementing temporal logic;

1. Read two input *intervals* from source registers.
2. Write a *boolean* output to the destination register. The destination
   register is a general-purpose register, `x0-x31`, regardless of the extension.

The list of temporal logic instructions is shown in @temporal-instructions.

#figure(
  table(
    columns: (1fr, 1fr, 1fr, 1fr, 1fr, 1fr, 2fr, 1.5fr),
    stroke: 0.5pt,
    table.header(
      [*funct5*], [*fmt*], [*rs2*], [*rs1*], [*rm*], [*rd*], [*Major Opcode*],
      [*Mnemonic*]
    ),
    `10000`, `fmt`, `rs2`, `rs1`, `000`, `rd`, `0001011`, `INTBFR`,
    `10001`, `fmt`, `rs2`, `rs1`, `000`, `rd`, `0001011`, `INTMTS`,
    `10010`, `fmt`, `rs2`, `rs1`, `000`, `rd`, `0001011`, `INTOVR`,
    `10011`, `fmt`, `rs2`, `rs1`, `000`, `rd`, `0001011`, `INTDUR`,
    `10100`, `fmt`, `rs2`, `rs1`, `000`, `rd`, `0001011`, `INTSTR`,
    `10101`, `fmt`, `rs2`, `rs1`, `000`, `rd`, `0001011`, `INTFIN`,
    `10110`, `fmt`, `rs2`, `rs1`, `000`, `rd`, `0001011`, `INTEQL`
  ),
  caption: "The encoding of temporal logic instructions",
) <temporal-instructions>

=== INTBFR
#table(
  columns: (auto, 1fr),
  stroke: 0.5pt,
 [*Half-precision Format:*], `intbfr.h rd, rs1, rs2`,
 [*Single-precision Format:*], `intbfr.s rd, rs1, rs2`,
 [*F-Register Implementation:*], `x[rd] = allensIntervalBefore(f[rs1], f[rs2])`,
 [*X-Register Implementation:*], `x[rd] = allensIntervalBefore(x[rs1], x[rs2])`,
 [*Description:*], [Determines if one interval occurs strictly before another, based on Allen’s Interval Algebra.]
)

=== INTMTS
#table(
  columns: (auto, 1fr),
  stroke: 0.5pt,
 [*Half-precision Format:*], `intmts.h rd, rs1, rs2`,
 [*Single-precision Format:*], `intmts.s rd, rs1, rs2`,
 [*F-Register Implementation:*], `x[rd] = allensIntervalMeets(f[rs1], f[rs2])`,
 [*X-Register Implementation:*], `x[rd] = allensIntervalMeets(x[rs1], x[rs2])`,
 [*Description:*], [Determines if one interval meets another, with no gap in between.]
)

#pagebreak()

=== INTOVR
#table(
  columns: (auto, 1fr),
  stroke: 0.5pt,
 [*Half-precision Format:*], `intovr.h rd, rs1, rs2`,
 [*Single-precision Format:*], `intovr.s rd, rs1, rs2`,
 [*F-Register Implementation:*], `x[rd] = allensIntervalOverlaps(f[rs1], f[rs2])`,
 [*X-Register Implementation:*], `x[rd] = allensIntervalOverlaps(x[rs1], x[rs2])`,
 [*Description:*], [Determines if two intervals overlap, without one fully containing the other.]
)

=== INTDUR
#table(
  columns: (auto, 1fr),
  stroke: 0.5pt,
 [*Half-precision Format:*], `intdur.h rd, rs1, rs2`,
 [*Single-precision Format:*], `intdur.s rd, rs1, rs2`,
 [*F-Register Implementation:*], `x[rd] = allensIntervalDuring(f[rs1], f[rs2])`,
 [*X-Register Implementation:*], `x[rd] = allensIntervalDuring(x[rs1], x[rs2])`,
 [*Description:*], [Determines if one interval is fully contained within another.]
)

=== INTSTR
#table(
  columns: (auto, 1fr),
  stroke: 0.5pt,
 [*Half-precision Format:*], `intstr.h rd, rs1, rs2`,
 [*Single-precision Format:*], `intstr.s rd, rs1, rs2`,
 [*F-Register Implementation:*], `x[rd] = allensIntervalStarts(f[rs1], f[rs2])`,
 [*X-Register Implementation:*], `x[rd] = allensIntervalStarts(x[rs1], x[rs2])`,
 [*Description:*], [Determines if one interval starts another, meaning they have the same starting point but the first interval ends before the second.]
)

=== INTFIN
#table(
  columns: (auto, 1fr),
  stroke: 0.5pt,
 [*Half-precision Format:*], `intfin.h rd, rs1, rs2`,
 [*Single-precision Format:*], `intfin.s rd, rs1, rs2`,
 [*F-Register Implementation:*], `x[rd] = allensIntervalFinishes(f[rs1], f[rs2])`,
 [*X-Register Implementation:*], `x[rd] = allensIntervalFinishes(x[rs1], x[rs2])`,
 [*Description:*], [Determines if one interval finishes another, meaning they share the same ending point, but the first interval starts later than the second.]
)

=== INTEQL
#table(
  columns: (auto, 1fr),
  stroke: 0.5pt,
 [*Half-precision Format:*], `inteql.h rd, rs1, rs2`,
 [*Single-precision Format:*], `inteql.s rd, rs1, rs2`,
 [*F-Register Implementation:*], `x[rd] = allensIntervalEqual(f[rs1], f[rs2])`,
 [*X-Register Implementation:*], `x[rd] = allensIntervalEqual(x[rs1], x[rs2])`,
 [*Description:*], [Determines if two intervals are exactly equal.]
)

#pagebreak()

= Traps & Exceptions

The interval arithmetic operations introduced in this document raise exception
flags for the conditions listed in @fcsr.

The accrued exception flags indicate the exception conditions that have arisen
on any interval arithmetic instruction since the field was last reset by
software, as shown in @fcsr.

The base RISC-V ISA does not support generating a trap on the setting of an
exception flag. So, the software is responsible for checking them.

#figure(
  table(
    columns: (auto, auto),
    stroke: 0.5pt,
    table.header(
      [*Flag Mnemonic*], [*Flag Meaning*],
    ),
    "NV","Invalid Operation",
    "DZ","Divide by Zero",
    "OF","Overflow",
    "UF","Underflow",
    "NX","Inexact",
  ),
  caption: "Accrued exception flag encoding.",
) <fcsr>

== "Zfinx" and "Zhinx"

These extensions depend on the `Zicsr` extension for control and status
registers. And they directly interact with the `fflags` registers to raise and
clear exceptions. 

== "Zfinf" and "Zhinf"

Since these extensions depend on the standard floating-point extensions, they
can reuse `fcsr`, the floating-point control and status register. `fcsr`, is a
RISC-V control and status register (CSR) introduced by the "F" extension. It is
a 32-bit read/write register that selects the dynamic rounding mode for
floating-point arithmetic operations and holds the accrued exception flags
listed in @fcsr.

#pagebreak()

= Individual Extension Descriptions

== "Zhinf": Half-precision interval arithmetic in floating-point registers
- This extension imports *half-precision format* of all instructions.
- The instructions imported by this extension operate on *floating-point
  registers* `f0-f31`.
- Depends on the single-precision extension F for 32-bit floating-point
  registers.
- Can coexist with `Zfinf`.
- *Cannot* coexist with `Zfinx` or `Zhinx`.
- Can be implemented on either of RV32 and RV64.

== "Zfinf": Single-precision interval arithmetic in floating-point registers
- This extension imports *single-precision format* of all instructions.
- The instructions imported by this extension operate on *floating-point
  registers* `f0-f31`.
- Depends on the double-precision extension D for 64-bit floating-point
  registers.
- Can coexist with `Zhinf`.
- *Cannot* coexist with `Zfinx` or `Zhinx`.
- Can be implemented on either of RV32 and RV64.

== "Zhinx": Half-precision interval arithmetic in general-purpose registers
- This extension imports *half-precision format* of all instructions.
- The instructions imported by this extension operate on *general-purpose
  registers* `x0-x31`.
- Depends on the `Zicsr` extension for control and status registers.
- Can coexist with `Zfinx`.
- *Cannot* coexist with `Zfinf` or `Zhinf`.
- Can be implemented on either of RV32 and RV64.

== "Zfinx": Single-precision interval arithmetic in general-purpose registers
- This extension imports *single-precision format* of all instructions.
- The instructions imported by this extension operate on *general-purpose
  registers* `x0-x31`.
- Depends on the `Zicsr` extension for control and status registers.
- Can coexist with `Zhinx`.
- *Cannot* coexist with `Zfinf` or `Zhinf`.
- On RV32, this extension is implemented with *register pairing*. According to this:
    - Register numbers must be even.
    - Use of misaligned (odd-numbered) registers is reserved.
    - Regardless of endianness, the lower-numbered register holds the lower
      bound, and the higher-numbered register holds the upper bound.
    - When a double-width floating-point result is written to `x0`, the entire
      write takes no effect

#pagebreak()

= Appendix

== Complete Instruction Table

#table(
  align: center,
  columns: (1fr, 1fr, 1fr, 1fr, 1fr, 1fr, 2fr, 1.5fr),
  stroke: 0.5pt,

  table.header(
    [*funct5*], [*fmt*], [*rs2*], [*rs1*], [*rm*], [*rd*], [*Major Opcode*],
    [*Mnemonic*]
  ),

  table.cell(colspan: 8, `Half-precision variants`),

  `00000`, `00`, `rs2`, `rs1`, `rm`, `rd`, `0001011`, `INTADD.H`,
  `00001`, `00`, `rs2`, `rs1`, `rm`, `rd`, `0001011`, `INTSUB.H`,
  `00010`, `00`, `rs2`, `rs1`, `rm`, `rd`, `0001011`, `INTMUL.H`,
  `00011`, `00`, `rs2`, `rs1`, `rm`, `rd`, `0001011`, `INTDIV.H`,

  `01000`, `00`, `00000`, `rs1`, `rm`, `rd`, `0001011`, `INTMID.H`,
  `01001`, `00`, `00000`, `rs1`, `rm`, `rd`, `0001011`, `INTWDT.H`,
  `01010`, `00`, `00000`, `rs1`, `rm`, `rd`, `0001011`, `INTRAD.H`,
  `01011`, `00`, `00000`, `rs1`, `rm`, `rd`, `0001011`, `INTMIN.H`,
  `01100`, `00`, `00000`, `rs1`, `rm`, `rd`, `0001011`, `INTMAX.H`,

  `10000`, `00`, `rs2`, `rs1`, `000`, `rd`, `0001011`, `INTBFR.H`,
  `10001`, `00`, `rs2`, `rs1`, `000`, `rd`, `0001011`, `INTMTS.H`,
  `10010`, `00`, `rs2`, `rs1`, `000`, `rd`, `0001011`, `INTOVR.H`,
  `10011`, `00`, `rs2`, `rs1`, `000`, `rd`, `0001011`, `INTDUR.H`,
  `10100`, `00`, `rs2`, `rs1`, `000`, `rd`, `0001011`, `INTSTR.H`,
  `10101`, `00`, `rs2`, `rs1`, `000`, `rd`, `0001011`, `INTFIN.H`,
  `10110`, `00`, `rs2`, `rs1`, `000`, `rd`, `0001011`, `INTEQL.H`,

  table.cell(colspan: 8, `Single-precision variants`),

  `00000`, `01`, `rs2`, `rs1`, `rm`, `rd`, `0001011`, `INTADD.S`,
  `00001`, `01`, `rs2`, `rs1`, `rm`, `rd`, `0001011`, `INTSUB.S`,
  `00010`, `01`, `rs2`, `rs1`, `rm`, `rd`, `0001011`, `INTMUL.S`,
  `00011`, `01`, `rs2`, `rs1`, `rm`, `rd`, `0001011`, `INTDIV.S`,

  `01000`, `01`, `00000`, `rs1`, `rm`, `rd`, `0001011`, `INTMID.S`,
  `01001`, `01`, `00000`, `rs1`, `rm`, `rd`, `0001011`, `INTWDT.S`,
  `01010`, `01`, `00000`, `rs1`, `rm`, `rd`, `0001011`, `INTRAD.S`,
  `01011`, `01`, `00000`, `rs1`, `rm`, `rd`, `0001011`, `INTMIN.S`,
  `01100`, `01`, `00000`, `rs1`, `rm`, `rd`, `0001011`, `INTMAX.S`,

  `10000`, `01`, `rs2`, `rs1`, `000`, `rd`, `0001011`, `INTBFR.S`,
  `10001`, `01`, `rs2`, `rs1`, `000`, `rd`, `0001011`, `INTMTS.S`,
  `10010`, `01`, `rs2`, `rs1`, `000`, `rd`, `0001011`, `INTOVR.S`,
  `10011`, `01`, `rs2`, `rs1`, `000`, `rd`, `0001011`, `INTDUR.S`,
  `10100`, `01`, `rs2`, `rs1`, `000`, `rd`, `0001011`, `INTSTR.S`,
  `10101`, `01`, `rs2`, `rs1`, `000`, `rd`, `0001011`, `INTFIN.S`,
  `10110`, `01`, `rs2`, `rs1`, `000`, `rd`, `0001011`, `INTEQL.S`,
)
