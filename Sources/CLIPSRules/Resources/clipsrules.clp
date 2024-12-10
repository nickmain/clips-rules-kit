;;-------------------------------------------------------------
;; Optional support constructs
;;
;; Copyright (C) 2024 David N Main - All Rights Reserved.
;; See LICENSE file for permitted uses.
;;-------------------------------------------------------------

(defmodule CLIPSRules
    "CLIPSRules support constructs"
    (export ?ALL))

(defclass CLIPSRules::NativeObject
    "Parent class holding an external object in order to manage its lifetime"
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
