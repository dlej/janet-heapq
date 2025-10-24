(import heapq)

(def heap @[])
(heapq/push heap 0)
(assert (= (heap 0) 0))
(for i 1 50
  (heapq/push heap i)
  (assert (= (heap 0) (- (dec i))))
  (heapq/push heap (- i))
  (assert (= (heap 0) (- i))))
(assert (= (length heap) 99))

(loop [i :in (range 49 -50 -1)]
  (assert (= (heapq/pop heap) (- i))))
(assert (= nil (heapq/pop heap)))
