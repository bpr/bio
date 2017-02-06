import strutils

type
  FastaRecord* = object
    header*: string
    sequence*: string

iterator records*(filename: string): FastaRecord =
  var header = ""
  var sequence: seq[string] = @[]
  for line in lines(filename):
    if line[0] == '>':
        if header == "":
          header = line
        else:
          yield FastaRecord(header: header, sequence: join(sequence))
          header = line
          sequence = @[]
    else:
      sequence.add(line)
  yield FastaRecord(header: header, sequence: join(sequence))
  
