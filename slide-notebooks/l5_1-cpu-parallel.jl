#src # This is needed to make this run as normal Julia file
using Markdown #src

#nb # %% A slide [markdown] {"slideshow": {"slide_type": "slide"}}
#nb # _Lecture 5_
md"""
# Parallel computing (on CPUs) and performance assessment
"""

#src ######################################################################### 
#nb # %% A slide [markdown] {"slideshow": {"slide_type": "slide"}}
md"""
### The goal of this lecture 5 is to introduce:
- Performance limiters
- Effective memory throughput metric $T_\mathrm{eff}$
"""

#nb # %% A slide [markdown] {"slideshow": {"slide_type": "fragment"}}
md"""
- Parallel computing on CPUs
- Shared memory parallelisation
"""

#src #########################################################################
#nb # %% A slide [markdown] {"slideshow": {"slide_type": "slide"}}
md"""
## Performance limiters

### Hardware
- GPUs are throughput-oriented systems
- GPUs use their parallelism to hide latency
- Some multi-core CPUs have many cores nowadays - similar challenges ?
"""

#nb # %% A slide [markdown] {"slideshow": {"slide_type": "fragment"}}
md"""
*Recall from [lecture 1](lecture1/#why_we_do_it) ...*
"""

#src #########################################################################
#nb # %% A slide [markdown] {"slideshow": {"slide_type": "slide"}}
md"""
Use **parallel computing** (to address this):
- The "memory wall" in ~ 2004
- Single-core to multi-core devices

![mem_wall](./figures/mem_wall.png)

"""

#src #########################################################################
#nb # %% A slide [markdown] {"slideshow": {"slide_type": "slide"}}
md"""
GPUs are massively parallel devices
- SIMD machine (programmed using threads - SPMD) ([more](https://safari.ethz.ch/architecture/fall2020/lib/exe/fetch.php?media=onur-comparch-fall2020-lecture24-simdandgpu-afterlecture.pdf))
- Further increases the Flop vs Bytes gap

![cpu_gpu_evo](./figures/cpu_gpu_evo.png)

"""

#src #########################################################################
#nb # %% A slide [markdown] {"slideshow": {"slide_type": "slide"}}
md"""
Taking a look at a recent GPU and CPU:
- Nvidia Tesla A100 GPU
- AMD EPYC "Rome" 7282 (16 cores) CPU

| Device         | TFLOP/s (FP64) | Memory BW TB/s |
| :------------: | :------------: | :------------: |
| Tesla A100     | 9.7            | 1.55           |
| AMD EPYC 7282  | 0.7            | 0.085          |

"""

#nb # %% A slide [markdown] {"slideshow": {"slide_type": "fragment"}}
md"""
Current GPUs (and CPUs) can do many more computations in a given amount of time than they can access numbers from main memory.
"""

#src #########################################################################
#nb # %% A slide [markdown] {"slideshow": {"slide_type": "slide"}}
md"""
Quantify the imbalance:

$$ \frac{\mathrm{computation\;peak\;performance\;[TFLOP/s]}}{\mathrm{memory\;access\;peak\;performance\;[GB/s]}} × \mathrm{size\;of\;a\;number\;[Bytes]} $$

"""

#nb # %% A slide [markdown] {"slideshow": {"slide_type": "fragment"}}
md"""
_(Theoretical peak performance values as specified by the vendors can be used)._
"""

#src #########################################################################
#nb # %% A slide [markdown] {"slideshow": {"slide_type": "slide"}}
md"""
Back to our hardware:

| Device         | TFLOP/s (FP64) | Memory BW TB/s | Imbalance (FP64)     |
| :------------: | :------------: | :------------: | :------------------: |
| Tesla A100     | 9.7            | 1.55           | 9.7 / 1.55  × 8 = 50 |
| AMD EPYC 7282  | 0.7            | 0.085          | 0.7 / 0.085 × 8 = 66 |


_(here computed with double precision values)_
"""

#nb # %% A slide [markdown] {"slideshow": {"slide_type": "fragment"}}
md"""
**Meaning:** we can do 50 (GPU) and 66 (CPU) floating point operations per number accessed from main memory. Floating point operations are "for free" when we work in memory-bounded regimes

➡ Requires to re-think the numerical implementation and solution strategies
"""

#src #########################################################################
#nb # %% A slide [markdown] {"slideshow": {"slide_type": "slide"}}
md"""
### On the scientific application side

- Most algorithms require only a few operations or flops ...
- ... compared to the amount of numbers or bytes accessed from main memory.
"""

