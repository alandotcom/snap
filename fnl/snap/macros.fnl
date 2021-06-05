(fn safefn [name ...]
  `(local ,name (vim.schedule_wrap (fn ,...))))

(fn assertfunction [value msg]
  `(assert (= (type ,value) :function) ,msg))

(fn assertfunction? [value msg]
  `(when ,value (assertfunction ,value ,msg)))

(fn asserttable [value msg]
  `(assert (= (type ,value) :table) ,msg))

(fn asserttable? [value msg]
  `(when ,value (asserttable ,value ,msg)))

(fn assertstring [value msg]
  `(assert (= (type ,value) :string) ,msg))

(fn assertstring? [value msg]
  `(when ,value (assertstring ,value ,msg)))

(fn assertmetatable [value metatable msg]
  `(assert (= (getmetatable ,value) metatable) ,msg))

{: safefn
 : assertfunction
 : assertfunction?
 : asserttable
 : asserttable?
 : assertstring
 : assertstring?
 : assertmetatable}