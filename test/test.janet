```
Tests based on https://github.com/python/cpython/blob/main/Lib/test/test_heapq.py

Copyright (c) 2001 Python Software Foundation; All Rights Reserved.
```

(import /heapq)

(defn- check-invariant [heap &opt lt]
  (default lt <)
  (loop [i :range [1 (length heap)]] # root has no parent
    (assert (not (lt (heap i) (heap (div (dec i) 2)))))))

(defn- check-equal [& inds]
  (assert (= ;(map length inds)))
  (assert (all |(= ;$&) ;inds)))


# set a random seed
(def rng (math/rng 42))


# test push/pop for min-heap
(def heap @[])
(def data (seq [:repeat 256] (:uniform rng)))
(each x data
  (heapq/push heap x)
  (check-invariant heap))
(def result
  (seq [:repeat 256
        :let [x (heapq/pop heap)]]
    (check-invariant heap)
    x))
(check-equal (sorted data) result)


# test push/pop for max-heap
(each x data
  (heapq/push heap x >)
  (check-invariant heap >))
(def result
  (seq [:repeat 256
        :let [x (heapq/pop heap >)]]
    (check-invariant heap >)
    x))
(check-equal (reverse (sorted data)) result)


# test heapify
(loop [size :in [20000 ;(range 30)]
       :let [heap (seq [:repeat size] (:uniform rng))]]
  (heapq/heapify heap)
  (check-invariant heap)
  (heapq/heapify heap >)
  (check-invariant heap >))


# test several nbest approaches
# naive
(def data (seq [:repeat 1000] (:int rng 2000)))
(def nbest (array/slice (sorted data) 990 1000))
(def heap @[])
(each x data
  (heapq/push heap x)
  (if (< 10 (length heap)) (heapq/pop heap)))
(check-equal nbest (sorted heap))
# better, replace version
(def heap (array/slice data 0 10))
(heapq/heapify heap)
(loop [i :range [10 1000]
       :let [x (data i)]]
  (if (> x (heap 0)) (heapq/replace heap x)))
(check-equal nbest (sorted heap))
# better, push-pop version
(def heap (array/slice data 0 10))
(heapq/heapify heap)
(loop [i :range [10 1000]
       :let [x (data i)]]
  (heapq/push-pop heap x))
(check-equal nbest (sorted heap))
# even better, with max-heap
(def heap (array/slice data))
(heapq/heapify heap >)
(def result (seq [:repeat 10] (heapq/pop heap >)))
(check-equal nbest (reverse result))
# using n-largest
(def heap (array/slice data))
(def result (heapq/n-largest heap 10))
(check-equal nbest (reverse result))


# test several nworst approaches
# naive
(def data (seq [:repeat 1000] (:int rng 2000)))
(def nworst (array/slice (sorted data) 0 10))
(def heap @[])
(each x data
  (heapq/push heap x >)
  (if (< 10 (length heap)) (heapq/pop heap >)))
(check-equal nworst (sorted heap))
# better, replace version
(def heap (array/slice data 0 10))
(heapq/heapify heap >)
(loop [i :range [10 1000]
       :let [x (data i)]]
  (if (< x (heap 0)) (heapq/replace heap x >)))
(check-equal nworst (sorted heap))
# better, push-pop version
(def heap (array/slice data 0 10))
(heapq/heapify heap >)
(loop [i :range [10 1000]
       :let [x (data i)]]
  (heapq/push-pop heap x >))
(check-equal nworst (sorted heap))
# even better, with min-heap
(def heap (array/slice data))
(heapq/heapify heap)
(def result (seq [:repeat 10] (heapq/pop heap)))
(check-equal nworst result)
# using n-largest
(def heap (array/slice data))
(def result (heapq/n-largest heap 10 >))
(check-equal nworst result)


# test push-pop
(def heap @[])
(def x (heapq/push-pop heap 10))
(assert (empty? heap))
(assert (= x 10))

(def heap @[10])
(def x (heapq/push-pop heap 9))
(check-equal heap [10])
(assert (= x 9))

(def heap @[10])
(def x (heapq/push-pop heap 11))
(check-equal heap [11])
(assert (= x 10))

(def heap @[10])
(def x (heapq/push-pop heap 9 >))
(check-equal heap [9])
(assert (= x 10))

(def heap @[10])
(def x (heapq/push-pop heap 11 >))
(check-equal heap [10])
(assert (= x 11))


# test heapsort
(loop [i :range [0 100]
       :let [size (:int rng 50)
             data (seq [:repeat size] (:int rng 25))]]
  # test standard sort with min-heap
  (def heap @[])
  (if (odd? i)
    (do # half of the time, use heapify
      (array/push heap ;data)
      (heapq/heapify heap))
    (do # the rest of the time, use push
      (each x data (heapq/push heap x))))
  (def heap-sorted (seq [:repeat size] (heapq/pop heap)))
  (check-equal heap-sorted (sorted data))

  # test reverse sort with max-heap
  (def heap @[])
  (if (odd? i)
    (do # half of the time, use heapify
      (array/push heap ;data)
      (heapq/heapify heap >))
    (do # the rest of the time, use push
      (each x data (heapq/push heap x >))))
  (def heap-sorted (seq [:repeat size] (heapq/pop heap >)))
  (check-equal heap-sorted (reverse (sorted data))))


# test merge
(def inputs
  (seq [:repeat 25]
    (sorted (seq [:repeat (:int rng 100)] (:buffer rng 8)))))
(def input-merged (map identity (heapq/merge inputs)))
(check-equal (sorted (array/join ;inputs)) input-merged)

(def inputs
  (seq [:repeat 25]
    (reverse (sorted (seq [:repeat (:int rng 100)] (:buffer rng 8))))))
(def input-merged (map identity (heapq/merge inputs >)))
(check-equal (reverse (sorted (array/join ;inputs))) input-merged)

(check-equal @[] (map identity (heapq/merge [@[]])))
(check-equal @[] (map identity (heapq/merge [@[] @[]])))
