#import "@preview/fletcher:0.5.4" as fletcher: diagram, node, edge
#import "@preview/showybox:2.0.3": showybox
#import fletcher.shapes: house, hexagon

#set text(font: "Arial", size: 11pt, lang: "en")
#set par(justify: true)
#show link: text.with(fill: blue)

#let blob(pos, label, tint: white, ..args) = node(
	pos, align(center, label),
	width: 28mm,
	fill: tint.lighten(60%),
	stroke: 1pt + tint.darken(20%),
	corner-radius: 5pt,
	..args,
)

#let todo = rect.with(width: 100%, inset: 15pt, strong(align(center, "TODO")))

#align(center, text(17pt)[
  *Problem Statement:\ Extending RISC-V to Accelerate Interval Arithmetic*
])

= Motivation

Interval arithmetic plays a fundamental role in scientific computing,
uncertainty quantification, and numerical methods, however, these arithmetic
operations are computationally expensive, often requiring dozens of instructions
for a single operation on general-purpose processors. This inefficiency becomes
a bottleneck in performance-critical applications, making hardware acceleration
essential. Our study aims to address this issue by designing and implementing a
proof-of-concept RISC-V extension with hardware & software support that
accelerates interval arithmetic operations.

== Why RISC-V?

RISC-V offers an ecosystem with extensive tooling support, including compilers,
debuggers, and back-ends, which facilitates efficient development and testing.
Additionally, its modular design makes it well-suited for integrating custom
instructions tailored to interval arithmetic computations. Finally, as a
royalty-free and open-source architecture, RISC-V provides extensive
documentation and community support, ensuring accessibility and ease of
implementation.

= Methodology

Our study is going to be conducted in three main phases: design, implementation,
and validation. We will begin by designing the custom RISC-V instructions,
followed by implementing support across both hardware and software. Finally, we
will validate our work using hardware and software test suites. An overview of
these steps is illustrated in @roadmap.

#figure(
  diagram(
    spacing: 2pt,
    cell-size: (4mm, 5mm),
    edge-stroke: 1pt,
    edge-corner-radius: 5pt,
    mark-scale: 70%,

    blob((2,0), [Design the\ instruction set], tint: purple),
    edge("r,d", "-|>"),
    edge("l,dd", "-|>"),

    blob((3,1), [Extend *LLVM*], tint: yellow),
    edge("-|>"),
    blob((3,2), [Extend *rustc*], tint: yellow),
    edge("-|>"),
    blob((3,3), [Implement\ the library], tint: yellow),
    edge("d,l", "-|>"),

    blob((1,2), [Extend the\ RTL design], tint: blue),
    edge("dd,r", "-|>"),

    blob((2,4), [Validate], tint: green, extrude: (-2.5, 0)),
  ),
  caption: [A high-level roadmap for this study.]
) <roadmap>


== Instruction set design

The first step in conducting this study is to define the RISC-V instruction set
design. This involves:

- Determining the specific interval arithmetic operations to be implemented.
- Selecting which registers will be utilized.
- Finalizing the bit-level representation of the instructions.

These details are currently *undefined*, and they are going to be determined in
the very first steps of the study.

== Implementation

For the hardware implementation, we will extend an existing RISC-V design, such
as #link("https://github.com/stnolting/neorv32")[neorv32], by introducing custom
instructions for interval arithmetic operations. On the software side, we will
first extend the #link("https://llvm.org/")[LLVM] back-end with custom interval
arithmetic intrinsics. Next, we will modify a compiler front-end that generates
LLVM IR, enabling these intrinsics to be used as callable procedures in a
programming language. For this study, we have chosen the Rust programming
language and its compiler, #link("https://github.com/rust-lang/rust")[rustc] as
our front-end. Finally, to demonstrate the end-to-end functionality, we will
develop a Rust library showcasing the complete integration of our hardware and
software enhancements.

== Validation

=== Testing the Code Generation (LLVM & rustc)

To verify compiler support and ensure correct code generation, we will integrate
our own test cases into the existing test harnesses of both
#link("https://llvm.org/")[LLVM] and
#link("https://github.com/rust-lang/rust")[rustc]. By doing so, we can
systematically evaluate the correctness of our modifications and confirm that
the generated code correctly utilizes our custom interval arithmetic
instructions.

=== Testing the Generated Binaries (Including the Interval Algebra Library)

To validate the correctness and functionality of the compiled binaries, we first
need to establish an execution environment. This environment can either be a
simulated hardware design or an emulator software. To facilitate
hardware-independent testing, we will extend a simple RISC-V emulator, such as
#link("https://github.com/takahirox/riscv-rust")[takahirox/riscv-rust] or
#link("https://github.com/d0iasm/rvemu")[d0iasm/rvemu]. With this, we can
execute test binaries carrying our custom interval arithmetic instructions,
allowing us to test their behavior and correctness without the need for physical
hardware.

=== Testing the RTL design

To validate the RTL implementation of our custom interval arithmetic
instructions, we are going to simulate the extended RISC-V processor using
software-based simulation tools. This simulation will allow us to evaluate the
behavior of our modifications within a controlled environment before deployment
on physical hardware. We will execute test cases that cover our custom interval
arithmetic operations and compare the simulation results against expected
outputs to ensure correctness.

= Next Steps

Our study will first concentrate on creating the RISC-V instruction set design,
which will form the basis for later stages. We will be prepared to move into the
implementation phase with a precise and well-organized blueprint once the
instruction set is well defined.
