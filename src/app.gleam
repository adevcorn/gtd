import app/database
import app/router
import app/web.{Context}
import dot_env
import dot_env/env
import gleam/erlang/process
import gleam/option.{Some}
import mist
import wisp
import wisp/wisp_mist

pub fn main() {
  dot_env.new()
  |> dot_env.set_path(".env")
  |> dot_env.set_debug(False)
  |> dot_env.load

  let assert Ok(secret_key_base) = env.get_string("SECRET_KEY_BASE")
  let assert Ok(database_password) = env.get_string("DATABASE_PASSWORD")

  let connection = database.initialize_database(database_password)
  let _result = database.configure_database(connection)

  wisp.configure_logger()

  let context = Context(static_directory(), connection)

  let handler = router.handle_request(_, context)

  let assert Ok(_) =
    wisp_mist.handler(handler, secret_key_base)
    |> mist.new
    |> mist.port(8000)
    |> mist.start_http

  process.sleep_forever()
}

fn static_directory() {
  let assert Ok(priv_directory) = wisp.priv_directory("app")
  priv_directory <> "/static"
}
