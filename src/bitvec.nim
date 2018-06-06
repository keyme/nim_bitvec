# bitvec
# Copyright KeyMe
# Extensible Bit Vector library for nim

## Extensible bit vectors are an endian independent way of encoding
## arbitrary width integers (signed or otherwise) into a delimited
## stream of bytes.  This is especially useful for serialization as it
## allows adjacent encoding of fields without requiring 'tags' (the
## downside being that one must know the order of encoding!).  One
## additional benefit is that integers will ONLY use the number of
## bytes required, so if (for example) you had a uint32 of the value
## 1, only a single byte is required to serialize (rather than 4).

import options
import sequtils

proc pop[T](s: var seq[T], idx: int): T =
  result = s[idx]
  s.delete(idx)

proc encode*[T: SomeInteger](n: T): seq[byte] =
  ## Returns a sequence containing the encoded integer
  result = @[]

  if n == 0:
    return @[0.byte]

  var num = n
  while num > 0.T:
    var v = num mod 128
    num = num div 128
    if num > 0.T:
      v = v or 0x80
    result.add(v.byte)

proc decode*[T: SomeInteger](input: openarray[byte]): (Option[T], seq[byte]) =
  ## Returns a tuple containing the (optional) first decoded integer
  ## and the remainder of the input as a sequence of bytes

  if len(input) == 0:
    return

  # Duplicate the input as a mutable sequence
  var
    ls = @input
    digit: byte
    resVal = 0.T
    mul = 1

  #If this is larger than a single byte, build up the integer
  while len(ls) > 0:
    digit = ls.pop(0)
    resVal += ((digit.int and 127) * mul).T
    mul = mul * 128
    if (digit and 128).int == 0.int:
      break

  # If we ran out of bytes without a proper final termination byte,
  # this is also an error
  if not ((digit and 128).int == 0.int):
    return

  result = (some(resVal), ls)