#nb # %% A slide [markdown] {"slideshow": {"slide_type": "fragment"}}
md"""
First derivative example $∂A / ∂x$:
"""

#src #########################################################################
#nb # %% A slide [markdown] {"slideshow": {"slide_type": "slide"}}
md"""
If we "naively" compare the "cost" of an isolated evaluation of a finite-difference first derivative, e.g., computing a flux $q$:

$$q = -D~\frac{∂A}{∂x}~,$$

which in the discrete form reads `q[ix] = -D*(A[ix+1]-A[ix])/dx`.
"""

#src #########################################################################
#nb # %% A slide [markdown] {"slideshow": {"slide_type": "slide"}}
md"""
The cost of evaluating `q[ix] = -D*(A[ix+1]-A[ix])/dx`:

1 reads + 1 write => $2 × 8$ = **16 Bytes transferred**

1 (fused) addition and division => **1 floating point operations**
"""

#nb # %% A slide [markdown] {"slideshow": {"slide_type": "fragment"}}
md"""
assuming:
- $D$, $∂x$ are scalars
- $q$ and $A$ are arrays of `Float64` (read from main memory)
"""

#src #########################################################################
#nb # %% A slide [markdown] {"slideshow": {"slide_type": "slide"}}
md"""
GPUs and CPUs perform 50 - 60 FLOP pro number accessed from main memory

First derivative evaluation requires to transfer 2 numbers per FLOP
"""

#nb # %% A slide [markdown] {"slideshow": {"slide_type": "fragment"}}
md"""
The FLOP/s metric is no longer the most adequate for reporting the application performance of many modern applications on modern hardware.
"""

#src #########################################################################
#nb # %% A slide [markdown] {"slideshow": {"slide_type": "slide"}}
md"""
## Effective memory throughput metric $T_\mathrm{eff}$

Need for a memory throughput-based performance evaluation metric: $T_\mathrm{eff}$ [GB/s]

➡ Evaluate the performance of iterative stencil-based solvers.
"""

#src #########################################################################
#nb # %% A slide [markdown] {"slideshow": {"slide_type": "slide"}}
md"""
The effective memory access $A_\mathrm{eff}$ [GB]

Sum of:
- twice the memory footprint of the unknown fields, $D_\mathrm{u}$, (fields that depend on their own history and that need to be updated every iteration)
- known fields, $D_\mathrm{k}$, that do not change every iteration. 
"""

#nb # %% A slide [markdown] {"slideshow": {"slide_type": "fragment"}}
md"""
The effective memory access divided by the execution time per iteration, $t_\mathrm{it}$ [sec], defines the effective memory throughput, $T_\mathrm{eff}$ [GB/s]:

$$ A_\mathrm{eff} = 2~D_\mathrm{u} + D_\mathrm{k} $$

$$ T_\mathrm{eff} = \frac{A_\mathrm{eff}}{t_\mathrm{it}} $$
"""

#src #########################################################################
#nb # %% A slide [markdown] {"slideshow": {"slide_type": "slide"}}
md"""
The upper bound of $T_\mathrm{eff}$ is $T_\mathrm{peak}$ as measured, e.g., by [McCalpin, 1995](https://www.researchgate.net/publication/51992086_Memory_bandwidth_and_machine_balance_in_high_performance_computers) for CPUs or a GPU analogue. 

Defining the $T_\mathrm{eff}$ metric, we assume that:
1. we evaluate an iterative stencil-based solver,
2. the problem size is much larger than the cache sizes and
3. the usage of time blocking is not feasible or advantageous (reasonable for real-world applications).
"""

#nb # > 💡 note: Fields within the effective memory access that do not depend on their own history; such fields can be re-computed on the fly or stored on-chip.
#md # \note{Fields within the effective memory access that do not depend on their own history; such fields can be re-computed on the fly or stored on-chip.}

#src #########################################################################
#nb # %% A slide [markdown] {"slideshow": {"slide_type": "slide"}}
md"""
As first task, we'll compute the $T_\mathrm{eff}$ for the 2D diffusion code [`diffusion_2D.jl`](https://github.com/eth-vaw-glaciology/course-101-0250-00/blob/main/scripts/) we are already familiar with (download the script if needed to get started).
"""

