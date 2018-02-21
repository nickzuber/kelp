
(* We print the intermediate steps and data structures when in debug mode. *)
let debug_mode = true

(* Decide if we bother to compute the liveness matrix. We don't need to since we use a graph instead,
   but having the matrix could be a good benchmark to see how efficient we're being in our graph relatively.
   WARNING: It's super slow for very large programs. Example, it will take ~4 months to compute a `pow2 13` program. *)
let compute_liveness_matrix = true

(* For the graph output to the terminal, use colors to easily identify variables at a glance. *)
let use_color_coded_graph = true

(* Show the verbose diffs if a test case fails. *)
let use_verbose_tests = true

(* Kind of like tab space for printing our data structures. *)
let padding_offset_for_pprint_ast = 2

(* Max amount of characters a program can have before we decide not to print it. *)
let max_characters_to_show = 6000
