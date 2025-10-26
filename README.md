# Heapq

Heapq is a pure-[Janet](https://janet-lang.org/) binary heap library similar to (and borrowing from) Python®'s [`heapq` module](https://docs.python.org/3/library/heapq.html). You can install it with `jpm`:

```janet
# project.janet
(declare-project
  :dependencies [
    {:url "https://github.com/dlej/janet-heapq.git"
     :tag "v0.1.0"}
  ])
```

This library largely replicates the functionality available in `heapq`, with a few adaptations more suitable for Janet:

- Instead of implementing separate min- and max-heap functionality, all functions accept an optional custom `lt` (less-than) function to implement any comparison.
- Function names are simplified and converted to kebab-case.
- Functions with no return value return the heap array.
- In addition to the functional style, it provides a simple object-oriented interface for encapsulating custom comparison functions.

## Usage

Heaps are just ordinary Janet arrays that satisfy the heap invariant.

```janet
(import heapq)

(def heap @[])
# @[0]
(heapq/push heap 1) # push an item onto the heap
# @[1]
(heapq/push heap 0)
# @[0 1]

(heapq/pop heap) # pop the smallest item from the heap
# 0
(heapq/pop heap)
# 1
(empty? heap)
# true

(def heap (heapq/heapify @[3 2 1 0])) # modify an array in-place to satisfy the heap invariant
# @[0 2 1 3]
(heapq/replace heap -1) # like popping an item and then pushing, but more efficient
# 0
heap
# @[-1 2 1 3]
(heapq/push-pop heap -2) # like pushing and then popping, but more efficient
# -2
heap
# @[-1 2 1 3]

```

We can also use heaps to facilitate functionality such as a sorted merge of iterables or finding the n largest items.

```janet
(def arr @[1 3 5])
(def tup [2 4])
(def fib (fiber/new (fn [] (yield 0))))
(def merged (heapq/merge [arr tup fib])) # merge sorted iterables, as an iterable fiber
(def merged-arr (map identity merged))
# @[0 1 2 3 4 5]

(heapq/n-largest [0 3 5 2 4 1] 3) # get the n largest items, in decreasing order
@[5 4 3]
```

Every function accepts an optional `lt` argument which should be a function of arity 2 (or more, but only 2 arguments will be passed) that returns truthy if the first comes before the second, and falsy otherwise. The most obvious example of such a function would be `>` to implement max-heaps instead of min-heaps (using the default `<`).

```janet
(def heap (heapq/heapify @[0 1 2 3 4 5] >))
# @[5 4 2 3 1 0]
(seq [:repeat 6] (heapq/pop heap >)) # pop all items, returning a decreasing list
# @[5 4 3 2 1 0]

(heapq/n-largest [0 3 5 2 4 1] 3 >) # get the n smallest items, in increasing order
@[0 1 2]
```

### Object-oriented encapsulation

To make it easier to use custom comprison functions without having to remember to pass in the `lt` argument every time, we also provide an object-oriented version of the library.

```janet
(def heap (heapq/new >)) # create a new heap
# @{:arr @[] :lt <function >>}
(:push heap 0)
(heap :arr) # access the actual heap array
# @[0]
(:push heap 1)
(:array heap) # get a copy of the heap array
# @[1 0]

(:pop heap)
# 1
(:pop heap)
# 0
(:array heap)
# @[]

(def heap (heapq/from [0 1 2 3] >)) # create a new heap from an existing iterable
@{:arr @[3 1 2 0] :lt <function >>}
(:replace heap 4)
# 3
(:array heap)
# @[4 1 2 0]
(:push-pop heap 5)
# 5
(:array heap)
# @[-1 2 1 3]
(:length heap)
# 4
```

## Testing

This library uses [Judge](https://github.com/ianthehenry/judge) for basic tests. To run them, clone the repository and run

```bash
jpm deps
judge
```

The library also includes more extensive tests ported from the [CPython heapq test suite](https://github.com/python/cpython/blob/main/Lib/test/test_heapq.py) in [test.janet](test/test.janet), which can be run with `jpm`:

```bash
jpm test
```

## Copyright and License Information

Copyright © 2025 Daniel LeJeune.

This software is distributed under an [MIT License](LICENSE).

Copyright © 2001 Python Software Foundation; All Rights Reserved.

"Python" is a registered trademark of the Python Software Foundation.

This softwares is based on the [`heapq` implementation](https://github.com/python/cpython/blob/main/Lib/heapq.py) and [tests](https://github.com/python/cpython/blob/main/Lib/test/test_heapq.py) from CPython under the [Python Software Foundation License Version 2](cpython.LICENSE).
