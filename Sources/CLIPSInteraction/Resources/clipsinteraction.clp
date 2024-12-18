;;-------------------------------------------------------------
;; CLIPS Interaction Constructs
;;
;; Copyright (C) 2024 David N Main - All Rights Reserved.
;; See LICENSE file for permitted uses.
;;-------------------------------------------------------------

(defmodule CLIPSInteraction
    "CLIPS Interaction Constructs"
    (export ?ALL))

(defclass CLIPSInteraction::CLIPSInteraction
    ""
    (is-a USER)
    (role abstract)
[<pattern-match-role>]
<slot>*
<handler-documentation>*)

(defclass CLIPSInteraction::ResponseOption
    ""
    (is-a USER)
    (role concrete)
[<pattern-match-role>]
<slot>*
<handler-documentation>*)
