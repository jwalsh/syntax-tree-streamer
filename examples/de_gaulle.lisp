;; De Gaulle: "La France ne peut être la France sans la grandeur."
(S :id "de-gaulle-1" :metadata {:complete true}
  (NP :metadata {:semantic-role :subject}
    (DET "La" :metadata {:gender :fem :number :sing :definite true})
    (N "France" :metadata {:proper-noun true :country true})
  )
  (VP
    (V "peut" :metadata {:person 3 :number :sing :tense :present :negation true})
    (ADV "ne" :metadata {:negation true})
    (V "être" :metadata {:features (INF)})
    (NP
      (DET "la" :metadata {:gender :fem :number :sing :definite true})
      (N "France" :metadata {:proper-noun true :country true})
    )
    (PP
      (P "sans" :metadata {:negation true})
      (NP
        (DET "la" :metadata {:gender :fem :number :sing :definite true})
        (N "grandeur" :metadata {:abstractness 0.9})
      )
    )
  )
  (PUNCT ".")
)
