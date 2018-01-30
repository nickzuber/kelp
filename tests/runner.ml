let run test name desc =
  try
    test ();
    print_endline ("\x1b[32m✓ success\x1b[39m " ^ name)
  with
    | _ -> print_endline ("\x1b[31m✕ failure\x1b[39m " ^ name ^ " \x1b[90m" ^ desc ^ "\x1b[39m")
