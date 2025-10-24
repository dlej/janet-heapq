(declare-project
  :name "heapq"
  :description "A binary heap implementation similar to Python's heapq"
  :author "Daniel LeJeune"
  :url "https://github.com/dlej/heapq"
  :license "MIT"
  :dependencies [{:url "https://github.com/ianthehenry/judge.git"
                  :tag "v2.10.0"}])

(declare-source
  :name "heapq"
  :source @["heapq.janet"])