#nb # %% A slide [markdown] {"slideshow": {"slide_type": "fragment"}}
md"""
**To-do list:**
- copy `diffusion_2D.jl` and rename it to `diffusion_2D_Teff.jl` 
- add a timer
- include the performance metric formulas
- deactivate visualisation

💻 Let's get started
"""

#src #########################################################################
#nb # %% A slide [markdown] {"slideshow": {"slide_type": "slide"}}
md"""
### Timer and performance
- Use `Base.time()` to return the current timestamp
- Define `t_tic`, the starting time, after 11 time steps to allow for "warmup"
- Record the exact number of iterations (introduce e.g. `niter`)
- Compute the elapsed time `t_toc` at the end of the time loop and report:

```julia
#sol t_toc = Base.time() - t_tic
#sol A_eff = (1*2)/1e9*nx*ny*sizeof(Float64)  # Effective main memory access per iteration [GB]
#sol t_it  = t_toc/niter                      # Execution time per iteration [s]
#sol T_eff = A_eff/t_it                       # Effective memory throughput [GB/s]
#hint t_toc = ...
#hint A_eff = ...          # Effective main memory access per iteration [GB]
#hint t_it  = ...          # Execution time per iteration [s]
#hint T_eff = A_eff/t_it   # Effective memory throughput [GB/s]
```
"""

#src #########################################################################
#nb # %% A slide [markdown] {"slideshow": {"slide_type": "slide"}}
md"""
- Report `t_toc`, `T_Eff` and `niter` at the end of the code, formatting output using `@printf()` macro.
- Round `T_eff` to the 3rd significant digit.

```julia
#sol @printf("Time = %1.3f sec, T_eff = %1.2f GB/s (niter = %d)\n", t_toc, round(T_eff, sigdigits=3), niter)
#hint @printf("Time = %1.3f sec, ... \n", t_toc, ...)
```
"""

#src #########################################################################
#nb # %% A slide [markdown] {"slideshow": {"slide_type": "slide"}}
md"""
### Deactivate visualisation
- Use keyword arguments ("kwargs") to allow for default behaviour
- Define a `do_visu` flag set to `false`

```julia
#sol @views function diffusion_2D(; do_visu=false)
#hint @views function diffusion_2D(; ??)

#hint    ...

#sol    if do_visu && (it % nout == 0)
#sol        ...
#sol    end
    return
end

#sol diffusion_2D(; do_visu=false)
#hint diffusion_2D(; ??)
```
"""

#src #########################################################################
#nb # %% A slide [markdown] {"slideshow": {"slide_type": "slide"}}
md"""
So far so good, we have now a timer.

Let's also boost resolution to `nx = ny = 512` and set `ttot = 0.1` to have the code running ~1 sec.

In the next part, we'll work on a multi-threading implementation.
"""

#src #########################################################################
#nb # %% A slide [markdown] {"slideshow": {"slide_type": "slide"}}
md"""
## Parallel computing on CPUs

_Towards implementing shared memory parallelisation using multi-threading capabilities of modern multi-core CPUs._
"""

#nb # %% A slide [markdown] {"slideshow": {"slide_type": "fragment"}}
md"""
We'll work it out in 4 steps:
1. Precomputing scalars, removing divisions and casual arrays
2. Replacing flux arrays by macros
3. Back to loops I
4. Back to loops II - compute functions (kernels)
"""

#src #########################################################################
#nb # %% A slide [markdown] {"slideshow": {"slide_type": "slide"}}
md"""
### 1. Precomputing scalars, removing divisions and casual arrays

As first, duplicate `diffusion_2D_Teff.jl` and rename it as `diffusion_2D_perf.jl`
"""

#nb # %% A slide [markdown] {"slideshow": {"slide_type": "fragment"}}
md"""
- First, replace `D/dx` and `D/dy` in the flux calculations by precomputed `D_dx = D/dx` and `D_dy = D/dy` in the fluxes.
- Then, replace divisions `/dx, /dy` by inverse multiplications `*_dx, *_dy` where `_dx, _dy = 1.0/dx, 1.0/dy`.
- Remove the `dCdt` array as we do not actually need it in the algorithm.
"""

#src #########################################################################
#nb # %% A slide [markdown] {"slideshow": {"slide_type": "slide"}}
md"""
### 2. Replacing flux arrays by macros

As first, duplicate `diffusion_2D_perf.jl` and rename it as `diffusion_2D_perf2.jl`
"""

