open OUnit

open Ast
open Compiler
open Pprint_ast

let test_int () = Ast.Standard.(
  let output = Program (Int 2)
    |> Uniquify.transform
    |> string_of_program in
  let expect = Program (Int 2)
    |> string_of_program in
  assert_equal output expect
)

let test_read () = Ast.Standard.(
  let output = Program (Read)
    |> Uniquify.transform
    |> string_of_program in
  let expect = Program (Read)
    |> string_of_program in
  assert_equal output expect
)

let test_binop () = Ast.Standard.(
  let output = Program
    (BinaryExpression
      (Plus,
      (Int 1),
      (Int 2)))
    |> Uniquify.transform
    |> string_of_program in
  let expect = Program
    (BinaryExpression
      (Plus,
      (Int 1),
      (Int 2)))
    |> string_of_program in
  assert_equal output expect
)

let test_unop () = Ast.Standard.(
  let output = Program
    (UnaryExpression
      (Minus,
      (Int 2)))
    |> Uniquify.transform
    |> string_of_program in
  let expect = Program
    (UnaryExpression
      (Minus,
      (Int 2)))
    |> string_of_program in
  assert_equal output expect
)

let test_letexpr () = Ast.Standard.(
  let output = Program
    (LetExpression
      ("x",
      (Int 1),
      (Int 2)))
    |> Uniquify.transform
    |> string_of_program in
  let expect = Program
    (LetExpression
      ("x_1",
      (Int 1),
      (Int 2)))
    |> string_of_program in
  assert_equal output expect
)

let test_letexpr_nested_diff_name () = Ast.Standard.(
  let output = Program
    (LetExpression
      ("x",
      (Int 1),
      (LetExpression
        ("y",
        (Int 1),
        (Variable "x")))))
    |> Uniquify.transform
    |> string_of_program in
  let expect = Program
      (LetExpression
        ("x_1",
        (Int 1),
        (LetExpression
          ("y_1",
          (Int 1),
          (Variable "x_1")))))
    |> string_of_program in
  assert_equal output expect
)

let test_letexpr_nested_same_name () = Ast.Standard.(
  let output = Program
    (LetExpression
      ("xz",
      (Int 1),
      (LetExpression
        ("x",
        (Int 1),
        (Variable "x")))))
    |> Uniquify.transform
    |> string_of_program in
  let expect = Program
      (LetExpression
        ("x_1",
        (Int 1),
        (LetExpression
          ("x_2",
          (Int 1),
          (Variable "x_2")))))
    |> string_of_program in
  assert_equal output expect
)

let test_letexpr_illegal_ref1 () = Ast.Standard.(
  let output = Program
    (LetExpression
      ("x",
      (Int 1),
      (LetExpression
        ("y",
        (Int 1),
        (Variable "z"))))) in
  let fn = fun () -> Uniquify.transform output in
  assert_raises (Uniquify.Illegal_variable_reference "z") fn
)

let test_letexpr_illegal_ref2 () = Ast.Standard.(
  let output = Program
    (LetExpression
      ("x",
      (Int 1),
      (LetExpression
        ("y",
        (Variable "y"),
        (Int 1))))) in
  let fn = fun () -> Uniquify.transform output in
  assert_raises (Uniquify.Illegal_variable_reference "y") fn
)

let test_complex () = Ast.Standard.(
  let output = Program
    (LetExpression
      ("x",
      (Int 1),
      (BinaryExpression
        (Plus,
        (Variable "x"),
        (LetExpression
          ("x",
          (Int 1),
          (LetExpression
            ("y",
            (Int 1),
            (BinaryExpression
              (Plus,
              (UnaryExpression
                (Minus,
                (Int 1))),
              (Variable "x")))))))))))
    |> Uniquify.transform
    |> string_of_program in
  let expect = Program
    (LetExpression
      ("x_1",
      (Int 1),
      (BinaryExpression
        (Plus,
        (Variable "x_1"),
        (LetExpression
          ("x_2",
          (Int 1),
          (LetExpression
            ("y_1",
            (Int 1),
            (BinaryExpression
              (Plus,
              (UnaryExpression
                (Minus,
                (Int 1))),
              (Variable "x_2")))))))))))
    |> string_of_program in
  assert_equal output expect
)

let main () = Runner.(
  print_endline ("\n\x1b[1mflatten\x1b[0m");
  run test_read "read" "Shouldn't change the structure of the input";
  run test_int "int" "Shouldn't change the structure of the input";
  run test_binop "binary expression" "Shouldn't change the structure of the input";
  run test_unop "unary expression" "Shouldn't change the structure of the input";
  run test_letexpr "let expression" "Should change x to x_1";
  run test_letexpr_nested_diff_name "let expression x and y" "Should change x and y and reference correct x";
  run test_letexpr_nested_same_name "let expression multi x" "Should change x's and reference correct x";
  run test_letexpr_illegal_ref1 "let expression illegal reference" "Should throw illegal reference exception on z";
  run test_letexpr_illegal_ref2 "let expression illegal reference" "Should throw illegal reference exception on y";
  run test_complex "complex expression" "Should change variables accordingly";
)
