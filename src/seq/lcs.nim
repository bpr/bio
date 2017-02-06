# args.nim
import macros, os, parseopt, re, sequtils, strutils

discard """
proc printArray(args : openArray[string]) = 
  let wsRegex = re"[\s]+"
  var fields : seq[string]
  for arg in args:
    fields = split(arg, wsRegex)
    for field in fields:
      echo(field)
"""
#[
# openarray is the bridge so that both seq and array can be 
# passed to a proc
type Matrix[T] = tuple
  nRows: int
  nCols: int
  data: seq[T]

proc newMatrix*[T](nRows:int, nCols:int, init:T): Matrix[T] =
  result = (nRows, nCols, newSeqWith(nRows * nCols, init))

proc get[T](m: Matrix[T], row: int, col: int): T =
  result = m.data[row * m.nCols + col]

proc put[T](m: Matrix[T], row: int, col: int, val: T) =
  m.data[row * m.nCols + col] = val

proc `[]`[T](m: Matrix[T], row: int, col: int): T =
  result = get(m, row, col)

proc `[]=`[T](m: var Matrix[T], row: int, col: int, val: T)  =
  put(m, row, col, val)
]#

type Cell = tuple
  score: int
  prevRow: int
  prevCol: int

type Matrix[T] = seq[seq[T]]

proc newMatrix[T](rows : int, cols : int, default : T) : Matrix[T] =
  newSeq(result,rows)
  for i in 0..rows-1:
    newSeq(result[i], cols)
    for j in 0..cols-1:
      result[i][j] = default

const usage = """Fuck off dude!"""

const version = 666

proc printHelp() =
  echo("Usage: ", usage)

proc printVersion() =
  echo("Version: ", version)

proc lcs(x, y: string): (int, string) =
  # echo("lcs: x=", x, " y=", y)
  let nRows = len(y) + 1
  let nCols = len(x) + 1
  var dist = newMatrix[Cell](nRows,
                             nCols,
                             (score:0, prevRow:(-1), prevCol:(-1)))

  for row in 1..nRows-1:
    for col in 1..nCols-1:
      let above = dist[row-1][col].score
      let left  = dist[row][col-1].score
      let aboveLeft =
        if x[col-1] == y[row-1]:
          dist[row-1][col-1].score + 1
        else:
          dist[row-1][col-1].score
      if aboveLeft >= above:
        if aboveLeft >= left:
          dist[row][col].score = aboveLeft
          dist[row][col].prevRow = row-1
          dist[row][col].prevCol = col-1
        else: # left > aboveLeft >= above
          dist[row][col].score = left
          dist[row][col].prevRow = row
          dist[row][col].prevCol = col-1
      elif above >= left:
          dist[row][col].score = above
          dist[row][col].prevRow = row-1
          dist[row][col].prevCol = col
      else:
          dist[row][col].score = left
          dist[row][col].prevRow = row
          dist[row][col].prevCol = col-1

  var 
    currRow = nRows-1
    currCol = nCols-1
    currCell = dist[currRow][currCol]
    score = currCell.score
    currLcs:string = ""

  while currCell.score > 0:
    let (currScore, prevRow, prevCol) = currCell
    let prevCell = dist[prevRow][prevCol]
    if currRow - prevRow == 1 and
       currCol - prevCol == 1 and
       currScore == prevCell.score + 1:
      currLcs = x[currCol-1] & currLcs
    currRow = prevRow
    currCol = prevCol
    currCell = prevCell

  result = (score, currLcs)

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
    let (score, s) = lcs(args[0], args[1])
    echo("lcs(", args[0], ", ", args[1], ") = ", s, " of score ", score)
  else:
    printHelp()
