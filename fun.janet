(import sqlite3)

(declare-project)


(+ 3 4)

(->> (map (fn [x] (inc x)) [1 3 4])
     (filter odd?))

(defn foobar [x]
  (* x 3))

(foobar 3)

(doc *)
