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

  # This is a cast rather than a conversion in order to maintain bit
  # position. i.e. if we cast a signed integer, I want the sign bit to
  # stay in position 31 rather than position 63
  var num = cast[uint64](n)
  while num > 0.uint64:
    var v = num mod 128
    num = num div 128
    if num > 0.uint64:
      v = v or 0x80
    result.add(v.byte)

proc encode*[T: float32|float64](n: T): seq[byte] =
  ## Returns a sequence containing the encoded floating point number
  when T is float32:
    result = cast[uint32](n).encode()
  elif T is float64:
    result = cast[uint64](n).encode()

proc decode*[T: SomeInteger|float32|float64](input: openarray[byte]): (Option[T], seq[byte]) =
  ## Returns a tuple containing the (optional) first decoded integer
  ## and the remainder of the input as a sequence of bytes

  if len(input) == 0:
    return

  # Duplicate the input as a mutable sequence
  var
    ls = @input
    digit: byte
    mul:uint64 = 1

  when T is SomeInteger:
    var resVal = 0.T
  elif T is float32:
    var resval = 0.uint32
  elif T is float64:
    var resval = 0.uint64

  #If this is larger than a single byte, build up the integer
  while len(ls) > 0:
    digit = ls.pop(0)
    when T is SomeInteger:
      resVal += ((digit.int and 127).uint64 * mul).T
    elif T is float32:
      resVal += ((digit.int and 127).uint64 * mul).uint32
    elif T is float64:
      resVal += ((digit.int and 127).uint64 * mul).uint64

    if (digit and 128).int == 0.int:
      break

    mul = mul * 128

  # If we ran out of bytes without a proper final termination byte,
  # this is also an error
  if not ((digit and 128).int == 0.int):
    return

  when T is float32:
    result = (some(cast[float32](resVal)), ls)
  elif T is float64:
    result = (some(cast[float64](resVal)), ls)
  else:
    result = (some(resVal), ls)
