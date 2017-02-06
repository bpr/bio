type
  FastqRecord* = object
    description*: string
    sequence*: string
    quality*: string

proc qToPhred33*(q: int): char =
  #Turn q into Phred+33 ASCII-encoded quality
  result = chr(q + 33)

proc phred33ToQ*(qual: char): int =
  # Turn Phred+33 ASCII-encoded quality into q
  result = ord(qual) - 33

iterator records*(filename: string): FastqRecord =
  var description = ""
  var sequence = ""
  var quality = ""
  var pos = 0
  for line in lines(filename):
    if pos == 0:
      description = line
      pos += 1
    elif pos == 1:
      sequence = line
      pos += 1
    elif pos == 2:
      pos += 1
      continue
    else:
      quality = line
      yield FastqRecord(description: description,
                        sequence: sequence,
                        quality: quality)
      pos = 0
