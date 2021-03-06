open Ast
open Ast.Standard
open Polyfill

exception Illegal_variable_reference of string
exception Incorrect_step of string

(* Given an expression, remove any macros/sugar from the expression. *)
let rec desugar (expr : expression) : expression =
  let uid = Dangerous_guid.get () in
  let variable_name = Printf.sprintf "_UNUSED_desugar_%d" uid in
  match expr with
  | When (cond, exprs) ->
    let exprs' = desugar (Begin exprs) in
    (IfExpression
       (cond,
        exprs',
        Void))
  | Begin ([]) -> Void
  | Begin (expr :: []) ->
    (LetExpression
       (variable_name, expr, Void))
  | Begin (expr :: rest) ->
    let rest' = desugar (Begin rest) in
    (LetExpression
       (variable_name, expr, rest'))
  | LetExpression (name, binding, body) ->
    let binding' = desugar binding in
    let body' = desugar body in
    LetExpression (name, binding', body')
  | IfExpression (test, consequent, alternate) ->
    let test' = desugar test in
    let consequent' = desugar consequent in
    let alternate' = desugar alternate in
    IfExpression (test', consequent', alternate')
  | BinaryExpression (op, lhs, rhs) ->
    let lhs' = desugar lhs in
    let rhs' = desugar rhs in
    BinaryExpression (op, lhs', rhs')
  | UnaryExpression (op, operand) ->
    let operand' = desugar operand in
    UnaryExpression (op, operand')
  | Vector exprs ->
    let exprs' = List.fold_left (fun acc e -> (desugar e) :: acc) [] exprs in
    Vector exprs'
  | VectorRef (vec, index) ->
    let vec' = desugar vec in
    VectorRef (vec', index)
  | VectorSet (vec, index, value) ->
    let vec' = desugar vec in
    let value' = desugar value in
    VectorSet (vec', index, value')
  | _ -> expr

(* Given a typed expression, remove any macros/sugar from the expression. *)
let rec desugar_typed (expr : TypedStandard.typed_expression) : TypedStandard.typed_expression =
  let open Ast.TypedStandard in
  let uid = Dangerous_guid.get () in
  let variable_name = Printf.sprintf "_UNUSED_ds%d" uid in
  match expr with
  | (t, Begin ([])) -> (t, Void)
  | (t, Begin (expr :: [])) ->
    (T_VOID, LetExpression
       (variable_name, expr, (T_VOID, Void)))
  | (t, Begin (expr :: rest)) ->
    let (t', rest') = desugar_typed (t, (Begin rest)) in
    (t', (LetExpression
            (variable_name, expr, (t', rest'))))
  | (t, When (cond, exprs)) ->
    let exprs' = desugar_typed (t, (Begin exprs)) in
    (t, (IfExpression
           (cond,
            exprs',
            (T_VOID, Void))))
  | (t, Unless (cond, exprs)) ->
    let cond' = (T_BOOL, UnaryExpression (Not, cond)) in
    desugar_typed (t, When
                     (cond',
                      exprs))
  | (t, LetExpression (name, binding, body)) ->
    let binding' = desugar_typed binding in
    let body' = desugar_typed body in
    (t, LetExpression (name, binding', body'))
  | (t, IfExpression (test, consequent, alternate)) ->
    let test' = desugar_typed test in
    let consequent' = desugar_typed consequent in
    let alternate' = desugar_typed alternate in
    (t, IfExpression (test', consequent', alternate'))
  | (t, BinaryExpression (op, lhs, rhs)) ->
    let lhs' = desugar_typed lhs in
    let rhs' = desugar_typed rhs in
    (t, BinaryExpression (op, lhs', rhs'))
  | (t, UnaryExpression (op, operand)) ->
    let operand' = desugar_typed operand in
    (t, UnaryExpression (op, operand'))
  | (t, Vector exprs) ->
    let exprs' = List.fold_left (fun acc e -> (desugar_typed e) :: acc) [] exprs in
    (t, Vector exprs')
  | (t, VectorRef (vec, index)) ->
    let vec' = desugar_typed vec in
    (t, VectorRef (vec', index))
  | (t, VectorSet (vec, index, value)) ->
    let vec' = desugar_typed vec in
    let value' = desugar_typed value in
    (t, VectorSet (vec', index, value'))
  | (t, Global (str)) -> (t, Global (str))
  | (t, Collect) -> (t, Collect)
  | (t, Allocate (gs, tt, len)) -> (t, Allocate (gs, tt, len))
  | _ -> expr

(* Remove all macros/sugar from the given program. *)
let transform (prog : program) : program =
  let (defines, desugared) = match prog with
    | Program (defines, expr) -> (defines, desugar expr)
    | _ -> raise (Incorrect_step "expected type Program")
  in
  Program (defines, desugared)
