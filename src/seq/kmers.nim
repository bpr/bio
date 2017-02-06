type
  BitMasks = array[0..32, uint64]

const
  kmerMasks: BitMasks =
    [0x0000000000000000'u64,
     0x0000000000000003'u64,
     0x000000000000000f'u64,
     0x000000000000003f'u64,
     0x00000000000000ff'u64,
     0x00000000000003ff'u64,
     0x0000000000000fff'u64,
     0x0000000000003fff'u64,
     0x000000000000ffff'u64,
     0x000000000003ffff'u64,
     0x00000000000fffff'u64,
     0x00000000003fffff'u64,
     0x0000000000ffffff'u64,
     0x0000000003ffffff'u64,
     0x000000000fffffff'u64,
     0x000000003fffffff'u64,
     0x00000000ffffffff'u64,
     0x00000003ffffffff'u64,
     0x0000000fffffffff'u64,
     0x0000003fffffffff'u64,
     0x000000ffffffffff'u64,
     0x000003ffffffffff'u64,
     0x00000fffffffffff'u64,
     0x00003fffffffffff'u64,
     0x0000ffffffffffff'u64,
     0x0003ffffffffffff'u64,
     0x000fffffffffffff'u64,
     0x003fffffffffffff'u64,
     0x00ffffffffffffff'u64,
     0x03ffffffffffffff'u64,
     0x0fffffffffffffff'u64,
     0x3fffffffffffffff'u64,
     0xffffffffffffffff'u64]

type Kmer64 = distinct uint64

proc pow(base: uint64, exp: int): uint64 = 
  result = base
  for i in 1..<exp:
    result *= base

proc numberToDna(n: uint8): char =
  case n
  of 0'u8: return 'A'
  of 1'u8: return 'C'
  of 2'u8: return 'G'
  of 3'u8: return 'T'
  else: 
    raise newException(ValueError, "Must be a between 0 and 3")

proc kmerIntoSlice*(k: int, kmer: uint64, slice: var string) =
    let maxKmer = pow(4, 2 * k)
    assert(kmer < maxKmer)
    var remainder = kmer
    for i in 0..k:
        let lastDigit = uint8(remainder mod 4)
        slice[k - 1 - i] = numberToDna(lastDigit)
        remainder = remainder div 4

proc dnaToNumber(n: char): uint64 =
  case n
  of 'A', 'a': return 0
  of 'C', 'c': return 1
  of 'G', 'g': return 2
  of 'T', 't': return 3
  else: 
    raise newException(ValueError, n & " must be a DNAnucleotide")

proc revComp(kmer: uint64, k: int): uint64 =
  result = kmer
  # We can do this because complementary pairs are bitwise complements
  result = (not result) and kmerMasks[k]

  # We don't want to swap odd and even bits, but if we did, we'd include
  # the following line
  #result = ((result shr 1) and 0x55555555) | ((result and 0x55555555) shl 1)

  # swap consecutive pairs
  result = ((result shr 2) and 0x3333333333333333'u64) or ((result and 0x3333333333333333'u64) shl 2)
  # swap nibbles
  result = ((result shr 4) and 0x0F0F0F0F0F0F0F0F'u64) or ((result and 0x0F0F0F0F0F0F0F0F'u64) shl 4)
  # swap bytes
  result = ((result shr 8) and 0x00FF00FF00FF00FF'u64) or ((result and 0x00FF00FF00FF00FF'u64) shl 8)
  # swap 2-byte long pairs
  result = (result shr 16 and 0x0000FFFF0000FFFF'u64) or ((result and 0x0000FFFF0000FFFF'u64) shl 16)
  # swap 4-byte long pairs
  result = (result shr 32) or (result shl 32)
  # Shift to rightmost position of the kmer in the 64 bit value
  result = result shr (64'u64 - 2'u64*uint(k))

proc canonical(kmer: uint64, k: int): uint64 =
  let complement = revComp(kmer, k)
  result = if complement < kmer: complement else: kmer

proc nextKmer(kmer: uint64, k: int, c: char): uint64 =
  result = kmer
  result = result shl 2
  result = result and kmerMasks[k]
  result = result or dnaToNumber(c)
  
proc makeKmer(k: int, s: string): uint64 =
  result = 0'u64
  var mul = 1'u64
  for i in 0..<k:
    result += mul * dnaToNumber(s[k - 1 - i])
    mul *= 4'u64

iterator kmers*(k: int, s: string): uint64 =
  var pos = 0
  var currKmer = makeKmer(k, s)
  yield currKmer
  for pos in 1..< len(s) - k:
    currKmer = nextKmer(currKmer, k, s[pos+k])
    yield canonical(currKmer, k)

