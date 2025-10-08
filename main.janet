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
    (if data (load-image data) (make-env compile-env))))

(defn load-last-env []
  (merge-into
   # Compiled image functions have priority over loaded image functions
   # meaning they cannot be modified.
   (q-env `order by id desc limit 1`)
   compile-env))

(defn save-env! [env]
  (let [id (-> (q (conn!) `select id from image order by id desc limit 1`)
               first (get :id 0) inc)]
    (q (conn!) `insert into image values(:id, :data)`
       {:id id :data (make-stubbed-image env)})))

(defn repl-handler [stream]
  (defer (net/close stream)
    (def out-b @"")
    (def result-fiber
      (fiber/new
       (fn []
         (forever
          (net/write stream out-b)
          (buffer/clear out-b)
          (yield)))))
    (with-dyns [*out* out-b
                *err* out-b]
      (repl (fn [buf p]
              (resume result-fiber)
              (net/write stream
                         (string
                          "repl:"
                          ((parser/where p) 0)
                          ":"
                          (parser/state p :delimiters) "> "))
              (net/read stream 1024 buf))
            nil
            (load-last-env)))))

(defn main [&]
  (q (conn!) `create table if not exists image(id INTEGER PRIMARY KEY, data BLOB)`)
  (setdyn *redef* true) # Allows dynamically rebinding defs (perf cost).
  (net/server "127.0.0.1" "7650" repl-handler))

(comment
 # sqlite connection pool
 # zstandard bindings

 (defn foo [x]
   (inc x))

 (foo 3)

 (defn bar []
   (foo 3))

 (bar)

 (defn foo [x]
   (dec x))

 (bar)

 (def fiber-test
   (fiber/new (fn []
                (yield 1)
                (yield 2)
                (yield 3)
                (yield 4)
                5)))

 (resume fiber-test)

 # save env to db
 (save-env! (curenv))

 # remove a definition from env
 (set ((curenv) 'foobar) nil)
 (set ((curenv) 'fiber-test) nil)

 (q (conn!) `select id from image order by id desc`)

 (repl nil nil (curenv))
 # can be used to (quit) nested repls
 (quit)

 # nc localhost 7650

 # pretty print
 (printf "%M" (curenv))
 (printf "%P" (curenv))
 (printf "%M" make-image-dict))
