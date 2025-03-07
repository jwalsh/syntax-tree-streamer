(S :id "sent-42" :metadata {:stream-position 0 :complete true}
  (PARTCL :metadata {:line-start true :rhetorical-role :motivation}
    (V "Voulant" :metadata {:lemma "vouloir" :features (PART PRES)})
    (V "améliorer" :metadata {:features (INF)})
    (NP :metadata {:semantic-role :theme}
      (DET "mon" :metadata {:gender :masc :number :sing :person 1})
      (N "flux" :metadata {:domain :technical})
      (PP :metadata {:relation :attributive}
        (P "de")
        (N "travail" :metadata {:domain :activity})
      )
    )
  )
  
  (PUNCT ",")
  
  (NP :metadata {:semantic-role :agent}
    (PRON "je" :metadata {:person 1 :number :sing})
  )
  
  (VP :metadata {:core-predicate true}
    (V "souhaite" :metadata {:lemma "souhaiter" :features (INDIC PRES) :valence 2})
    (V "installer" :metadata {:features (INF)})
    
    (NP :metadata {:tech-entity true}
      (N "Emacs" :metadata {:entity-type :software :domain :computing})
      (NUM "31.0" :metadata {:version {:major 31 :minor 0}})
      
      (RELCL :metadata {:restrictive false}
        (REL "qui" :metadata {:antecedent "Emacs"})
        (V "est" :metadata {:features (INDIC PRES)})
        (ADJ "réputé")
        
        (PP
          (P "pour")
          (NP
            (DET "sa" :metadata {:gender :fem :number :sing :person 3 :possessive true})
            (N "stabilité" :metadata {:abstractness 0.8})
          )
        )
      )
    )
    
    (ADV "demain" :metadata {:temporal-type :future :specificity :day})
    
    (PP :metadata {:temporal true}
      (P "après" :metadata {:temporal-relation :posterior})
      
      (INFCL
        (V "avoir" :metadata {:features (AUX INF)})
        (V "terminé" :metadata {:features (PAST PART) :aspect :perfective})
        
        (NP
          (DET "l'")
          (N "installation" :metadata {:domain :computing :process true})
          
          (PP
            (P "des" :metadata {:contraction true})
            (N "ports/schemesh" :metadata {:tech-term true :compound true})
            
            (RELCL
              (REL "dont" :metadata {:relation :genitive})
              (NP
                (PRON "j'" :metadata {:elision true})
              )
              (V "ai" :metadata {:features (INDIC PRES)})
              (N "besoin" :metadata {:idiom :avoir-besoin})
              
              (PP
                (P "pour" :metadata {:purpose true})
                (NP
                  (DET "mes" :metadata {:number :plur :person 1 :possessive true})
                  (N "projets" :metadata {:abstractness 0.5})
                )
              )
            )
          )
        )
      )
    )
  )
  
  (CONJ "mais" :metadata {:relation :adversative})
  
  (ADVP
    (ADV "pas" :metadata {:negation true})
    
    (PP
      (P "avant" :metadata {:temporal-relation :anterior})
      
      (SUBCL :metadata {:mode :subjunctive}
        (SUB "que")
        (NP
          (PRON "je")
        )
        (PART "ne" :metadata {:expletive true :negation false})
        (V "récupère" :metadata {:features (SUBJ PRES)})
        
        (NP :metadata {:tech-entity true}
          (DET "les")
          (N "ports" :metadata {:domain :computing :tech-term true})
          (N "FreeBSD" :metadata {:proper-noun true :entity-type :software})
        )
      )
    )
  )
  
  (SUBCL :metadata {:mode :subjunctive :concessive true}
    (SUB "bien que" :metadata {:multi-word true})
    (NP
      (PRON "je")
    )
    (V "craigne" :metadata {:lemma "craindre" :features (SUBJ PRES) :semantic-class :apprehension})
    
    (NOMCL
      (SUB "que")
      (NP :metadata {:discourse-status :new}
        (DET "cette" :metadata {:demonstrative true})
        (N "séquence")
        
        (PP
          (P "d'" :metadata {:elision true})
          (N "opérations" :metadata {:number :plur})
        )
      )
      (PART "ne" :metadata {:expletive true :negation false})
      (V "prenne" :metadata {:features (SUBJ PRES)})
      
      (ADVP :metadata {:comparative true}
        (ADV "plus" :metadata {:quantity true})
        (P "de")
        (N "temps" :metadata {:abstractness 0.7 :measurable true})
        (SUB "que" :metadata {:comparative true})
        (V "prévu" :metadata {:features (PAST PART) :ellipsis true})
      )
    )
  )
  
  (PUNCT ".")
)
