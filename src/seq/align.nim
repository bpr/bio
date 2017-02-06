# args.nim
import os, parseopt, re, strutils

# openarray is the bridge so that both seq and array can be 
# passed to a proc
type Cell = tuple
  score: int
  prevRow: int
  prevCol: int

type Matrix[T] = seq[seq[T]]

proc newMatrix[T](rows : int, cols : int, initf: proc(i,j:int):T) : Matrix[T] =
  newSeq(result,rows)
  for i in 0..rows-1:
    newSeq(result[i], cols)
    for j in 0..cols-1:
      result[i][j] = initf(i, j)

const usage = """Fuck off dude!"""

const version = 666

proc printHelp() =
  echo("Usage: ", usage)

proc printVersion() =
  echo("Version: ", version)

# This is an approximation of the Needleman Wunsch algorithm for 
# global alignment
proc globalALign(x, y: string): (int, string, string) =
  # echo("globalALign: x=", x, " y=", y)
  let nRows = len(y) + 1
  let nCols = len(x) + 1
  let gapPenalty = -2
  let match = 1
  let mismatch = -1

  proc initf(row, col: int): Cell =
    if row == 0:
      result.score = col * gapPenalty
      result.prevRow = -1
      result.prevCol = col - 1
    elif col == 0:
      result.score = row * gapPenalty
      result.prevRow = -1
      result.prevCol = col - 1
    else:
      result.score = 0
      result.prevRow = row - 1
      result.prevCol = col - 1

  var dist = newMatrix[Cell](nRows, nCols, initf)

  # Fill in the table
  for row in 1..nRows-1:
    for col in 1..nCols-1:
      let above = dist[row-1][col].score + gapPenalty
      let left  = dist[row][col-1].score + gapPenalty
      let aboveLeft =
        if x[col-1] == y[row-1]:
          dist[row-1][col-1].score + match
        else:
          dist[row-1][col-1].score + mismatch

      if above >= left:
        if aboveLeft >= above:
          dist[row][col].score = aboveLeft
          dist[row][col].prevRow = row-1
          dist[row][col].prevCol = col-1
        else:
          dist[row][col].score = above
          dist[row][col].prevRow = row - 1
          dist[row][col].prevCol = col
      else:
        if aboveLeft >= left:
          dist[row][col].score = aboveLeft
          dist[row][col].prevRow = row-1
          dist[row][col].prevCol = col-1
        else:
          dist[row][col].score = left
          dist[row][col].prevRow = row
          dist[row][col].prevCol = col-1

  # Backtrace solution(s)
  var 
    currRow = nRows-1
    currCol = nCols-1
    currCell = dist[currRow][currCol]
    score = currCell.score
    currAlign0:string = ""
    currAlign1:string = ""

  while currCell.prevRow >= 0 and currCell.prevCol >= 0:
    let (_, prevRow, prevCol) = currCell
    let prevCell = dist[prevRow][prevCol]
    if currRow - prevRow == 1:
      currAlign1 = y[currRow-1] & currAlign1
    else:
      currAlign1 = '-' & currAlign1

    if currCol - prevCol == 1:
      currAlign0 = x[currCol-1] & currAlign0
    else:
      currAlign0 = '-' & currAlign0

    currRow = prevRow
    currCol = prevCol
    currCell = prevCell

  result = (score, currAlign0, currAlign1)

# This is an approximation of the Smith-Waterman algorithm for 
# local alignment
proc localALign(x, y: string): (int, string, string) =
  # echo("globalALign: x=", x, " y=", y)
  let nRows = len(y) + 1
  let nCols = len(x) + 1
  let gapPenalty = -2
  let match = 1
  let mismatch = -1

  proc initf(row, col: int): Cell =
    if row == 0:
      result.score = 0
      result.prevRow = -1
      result.prevCol = col - 1
    elif col == 0:
      result.score = 0
      result.prevRow = row - 1
      result.prevCol = -1
    else:
      result.score = 0
      result.prevRow = row - 1
      result.prevCol = col - 1

  var dist = newMatrix[Cell](nRows, nCols, initf)
  var highScore = -1
  var highScoreRow = -1
  var highScoreCol = -1

  # Fill in the table
  for row in 1..nRows-1:
    for col in 1..nCols-1:
      let above = dist[row-1][col].score + gapPenalty
      let left  = dist[row][col-1].score + gapPenalty
      var aboveLeft = dist[row-1][col-1].score
      if x[col-1] == y[row-1]:
        aboveLeft += match
      else:
        aboveLeft += mismatch

      if above >= left:
        if aboveLeft >= above:
          if aboveLeft > 0:
            dist[row][col].score = aboveLeft
            dist[row][col].prevRow = row-1
            dist[row][col].prevCol = col-1
        else:
          if above > 0:
            dist[row][col].score = above
            dist[row][col].prevRow = row - 1
            dist[row][col].prevCol = col
      else:
        if aboveLeft >= left:
          if aboveLeft > 0:
            dist[row][col].score = aboveLeft
            dist[row][col].prevRow = row-1
            dist[row][col].prevCol = col-1
        else:
          if left > 0:
            dist[row][col].score = left
            dist[row][col].prevRow = row
            dist[row][col].prevCol = col-1

      if dist[row][col].score > highScore:
        highScore = dist[row][col].score
        highScoreRow = row
        highScoreCol = col

  # Backtrace solution(s)
  var 
    currRow = highScoreRow
    currCol = highScoreCol
    currCell = dist[currRow][currCol]
    score = currCell.score
    currAlign0:string = ""
    currAlign1:string = ""

  while currCell.prevRow >= 0 and currCell.prevCol >= 0:
    let (_, prevRow, prevCol) = currCell
    let prevCell = dist[prevRow][prevCol]
    if currRow - prevRow == 1:
      currAlign1 = y[currRow-1] & currAlign1
    else:
      currAlign1 = '-' & currAlign1

    if currCol - prevCol == 1:
      currAlign0 = x[currCol-1] & currAlign0
    else:
      currAlign0 = '-' & currAlign0

    currRow = prevRow
    currCol = prevCol
    currCell = prevCell

  result = (score, currAlign0, currAlign1)

when isMainModule:
  var
    args = newSeq[string]()
  for kind, key, val in getopt():
    case kind
    of cmdArgument:
      args.add(key)
    of cmdLongOption, cmdShortOption:
      case key
      of "help", "h": printHelp()
      of "version", "v": printVersion()
      else:
        discard
    of cmdEnd: assert(false) # cannot happen
  if len(args) == 2:
    block block0:
      let (score, s0, s1) = globalALign(args[0], args[1])
      echo("globalAlign(", args[0], ", ", args[1], ") = ")
      echo(s0)
      echo(s1)
      echo("of score ", score)
    block block1:
      let (score, s0, s1) = localALign(args[0], args[1])
      echo("localAlign(", args[0], ", ", args[1], ") = ")
      echo(s0)
      echo(s1)
      echo("of score ", score)
  else:
    printHelp()
