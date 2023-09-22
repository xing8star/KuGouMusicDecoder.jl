module KuGouMusicDecoder
export decode,
KuGouMusic
using PrecompileTools
@recompile_invalidations begin
    
    using CodecXz
    using FileIO
end
@setup_workload begin
const MAGIC_HEADER=[
0x7c, 0xd5, 0x32, 0xeb, 0x86, 0x02, 0x7f, 0x4b, 0xa8, 0xaf, 0xa6, 0x8e, 0x0f, 0xff,
0x99, 0x14, 0x00, 0x04, 0x00, 0x00, 0x03, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00]
const PUB_KEY_MEND = [
    0xB8, 0xD5, 0x3D, 0xB2, 0xE9, 0xAF, 0x78, 0x8C, 0x83, 0x33, 0x71, 0x51, 0x76, 0xA0,
    0xCD, 0x37, 0x2F, 0x3E, 0x35, 0x8D, 0xA9, 0xBE, 0x98, 0xB7, 0xE7, 0x8C, 0x22, 0xCE,
    0x5A, 0x61, 0xDF, 0x68, 0x69, 0x89, 0xFE, 0xA5, 0xB6, 0xDE, 0xA9, 0x77, 0xFC, 0xC8,
    0xBD, 0xBD, 0xE5, 0x6D, 0x3E, 0x5A, 0x36, 0xEF, 0x69, 0x4E, 0xBE, 0xE1, 0xE9, 0x66,
    0x1C, 0xF3, 0xD9, 0x02, 0xB6, 0xF2, 0x12, 0x9B, 0x44, 0xD0, 0x6F, 0xB9, 0x35, 0x89,
    0xB6, 0x46, 0x6D, 0x73, 0x82, 0x06, 0x69, 0xC1, 0xED, 0xD7, 0x85, 0xC2, 0x30, 0xDF,
    0xA2, 0x62, 0xBE, 0x79, 0x2D, 0x62, 0x62, 0x3D, 0x0D, 0x7E, 0xBE, 0x48, 0x89, 0x23,
    0x02, 0xA0, 0xE4, 0xD5, 0x75, 0x51, 0x32, 0x02, 0x53, 0xFD, 0x16, 0x3A, 0x21, 0x3B,
    0x16, 0x0F, 0xC3, 0xB2, 0xBB, 0xB3, 0xE2, 0xBA, 0x3A, 0x3D, 0x13, 0xEC, 0xF6, 0x01,
    0x45, 0x84, 0xA5, 0x70, 0x0F, 0x93, 0x49, 0x0C, 0x64, 0xCD, 0x31, 0xD5, 0xCC, 0x4C,
    0x07, 0x01, 0x9E, 0x00, 0x1A, 0x23, 0x90, 0xBF, 0x88, 0x1E, 0x3B, 0xAB, 0xA6, 0x3E,
    0xC4, 0x73, 0x47, 0x10, 0x7E, 0x3B, 0x5E, 0xBC, 0xE3, 0x00, 0x84, 0xFF, 0x09, 0xD4,
    0xE0, 0x89, 0x0F, 0x5B, 0x58, 0x70, 0x4F, 0xFB, 0x65, 0xD8, 0x5C, 0x53, 0x1B, 0xD3,
    0xC8, 0xC6, 0xBF, 0xEF, 0x98, 0xB0, 0x50, 0x4F, 0x0F, 0xEA, 0xE5, 0x83, 0x58, 0x8C,
    0x28, 0x2C, 0x84, 0x67, 0xCD, 0xD0, 0x9E, 0x47, 0xDB, 0x27, 0x50, 0xCA, 0xF4, 0x63,
    0x63, 0xE8, 0x97, 0x7F, 0x1B, 0x4B, 0x0C, 0xC2, 0xC1, 0x21, 0x4C, 0xCC, 0x58, 0xF5,
    0x94, 0x52, 0xA3, 0xF3, 0xD3, 0xE0, 0x68, 0xF4, 0x00, 0x23, 0xF3, 0x5E, 0x0A, 0x7B,
    0x93, 0xDD, 0xAB, 0x12, 0xB2, 0x13, 0xE8, 0x84, 0xD7, 0xA7, 0x9F, 0x0F, 0x32, 0x4C,
    0x55, 0x1D, 0x04, 0x36, 0x52, 0xDC, 0x03, 0xF3, 0xF9, 0x4E, 0x42, 0xE9, 0x3D, 0x61,
    0xEF, 0x7C, 0xB6, 0xB3, 0x93, 0x50]
const KUGOUKEYS=Ref(Vector{UInt8}())
end
function __init__()
    add_format(format"KGM",  MAGIC_HEADER, [".kgm"])
    KUGOUKEYS[]=XzDecompressorStream(open(joinpath(@__DIR__,"..","kugou_key.xz")))|>read
