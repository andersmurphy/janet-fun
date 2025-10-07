(import sqlite3)

(def compile-env (curenv))

(defn conn! []
  (sqlite3/open "database.db"))

(def q sqlite3/eval)

(defn make-stubbed-image [env]
  (let [modified-image-dict (table/setproto @{} make-image-dict)]
    (merge-into modified-image-dict
                {sqlite3/allow-loading-extensions 'sqlite3/stub
                 sqlite3/close                    'sqlite3/stub
                 sqlite3/error-code               'sqlite3/stub
                 sqlite3/eval                     'sqlite3/stub
                 sqlite3/last-insert-rowid        'sqlite3/stub
                 sqlite3/load-extension           'sqlite3/stub
                 sqlite3/open                     'sqlite3/stub})
    (marshal env modified-image-dict)))

(defn q-env [query]
  (let [data (-> (q (conn!) (string `select data from image ` query))
                 first
                 (get :data))]
    (if data (load-image data) @{})))

(defn load-last-env []
    (merge-into
     # compiled image functions have priority over loaded image functions
     # meaning they cannot be modified
     (q-env `order by id desc limit 1`)
     compile-env))

(defn save-env! [env]
  (let [id (-> (q (conn!) `select id from image order by id desc limit 1`)
               first (get :id 0) inc)]
    (q (conn!) `insert into image values(:id, :data)`
       {:id id :data (make-stubbed-image env)})))

(defn main [&]
  (q (conn!) `create table if not exists image(id INTEGER PRIMARY KEY, data BLOB)`)
  (repl nil nil (load-last-env)))

(comment
 # proto env? root env 
 
 (foobar)
 
 (defn foobar []
   (printf "foo"))

 # save env to db
 (save-env! (curenv))

 # remove a definition from env
 (set ((curenv) 'foobar) nil)

 (q (conn!) `select id from image order by id desc`)

 (repl nil nil
       (merge-into (q-env `where id = 1 limit 1`) (curenv)))
 
 # can be used to (quit) nested repls
 (quit)

 # pretty print
 (printf "%M" (curenv))
 (printf "%P" (curenv))
 (printf "%M" make-image-dict))
