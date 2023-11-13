(deffunction foo (?a ?b ?c)
    (println ?c)
    (+ ?a ?b))

(deftemplate bar
    (slot a)
    (slot b))

(deffunction assert-bar (?a ?b)
    (println ?a " " ?b)
    (assert (bar (a ?a) (b ?b))))