#nb # %% A slide [markdown] {"slideshow": {"slide_type": "fragment"}}
md"""
Storing flux calculations in `qx` and `qy` arrays is not needed and produces additional read/write we want to avoid.

Let's create macros and call them in the time loop:

```julia
#sol macro qx()  esc(:( .-D_dx.*diff(C[:,2:end-1],dims=1) )) end
#sol macro qy()  esc(:( .-D_dy.*diff(C[2:end-1,:],dims=2) )) end
#hint macro qx()  esc(:( ... )) end
#hint macro qy()  esc(:( ... )) end
```
"""

#src #########################################################################
#nb # %% A slide [markdown] {"slideshow": {"slide_type": "slide"}}
md"""
Macro will be expanded at preprocessing stage (copy-paste)

Advantages of using macros vs functions:
- easier syntax (no need to specify indices)
- there can be a performance advantage (if functions are not inlined)
"""

#nb # %% A slide [markdown] {"slideshow": {"slide_type": "fragment"}}
md"""
Also, we now have to ensure `C` is not read and written back in the same (will become important when enabling multi-threading).

Define `C2`, a copy of `C`, modify the physics computation line, and implement a pointer swap

```julia
#sol C2      = copy(C)
#sol # [...]
#sol C2[2:end-1,2:end-1] .= C[2:end-1,2:end-1] .- dt.*(diff(@qx(),dims=1).*_dx .+ diff(@qy(),dims=2).*_dy)
#sol C, C2 = C2, C # pointer swap
#hint C2      = ...
#hint # [...]
#hint C2[2:end-1,2:end-1] .= C[2:end-1,2:end-1] .- dt.*( ... )
#hint C, C2 = ... # pointer swap
```
"""

#src #########################################################################
#nb # %% A slide [markdown] {"slideshow": {"slide_type": "slide"}}
md"""
### 3. Back to loops I

As first, duplicate `diffusion_2D_perf2.jl` and rename it as `diffusion_2D_perf_loop.jl`
"""

#nb # %% A slide [markdown] {"slideshow": {"slide_type": "fragment"}}
md"""
The goal is now to write out the diffusion physics in a loop fashion over $x$ and $y$ dimensions.

Implement a nested loop, taking car of bounds and staggering.

```julia
#sol for iy=1:size(C,2)-2
#sol     for ix=1:size(C,1)-2
#sol         C2[ix+1,iy+1] = C[ix+1,iy+1] - dt*( (@qx(ix+1,iy) - @qx(ix,iy))*_dx + (@qy(ix,iy+1) - @qy(ix,iy))*_dy )
#sol     end
#sol end
#hint for iy=1:??
#hint     for ix=1:??
#hint         C2[??] = C[??] - dt*( (@qx(ix+1,iy) - @qx(ix,iy))*_dx + (@qy(ix,iy+1) - @qy(ix,iy))*_dy )
#hint     end
#hint end
```
"""

#src #########################################################################
#nb # %% A slide [markdown] {"slideshow": {"slide_type": "slide"}}
md"""
Note that macros can take arguments, here `ix,iy`, and need updated definition.

Macro argument can be used in definition appending `$`.

```julia
#sol macro qx(ix,iy)  esc(:( -D_dx*(C[$ix+1,$iy+1] - C[$ix,$iy+1]) )) end
#sol macro qy(ix,iy)  esc(:( -D_dy*(C[$ix+1,$iy+1] - C[$ix+1,$iy]) )) end
#hint macro qx(ix,iy)  esc(:( ... C[$ix+1,$iy+1] ... )) end
#hint macro qy(ix,iy)  ...
```
"""

#src #########################################################################
#nb # %% A slide [markdown] {"slideshow": {"slide_type": "slide"}}
md"""
Performance is already quite better with the loop version. Reasons are that `diff()` are allocating tmp and that Julia is overall well optimised for executing loops.

Let's now implement the final step.
"""

#src #########################################################################
#nb # %% A slide [markdown] {"slideshow": {"slide_type": "slide"}}
md"""
### 4. Back to loops II

Duplicate `diffusion_2D_perf2_loop.jl` and rename it as `diffusion_2D_perf_loop_fun.jl`
"""

#nb # %% A slide [markdown] {"slideshow": {"slide_type": "fragment"}}
md"""
In this last step, the goal is to define a `compute` function to hold the physics calculations, and to call it within the time loop.
"""

