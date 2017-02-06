import times
import os
import io.fasta
import seq.kmers

proc pow(b:int, e:int):uint64 =
  result = 1
  for i in 0..<e:
    result *= uint64(b)

proc mean(oa: openArray[int32]): float64 =
  result = 0.0
  for i in oa:
    result += float64(i)
  result /= float64(oa.len)

proc maxInSequence(oa: openArray[int32]): int32 =
  result = low(int32)
  for i in oa:
    if i > result:
      result = i

proc minInSequence(oa: openArray[int32]): int32 =
  result = high(int32)
  for i in oa:
    if i < result:
      result = i

proc run(fileNames: seq[string], k:int) =
  var s = "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA"
  let numKmers:uint64 = pow(4, k)
  var kmerCounts = newSeq[int32](numKmers)
  var readLengths = newSeq[int32]()
  for fname in fileNames:
    for r in records(fname):
      readLengths.add(int32(len(r.sequence)))

      for kmer in kmers(k, r.sequence):
        kmerCounts[int(kmer)] += 1

  for kmer in 0u64..<numKmers:
    if kmerCounts[int(kmer)] > 1:
      kmerIntoSlice(k, uint64(kmer), s)

  echo(len(readLengths), " reads")
  echo(mean(readLengths), " mean read length")
  echo(maxInSequence(readLengths), " maximum length read")
  echo(minInSequence(readLengths), " minimum length read")

proc main() =
  let start = epochtime()
  var fileNames = newSeq[string]()
  for i in 1..paramCount():
    fileNames.add(paramStr(i))
  run(filenames, 14)
  let stop = epochtime()
  stderr.write("Nim elapsed ", stop-start, " seconds\n")

main()
#when isMainModule:
