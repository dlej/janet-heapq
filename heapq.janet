```
Ported from https://github.com/python/cpython/blob/main/Lib/heapq.py

Copyright (c) 2001 Python Software Foundation; All Rights Reserved.
```

(use judge)

(defmacro- defn-heap
  ````Define a heap function with an optional `lt` parameter that will automatically be passed to `sift-up` and `sift-down`.

The function should be defined as normal, without the optional `lt` parameter passed to `sift-up` or `sift-down`.

For example:

```janet
(defn-heap f [a b]
(sift-up a b))
```

becomes

```janet
(defn-heap f [a b &opt lt]
(sift-up a b lt))
```
````
  [name docs args & body]
  (var front-matter [name docs])
  (var args args)
  (var body body)
  (unless (string? docs)
    (set front-matter [name])
    (set body [args ;body])
    (set args docs))
  (def args (tuple/join args '(&opt lt)))
  (defn walk-for-sift [form]
    (def head (first form))
    (if (in {'sift-up true
             'sift-down true
             'push true
             'pop true
             'replace true
             'push-pop true
             'heapify true
             'merge true
             'n-largest true} head)
      [head ;(walk walk-for-sift (tuple/slice form 1)) 'lt]
      (walk walk-for-sift form)))
  ~(defn ,;front-matter ,args (default lt <) ,;(walk-for-sift body)))


(defn- sift-down
  `Sift an item down towards the root (bubble up).

'heap' is a heap at all indices >= startpos, except possibly for pos.  pos
is the index of a leaf with a possibly out-of-order value.  Restore the
heap invariant. Returns the heap.
  `
  [heap start-pos pos lt]
  (def new-item (heap pos))
  (var pos pos)
  (var parent-pos (div (dec pos) 2))
  # Follow the path to the root, moving parents down until finding a place
  # newitem fits.
  (while (and (< start-pos pos) (lt new-item (heap parent-pos)))
    (put heap pos (heap parent-pos))
    (set pos parent-pos)
    (set parent-pos (div (dec pos) 2)))
  (put heap pos new-item))

(test (sift-down @[1 2 3 0] 0 3 <) @[0 1 3 2])
(test (sift-down @[1 2 3 4 5 6 0] 0 6 <) @[0 2 1 4 5 6 3])
(test (sift-down @[1 2 3 4 5 6 0] 2 6 <) @[1 2 0 4 5 6 3])


(defn- sift-up
  "Sift an item up away from the root (bubble down). Returns the heap."
  [heap pos lt]
  (var pos pos)
  (def start-pos pos)
  (def new-item (heap pos))
  # Bubble up the smaller child until hitting a leaf.
  (var child-pos (inc (* 2 pos))) # leftmost child position
  (while (< child-pos (length heap))
    # Set child-pos to index of smaller child.
    (def right-pos (inc child-pos))
    (if (and (< right-pos (length heap))
             (not (lt (heap child-pos) (heap right-pos))))
      (set child-pos right-pos))
    # Move the smaller child up.
    (put heap pos (heap child-pos))
    (set pos child-pos)
    (set child-pos (inc (* 2 pos))))
  # The leaf at pos is empty now.  Put newitem there, and bubble it up
  # to its final resting place (by sifting its parents down).
  (put heap pos new-item)
  (sift-down heap start-pos pos lt))

(test (sift-up @[4 1 2 3] 0 <) @[1 3 2 4])
(test (sift-up @[4 2 1 3] 0 <) @[1 2 4 3])
(test (sift-up @[8 1 2 3 4 5 6 7] 0 <) @[1 3 2 7 4 5 6 8])
(test (sift-up @[0 8 2 3 4 5 6 7] 1 <) @[0 3 2 7 4 5 6 8])


(defn-heap push
  "Push item onto heap, maintaining the heap invariant. Returns the heap."
  [heap item]
  (array/push heap item)
  (sift-down heap 0 (dec (length heap))))

(test (let [heap @[]]
        (seq [i :range [0 3]]
          (push heap i)
          (push heap (- i))
          (array/slice heap)))
      @[@[0 0] @[-1 0 1 0] @[-2 0 -1 0 2 1]])
(test (let [heap @[]] (push heap 0)) @[0])


(defn-heap pop
  "Pop the smallest item off the heap, maintaining the heap invariant."
  [heap]
  (def item (array/pop heap))
  (if (empty? heap)
    item
    (let [return-item (heap 0)]
      (put heap 0 item)
      (sift-up heap 0)
      return-item)))

(test (let [heap @[0 1 2 3 4 5 6]]
        (seq [:repeat 7]
          (pop heap)
          (array ;heap)))
      @[@[1 3 2 6 4 5]
        @[2 3 5 6 4]
        @[3 4 5 6]
        @[4 6 5]
        @[5 6]
        @[6]
        @[]])


(defn-heap replace
  ````Pop and return the current smallest value, and add the new item.

This is more efficient than heapq/pop followed by heapq/push, and can be
more appropriate when using a fixed-size heap.  Note that the value
returned may be larger than item!
````
  [heap item]
  (def return-item (heap 0))
  (put heap 0 item)
  (sift-up heap 0)
  return-item)

(test (let [heap @[1 2 3 4 5 6 7]]
        (seq [i :range [0 7]]
          (replace heap i)
          (array ;heap)))
      @[@[0 2 3 4 5 6 7]
        @[1 2 3 4 5 6 7]
        @[2 2 3 4 5 6 7]
        @[2 3 3 4 5 6 7]
        @[3 3 4 4 5 6 7]
        @[3 4 4 5 5 6 7]
        @[4 4 6 5 5 6 7]])


(defn-heap push-pop
  "Fast version of a push followed by a pop."
  [heap item]
  (if (and
        (not (empty? heap))
        (lt (heap 0) item))
    (let [head (heap 0)]
      (put heap 0 item)
      (sift-up heap 0)
      head)
    item))

(test (let [heap @[1 2 3 4 5 6 7]]
        (seq [i :range [0 7]]
          (push-pop heap i)
          (array ;heap)))
      @[@[1 2 3 4 5 6 7]
        @[1 2 3 4 5 6 7]
        @[2 2 3 4 5 6 7]
        @[2 3 3 4 5 6 7]
        @[3 3 4 4 5 6 7]
        @[3 4 4 5 5 6 7]
        @[4 4 6 5 5 6 7]])


(defn-heap heapify
  "Transform list into a heap, in-place, in O(len(x)) time. Returns the heap."
  [heap]
  # Transform bottom-up.  The largest index there's any point to looking at
  # is the largest with a child index in-range, so must have 2*i + 1 < n,
  # or i < (n-1)/2.  If n is even = 2*j, this is (2*j-1)/2 = j-1/2 so
  # j-1 is the largest, which is n//2 - 1.  If n is odd = 2*j+1, this is
  # (2*j+1-1)/2 = j so j-1 is the largest, and that's again n//2-1.
  (loop [i :in (range (dec (div (length heap) 2)) -1 -1)]
    (sift-up heap i))
  heap)

(test (let [heap @[0 1 2 3 4 5 6 7]]
        (heapify heap))
      @[0 1 2 3 4 5 6 7])
(test (let [heap @[7 6 5 4 3 2 1 0]]
        (heapify heap))
      @[0 3 1 4 7 2 5 6])
(test (let [heap @[9 4 8 2 9 4 3 0 8]]
        (heapify heap))
      @[0 2 3 4 9 4 8 9 8])


(defn-heap merge
  "Merge multiple sorted inputs (any iterable type) into a single sorted output, as an iterable fiber. The iterables argument should be an array or tuple of iterables."
  [iterables]
  (def heap @[])
  (def ks (map |(next $) iterables))
  (loop [i :range [0 (length iterables)]
         :let [iterable (iterables i)
               k (ks i)]]
    (unless (nil? k)
      (array/push heap [(in iterable k) i])))
  (heapify heap)
  (fiber/new (fn []
               (while (not (empty? heap))
                 (let [[x i] (heap 0)
                       it (iterables i)
                       k (ks i)
                       next-k (next it k)]
                   (yield x)
                   (if-not (nil? next-k)
                     (do
                       (put ks i next-k)
                       (replace heap [(in it next-k) i]))
                     (pop heap)))))))

(test (map identity
           (merge []))
      @[])
(test (map identity
           (merge [] []))
      @[])
(test (map identity
           (merge [[4 5 6]]))
      @[4 5 6])
(test (map identity
           (merge [[4 5 6]
                   (fiber/new (fn []))
                   (fiber/new (fn [] (yield 1) (yield 5) (yield 8)))
                   (fiber/new (fn [] (yield 0) (yield 4) (yield 4) (yield 9)))
                   @[0]
                   []]))
      @[0 0 1 4 4 4 5 5 6 8 9])
(test (map identity
           (merge [[4 3 2]
                   (fiber/new (fn []))
                   (fiber/new (fn [] (yield 5) (yield 3) (yield 1)))
                   (fiber/new (fn [] (yield 4) (yield 4) (yield 3) (yield 0)))
                   @[0]
                   []] >))
      @[5 4 4 4 3 3 3 2 1 0 0])


(defn-heap n-largest
  "Find the n largest elements in an array or tuple, in descending order.
  
  Returns the same items as (take n (reverse (sorted arrtup))), but more efficient."
  [arrtup n]
  (if (< n 0) (error "n cannot be negative"))
  (def n (min n (length arrtup)))
  (def heap (array/slice arrtup 0 n))
  (heapify heap)
  (for i n (length arrtup)
    (push-pop heap (arrtup i)))
  (reverse (seq [:repeat n] (pop heap))))

(test (n-largest [] 1) @[])
(test (n-largest [2 5 1 7 0 3 2 4 2] 0) @[])
(test (n-largest [2 5 1 7 0 3 2 4 2] 4) @[7 5 4 3])
(test (take 4 (reverse (sorted [2 5 1 7 0 3 2 4 2]))) [7 5 4 3])
(test (n-largest [2 5 1 7 0 3 2 4 2] 4 >) @[0 1 2 2])
(test (n-largest [2 5 1 7 0 3 2 4 2] 100) @[7 5 4 3 2 2 2 1 0])
(test-error (n-largest [2 5 1 7 0 3 2 4 2] -1) "n cannot be negative")


(test-macro (defn-heap f [a b c]
              (do (sift-up a b) (sift-down a b c)
                (do (push a b) (pop a) (push-pop a b) (heapify a) (replace a b) (merge [a b c]))))
            (defn f
              (a b c &opt lt)
              (default lt <)
              (do
                (sift-up a b lt)
                (sift-down a b c lt)
                (do
                  (push a b lt)
                  (pop a lt)
                  (push-pop a b lt)
                  (heapify a lt)
                  (replace a b lt)
                  (merge [a b c] lt)))))
(test-macro (defn-heap f "docstring" [a b c]
              (do (sift-up a b) (sift-down a b c)
                (do (push a b) (pop a) (push-pop a b) (heapify a) (replace a b) (merge [a b c]))))
            (defn f
              "docstring"
              (a b c &opt lt)
              (default lt <)
              (do
                (sift-up a b lt)
                (sift-down a b c lt)
                (do
                  (push a b lt)
                  (pop a lt)
                  (push-pop a b lt)
                  (heapify a lt)
                  (replace a b lt)
                  (merge [a b c] lt)))))


(def- Heap
  @{:lt <
    :array (fn [self] (array/slice (self :arr)))
    :push (fn [self x] (push (self :arr) x (self :lt)) self)
    :pop (fn [self] (pop (self :arr) (self :lt)))
    :replace (fn [self x] (replace (self :arr) x (self :lt)))
    :push-pop (fn [self x] (push-pop (self :arr) x (self :lt)))})


(defn-heap new
  "Create a new heap object."
  []
  (table/setproto @{:lt lt :arr @[]} Heap))

(test (let [heap (new >)]
        (for i 0 8
          (:push heap i))
        (:array heap)) @[7 6 5 3 2 1 4 0])
(test (let [heap (new >)]
        (seq [i :range [0 3]]
          (:push heap i)
          (:push heap (- i))
          (:array heap)))
      @[@[0 0] @[1 0 0 -1] @[2 1 0 -1 0 -2]])
(test (let [heap (new >)] (:array (:push heap 0))) @[0])


(defn-heap from
  "Create a new heap object from an iterable or fiber."
  [ind]
  (let [heap (table/setproto
               @{:lt lt
                 :arr (heapify (map identity ind))} Heap)]
    heap))

(test (:array (from [0 1 2 3 4 5 6 7] >)) @[7 4 6 3 0 5 2 1])

(test (let [heap (from [0 1 2 3 4 5 6] >)]
        (seq [i :in (range 8 2 -1)]
          (:replace heap i)
          (:array heap)))
      @[@[8 4 5 3 1 0 2]
        @[7 4 5 3 1 0 2]
        @[6 4 5 3 1 0 2]
        @[5 4 5 3 1 0 2]
        @[5 4 4 3 1 0 2]
        @[4 4 3 3 1 0 2]])

(test (let [heap (from [0 1 2 3 4 5 6] >)]
        (seq [i :in (range 8 2 -1)]
          (:push-pop heap i)
          (:array heap)))
      @[@[6 4 5 3 1 0 2]
        @[6 4 5 3 1 0 2]
        @[6 4 5 3 1 0 2]
        @[5 4 5 3 1 0 2]
        @[5 4 4 3 1 0 2]
        @[4 4 3 3 1 0 2]])
