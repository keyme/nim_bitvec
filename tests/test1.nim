import bitvec
import unittest
import random
import sequtils
import strformat
import options
import math

suite "Test EBV Round Trip":
  test "zero":
    let enc = encode(0)
    let (decRes, rem) = decode[int](enc)
    assert decRes.isSome()
    assert decRes.get() == 0.int
    assert rem.len() == 0

  test "One":
    let enc = encode(1)
    let (decRes, rem) = decode[int](enc)
    assert decRes.isSome()
    assert decRes.get() == 1.int
    assert rem.len() == 0

  test "Negative One":
    let enc = encode(-1)
    let (decRes, rem) = decode[int](enc)
    assert decRes.isSome()
    assert decRes.get() == -1.int
    assert rem.len() == 0

  test "DeadBeef":
    let enc = encode(0xdeadbeef)
    let (decRes, rem) = decode[int](enc)
    assert decRes.isSome()
    assert decRes.get() == 0xdeadbeef.int
    assert rem.len() == 0

  test "Floating Point F32":
    let num = 1.234.float32
    let enc = encode(num)
    let (decRes, rem) = decode[float32](enc)
    assert decRes.isSome()
    assert decRes.get() == num
    assert rem.len() == 0

  test "negative Floating Point F32":
    let num = -1.234.float32
    let enc = encode(num)
    let (decRes, rem) = decode[float32](enc)
    assert decRes.isSome()
    assert decRes.get() == num
    assert rem.len() == 0

  test "Floating Point F64":
    let num = 1.234.float64
    let enc = encode(num)
    let (decRes, rem) = decode[float64](enc)
    assert decRes.isSome()
    assert decRes.get() == num
    assert rem.len() == 0

  test "Two Integers":
    ## Test to be sure we can encode multiple integers into the same
    ## stream and extract them properly
    var enc = encode(0xdeadbeef)
    enc &= encode(0xf00fbeef)

    # Try to unpack the first integer, ensuring that we still have
    # bytes remaining
    var (decRes, rem) = decode[int](enc)
    assert decRes.isSome()
    assert decRes.get() == 0xdeadbeef.int
    assert rem.len() != 0

    # Extrac the second integer
    (decRes, rem) = decode[int](rem)
    assert decRes.isSome()
    assert decRes.get() == 0xf00fbeef.int
    assert rem.len() == 0

  test "Bad Encode":
    ## tests to be sure that we get an error if the last byte doesn't
    ## have a zero in the MSB
    let data = @[0xff.byte, 0xff.byte]
    let (decRes, rem) = decode[int](data)
    assert decRes.isNone()
    assert rem.len() == 0

  test "Empty Decode":
    ## tests to be sure that we get an error if the last byte doesn't
    ## have a zero in the MSB
    let data: seq[byte] = @[]
    let (decRes, rem) = decode[int](data)
    assert decRes.isNone()
    assert rem.len() == 0
