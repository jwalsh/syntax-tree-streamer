;; Macron: "Je ne céderai rien, ni aux fainéants, ni aux cyniques, ni aux extrêmes."
(S :id "macron-1" :metadata {:complete true}
  (NP :metadata {:semantic-role :subject}
    (PRON "Je" :metadata {:person 1 :number :sing})
  )
  (VP
    (ADV "ne" :metadata {:negation true})
    (V "céderai" :metadata {:person 1 :number :sing :tense :future})
    (PRON "rien" :metadata {:indefinite true :negation true})
    (PUNCT ",")
    (CONJ "ni" :metadata {:coordination true :negation true})
    (PP
      (P "aux" :metadata {:contraction true})
      (NP
        (N "fainéants" :metadata {:number :plur :pejorative true})
      )
    )
    (PUNCT ",")
    (CONJ "ni" :metadata {:coordination true :negation true})
    (PP
      (P "aux" :metadata {:contraction true})
      (NP
        (N "cyniques" :metadata {:number :plur})
      )
    )
    (PUNCT ",")
    (CONJ "ni" :metadata {:coordination true :negation true})
    (PP
      (P "aux" :metadata {:contraction true})
      (NP
        (N "extrêmes" :metadata {:number :plur :political true})
      )
    )
  )
  (PUNCT ".")
)
