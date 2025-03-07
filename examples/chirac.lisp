;; Chirac: "Notre maison brûle et nous regardons ailleurs."
(S :id "chirac-1" :metadata {:complete true}
  (S :metadata {:clause-type :main}
    (NP :metadata {:semantic-role :subject}
      (DET "Notre" :metadata {:possessive true :person 1 :number :plur})
      (N "maison" :metadata {:gender :fem :number :sing})
    )
    (VP
      (V "brûle" :metadata {:person 3 :number :sing :tense :present})
    )
  )
  (CONJ "et" :metadata {:coordination true})
  (S :metadata {:clause-type :main}
    (NP :metadata {:semantic-role :subject}
      (PRON "nous" :metadata {:person 1 :number :plur})
    )
    (VP
      (V "regardons" :metadata {:person 1 :number :plur :tense :present})
      (ADV "ailleurs" :metadata {:spatial true})
    )
  )
  (PUNCT ".")
)
