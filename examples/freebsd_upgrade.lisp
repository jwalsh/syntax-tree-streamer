;; Baseline: "Voulant améliorer mon flux de travail, je souhaite installer Emacs 31.0..."
(S :id "freebsd-upgrade" :metadata {:complete true}
  (PARTCL :metadata {:rhetorical-role :motivation}
    (V "Voulant" :metadata {:features (PART PRES)})
    (V "améliorer" :metadata {:features (INF)})
    (NP
      (DET "mon" :metadata {:gender :masc :number :sing :person 1 :possessive true})
      (N "flux" :metadata {:domain :technical})
      (PP
        (P "de")
        (N "travail" :metadata {:domain :activity})
      )
    )
    (PUNCT ",")
  )
  
  (NP :metadata {:semantic-role :agent}
    (PRON "je" :metadata {:person 1 :number :sing})
  )
  
  (VP
    (V "souhaite" :metadata {:person 1 :number :sing :tense :present})
    (V "installer" :metadata {:features (INF)})
    
    (NP :metadata {:tech-entity true}
      (N "Emacs" :metadata {:proper-noun true :software true})
      (NUM "31.0" :metadata {:version true})
      
      (RELCL
        (REL "qui" :metadata {:antecedent "Emacs"})
        (V "est" :metadata {:person 3 :number :sing :tense :present})
        (ADJ "réputé")
        
        (PP
          (P "pour")
          (NP
            (DET "sa" :metadata {:gender :fem :number :sing :person 3 :possessive true})
            (N "stabilité")
          )
        )
      )
    )
    
    (ADV "demain" :metadata {:temporal true})
    
    (PP
      (P "après")
      
      (INFCL
        (V "avoir" :metadata {:features (AUX INF)})
        (V "terminé" :metadata {:features (PAST PART)})
        
        (NP
          (DET "l'" :metadata {:definite true})
          (N "installation" :metadata {:domain :computing})
          
          (PP
            (P "des")
            (NP
              (N "ports/schemesh" :metadata {:tech-term true})
              
              (RELCL
                (REL "dont" :metadata {:relation :genitive})
                (NP
                  (PRON "j'" :metadata {:person 1 :number :sing})
                )
                (V "ai" :metadata {:person 1 :number :sing :tense :present})
                (N "besoin")
                
                (PP
                  (P "pour")
                  (NP
                    (DET "mes" :metadata {:person 1 :number :plur :possessive true})
                    (N "projets")
                  )
                )
              )
            )
          )
        )
      )
    )
  )
  
  (CONJ "mais" :metadata {:adversative true})
  
  (ADVP
    (ADV "pas" :metadata {:negation true})
    
    (PP
      (P "avant")
      
      (SUBCL
        (SUB "que")
        (NP
          (PRON "je" :metadata {:person 1 :number :sing})
        )
        (PART "ne" :metadata {:expletive true})
        (V "récupère" :metadata {:person 1 :number :sing :tense :present :mood :subjunctive})
        
        (NP
          (DET "les" :metadata {:definite true :number :plur})
          (N "ports" :metadata {:domain :computing})
          (N "FreeBSD" :metadata {:proper-noun true})
        )
      )
    )
  )
  
  (SUBCL
    (SUB "bien que" :metadata {:concessive true})
    (NP
      (PRON "je" :metadata {:person 1 :number :sing})
    )
    (V "craigne" :metadata {:person 1 :number :sing :tense :present :mood :subjunctive})
    
    (NOMCL
      (SUB "que")
      (NP
        (DET "cette" :metadata {:demonstrative true})
        (N "séquence")
        
        (PP
          (P "d'" :metadata {:elision true})
          (N "opérations" :metadata {:number :plur})
        )
      )
      (PART "ne" :metadata {:expletive true})
      (V "prenne" :metadata {:person 3 :number :sing :tense :present :mood :subjunctive})
      
      (ADVP
        (ADV "plus")
        (P "de")
        (N "temps")
        (SUB "que")
        (V "prévu" :metadata {:features (PAST PART)})
      )
    )
  )
  
  (PUNCT ".")
)