#src #########################################################################
#nb # %% A slide [markdown] {"slideshow": {"slide_type": "slide"}}
md"""
Create a `compute!()` function that takes input and output arrays and needed scalars as argument and returns nothing. 

```julia
#sol function compute!(C2, C, D_dx, D_dy, dt, _dx, _dy)
#sol     for iy=1:size(C,2)-2
#sol         for ix=1:size(C,1)-2
#sol             C2[ix+1,iy+1] = C[ix+1,iy+1] - dt*( (@qx(ix+1,iy) - @qx(ix,iy))*_dx + (@qy(ix,iy+1) - @qy(ix,iy))*_dy )
#sol         end
#sol     end
#sol     return
#sol end
#hint function compute!(...)
#hint     ...
#hint     return
#hint end
```
"""

#nb # > 💡 note: Function that modify arguments take a `!` in their name, a Julia convention.
#md # \note{Function that modify arguments take a `!` in their name, a Julia convention.}

#src #########################################################################
#nb # %% A slide [markdown] {"slideshow": {"slide_type": "slide"}}
md"""
The `compute!()` function can then be called within the time loop

```julia
#sol compute!(C2, C, D_dx, D_dy, dt, _dx, _dy)
#hint compute!(...)
```
"""

#src #########################################################################
#nb # %% A slide [markdown] {"slideshow": {"slide_type": "slide"}}
md"""
This last implementation executes a bit faster as previous one, as functions allow Julia to further optimise during just-ahead-of-time compilation.

"""

#nb # %% A slide [markdown] {"slideshow": {"slide_type": "fragment"}}
md"""
Let's now see how to implement multi-threading and use [advanced vector extensions (AVX)](https://en.wikipedia.org/wiki/Advanced_Vector_Extensions).
"""

#src #########################################################################
#nb # %% A slide [markdown] {"slideshow": {"slide_type": "slide"}}
md"""
## Shared memory parallelisation

### Multi-threading (native)

Julia ships with it's `base` feature the possibility to enable [multi-threading](https://docs.julialang.org/en/v1/manual/multi-threading/).
"""

#nb # %% A slide [markdown] {"slideshow": {"slide_type": "fragment"}}
md"""
The only 2 modifications needed to enable it in our code are:

1. Place `Threads.@threads` in front of the outer loop definition
2. Export the desired amount of threads, e.g., `export JULIA_NUM_THREADS=4`, to be activate prior to launching Julia (or executing the script from the shell)
"""

#nb # > 💡 note: For optimal performance, the numbers of threads should be identical to the  number of physical cores of the target CPU.
#md # \note{For optimal performance, the numbers of threads should be identical to the  number of physical cores of the target CPU.}

#src #########################################################################
#nb # %% A slide [markdown] {"slideshow": {"slide_type": "slide"}}
md"""
### Multi-threading and AVX

Relying on Julia's [LoopVectorization.jl](https://github.com/JuliaSIMD/LoopVectorization.jl) package, it is possible to combine multi-threading with AVX optimisations, relying on extensions to the x86 instruction set architecture.
"""

#nb # %% A slide [markdown] {"slideshow": {"slide_type": "fragment"}}
md"""
To enable it in our code:

1. Add `using LoopVectorization` at the top of the script
2. Replace `Threads.@threads` by `@tturbo` in front of the outer loop in the `compute!()` kernel

And here we go 🚀
"""

#src #########################################################################
#nb # %% A slide [markdown] {"slideshow": {"slide_type": "slide"}}
#nb # > 💡 note: For optimal performance assessment, bound-checking should be deactivated. This can be achieved by adding `@inbounds` in front of the compute statement, or running the scripts (or launching Julia) with the `--check-bounds=no` option.
#md # \note{For optimal performance assessment, bound-checking should be deactivated. This can be achieved by adding `@inbounds` in front of the compute statement, or running the scripts (or launching Julia) with the `--check-bounds=no` option.}

#src #########################################################################
#nb # %% A slide [markdown] {"slideshow": {"slide_type": "slide"}}
md"""
### Wrapping-up

- We discussed main performance limiters
- We implemented the effective memory throughput metric $T_\mathrm{eff}$
- We optimised the Julia 2D diffusion code (multi-threading and AVX)
"""

#md # \note{Various timing and benchmarking tools are available in Julia's ecosystem to [track performance issues](https://docs.julialang.org/en/v1/manual/performance-tips/). Julia's base exposes the `@time` macro which returns timing and allocation estimation. [BenchmarkTools.jl](https://github.com/JuliaCI/BenchmarkTools.jl) package provides finer grained timing and benchmarking tooling, namely the `@btime` and `@benchmark` macros, among others.}
