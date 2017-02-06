import times
import os
import io.fastq
import seq.kmers

proc run(fname: string) =
  var s = "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA"
  const k:int = 14
  for record in records(fname):
    echo "Sequence is ",
        record.sequence,
        " quality is ",
        record.quality
#[
    for kmer in kmers(k, record.sequence):
      kmerIntoSlice(k, kmer, s)
      echo("kmer is ", s[0..<k])
]#

proc main() =
  let start = epochtime()
  run(paramStr(1))
  let stop = epochtime()
  stderr.write("Nim elapsed ", stop-start, " seconds\n")

main()
#when isMainModule:
