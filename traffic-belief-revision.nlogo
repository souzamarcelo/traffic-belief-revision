breed [vehicles]

globals[
  experimentation?

  system-travel-time
  counter
  vehicles-ab
  vehicles-ad
  travel-time-mean-count
  vehicles-ad-mean-count

  private-false
  private-true
  professional-false
  professional-true
  authorities-false
  authorities-true

  private-trust
  professional-trust
  authorities-trust

  private-false-dangerous
  private-true-dangerous
  professional-false-dangerous
  professional-true-dangerous
  authorities-false-dangerous
  authorities-true-dangerous

  private-trust-dangerous
  professional-trust-dangerous
  authorities-trust-dangerous

  total-abjam
  total-abfree
  total-adjam
  total-adfree

  total-dangerous
  total-not-dangerous

  belief-ab
  disbelief-ab
  uncertainty-ab
  base-rate-ab
  belief-ad
  disbelief-ad
  uncertainty-ad
  base-rate-ad

  belief-dangerous
  disbelief-dangerous
  uncertainty-dangerous
  base-rate-dangerous

]

vehicles-own [
  category
  path-last-iteration
  discomfort

  agent-communicate?
  agent-malicious?
  agent-communicate-dangerous?
  agent-malicious-dangerous?

  information-ab
  information-ad
  received-ab
  received-ad

  information-dangerous

  b-ab
  d-ab
  u-ab
  a-ab

  b-ad
  d-ad
  u-ad
  a-ad

  b-dangerous
  d-dangerous
  u-dangerous
  a-dangerous

  confidence-ab
  confidence-ad
]

to setup
  clear-all
  reset-ticks
  set counter 1
  start-vehicles

  set travel-time-mean-count 0
  set vehicles-ad-mean-count 0
  set experimentation? false
end
;; ==============================================================================================================

to go
  tick

  if not experimentation? [
    set travel-time-mean ""
    set vehicles-ad-mean ""
  ]

  let total-travel-time 0
  let ab-sum 0
  let ad-sum 0

  ask vehicles [
    ifelse get-path-choice = "AB" [
      set path-last-iteration "AB"
      set ab-sum ab-sum + 1
    ][
    set path-last-iteration "AD"
    set ad-sum ad-sum + 1
    ]
  ]

  set vehicles-ab ab-sum
  set vehicles-ad ad-sum

  let time-ab ((calculate-travel-time "AB" ab-sum) + (calculate-travel-time "BC" ab-sum))
  let time-ad ((calculate-travel-time "AD" ad-sum) + (calculate-travel-time "DC" ad-sum))

  set total-travel-time (total-travel-time + time-ab + time-ad)
  set system-travel-time (total-travel-time / 2)

  set travel-time-mean-count (travel-time-mean-count + system-travel-time)
  set vehicles-ad-mean-count (vehicles-ad-mean-count + vehicles-ad)

  if communication? [
    perform-communication
    perform-reception
    ;show-beliefs-mean
  ]

  if communication-dangerous? [
    ;show-discomfort-mean
    perform-communication-dangerous
    perform-reception-dangerous
  ]

  set counter counter + 1
  if counter > iterations [
    set travel-time-mean-count (travel-time-mean-count / iterations)
    set vehicles-ad-mean-count (vehicles-ad-mean-count / iterations)

    if not experimentation? [
      set travel-time-mean word "" travel-time-mean-count
      set vehicles-ad-mean word "" vehicles-ad-mean-count
    ]

    stop
  ]

  ;show-confidence-ab-mean
  ;show ((vehicles-ad * 100) / (private-drivers + professional-drivers + authorities-drivers))
  ;show "--"
  ;show-discomfort-mean
end
;; ==============================================================================================================

to show-confidence-ab-mean
  ;let soma 0
  ;ask vehicles [
  ;  set soma soma + confidence-ab
  ;]
  ;set soma soma / 300
  ;show word "AB: " soma

  let soma 0
  ask vehicles [
    set soma soma + confidence-ad
  ]
  set soma soma / 300
  show word "AD: " soma
end

to start-vehicles
  create-vehicles (private-drivers + professional-drivers + authorities-drivers)

  let index 0

  let private private-drivers
  let professional (private-drivers + professional-drivers)

  ask vehicles [
    set hidden? true
    set received-ab 0.5
    set received-ad 0.5

    set agent-communicate? false
    set agent-communicate-dangerous? false

    initialize-discomfort

    ifelse index < private [
      set category "private"
    ][
    ifelse index < professional[
      set category "professional"
    ][
    set category "authorities"
    ]
    ]

    set private-true 0
    set private-false 0
    set professional-true 0
    set professional-false 0
    set authorities-true 0
    set authorities-false 0

    set index index + 1
  ]

  set-vehicles-communicate
  set-vehicles-malicious

  set-subjective-logic-values

  if communication-dangerous? [
    set-vehicles-communicate-dangerous
    set-vehicles-malicious-dangerous
  ]
end
;; ==============================================================================================================

to set-subjective-logic-values
  set belief-ab 0
  set disbelief-ab 0
  set uncertainty-ab 1
  set base-rate-ab 0.5

  set belief-ad 0
  set disbelief-ad 0
  set uncertainty-ad 1
  set base-rate-ad 0.5

  ask vehicles [
    set confidence-ab 0.5
    set confidence-ad 0.5
  ]
end
;; ==============================================================================================================

to initialize-discomfort
  ifelse discomfort? [
    set discomfort (random-normal discomfort-mean discomfort-deviation)
    if discomfort > 1 [set discomfort 1]
    if discomfort < 0 [set discomfort 0]

  ][
  set discomfort 0
  ]
end
;; ==============================================================================================================

to set-vehicles-communicate
  let total-vehicles (private-drivers + professional-drivers + authorities-drivers)
  let amount-communicate ((total-vehicles * percent-vehicles-communicate) / 100)
  let amount-applied 0

  while [amount-applied < amount-communicate] [
    ask one-of vehicles[
      if not agent-communicate? [
        set agent-communicate? true
        set amount-applied (amount-applied + 1)
      ]
    ]
  ]
end
;; ==============================================================================================================

to set-vehicles-malicious

  ifelse not malicious? [
    ask vehicles [
      set agent-malicious? false
    ]
  ][

  let privatecomm 0
  let professionalcomm 0
  let authoritiescomm 0

  ask vehicles [
    if category = "private" [
      if agent-communicate? [
        set privatecomm privatecomm + 1
      ]
    ]

    if category = "professional" [
      if agent-communicate? [
        set professionalcomm professionalcomm + 1
      ]
    ]

    if category = "authorities" [
      if agent-communicate? [
        set authoritiescomm authoritiescomm + 1
      ]
    ]
  ]

  let amount-private-malicious ((privatecomm * percent-private-malicious) / 100)
  let amount-professional-malicious ((professionalcomm * percent-professional-malicious) / 100)
  let amount-authorities-malicious ((authoritiescomm * percent-authorities-malicious) / 100)

  let amount-private-applied 0
  let amount-professional-applied 0
  let amount-authorities-applied 0

  ask vehicles [
    if category = "private"[
      ifelse amount-private-applied < amount-private-malicious [
        ifelse agent-communicate?[
          set agent-malicious? true
          set amount-private-applied (amount-private-applied + 1)
        ][
        set agent-malicious? false
        ]
      ][
      set agent-malicious? false
      ]
    ]

    if category = "professional"[
      ifelse amount-professional-applied < amount-professional-malicious [
        ifelse agent-communicate?[
          set agent-malicious? true
          set amount-professional-applied (amount-professional-applied + 1)
        ][
        set agent-malicious? false
        ]
      ][
      set agent-malicious? false
      ]
    ]

    if category = "authorities"[
      ifelse amount-authorities-applied < amount-authorities-malicious [
        ifelse agent-communicate? [
          set agent-malicious? true
          set amount-authorities-applied (amount-authorities-applied + 1)
        ][
        set agent-malicious? false
        ]
      ][
      set agent-malicious? false
      ]
    ]
  ]
  ]
end
;; ==============================================================================================================

to set-vehicles-communicate-dangerous
  let total-vehicles (private-drivers + professional-drivers + authorities-drivers)
  let amount-communicate ((total-vehicles * percent-vehicles-communicate) / 100)
  let amount-applied 0

  while [amount-applied < amount-communicate] [
    ask one-of vehicles[
      if not agent-communicate-dangerous?[
        set agent-communicate-dangerous? true
        set amount-applied (amount-applied + 1)
      ]
    ]
  ]
end
;; ==============================================================================================================

to set-vehicles-malicious-dangerous

  ifelse malicious-dangerous? [
    let privatecomm 0
    let professionalcomm 0
    let authoritiescomm 0

    ask vehicles [
      if category = "private" [
        if agent-communicate-dangerous? [
          set privatecomm privatecomm + 1
        ]
      ]

      if category = "professional" [
        if agent-communicate-dangerous? [
          set professionalcomm professionalcomm + 1
        ]
      ]

      if category = "authorities" [
        if agent-communicate-dangerous? [
          set authoritiescomm authoritiescomm + 1
        ]
      ]
    ]

    let amount-private-malicious ((privatecomm * percent-private-malicious) / 100)
    let amount-professional-malicious ((professionalcomm * percent-professional-malicious) / 100)
    let amount-authorities-malicious ((authoritiescomm * percent-authorities-malicious) / 100)

    let amount-private-applied 0
    let amount-professional-applied 0
    let amount-authorities-applied 0

    ask vehicles [
      if category = "private"[
        ifelse amount-private-applied < amount-private-malicious [
          ifelse agent-communicate-dangerous?[
            set agent-malicious-dangerous? true
            set amount-private-applied (amount-private-applied + 1)
          ][
          set agent-malicious-dangerous? false
          ]
        ][
        set agent-malicious-dangerous? false
        ]
      ]

      if category = "professional"[
        ifelse amount-professional-applied < amount-professional-malicious [
          ifelse agent-communicate-dangerous?[
            set agent-malicious-dangerous? true
            set amount-professional-applied (amount-professional-applied + 1)
          ][
          set agent-malicious-dangerous? false
          ]
        ][
        set agent-malicious-dangerous? false
        ]
      ]

      if category = "authorities"[
        ifelse amount-authorities-applied < amount-authorities-malicious [
          ifelse agent-communicate-dangerous? [
            set agent-malicious-dangerous? true
            set amount-authorities-applied (amount-authorities-applied + 1)
          ][
          set agent-malicious-dangerous? false
          ]
        ][
        set agent-malicious-dangerous? false
        ]
      ]
    ]
  ][
    ask vehicles [
      set agent-malicious-dangerous? false
    ]
  ]
end
;; ==============================================================================================================

to-report calculate-travel-time [path volume]
  ;; t = t0 * [1 + alpha * (V/C)^beta]
  if path = "AB" [
    report (7 * (1 + (alpha * (((volume + ab-volume) / 10000) ^ beta))))
  ]
  if path = "BC" [
    report (4 * (1 + (alpha * (((volume + bc-volume) / 10000) ^ beta))))
  ]
  if path = "AD" [
    report (7 * (1 + (alpha * (((volume + ad-volume) / 3000) ^ beta))))
  ]
  if path = "DC" [
    report (4 * (1 + (alpha * (((volume + dc-volume) / 3000) ^ beta))))
  ]
end
;; ==============================================================================================================

to-report get-path-choice

  ;show word word received-ab "/" received-ad

  if complete-vision? [
    set received-ab 0
    set received-ad 1
  ]

  if discomfort > 0.5 [
    report "AB"
  ]

  if received-ab = 1 and received-ad = 1 and discomfort < 0.5 [report get-random-path]
  if received-ab = 1 and received-ad < 1 and discomfort < 0.5 [report "AB"]
  if received-ab = 0.5 and received-ad = 1 and discomfort < 0.5 [report "AD"]
  if received-ab = 0.5 and received-ad = 0.5 and discomfort < 0.5 [report get-random-path]
  if received-ab = 0.5 and received-ad = 0 and discomfort < 0.5 [report "AB"]
  if received-ab = 0 and received-ad = 1 and discomfort < 0.5 [report "AD"]
  if received-ab = 0 and received-ad = 0.5 and discomfort < 0.5 [report "AD"]
  if received-ab = 0 and received-ad = 0 and discomfort < 0.5 [report get-random-path]

  if received-ab = 0 and discomfort = 0.5 [report get-random-path]
  if received-ab > 0 and discomfort = 0.5 [report "AB"]

  if discomfort = 0 [
    if received-ab > received-ad [report "AB"]
    if received-ad > received-ab [report "AD"]
  ]

  report get-random-path

  ;if (not communication?) and (not discomfort?) and (not complete-vision?) [
  ;  report get-random-path
  ;]

  ;let situation-ab received-ab
  ;let situation-ad received-ad

  ;if complete-vision? [
  ;  set situation-ab 0
  ;  set situation-ad 1
  ;]

  ;let utility-ab (get-utility-ab situation-ab)
  ;let utility-ad (get-utility-ad situation-ab situation-ad discomfort)

  ;if not (is-different? utility-ab utility-ad)[
  ;  report get-random-path
  ;]

  ;ifelse utility-ab > utility-ad [report "AB"][
  ;  ifelse utility-ad > utility-ab [report "AD"][
  ;    report get-random-path
  ;  ]
  ;]
end
;; ==============================================================================================================

to-report get-utility-ab[situation-ab]
  report (situation-ab)
end
;; ==============================================================================================================

to-report get-utility-ad [situation-ab situation-ad discomfort-ad]

  if (situation-ab = situation-ad)[
    if (situation-ab = 0) [
      ifelse (discomfort-ad > 0.5) [
        report -1
      ][
        report 0
      ]
    ]

    if (situation-ab = 0.5) [
      ifelse (discomfort-ad > 0.5) [
        report -1
      ][
        report 0.5
      ]
    ]

    if (situation-ab = 1) [
      ifelse (discomfort-ad > 0.5) [
        report -1
      ][
        report 0.5
      ]
    ]
  ]

  if (situation-ab > situation-ad) [
    if (situation-ab = 1) [ report -1]
    if (situation-ab = 0.5) [
      ifelse (discomfort-ad = 0) [report 0.5] [report -1]
    ]
  ]

  if (situation-ad > situation-ab) [
    if (situation-ad = 1 and situation-ab = 0)[
      ifelse (discomfort-ad > 0.5) [report 0] [report 1]
    ]

    if (situation-ad = 1 and situation-ab = 0.5)[
      ifelse (discomfort-ad > 0.5) [report 0.5] [report 1]
    ]

    if (situation-ad = 0.5)[
      ifelse (discomfort-ad > 0.5) [report 0] [report 1]
    ]
  ]

  report 0
end
;; ==============================================================================================================

to perform-communication-dangerous
  ask vehicles [
    set information-dangerous 0.5

    if agent-communicate-dangerous? [
      if path-last-iteration = "AD" [
        set information-dangerous 0
      ]

      if agent-malicious-dangerous? [
        ifelse path-last-iteration = "AD" [ set information-dangerous 1 ] [ set information-dangerous 0 ]
      ]
    ]
  ]
end
;; ==============================================================================================================

to perform-reception-dangerous
  one-collect-information-dangerous

  ifelse not operator? [
    ask vehicles [
      let choice ((random 100) + 1)
      if (choice < percent-vehicles-receive) or (percent-vehicles-receive = 100) [
        if total-dangerous > total-not-dangerous [
          set discomfort 1
        ]
        if total-dangerous < total-not-dangerous [
          set discomfort 0
        ]
      ]
    ]
  ][

    if operator = "ours" [
      two-aggregate-information-dangerous

      ask vehicles [
        let choice ((random 100) + 1)
        if (choice < percent-vehicles-receive) or (percent-vehicles-receive = 100) [
          ;aqui!!
          ;set discomfort belief-dangerous
          set discomfort (belief-dangerous + (base-rate-dangerous * uncertainty-dangerous))
        ]
      ]
    ]

    if operator = "pereira" [
      pereira-model-dangerous
    ]
  ]
end
;; ==============================================================================================================

