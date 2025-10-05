(import sqlite3 :as sql)

(def db (sql/open "test.db"))

(sql/eval db `CREATE TABLE customers(id INTEGER PRIMARY KEY, name TEXT);`)

(for i 0 1000
  (sql/eval db `INSERT INTO customers VALUES(:id, :name);` {:name "John" :id i}))

(sql/eval db `SELECT * FROM customers;`)

(doc printf)
(doc pp)

(doc sql/eval)

(let [[_ start] (os/clock :realtime :tuple)]
  (for i 0 1000
    (sql/eval db `SELECT * FROM customers limit 1;`))
  (let [[_ end] (os/clock :realtime :tuple)]
    (/ (/ (- end start) 1e3) 1000)))
