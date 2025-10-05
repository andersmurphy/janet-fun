(import sqlite3 :as sql)

(defn conn! []
  (sql/open "database.db"))

(def q sql/eval)

(comment
 (q (conn!) `CREATE TABLE customers(id INTEGER PRIMARY KEY, name TEXT);`)
 (q (conn!) `SELECT * FROM customers;`)

 # pretty print
 (printf "%M" (curenv))
 (printf "%P" (curenv))

 )

(def env (curenv))

(defn main [&]
  (repl nil nil env))

(comment
 (make-image (curenv)))
