let buf = Buffer.create 16

let rec read_token in_token =
  try
    let c = input_char stdin (* chan *) in
    match c with
      ' ' | '\t' | '\r' | '\n' ->
        if in_token then ()
        else read_token false
    | _ ->
        Buffer.add_char buf c;
        read_token true
  with
    End_of_file ->
      if in_token then () else raise End_of_file

let read_float () =
  Buffer.clear buf;
  read_token false;
  try
    let f = float_of_string (Buffer.contents buf) in
    let i = (Int32.to_int (Int32.bits_of_float f) (*land 0xFFFFFFFF*)) in
    (print_int i; print_newline (); f)
  with
    Failure _ -> failwith ((Buffer.contents buf) ^ ": float conversion failed.")

let read_int () =
  Buffer.clear buf;
  read_token false;
  try
    let i = int_of_string (Buffer.contents buf) in
    (print_int i; print_newline (); i)
  with
    Failure _ -> failwith ((Buffer.contents buf) ^ ": int conversion failed.")

(**** 環境データの読み込み ****)
let read_environ _ =
  (* スクリーン中心の座標 *)
  let screen_0 = read_float () in
  let screen_1 = read_float () in
  let screen_2 = read_float () in

  (* 回転角 *)
  let v1 = read_float () in
  let v2 = read_float () in

  let nl = read_float () in

  (* 光線関係 *)
  let l1 = read_float () in
  let l2 = read_float () in
  let beam_0 = read_float () in
  ()

(**** オブジェクト1つのデータの読み込み ****)
let read_nth_object _ =
  let texture = read_int () in
  if texture <> -1 then
    let form = read_int () in
    let refltype = read_int () in
    let isrot_p = read_int () in

    let abc_0 = read_float () in
    let abc_1 = read_float () in
    let abc_2 = read_float () in

    let xyz_0 = read_float () in
    let xyz_1 = read_float () in
    let xyz_2 = read_float () in

    let m_invert = read_float () in

    let reflparam_0 = read_float () in
    let reflparam_1 = read_float () in

    let color_0 = read_float () in
    let color_1 = read_float () in
    let color_2 = read_float () in

    let _ =
      if isrot_p <> 0 then
        let rotation_0 = read_float () in
        let rotation_1 = read_float () in
        let rotation_2 = read_float () in ()
      else ()
    in
    true
  else
    false

(**** 物体データ全体の読み込み ****)
let rec read_object n =
  if n < 61 then
    if read_nth_object n
    then read_object (n + 1)
    else ()
  else ()

let read_all_object _ =
  read_object 0

(**** AND, OR ネットワークの読み込み ****)

(* ネットワーク1つを読み込みベクトルにして返す *)
let rec read_net_item _ =
  if read_int () <> -1
  then let _ = read_net_item () in true
  else false

let rec read_or_network _ =
  if read_net_item ()
  then read_or_network ()
  else ()

let rec read_and_network _ =
  if read_net_item ()
  then read_and_network ()
  else ()

let rec read_parameter _ =
  (
    read_environ ();
    read_all_object ();
    read_and_network ();
    read_or_network ()
  )

let _ = read_parameter ()
