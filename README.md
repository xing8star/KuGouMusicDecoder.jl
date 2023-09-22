## Overview
解密酷狗加密的音乐(kgm)
## Installation

```julia-repl
(@v1.9) pkg> add https://gitee.com/abaraba/ku-gou-music-decoder.jl
```

## Example
```julia
using KuGouMusicDecoder
decode("yourkugoumusic.kgm")
```

## Script
Firstly need to instantiate the 'script' project
```bash
julia --project=script dump.jl --keep "yourmusic.kgm" directory
```