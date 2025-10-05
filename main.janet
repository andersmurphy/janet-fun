(import sqlite3 :as sql)

(comment
 (sql/eval db `CREATE TABLE customers(id INTEGER PRIMARY KEY, name TEXT);`)

 (for i 0 1000
   (sql/eval db `INSERT INTO customers VALUES(:id, :name);` {:name "John" :id i}))

 (sql/eval db `SELECT * FROM customers;`)

 (doc printf)
 (doc pp)

 (doc sql/eval)

 (let [[_ start] (os/clock :realtime :tuple)]
   (for i 0 1000
     (sql/eval db `SELECT * FROM customers;`))
   (let [[_ end] (os/clock :realtime :tuple)]
     (/ (/ (- end start) 1e6) 1000))))

(defn main [&]
  (def db (sql/open "test.db"))
  (pp (sql/eval db `SELECT * FROM customers;`)))