end
mutable struct KuGouMusic
    const origin::IO
    const own_key::Vector{UInt8}
    position::Int
    function KuGouMusic(file::AbstractString)
        io=open(file)
        @assert read(io,28)==MAGIC_HEADER "Invalid KGM data"
        own_key=read(io,16)
        push!(own_key,0x0)
        seek(io,1024)
        new(io,own_key,0)
    end
    function KuGouMusic(file::format"KGM")
        file=filename(file)
        io=open(file)
        skip(io,28)
        own_key=read(io,16)
        push!(own_key,0x0)
        seek(io,1024)
        new(io,own_key,0)
    end
    function KuGouMusic(::Val{:safe},file::AbstractString)
        io=open(file)
        if read(io,28)!=MAGIC_HEADER
            close(io)
            return FormatError("KGM")
        end
        own_key=read(io,16)
        push!(own_key,0x0)
        seek(io,1024)
        new(io,own_key,0)
    end
end
struct FormatError <: Exception
    target_format::String
end
# const KUGOUKEYS=XzDecompressorStream("kugou_key.xz"|>open)|>read
# const KUGOUKEYSFILE=joinpath(@__DIR__,"..","asset","kugou_key.xz")

# const  LEN_KUGOUKEYS=length(KUGOUKEYS)
# get_pub_key(i::UnitRange{Int})=KUGOUKEYS[fld(i.start,16)+1:fld(i.stop,16)]
# function get_pub_key(i::UnitRange{Int})
#     io=XzDecompressorStream("kugou_key.xz"|>open)|>read
#     # seek(io,fld(i.start,16))
#     # read(io,fld(i.stop,16)-fld(i.start,16))
#     io[fld(i.start,16)+1:fld(i.stop,16)]
# end
@recompile_invalidations begin
    
function Base.read(x::KuGouMusic,_lenght::Int)
    pos=x.position
    audio=read(x.origin,_lenght)
    _lenght=length(audio)
    # pub_key=get_pub_key(pos:pos+_lenght+16)
    for i in pos:pos+_lenght-1
        _own_key=x.own_key[(i % 17 +1)] ⊻ audio[(i % _lenght+1)]
        _own_key ⊻= (_own_key & 0x0f) <<4
        # _pub_key=PUB_KEY_MEND[(i % 272 +1)] ⊻ pub_key[fld(i,16)-fld(pos,16)+1]
        _pub_key=PUB_KEY_MEND[(i % 272 +1)] ⊻ KUGOUKEYS[][fld(i,16)+1]
        _pub_key ⊻= (_pub_key & 0xf) <<4
        audio[i % _lenght+1]=_own_key ⊻ _pub_key
    end
    x.position=pos+_lenght
    audio
end
Base.read(x::KuGouMusic,_lenght::Int,::Val{:normal})=read(x,_lenght)
function Base.read(x::KuGouMusic,_lenght::Int,::Val{:threads})
    pos=x.position
    audio=read(x.origin,_lenght)
    _lenght=length(audio)
    Threads.@threads :dynamic for i in pos:pos+_lenght-1
        _own_key=x.own_key[(i % 17 +1)] ⊻ audio[(i % _lenght+1)]
        _own_key ⊻= (_own_key & 0x0f) <<4
        _pub_key=PUB_KEY_MEND[(i % 272 +1)] ⊻ KUGOUKEYS[][fld(i,16)+1]
        _pub_key ⊻= (_pub_key & 0xf) <<4
        audio[i % _lenght+1]=_own_key ⊻ _pub_key
    end
    x.position=pos+_lenght
    audio
end
end #end of recompile

function decode(x::KuGouMusic,out::IO=IOBuffer(),buffer::Int=typemax(Int);use_threads::Bool=true)
    flag=if use_threads Val(:threads) else Val(:normal) end
    while !eof(x.origin)
        audio=read(x,buffer,flag)
        write(out,audio)
    end
    out
end
# function decode(x::AbstractString)
#     ext=let t=decode(KuGouMusic(x),IOBuffer(),1024)
#         query(t)|>
#         file_extension
#     end
#     outfilename=splitext(x)[1]*ext
#     open(outfilename,"w+") do f
#         decode(KuGouMusic(x),f)
#     end
# end
function _decode(x::AbstractString,outname::AbstractString;kwargs...)
    open(outname,"w+") do f
        decode(KuGouMusic(x),f;kwargs...)
    end
end
using FileIO:formatname
function decode(x::AbstractString,outname::AbstractString=splitext(x)[1];kwargs...)
    ext=let t=read(KuGouMusic(x),1024)
        io=IOBuffer()
        write(io,t)
        query(io)|>
        formatname|>String|>lowercase
    end
    outfilename=outname*'.'*ext
    _decode(x,outfilename;kwargs...)
end
function decode(::Val{:safe},x::AbstractString,outname::AbstractString=splitext(x)[1];kwargs...)
    t=KuGouMusic(Val(:safe),x)
    if t isa FormatError return true end
    ext=let t=read(t,1024)
        io=IOBuffer()
        write(io,t)
        query(io)|>
        formatname|>String|>lowercase
    end
    outfilename=outname*'.'*ext
    _decode(x,outfilename;kwargs...)
end
function decode(x::AbstractString,outname::AbstractString,ext::AbstractString;kwargs...)
    outfilename=outname*ext
    _decode(x,outfilename;kwargs...)
end

end # module KuGouMusicDecoder