to perform-reception
  one-collect-information

  if (operator = "ours") or (not operator?)[
    two-aggregate-information

    ask vehicles [

      let info-ab 0.5
      let info-ad 0.5

      let choice ((random 100) + 1)
      ifelse (choice < percent-vehicles-receive) or (percent-vehicles-receive = 100) [

        ifelse not operator? [

          if (total-abjam > total-abfree) [set info-ab 0]
          if (total-abjam < total-abfree)  [set info-ab 1]

          if (total-adjam > total-adfree) [set info-ad 0]
          if (total-adjam < total-adfree) [set info-ad 1]

        ][

        let ab1 (belief-ab + uncertainty-ab * confidence-ab)
        let ab0 (disbelief-ab + uncertainty-ab * confidence-ab)
        let ad1 (belief-ad + uncertainty-ad * confidence-ad)
        let ad0 (disbelief-ad + uncertainty-ad * confidence-ad)

        ;ifelse belief-ab > disbelief-ab [
        ifelse ab1 > ab0 [
          set info-ab 1
        ][
          set info-ab 0
        ]

        ;ifelse belief-ad > disbelief-ad [
        ifelse ad1 > ad0 [
          set info-ad 1
        ][
          set info-ad 0
        ]

        set confidence-ab (ab1 / (ab1 + ab0))
        set confidence-ad (ad1 / (ad1 + ad0))

        ]
      ][

        ifelse not operator? [
          ;ifelse path-last-iteration = "AB"[
          ;  set info-ab 1
          ;  set info-ad 0
          ;][
          ;  set info-ab 0
          ;  set info-ad 1
          ;]
          set info-ab received-ab
          set info-ad received-ad
        ][
          if confidence-ab > 0.5 [set info-ab 1]
          if confidence-ab < 0.5 [set info-ab 0]
          if confidence-ab = 0.5 [set info-ab 0.5]
          if confidence-ad > 0.5 [set info-ad 1]
          if confidence-ad < 0.5 [set info-ad 0]
          if confidence-ad = 0.5 [set info-ad 0.5]
        ]
      ]

      set received-ab info-ab
      set received-ad info-ad
    ]

  ]

  if operator = "pereira" [
    pereira-model
  ]

  ;ask vehicles [
  ;  if agent-malicious? [
  ;    set received-ab 0
  ;    set received-ad 1
  ;  ]
  ;]

end
;; ==============================================================================================================

to pereira-model
  let ab-jam 0
  let ab-free 0
  let ad-jam 0
  let ad-free 0

  ask vehicles [
    if agent-communicate? [
      if information-ab = 1 [
        if category = "private" [
          if private-trust > ab-free [set ab-free private-trust]
        ]
        if category = "professional" [
          if professional-trust > ab-free [set ab-free professional-trust]
        ]
        if category = "authorities" [
          if authorities-trust > ab-free [set ab-free authorities-trust]
        ]
      ]
      if information-ab = 0 [
        if category = "private" [
          if private-trust > ab-jam [set ab-jam private-trust]
        ]
        if category = "professional" [
          if professional-trust > ab-jam [set ab-jam professional-trust]
        ]
        if category = "authorities" [
          if authorities-trust > ab-jam [set ab-jam authorities-trust]
        ]
      ]
      if information-ad = 1 [
        if category = "private" [
          if private-trust > ad-free [set ad-free private-trust]
        ]
        if category = "professional" [
          if professional-trust > ad-free [set ad-free professional-trust]
        ]
        if category = "authorities" [
          if authorities-trust > ad-free [set ad-free authorities-trust]
        ]
      ]
      if information-ad = 0 [
        if category = "private" [
          if private-trust > ad-jam [set ad-jam private-trust]
        ]
        if category = "professional" [
          if professional-trust > ad-jam [set ad-jam professional-trust]
        ]
        if category = "authorities" [
          if authorities-trust > ad-jam [set ad-jam authorities-trust]
        ]
      ]
    ]
  ]

  eq7-pereira-model ab-jam ab-free ad-jam ad-free
end
;; ==============================================================================================================

to pereira-model-dangerous
  let dangerous 0
  let not-dangerous 0

  ask vehicles [
    if agent-communicate-dangerous? [

      if information-dangerous = 1 [
        if category = "private"[
          if private-trust-dangerous > dangerous [set dangerous private-trust-dangerous]
        ]
        if category = "professional"[
          if professional-trust-dangerous > dangerous [set dangerous professional-trust-dangerous]
        ]
        if category = "authorities"[
          if authorities-trust-dangerous > dangerous [set dangerous authorities-trust-dangerous]
        ]
      ]

      if information-dangerous = 0 [
        if category = "private"[
          if private-trust-dangerous > not-dangerous [set not-dangerous private-trust-dangerous]
        ]
        if category = "professional"[
          if professional-trust-dangerous > not-dangerous [set not-dangerous professional-trust-dangerous]
        ]
        if category = "authorities"[
          if authorities-trust-dangerous > not-dangerous [set not-dangerous authorities-trust-dangerous]
        ]
      ]
    ]
  ]

  eq7-pereira-model-dangerous dangerous not-dangerous
end
;; ==============================================================================================================

to eq7-pereira-model [ab0 ab1 ad0 ad1]
  let ab0-a ab0
  let ab1-a ab1
  let ad0-a ad0
  let ad1-a ad1

  let ab0-b ab1
  let ab1-b ab0
  let ad0-b ad1
  let ad1-b ad0

  let proceed true

  while [proceed] [

    set proceed false

    let mult-ab0 min (list ab0 (1 - ab0-b))
    let mult-ab1 min (list ab1 (1 - ab1-b))
    let mult-ad0 min (list ad0 (1 - ad0-b))
    let mult-ad1 min (list ad1 (1 - ad1-b))

    let ab0-result ((ab0-a / 2) + (mult-ab0 / 2))
    let ab1-result ((ab1-a / 2) + (mult-ab1 / 2))
    let ad0-result ((ad0-a / 2) + (mult-ad0 / 2))
    let ad1-result ((ad1-a / 2) + (mult-ad1 / 2))

    if not (ab0-result = ab0-a) [set proceed true]
    if not (ab1-result = ab1-a) [set proceed true]
    if not (ad0-result = ad0-a) [set proceed true]
    if not (ad1-result = ad1-a) [set proceed true]

    set ab0-a ab0-result
    set ab1-a ab1-result
    set ad0-a ad0-result
    set ad1-a ad1-result
  ]

  let situation-ab 0.5
  let situation-ad 0.5

  if is-different? ab0-a ab1-a [
    if ab0-a > ab1-a [set situation-ab 0]
    if ab0-a < ab1-a [set situation-ab 1]
  ]
  if is-different? ad0-a ad1-a [
    if ad0-a > ad1-a [set situation-ad 0]
    if ad0-a < ad1-a [set situation-ad 1]
  ]

  ask vehicles [
    ;set received-ab 0.5
    ;set received-ad 0.5

    let choice ((random 100) + 1)
    if (choice < percent-vehicles-receive) or (percent-vehicles-receive = 100) [
      set received-ab situation-ab
      set received-ad situation-ad
    ]
  ]

end
;; ==============================================================================================================

to eq7-pereira-model-dangerous [dan ndan]
  let dan-a dan
  let ndan-a ndan

  let dan-b ndan
  let ndan-b dan

  let proceed true

  while [proceed] [

    set proceed false

    let mult-dan min (list dan (1 - dan-b))
    let mult-ndan min (list ndan (1 - ndan-b))

    let dan-result ((dan-a / 2) + (mult-dan / 2))
    let ndan-result ((ndan-a / 2) + (mult-ndan / 2))

    if not (dan-result = dan-a) [set proceed true]
    if not (ndan-result = ndan-a) [set proceed true]

    set dan-a dan-result
    set ndan-a ndan-result
  ]


  ask vehicles [
    let choice ((random 100) + 1)
    if (choice < percent-vehicles-receive) or (percent-vehicles-receive = 100) [
      let dangerous discomfort
      if is-different? dan-a ndan-a [
        if dan-a > ndan-a [set dangerous 1]
        if dan-a < ndan-a [set dangerous 0]
      ]
      set discomfort dangerous
    ]
  ]
end
;; ==============================================================================================================

to one-collect-information-dangerous

  let dangerous-private 0
  let dangerous-professional 0
  let dangerous-authorities 0
  let not-dangerous-private 0
  let not-dangerous-professional 0
  let not-dangerous-authorities 0

  set total-dangerous 0
  set total-not-dangerous 0

  ask vehicles [
    let val 1
    if agent-malicious? [
      set val malicious-multiplier
    ]
    if category = "private" [
      if information-dangerous = 0 [set not-dangerous-private (not-dangerous-private + val)]
      if information-dangerous = 1 [set dangerous-private (dangerous-private + val)]
    ]

    if category = "professional" [
      if information-dangerous = 0 [set not-dangerous-professional (not-dangerous-professional + val)]
      if information-dangerous = 1 [set dangerous-professional (dangerous-professional + val)]
    ]

    if category = "authorities" [
      if information-dangerous = 0 [set not-dangerous-authorities (not-dangerous-authorities + val)]
      if information-dangerous = 1 [set dangerous-authorities (dangerous-authorities + val)]
    ]
  ]

  set total-dangerous (dangerous-private + dangerous-professional + dangerous-authorities)
  set total-not-dangerous (not-dangerous-private + not-dangerous-professional + not-dangerous-authorities)

  set private-true-dangerous (private-true-dangerous + not-dangerous-private)
  set private-false-dangerous (private-false-dangerous + dangerous-private)
  set professional-true-dangerous (professional-true-dangerous + not-dangerous-professional)
  set professional-false-dangerous (professional-false-dangerous + dangerous-professional)
  set authorities-true-dangerous (authorities-true-dangerous + not-dangerous-authorities)
  set authorities-false-dangerous (authorities-false-dangerous + dangerous-authorities)

  set private-trust-dangerous (source-trust private-true-dangerous private-false-dangerous)
  set professional-trust-dangerous (source-trust professional-true-dangerous professional-false-dangerous)
  set authorities-trust-dangerous (source-trust authorities-true-dangerous authorities-false-dangerous)

  ask vehicles [
    if agent-communicate-dangerous? [
      if information-dangerous = 1 [
        if category = "private" [set b-dangerous 1 * private-trust-dangerous]
        if category = "professional" [set b-dangerous 1 * professional-trust-dangerous]
        if category = "authorities" [set b-dangerous 1 * authorities-trust-dangerous]

        set d-ab 0
        set u-ab (1 - b-ab)
        set a-ab discomfort-mean
      ]

      if information-dangerous = 0 [
        if category = "private" [set d-dangerous 1 * private-trust-dangerous]
        if category = "professional" [set d-dangerous 1 * professional-trust-dangerous]
        if category = "authorities" [set d-dangerous 1 * authorities-trust-dangerous]

        set b-dangerous 0
        set u-dangerous (1 - d-dangerous)
        set a-dangerous discomfort-mean
      ]

      if information-dangerous = 0.5 [
        set b-dangerous 0
        set d-dangerous 0
        set u-dangerous 1
        set a-dangerous discomfort-mean
      ]
    ]
  ]

end
;; ==============================================================================================================

to two-aggregate-information-dangerous
  let actual-b-dangerous 0
  let actual-d-dangerous 0
  let actual-u-dangerous 0
  let actual-a-dangerous 0

  set actual-b-dangerous 0
  set actual-d-dangerous 0
  set actual-u-dangerous 1
  set actual-a-dangerous discomfort-mean

  if fusion-method = "cumulative" [

    ask vehicles [
      ifelse (not (actual-u-dangerous = 0)) or (not (u-dangerous = 0)) [

        let den-dangerous (actual-u-dangerous + u-dangerous - (actual-u-dangerous * u-dangerous))

        set actual-b-dangerous (((actual-b-dangerous * u-dangerous) + (b-dangerous * actual-u-dangerous)) / den-dangerous)
        set actual-d-dangerous (((actual-d-dangerous * u-dangerous) + (d-dangerous * actual-u-dangerous)) / den-dangerous)
        set actual-u-dangerous ((actual-u-dangerous * u-dangerous) / den-dangerous)
        set actual-a-dangerous discomfort-mean

      ][

      set actual-b-dangerous (actual-b-dangerous + b-dangerous) / 2
      set actual-d-dangerous (actual-d-dangerous + d-dangerous) / 2
      set actual-u-dangerous (actual-u-dangerous + u-dangerous) / 2
      set actual-a-dangerous discomfort-mean

      ]
    ]

    set belief-dangerous actual-b-dangerous
    set disbelief-dangerous actual-d-dangerous
    set uncertainty-dangerous actual-u-dangerous
    set base-rate-dangerous actual-a-dangerous
  ]



  if fusion-method = "average" [

    ask vehicles [
      ifelse (not (actual-u-dangerous = 0)) or (not (u-dangerous = 0)) [

        let den-dangerous (actual-u-dangerous + u-dangerous)

        set actual-b-dangerous (((actual-b-dangerous * u-dangerous) + (b-dangerous * actual-u-dangerous)) / den-dangerous)
        set actual-d-dangerous (((actual-d-dangerous * u-dangerous) + (d-dangerous * actual-u-dangerous)) / den-dangerous)
        set actual-u-dangerous ((2 * actual-u-dangerous * u-dangerous) / den-dangerous)
        set actual-a-dangerous discomfort-mean

      ][

      set actual-b-dangerous (actual-b-dangerous + b-dangerous) / 2
      set actual-d-dangerous (actual-d-dangerous + d-dangerous) / 2
      set actual-u-dangerous (actual-u-dangerous + u-dangerous) / 2
      set actual-a-dangerous discomfort-mean

      ]
    ]

    set belief-dangerous actual-b-dangerous
    set disbelief-dangerous actual-d-dangerous
    set uncertainty-dangerous actual-u-dangerous
    set base-rate-dangerous actual-a-dangerous
  ]
end
;; ==============================================================================================================

to one-collect-information

  let abjam-private 0
  let abjam-professional 0
  let abjam-authorities 0
  let abfree-private 0
  let abfree-professional 0
  let abfree-authorities 0

  let adjam-private 0
  let adjam-professional 0
  let adjam-authorities 0
  let adfree-private 0
  let adfree-professional 0
  let adfree-authorities 0

  ;set total-abjam 0
  ;set total-abfree 0
  ;set total-adjam 0
  ;set total-adfree 0

  ask vehicles [
    let val 1
    if agent-malicious? [
      set val malicious-multiplier
    ]

    if category = "private" [
      if information-ab = 0 [set abjam-private (abjam-private + val)]
      if information-ab = 1 [set abfree-private (abfree-private + val)]
      if information-ad = 0 [set adjam-private (adjam-private + val)]
      if information-ad = 1 [set adfree-private (adfree-private + val)]
    ]

    if category = "professional" [
      if information-ab = 0 [set abjam-professional (abjam-professional + val)]
      if information-ab = 1 [set abfree-professional (abfree-professional + val)]
      if information-ad = 0 [set adjam-professional (adjam-professional + val)]
      if information-ad = 1 [set adfree-professional (adfree-professional + val)]
    ]

    if category = "authorities" [
      if information-ab = 0 [set abjam-authorities (abjam-authorities + val)]
      if information-ab = 1 [set abfree-authorities (abfree-authorities + val)]
      if information-ad = 0 [set adjam-authorities (adjam-authorities + val)]
      if information-ad = 1 [set adfree-authorities (adfree-authorities + val)]
    ]
  ]

  set total-abjam (abjam-private + abjam-professional + abjam-authorities)
  set total-abfree (abfree-private + abfree-professional + abfree-authorities)
  set total-adjam (adjam-private + adjam-professional + adjam-authorities)
  set total-adfree (adfree-private + adfree-professional + adfree-authorities)


  set private-true (private-true + abjam-private + adfree-private)
  set private-false (private-false + (abfree-private) + (adjam-private))
  set professional-true (professional-true + abjam-professional + adfree-professional)
  set professional-false (professional-false + (abfree-professional) + (adjam-professional))
  set authorities-true (authorities-true + abjam-authorities + adfree-authorities)
  set authorities-false (authorities-false + (abfree-authorities) + (adjam-authorities))

  set private-trust (source-trust private-true private-false)
  set professional-trust (source-trust professional-true professional-false)
  set authorities-trust (source-trust authorities-true authorities-false)

  ask vehicles [
    if agent-communicate? [

      if information-ab = 1 [
        if category = "private" [set b-ab 1 * private-trust]
        if category = "professional" [set b-ab 1 * professional-trust]
        if category = "authorities" [set b-ab 1 * authorities-trust]

        set d-ab 0
        set u-ab (1 - b-ab)
        set a-ab confidence-ab
      ]
      if information-ab = 0 [
        if category = "private" [set d-ab 1 * private-trust]
        if category = "professional" [set d-ab 1 * professional-trust]
        if category = "authorities" [set d-ab 1 * authorities-trust]

        set b-ab 0
        set u-ab (1 - d-ab)
        set a-ab confidence-ab
      ]
      if information-ab = 0.5 [
        set b-ab 0
        set d-ab 0
        set u-ab 1
        set a-ab confidence-ab
      ]

      if information-ad = 1 [
        if category = "private" [set b-ad 1 * private-trust]
        if category = "professional" [set b-ad 1 * professional-trust]
        if category = "authorities" [set b-ad 1 * authorities-trust]

        set d-ad 0
        set u-ad (1 - b-ad)
        set a-ad confidence-ad
      ]
      if information-ad = 0 [
        if category = "private" [set d-ad 1 * private-trust]
        if category = "professional" [set d-ad 1 * professional-trust]
        if category = "authorities" [set d-ad 1 * authorities-trust]

        set b-ad 0
        set u-ad (1 - d-ad)
        set a-ad confidence-ad
      ]
      if information-ad = 0.5 [
        set b-ad 0
        set d-ad 0
        set u-ad 1
        set a-ad confidence-ad
      ]

    ]
  ]

end
;; ==============================================================================================================

to two-aggregate-information

  let actual-b-ab 0
  let actual-d-ab 0
  let actual-u-ab 1
  let actual-a-ab 0.5

  let actual-b-ad 0
  let actual-d-ad 0
  let actual-u-ad 1
  let actual-a-ad 0.5

  let first-ab? true
  let first-ad? true

  if fusion-method = "cumulative" [

    ask vehicles [
      if agent-communicate? [

        let rep 1
        ;if agent-malicious? [set rep n]
        if agent-malicious? [set rep 1]

        repeat rep [
        ifelse (not (actual-u-ab = 0)) or (not (u-ab = 0)) [
          let den-ab ((actual-u-ab + u-ab) - (actual-u-ab * u-ab))
          set actual-b-ab (((actual-b-ab * u-ab) + (b-ab * actual-u-ab)) / den-ab)
          set actual-d-ab (((actual-d-ab * u-ab) + (d-ab * actual-u-ab)) / den-ab)
          set actual-u-ab ((actual-u-ab * u-ab) / den-ab)
          set actual-a-ab a-ab
        ][
        set actual-b-ab (actual-b-ab + b-ab) / 2
        set actual-d-ab (actual-d-ab + d-ab) / 2
        set actual-u-ab (actual-u-ab + u-ab) / 2
        set actual-a-ab (actual-a-ab + a-ab) / 2
        ]

        ifelse (not (actual-u-ad = 0)) or (not (u-ad = 0)) [
          let den-ad (actual-u-ad + u-ad - (actual-u-ad * u-ad))
          set actual-b-ad (((actual-b-ad * u-ad) + (b-ad * actual-u-ad)) / den-ad)
          set actual-d-ad (((actual-d-ad * u-ad) + (d-ad * actual-u-ad)) / den-ad)
          set actual-u-ad ((actual-u-ad * u-ad) / den-ad)
          set actual-a-ad a-ad
        ][
        set actual-b-ad (actual-b-ad + b-ad) / 2
        set actual-d-ad (actual-d-ad + d-ad) / 2
        set actual-u-ad (actual-u-ad + u-ad) / 2
        set actual-a-ad (actual-a-ad + a-ad) / 2
        ]
        ]

      ]
    ]

    set belief-ab actual-b-ab
    set disbelief-ab actual-d-ab
    set uncertainty-ab actual-u-ab
    set base-rate-ab actual-a-ab

    set belief-ad actual-b-ad
    set disbelief-ad actual-d-ad
    set uncertainty-ad actual-u-ad
    set base-rate-ad actual-a-ad

  ]




  if fusion-method = "average" [

    ask vehicles [
      if agent-communicate? [

        let rep 1
        if agent-malicious? [set rep 1]

        repeat rep [
        ifelse (not (actual-u-ab = 0)) or (not (u-ab = 0)) [
          let den-ab (actual-u-ab + u-ab)
          set actual-b-ab (((actual-b-ab * u-ab) + (b-ab * actual-u-ab)) / den-ab)
          set actual-d-ab (((actual-d-ab * u-ab) + (d-ab * actual-u-ab)) / den-ab)
          set actual-u-ab ((2 * actual-u-ab * u-ab) / den-ab)
          set actual-a-ab a-ab
        ][
        set actual-b-ab (actual-b-ab + b-ab) / 2
        set actual-d-ab (actual-d-ab + d-ab) / 2
        set actual-u-ab (actual-u-ab + u-ab) / 2
        set actual-a-ab (actual-a-ab + a-ab) / 2
        ]

        ifelse (not (actual-u-ad = 0)) or (not (u-ad = 0)) [
          let den-ad (actual-u-ad + u-ad)
          set actual-b-ad (((actual-b-ad * u-ad) + (b-ad * actual-u-ad)) / den-ad)
          set actual-d-ad (((actual-d-ad * u-ad) + (d-ad * actual-u-ad)) / den-ad)
          set actual-u-ad ((2 * actual-u-ad * u-ad) / den-ad)
          set actual-a-ad a-ad
        ][
        set actual-b-ad (actual-b-ad + b-ad) / 2
        set actual-d-ad (actual-d-ad + d-ad) / 2
        set actual-u-ad (actual-u-ad + u-ad) / 2
        set actual-a-ad (actual-a-ad + a-ad) / 2
        ]
        ]

      ]
    ]

    set belief-ab actual-b-ab
    set disbelief-ab actual-d-ab
    set uncertainty-ab actual-u-ab
    set base-rate-ab actual-a-ab

    set belief-ad actual-b-ad
    set disbelief-ad actual-d-ad
    set uncertainty-ad actual-u-ad
    set base-rate-ad actual-a-ad
  ]

  ;let expected-ab (belief-ab + uncertainty-ab * base-rate-ab)
  ;let expected-neg-ab (disbelief-ab + uncertainty-ab * base-rate-ab)
  ;set confidence-ab (expected-ab / (expected-ab + expected-neg-ab))

  ;let expected-ad (belief-ad + uncertainty-ad * base-rate-ad)
  ;let expected-neg-ad (disbelief-ad + uncertainty-ad * base-rate-ad)
  ;set confidence-ad (expected-ad / (expected-ad + expected-neg-ad))
end
;; ==============================================================================================================

to-report source-trust [r s]
  ;report ((r - s) / (r + s + 2))
  ;report ((r) / (r + s))
  report ((r + 1) / (r + s + 2))
end
;; ==============================================================================================================

to perform-communication

  ask vehicles[

    set information-ab 0.5
    set information-ad 0.5

    if (agent-communicate?) or (percent-vehicles-communicate = 100)[

      ifelse path-last-iteration = "AB"[
        set information-ab 0
      ][
        set information-ad 1
      ]

      ;set information-ab 0
      ;set information-ad 1

      if malicious?[
        if agent-malicious? [
          ifelse path-last-iteration = "AB"[
            set information-ab 0
            set information-ad 1
          ][
            set information-ab 1
            set information-ad 0
          ]
          ;set information-ab 1
          ;set information-ad 0
        ]
      ]
    ]
  ]
end
;; ==============================================================================================================


to-report get-random-path
  let choice random 2
  ifelse choice = 0 [
    report "AB"
  ][
  report "AD"
  ]
end
;; ==============================================================================================================

to-report is-different? [value1 value2]
  let dif value1 - value2
  if dif < 0 [
    set dif (dif * (-1))
  ]
  ifelse dif > 0.05 [
    report true
  ][
  report false
  ]
end
;; ==============================================================================================================

to show-discomfort-mean
  let sum-discomfort 0
  ask vehicles [
    set sum-discomfort (sum-discomfort + discomfort)
  ]

  set sum-discomfort (sum-discomfort / 300)
  show sum-discomfort
end
;; ==============================================================================================================

to show-beliefs-mean
  show word word word word word "AB: " belief-ab "|" disbelief-ab "|" uncertainty-ab
  show word word word word word "AD: " belief-ad "|" disbelief-ad "|" uncertainty-ad
  show "-------"
end
;; ==============================================================================================================











;; ==============================================================================================================
;; ==============================================================================================================
;; ==============================================================================================================
;; ==============================================================================================================
;; ==============================================================================================================
;; ==============================================================================================================
;; ==============================================================================================================

to paper-experiments
  ;Amount of drivers
  set private-drivers 200
  set professional-drivers 70
  set authorities-drivers 30
  set ab-volume 13000
  set bc-volume 13000
  set ad-volume 1000
  set dc-volume 1000

  ;Simulation parameters
  set alpha 0.2
  set beta 10
  set discomfort-mean 0.7
  set discomfort-deviation 0.2
  set percent-vehicles-communicate 40
  set percent-vehicles-receive 30
  set percent-private-malicious 20
  set percent-professional-malicious 30
  set percent-authorities-malicious 5

  ;Experiment parameters
  set iterations 100
  set replications 100

  set travel-time-mean ""
  set vehicles-ad-mean ""

  ;Experiment cases
  benchmark
  communication-no-operator
  communication-ours
  communication-pereira
  communication-malicious-no-operator
  communication-malicious-ours
  communication-malicious-pereira
  benchmark-discomfort
  communication-discomfort-no-operator
  communication-discomfort-ours
  communication-discomfort-pereira
  communication-discomfort-malicious-no-operator
  communication-discomfort-malicious-ours
  communication-discomfort-malicious-pereira
  communication-discomfort-malicious-dangerous-no-operator
  communication-discomfort-malicious-dangerous-ours
  communication-discomfort-malicious-dangerous-pereira
end

to benchmark
  set complete-vision? true
  set communication? false
  set discomfort? false
  set malicious? false
  set communication-dangerous? false
  set malicious-dangerous? false
  set operator? false
  set operator "ours"
  set fusion-method "cumulative"

  execution "benchmark"
end

to communication-no-operator
  set complete-vision? false
  set communication? true
  set discomfort? false
  set malicious? false
  set communication-dangerous? false
  set malicious-dangerous? false
  set operator? false
  set operator "ours"
  set fusion-method "cumulative"

  execution "communication-no-operator"
end

to communication-ours
  set complete-vision? false
  set communication? true
  set discomfort? false
  set malicious? false
  set communication-dangerous? false
  set malicious-dangerous? false
  set operator? true
  set operator "ours"
  set fusion-method "cumulative"

  execution "communication-ours"
end

to communication-pereira
  set complete-vision? false
  set communication? true
  set discomfort? false
  set malicious? false
  set communication-dangerous? false
  set malicious-dangerous? false
  set operator? true
  set operator "pereira"
  set fusion-method "cumulative"

  execution "communication-pereira"
end

to communication-malicious-no-operator
  set complete-vision? false
  set communication? true
  set discomfort? false
  set malicious? true
  set communication-dangerous? false
  set malicious-dangerous? false
  set operator? false
  set operator "ours"
  set fusion-method "cumulative"

  execution "communication-malicious-no-operator"
end

to communication-malicious-ours
  set complete-vision? false
  set communication? true
  set discomfort? false
  set malicious? true
  set communication-dangerous? false
  set malicious-dangerous? false
  set operator? true
  set operator "ours"
  set fusion-method "cumulative"

  execution "communication-malicious-ours"
end

to communication-malicious-pereira
  set complete-vision? false
  set communication? true
  set discomfort? false
  set malicious? true
  set communication-dangerous? false
  set malicious-dangerous? false
  set operator? true
  set operator "pereira"
  set fusion-method "cumulative"

  execution "communication-malicious-pereira"
end

to benchmark-discomfort
  set complete-vision? true
  set communication? false
  set discomfort? true
  set malicious? false
  set communication-dangerous? false
  set malicious-dangerous? false
  set operator? false
  set operator "ours"
  set fusion-method "cumulative"

  execution "benchmark-discomfort"
end

to communication-discomfort-no-operator
  set complete-vision? false
  set communication? true
  set discomfort? true
  set malicious? false
  set communication-dangerous? false
  set malicious-dangerous? false
  set operator? false
  set operator "ours"
  set fusion-method "cumulative"

  execution "communication-discomfort-no-operator"
end

to communication-discomfort-ours
  set complete-vision? false
  set communication? true
  set discomfort? true
  set malicious? false
  set communication-dangerous? false
  set malicious-dangerous? false
  set operator? true
  set operator "ours"
  set fusion-method "cumulative"

  execution "communication-discomfort-ours"
end

to communication-discomfort-pereira
  set complete-vision? false
  set communication? true
  set discomfort? true
  set malicious? false
  set communication-dangerous? false
  set malicious-dangerous? false
  set operator? true
  set operator "pereira"
  set fusion-method "cumulative"

  execution "communication-discomfort-pereira"
end

to communication-discomfort-malicious-no-operator
  set complete-vision? false
  set communication? true
  set discomfort? true
  set malicious? true
  set communication-dangerous? false
  set malicious-dangerous? false
  set operator? false
  set operator "ours"
  set fusion-method "cumulative"

  execution "communication-discomfort-malicious-no-operator"
end

to communication-discomfort-malicious-ours
  set complete-vision? false
  set communication? true
  set discomfort? true
  set malicious? true
  set communication-dangerous? false
  set malicious-dangerous? false
  set operator? true
  set operator "ours"
  set fusion-method "cumulative"

  execution "communication-discomfort-malicious-ours"
end

to communication-discomfort-malicious-pereira
  set complete-vision? false
  set communication? true
  set discomfort? true
  set malicious? true
  set communication-dangerous? false
  set malicious-dangerous? false
  set operator? true
  set operator "pereira"
  set fusion-method "cumulative"

  execution "communication-discomfort-malicious-pereira"
end

to communication-discomfort-malicious-dangerous-no-operator
  set complete-vision? false
  set communication? true
  set discomfort? true
  set malicious? true
  set communication-dangerous? true
  set malicious-dangerous? true
  set operator? false
  set operator "ours"
  set fusion-method "cumulative"

  execution "communication-discomfort-malicious-dangerous-no-operator"
end

to communication-discomfort-malicious-dangerous-ours
  set complete-vision? false
  set communication? true
  set discomfort? true
  set malicious? true
  set communication-dangerous? true
  set malicious-dangerous? true
  set operator? true
  set operator "ours"
  set fusion-method "cumulative"

  execution "communication-discomfort-malicious-dangerous-ours"
end

to communication-discomfort-malicious-dangerous-pereira
  set complete-vision? false
  set communication? true
  set discomfort? true
  set malicious? true
  set communication-dangerous? true
  set malicious-dangerous? true
  set operator? true
  set operator "pereira"
  set fusion-method "cumulative"

  execution "communication-discomfort-malicious-dangerous-pereira"
end


to execution [experiment-case]
  let list-percents (list)

  repeat replications [
    setup
    set experimentation? true

    repeat iterations [
      go
    ]
    set list-percents (lput (percent-good vehicles-ad) list-percents)
  ]

  let mean-percents (mean list-percents)
  let deviation (standard-deviation list-percents)

  file-open ("results_three.txt")
  file-print word word word word word experiment-case " " mean-percents " " deviation "\n"
  file-close
  show word "DONE: " experiment-case
end


to-report percent-good [vehicles-in-ad]
  let total-vehicles (private-drivers + professional-drivers + authorities-drivers)
  report ((vehicles-in-ad * 100) / total-vehicles)
end








to experimentation

  ;;General parameters -------------------
  set discomfort-mean 0.7
  set discomfort-deviation 0.2
  set percent-vehicles-communicate 40
  set percent-private-malicious 30
  set percent-professional-malicious 20
  set percent-authorities-malicious 5
  set operator "ours"

  set communication-dangerous? false

  set iterations 50
  set replications 10
  ;;-------------------------------------

  set communication? false
  set discomfort? false
  set malicious? false
  set operator? false
  setup
  execute-communication "baseline"

  set communication? true
  set discomfort? false
  set malicious? false
  set operator? false
  setup
  execute-communication "comunicacao"

  set communication? true
  set discomfort? true
  set malicious? false
  set operator? false
  setup
  execute-communication "comunicacao+desconforto"

  set communication? true
  set discomfort? false
  set malicious? true
  set operator? false
  setup
  execute-communication "comunicacao+malicia"

  set communication? true
  set discomfort? true
  set malicious? true
  set operator? false
  setup
  execute-communication "comunicacao+desconforto+malicia"

  set communication? true
  set discomfort? true
  set malicious? true
  set operator? true
  set fusion-method "cumulative"
  setup
  execute-communication "comunicacao+desconforto+malicia+trust+cumulative"

  set communication? true
  set discomfort? true
  set malicious? true
  set operator? true
  set fusion-method "average"
  setup
  execute-communication "comunicacao+desconforto+malicia+trust+average"

  set communication? true
  set discomfort? true
  set malicious? true
  set operator? true
  set communication-dangerous? true
  set fusion-method "cumulative"
  set malicious-dangerous? false
  setup
  execute-communication "fusion-cumulative"

  set communication? true
  set discomfort? true
  set malicious? true
  set operator? true
  set communication-dangerous? true
  set fusion-method "cumulative"
  set malicious-dangerous? true
  setup
  execute-communication "fusion-cumulative-malicious"

  set communication? true
  set discomfort? true
  set malicious? true
  set operator? true
  set communication-dangerous? true
  set fusion-method "average"
  set malicious-dangerous? false
  setup
  execute-communication "fusion-average"

  set communication? true
  set discomfort? true
  set malicious? true
  set operator? true
  set communication-dangerous? true
  set fusion-method "average"
  set malicious-dangerous? true
  setup
  execute-communication "fusion-average-malicious"

  set communication? true
  set discomfort? true
  set malicious? true
  set operator? true
  set operator "pereira"
  setup
  execute-communication "comunicacao+desconforto+malicia+trust+pereira"

end

to execute-communication [filename]
  ;foreach [0 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24 25 26 27 28 29 30 31 32 33 34 35 36 37 38 39 40 41 42 43 44 45 46 47 48 49 50 51 52 53 54 55 56 57 58 59 60 61 62 63 64 65 66 67 68 69 70 71 72 73 74 75 76 77 78 79 80 81 82 83 84 85 86 87 88 89 90 91 92 93 94 95 96 97 98 99 100] [
  foreach [0 10 20 30 40 50 60 70 80 90 100] [

    set percent-vehicles-receive ?

    let total-travel-times 0
    let total-drivers-ab 0
    let total-drivers-ad 0

    repeat replications [
      setup
      let it 1
      let stop? false

      while [not stop?] [
        go

        set total-travel-times (total-travel-times + system-travel-time)
        set total-drivers-ab (total-drivers-ab + vehicles-ab)
        set total-drivers-ad (total-drivers-ad + vehicles-ad)

        set it it + 1
        if it > iterations [
          set stop? true
        ]
      ]
    ]

    let mean-travel-time (total-travel-times / iterations) / replications
    let mean-drivers-ab (total-drivers-ab / iterations) / replications
    let mean-drivers-ad (total-drivers-ad / iterations) / replications

    file-open (word filename ".txt")
    file-print word word word word percent-vehicles-receive " " mean-drivers-ad " " mean-travel-time
    file-close
    show ?
  ]
  show word "DONE: " filename
end
@#$#@#$#@
GRAPHICS-WINDOW
719
157
964
368
0
0
180.0
1
0
1
1
1
0
1
1
1
0
0
0
0
0
0
1
ticks
30.0

BUTTON
408
45
480
131
NIL
setup\n
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
484
45
556
131
NIL
go
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

SLIDER
17
180
189
213
discomfort-mean
discomfort-mean
0.0
1
0.7
0.01
1
NIL
HORIZONTAL

SLIDER
17
244
189
277
iterations
iterations
0
5000
30
1
1
NIL
HORIZONTAL

SLIDER
10
32
182
65
private-drivers
private-drivers
0
1000
200
1
1
NIL
HORIZONTAL

SLIDER
10
63
182
96
professional-drivers
professional-drivers
0
1000
70
1
1
NIL
HORIZONTAL

SLIDER
10
92
182
125
authorities-drivers
authorities-drivers
0
1000
30
1
1
NIL
HORIZONTAL

SLIDER
186
32
358
65
ab-volume
ab-volume
0
20000
13000
1
1
NIL
HORIZONTAL

SLIDER
186
63
358
96
bc-volume
bc-volume
0
20000
13000
1
1
NIL
HORIZONTAL

SLIDER
186
93
358
126
ad-volume
ad-volume
0
6000
1000
1
1
NIL
HORIZONTAL

SLIDER
186
124
358
157
dc-volume
dc-volume
0
6000
1000
1
1
NIL
HORIZONTAL

SWITCH
300
353
579
386
malicious?
malicious?
1
1
-1000

SWITCH
300
423
579
456
operator?
operator?
1
1
-1000

SWITCH
17
353
297
386
communication?
communication?
0
1
-1000

SWITCH
18
423
297
456
discomfort?
discomfort?
1
1
-1000

SLIDER
196
181
428
214
percent-vehicles-communicate
percent-vehicles-communicate
0
100
40
1
1
NIL
HORIZONTAL

SLIDER
196
212
428
245
percent-vehicles-receive
percent-vehicles-receive
0
100
62
1
1
NIL
HORIZONTAL

SLIDER
17
212
189
245
discomfort-deviation
discomfort-deviation
0
1
0.2
0.01
1
NIL
HORIZONTAL

TEXTBOX
14
10
363
34
_______________Environment parameters_______________
12
15.0
1

TEXTBOX
16
162
771
192
____________________________________Simulation parameters____________________________________
12
15.0
1

SLIDER
196
249
428
282
percent-private-malicious
percent-private-malicious
0
100
30
1
1
NIL
HORIZONTAL

SLIDER
196
279
428
312
percent-professional-malicious
percent-professional-malicious
0
100
20
1
1
NIL
HORIZONTAL

SLIDER
196
309
428
342
percent-authorities-malicious
percent-authorities-malicious
0
100
5
1
1
NIL
HORIZONTAL

SLIDER
17
276
189
309
replications
replications
1
100
10
1
1
NIL
HORIZONTAL

INPUTBOX
438
291
492
351
alpha
0.2
1
0
Number

INPUTBOX
496
291
549
351
beta
10
1
0
Number

INPUTBOX
701
31
936
91
travel-time-mean
NIL
1
0
String

INPUTBOX
701
90
936
150
vehicles-ad-mean
NIL
1
0
String

SWITCH
17
388
297
421
communication-dangerous?
communication-dangerous?
1
1
-1000

SWITCH
300
388
579
421
malicious-dangerous?
malicious-dangerous?
0
1
-1000

CHOOSER
438
246
576
291
fusion-method
fusion-method
"cumulative" "average"
1

CHOOSER
438
201
576
246
operator
operator
"ours" "pereira"
0

BUTTON
560
45
693
131
NIL
experimentation
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

SWITCH
17
312
190
345
complete-vision?
complete-vision?
1
1
-1000

BUTTON
596
423
763
456
NIL
paper-experiments\n
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

SLIDER
438
169
576
202
malicious-multiplier
malicious-multiplier
1
100
5
1
1
NIL
HORIZONTAL

@#$#@#$#@
## WHAT IS IT?

The model’s purpose is twofold. Firstly it aims at accurately modeling traffic conditions in a simplified representation of a real road network. Secondly, it aims at modeling the effect of communication, potentially false, and countermeasures to false communication within this network.

## HOW IT WORKS

The agents in this model represent cars that can decide for themselves which of the two edges to pick to go from G to U. Each agent belongs to one of three different groups:
private drivers, professional drivers or authority drivers. These different groups are used to initialize the simulation with heterogeneous behaviors, but other than that, all agents function in the same manner.

In each iteration, an agent decides, based on its beliefs about the roads, to drive along either GSU or GPU. There are three beliefs which influence its behavior: gsu_congested, gpu_congested and gpu_dangerous. Each agent then decides what road to take according to

## HOW TO USE IT
See the ODD description of the model for the full documentation: http://jo.my/scen-abms

## CREDITS AND REFERENCES

This model is used in submission number #304 at AAAI 2015. References will be added after the blind review phase is over.
@#$#@#$#@
default
true
0
Polygon -7500403 true true 150 5 40 250 150 205 260 250

airplane
true
0
Polygon -7500403 true true 150 0 135 15 120 60 120 105 15 165 15 195 120 180 135 240 105 270 120 285 150 270 180 285 210 270 165 240 180 180 285 195 285 165 180 105 180 60 165 15

arrow
true
0
Polygon -7500403 true true 150 0 0 150 105 150 105 293 195 293 195 150 300 150

box
false
0
Polygon -7500403 true true 150 285 285 225 285 75 150 135
Polygon -7500403 true true 150 135 15 75 150 15 285 75
Polygon -7500403 true true 15 75 15 225 150 285 150 135
Line -16777216 false 150 285 150 135
Line -16777216 false 150 135 15 75
Line -16777216 false 150 135 285 75

bug
true
0
Circle -7500403 true true 96 182 108
Circle -7500403 true true 110 127 80
Circle -7500403 true true 110 75 80
Line -7500403 true 150 100 80 30
Line -7500403 true 150 100 220 30

butterfly
true
0
Polygon -7500403 true true 150 165 209 199 225 225 225 255 195 270 165 255 150 240
Polygon -7500403 true true 150 165 89 198 75 225 75 255 105 270 135 255 150 240
Polygon -7500403 true true 139 148 100 105 55 90 25 90 10 105 10 135 25 180 40 195 85 194 139 163
Polygon -7500403 true true 162 150 200 105 245 90 275 90 290 105 290 135 275 180 260 195 215 195 162 165
Polygon -16777216 true false 150 255 135 225 120 150 135 120 150 105 165 120 180 150 165 225
Circle -16777216 true false 135 90 30
Line -16777216 false 150 105 195 60
Line -16777216 false 150 105 105 60

car
false
0
Polygon -7500403 true true 300 180 279 164 261 144 240 135 226 132 213 106 203 84 185 63 159 50 135 50 75 60 0 150 0 165 0 225 300 225 300 180
Circle -16777216 true false 180 180 90
Circle -16777216 true false 30 180 90
Polygon -16777216 true false 162 80 132 78 134 135 209 135 194 105 189 96 180 89
Circle -7500403 true true 47 195 58
Circle -7500403 true true 195 195 58

circle
false
0
Circle -7500403 true true 0 0 300

circle 2
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240

cow
false
0
Polygon -7500403 true true 200 193 197 249 179 249 177 196 166 187 140 189 93 191 78 179 72 211 49 209 48 181 37 149 25 120 25 89 45 72 103 84 179 75 198 76 252 64 272 81 293 103 285 121 255 121 242 118 224 167
Polygon -7500403 true true 73 210 86 251 62 249 48 208
Polygon -7500403 true true 25 114 16 195 9 204 23 213 25 200 39 123

cylinder
false
0
Circle -7500403 true true 0 0 300

dot
false
0
Circle -7500403 true true 90 90 120

face happy
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 255 90 239 62 213 47 191 67 179 90 203 109 218 150 225 192 218 210 203 227 181 251 194 236 217 212 240

face neutral
false
0
Circle -7500403 true true 8 7 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Rectangle -16777216 true false 60 195 240 225

face sad
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 168 90 184 62 210 47 232 67 244 90 220 109 205 150 198 192 205 210 220 227 242 251 229 236 206 212 183

fish
false
0
Polygon -1 true false 44 131 21 87 15 86 0 120 15 150 0 180 13 214 20 212 45 166
Polygon -1 true false 135 195 119 235 95 218 76 210 46 204 60 165
Polygon -1 true false 75 45 83 77 71 103 86 114 166 78 135 60
Polygon -7500403 true true 30 136 151 77 226 81 280 119 292 146 292 160 287 170 270 195 195 210 151 212 30 166
Circle -16777216 true false 215 106 30

flag
false
0
Rectangle -7500403 true true 60 15 75 300
Polygon -7500403 true true 90 150 270 90 90 30
Line -7500403 true 75 135 90 135
Line -7500403 true 75 45 90 45

flower
false
0
Polygon -10899396 true false 135 120 165 165 180 210 180 240 150 300 165 300 195 240 195 195 165 135
Circle -7500403 true true 85 132 38
Circle -7500403 true true 130 147 38
Circle -7500403 true true 192 85 38
Circle -7500403 true true 85 40 38
Circle -7500403 true true 177 40 38
Circle -7500403 true true 177 132 38
Circle -7500403 true true 70 85 38
Circle -7500403 true true 130 25 38
Circle -7500403 true true 96 51 108
Circle -16777216 true false 113 68 74
Polygon -10899396 true false 189 233 219 188 249 173 279 188 234 218
Polygon -10899396 true false 180 255 150 210 105 210 75 240 135 240

house
false
0
Rectangle -7500403 true true 45 120 255 285
Rectangle -16777216 true false 120 210 180 285
Polygon -7500403 true true 15 120 150 15 285 120
Line -16777216 false 30 120 270 120

leaf
false
0
Polygon -7500403 true true 150 210 135 195 120 210 60 210 30 195 60 180 60 165 15 135 30 120 15 105 40 104 45 90 60 90 90 105 105 120 120 120 105 60 120 60 135 30 150 15 165 30 180 60 195 60 180 120 195 120 210 105 240 90 255 90 263 104 285 105 270 120 285 135 240 165 240 180 270 195 240 210 180 210 165 195
Polygon -7500403 true true 135 195 135 240 120 255 105 255 105 285 135 285 165 240 165 195

line
true
0
Line -7500403 true 150 0 150 300

line half
true
0
Line -7500403 true 150 0 150 150

pentagon
false
0
Polygon -7500403 true true 150 15 15 120 60 285 240 285 285 120

person
false
0
Circle -7500403 true true 110 5 80
Polygon -7500403 true true 105 90 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285 180 195 195 90
Rectangle -7500403 true true 127 79 172 94
Polygon -7500403 true true 195 90 240 150 225 180 165 105
Polygon -7500403 true true 105 90 60 150 75 180 135 105

plant
false
0
Rectangle -7500403 true true 135 90 165 300
Polygon -7500403 true true 135 255 90 210 45 195 75 255 135 285
Polygon -7500403 true true 165 255 210 210 255 195 225 255 165 285
Polygon -7500403 true true 135 180 90 135 45 120 75 180 135 210
Polygon -7500403 true true 165 180 165 210 225 180 255 120 210 135
Polygon -7500403 true true 135 105 90 60 45 45 75 105 135 135
Polygon -7500403 true true 165 105 165 135 225 105 255 45 210 60
Polygon -7500403 true true 135 90 120 45 150 15 180 45 165 90

sheep
false
15
Circle -1 true true 203 65 88
Circle -1 true true 70 65 162
Circle -1 true true 150 105 120
Polygon -7500403 true false 218 120 240 165 255 165 278 120
Circle -7500403 true false 214 72 67
Rectangle -1 true true 164 223 179 298
Polygon -1 true true 45 285 30 285 30 240 15 195 45 210
Circle -1 true true 3 83 150
Rectangle -1 true true 65 221 80 296
Polygon -1 true true 195 285 210 285 210 240 240 210 195 210
Polygon -7500403 true false 276 85 285 105 302 99 294 83
Polygon -7500403 true false 219 85 210 105 193 99 201 83

square
false
0
Rectangle -7500403 true true 30 30 270 270

square 2
false
0
Rectangle -7500403 true true 30 30 270 270
Rectangle -16777216 true false 60 60 240 240

star
false
0
Polygon -7500403 true true 151 1 185 108 298 108 207 175 242 282 151 216 59 282 94 175 3 108 116 108

target
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240
Circle -7500403 true true 60 60 180
Circle -16777216 true false 90 90 120
Circle -7500403 true true 120 120 60

tree
false
0
Circle -7500403 true true 118 3 94
Rectangle -6459832 true false 120 195 180 300
Circle -7500403 true true 65 21 108
Circle -7500403 true true 116 41 127
Circle -7500403 true true 45 90 120
Circle -7500403 true true 104 74 152

triangle
false
0
Polygon -7500403 true true 150 30 15 255 285 255

triangle 2
false
0
Polygon -7500403 true true 150 30 15 255 285 255
Polygon -16777216 true false 151 99 225 223 75 224

truck
false
0
Rectangle -7500403 true true 4 45 195 187
Polygon -7500403 true true 296 193 296 150 259 134 244 104 208 104 207 194
Rectangle -1 true false 195 60 195 105
Polygon -16777216 true false 238 112 252 141 219 141 218 112
Circle -16777216 true false 234 174 42
Rectangle -7500403 true true 181 185 214 194
Circle -16777216 true false 144 174 42
Circle -16777216 true false 24 174 42
Circle -7500403 false true 24 174 42
Circle -7500403 false true 144 174 42
Circle -7500403 false true 234 174 42

turtle
true
0
Polygon -10899396 true false 215 204 240 233 246 254 228 266 215 252 193 210
Polygon -10899396 true false 195 90 225 75 245 75 260 89 269 108 261 124 240 105 225 105 210 105
Polygon -10899396 true false 105 90 75 75 55 75 40 89 31 108 39 124 60 105 75 105 90 105
Polygon -10899396 true false 132 85 134 64 107 51 108 17 150 2 192 18 192 52 169 65 172 87
Polygon -10899396 true false 85 204 60 233 54 254 72 266 85 252 107 210
Polygon -7500403 true true 119 75 179 75 209 101 224 135 220 225 175 261 128 261 81 224 74 135 88 99

wheel
false
0
Circle -7500403 true true 3 3 294
Circle -16777216 true false 30 30 240
Line -7500403 true 150 285 150 15
Line -7500403 true 15 150 285 150
Circle -7500403 true true 120 120 60
Line -7500403 true 216 40 79 269
Line -7500403 true 40 84 269 221
Line -7500403 true 40 216 269 79
Line -7500403 true 84 40 221 269

wolf
false
0
Polygon -16777216 true false 253 133 245 131 245 133
Polygon -7500403 true true 2 194 13 197 30 191 38 193 38 205 20 226 20 257 27 265 38 266 40 260 31 253 31 230 60 206 68 198 75 209 66 228 65 243 82 261 84 268 100 267 103 261 77 239 79 231 100 207 98 196 119 201 143 202 160 195 166 210 172 213 173 238 167 251 160 248 154 265 169 264 178 247 186 240 198 260 200 271 217 271 219 262 207 258 195 230 192 198 210 184 227 164 242 144 259 145 284 151 277 141 293 140 299 134 297 127 273 119 270 105
Polygon -7500403 true true -1 195 14 180 36 166 40 153 53 140 82 131 134 133 159 126 188 115 227 108 236 102 238 98 268 86 269 92 281 87 269 103 269 113

x
false
0
Polygon -7500403 true true 270 75 225 30 30 225 75 270
Polygon -7500403 true true 30 75 75 30 270 225 225 270

@#$#@#$#@
NetLogo 5.2.1
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
default
0.0
-0.2 0 0.0 1.0
0.0 1 1.0 0.0
0.2 0 0.0 1.0
link direction
true
0
Line -7500403 true 150 150 90 180
Line -7500403 true 150 150 210 180

@#$#@#$#@
0
@#$#@#$#@
